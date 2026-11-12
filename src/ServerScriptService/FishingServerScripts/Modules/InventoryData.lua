-- Inventory read / sell / favorite handlers for InventoryServer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local FishingConfig = require(FishingSystem:WaitForChild("FishingConfig"))

local RoleConfig = require(ReplicatedStorage:WaitForChild("RoleConfig"))
local GameProfileService = require(game:GetService("ServerScriptService").Data.PetCore:WaitForChild("FishData"))
local Shared = require(script.Parent:WaitForChild("InventoryShared"))
local Access = require(script.Parent:WaitForChild("InventoryAccess"))

local respondSuccess = Shared.respondSuccess
local respondFailure = Shared.respondFailure
local sanitizeIdentifier = Shared.sanitizeIdentifier
local isSpam = Shared.isSpam
local notify = Shared.notify
local RATE_LIMIT_READ = Shared.RATE_LIMIT_READ
local RATE_LIMIT_EQUIP = Shared.RATE_LIMIT_EQUIP
local RATE_LIMIT_SELL = Shared.RATE_LIMIT_SELL

local Data = {}

function Data.onGetData(player)
	-- Legacy behavior: this read is throttled but never blocked.
	isSpam(player, "getdata", RATE_LIMIT_READ)

	local fishData = GameProfileService:GetSavedFish(player)
	local rodData = GameProfileService:GetOwnedRods(player)
	local lastRod = GameProfileService:GetLastEquippedRod(player)

	return respondSuccess({
		Fish = fishData,
		Rods = rodData,
		LastRod = lastRod,
	}, "Inventory data retrieved.")
end

function Data.onGetVIPTools(player)
	if isSpam(player, "viptools", RATE_LIMIT_READ) then
		return respondFailure(429, "RATE_LIMITED", "Too many requests for VIP tools.")
	end
	if not Access.isPlayerVIP(player) then
		return respondFailure(400, "VIP_REQUIRED", "VIP access is required.")
	end

	local toolList = {}
	local seen = {}
	local ToolConfig = Shared.ToolConfig
	local allToolsFolder = Shared.getToolsFolders().all

	-- 1. Tools untuk Owner / Admin
	if RoleConfig.IsOwner(player) or RoleConfig.IsAdmin(player) then
		if ToolConfig and ToolConfig.RoleTools and ToolConfig.RoleTools.Owner and allToolsFolder then
			for _, toolName in ipairs(ToolConfig.RoleTools.Owner) do
				local t = allToolsFolder:FindFirstChild(toolName)
				if t and t:IsA("Tool") and not seen[t.Name] then
					seen[t.Name] = true
					table.insert(toolList, { Name = t.Name, TextureId = t.TextureId })
				end
			end
		end

		local adminF = ServerStorage:FindFirstChild("AdminTools")
		if adminF then
			for _, tool in ipairs(adminF:GetChildren()) do
				if tool:IsA("Tool") and not seen[tool.Name] then
					seen[tool.Name] = true
					table.insert(toolList, { Name = tool.Name, TextureId = tool.TextureId })
				end
			end
		end
	end

	-- 2. Tools VIP dari ToolDistributionConfig
	if ToolConfig and ToolConfig.VIPTools and allToolsFolder then
		for _, toolName in ipairs(ToolConfig.VIPTools) do
			local t = allToolsFolder:FindFirstChild(toolName)
			if t and t:IsA("Tool") and not seen[t.Name] then
				seen[t.Name] = true
				table.insert(toolList, { Name = t.Name, TextureId = t.TextureId })
			end
		end
	end

	-- 3. Fallback folder VIPTools
	local vipF = ServerStorage:FindFirstChild("VIPTools") or ServerStorage:FindFirstChild("VIPtools")
	if vipF then
		for _, tool in ipairs(vipF:GetChildren()) do
			if tool:IsA("Tool") and not seen[tool.Name] then
				seen[tool.Name] = true
				table.insert(toolList, { Name = tool.Name, TextureId = tool.TextureId })
			end
		end
	end

	return respondSuccess(toolList, "VIP tools retrieved.")
end

function Data.onToggleFavorite(player, fishUniqueId)
	local cleanFishUniqueId = sanitizeIdentifier(fishUniqueId)
	if not cleanFishUniqueId then
		return respondFailure(400, "INVALID_FISH_ID", "FishUniqueId must be a non-empty string.")
	end
	if isSpam(player, "fav", RATE_LIMIT_EQUIP) then
		return respondFailure(429, "RATE_LIMITED", "Too many favorite requests.")
	end

	local newStatus = GameProfileService:ToggleFavoriteFish(player, cleanFishUniqueId)
	if newStatus == nil then
		return respondFailure(400, "FISH_NOT_FOUND", "Fish not found in your inventory.")
	end

	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool:FindFirstChild("FishId") and tool.FishId.Value == cleanFishUniqueId then
				local favValue = tool:FindFirstChild("isFavorited")
				if favValue then
					favValue.Value = newStatus
				end
				break
			end
		end
	end

	local character = player.Character
	if character then
		local equippedTool = character:FindFirstChildOfClass("Tool")
		if equippedTool and equippedTool:FindFirstChild("FishId") and equippedTool.FishId.Value == cleanFishUniqueId then
			local favValue = equippedTool:FindFirstChild("isFavorited")
			if favValue then
				favValue.Value = newStatus
			end
		end
	end

	return respondSuccess(
		newStatus,
		newStatus and "Fish added to favorites." or "Fish removed from favorites."
	)
end

function Data.onSellAll(player)
	if isSpam(player, "sellall", RATE_LIMIT_SELL) then
		return respondFailure(429, "RATE_LIMITED", "Please wait before selling again.")
	end

	local profile = GameProfileService:GetProfile(player)
	if not profile or not profile:IsActive() then
		notify(player, "Data pemain belum siap. Coba lagi.", 3, Color3.fromRGB(255, 200, 100))
		return respondFailure(503, "PROFILE_NOT_READY", "Player profile is not ready.")
	end

	local isVIP = Access.isPlayerVIP(player)
	local hasRemoteSell = player:GetAttribute("HasRemoteSell") == true
		or player:GetAttribute("CanSellAnywhere") == true
		or GameProfileService:HasRemoteSell(player)
		or isVIP
	if not hasRemoteSell then
		notify(player, "🔒 Fitur Jual Ikan di Tas terkunci! Buka fitur ini di Toko atau kunjungi NPC Sell di map.", 4, Color3.fromRGB(255, 120, 100))
		return respondFailure(400, "REMOTE_SELL_LOCKED", "Remote selling is locked.")
	end

	local allFish = GameProfileService:GetSavedFish(player)

	if #allFish == 0 then
		notify(player, "No fish to sell.", 3, Color3.fromRGB(255, 200, 100))
		return respondFailure(400, "NO_FISH", "No fish to sell.")
	end

	local fishToRemove_Ids = {}

	-- Hanya jual ikan yang BUKAN favorit
	for _, fish in ipairs(allFish) do
		if not fish.isFavorited then
			table.insert(fishToRemove_Ids, fish.uniqueId)
		end
	end

	if #fishToRemove_Ids == 0 then
		notify(player, "All your fish are favorited!", 3, Color3.fromRGB(255, 200, 100))
		return respondFailure(400, "ALL_FISH_FAVORITED", "All your fish are favorited.")
	end

	-- Hapus Ikan dari Data Inventaris (DataStore) secara efisien O(n)
	local idSet = {}
	for _, fishId in ipairs(fishToRemove_Ids) do
		idSet[fishId] = true
	end
	local removedCount = 0
	local removedFish = {}
	if GameProfileService.RemoveFishBatch then
		removedCount, removedFish = GameProfileService:RemoveFishBatch(player, idSet)
		removedFish = removedFish or {}
	else
		for _, fishId in ipairs(fishToRemove_Ids) do
			local removed, fish = GameProfileService:RemoveFish(player, fishId)
			if removed and fish then
				removedCount = removedCount + 1
				table.insert(removedFish, fish)
			end
		end
	end

	if removedCount == 0 then
		notify(player, "No fish could be removed. Try again.", 3, Color3.fromRGB(255, 120, 100))
		return respondFailure(500, "SELL_FAILED", "No fish were removed.")
	end

	-- Hitung hanya ikan yang benar-benar terhapus.
	local totalCoins = 0
	for _, fish in ipairs(removedFish) do
		totalCoins = totalCoins + FishingConfig.CalculateFishPrice(fish.weight, fish.rarity)
	end

	-- Tambahkan koin dulu; kalau gagal, kembalikan ikan dan jangan hancurkan tool.
	local paid = GameProfileService:AddCoins(player, totalCoins)
	if not paid then
		local rollbackFailed = 0
		for _, fish in ipairs(removedFish) do
			if not GameProfileService:AddExistingFish(player, fish) then
				rollbackFailed = rollbackFailed + 1
			end
		end
		if rollbackFailed > 0 then
			warn(string.format("[SellAll] Gagal rollback %d ikan untuk %s", rollbackFailed, player.Name))
			notify(player, string.format("Gagal menambahkan koin dan gagal mengembalikan %d ikan. Hubungi admin.", rollbackFailed), 5, Color3.fromRGB(255, 100, 100))
			return respondFailure(500, "ROLLBACK_FAILED", string.format("Failed to add coins and rollback %d fish.", rollbackFailed))
		end
		notify(player, "Gagal menambahkan koin. Ikan tidak jadi dijual.", 3, Color3.fromRGB(255, 120, 100))
		return respondFailure(500, "COIN_CREDIT_FAILED", "Failed to add coins; sale cancelled.")
	end

	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	local fishToRemove_Tools = {}

	-- Hapus Tool Ikan dari Backpack
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			local fishId = tool:FindFirstChild("FishId")
			if tool:IsA("Tool") and fishId and idSet[fishId.Value] then
				table.insert(fishToRemove_Tools, tool)
			end
		end
	end

	-- Hapus Tool Ikan dari Karakter (Jika sedang di-equip)
	if character then
		local equippedTool = character:FindFirstChildOfClass("Tool")
		local fishId = equippedTool and equippedTool:FindFirstChild("FishId")
		if fishId and equippedTool:IsA("Tool") and idSet[fishId.Value] then
			table.insert(fishToRemove_Tools, equippedTool)
		end
	end

	-- Hancurkan semua tool ikan yang terjual
	for _, tool in ipairs(fishToRemove_Tools) do
		tool:Destroy()
	end

	local coinsString = Shared.formatNumberWithCommas(totalCoins)
	notify(player, string.format("Sold %d fish for %s coins!", removedCount, coinsString), 3, Color3.fromRGB(100, 255, 100))

	return respondSuccess(totalCoins, string.format("Sold %d fish for %s coins!", removedCount, coinsString))
end

return Data
