-- System by @thehandofvoid
-- Modified by @jay_peaceee
-- InventoryServer (REST + LEGACY DUAL-STACK)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")

local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))

local RoleConfig = require(ReplicatedStorage:WaitForChild("RoleConfig"))
local ToolConfig = nil
pcall(function()
	ToolConfig = require(ReplicatedStorage:WaitForChild("ToolDistributionConfig", 5))
end)

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local InventoryEvents = FishingSystem:FindFirstChild("InventoryEvents")
if not InventoryEvents then
	InventoryEvents = Instance.new("Folder")
	InventoryEvents.Name = "InventoryEvents"
	InventoryEvents.Parent = FishingSystem
end

local GameProfileService = require(game:GetService("ServerScriptService").Data.PetCore:WaitForChild("FishData"))
local FishingConfig = require(FishingSystem:WaitForChild("FishingConfig"))
local ShowNotification = FishingSystem:WaitForChild("ShowNotification")
local fishFolder = FishingSystem:WaitForChild("Assets"):WaitForChild("Fish")
local rodToolFolder = ServerStorage:WaitForChild("AllRods")
local allToolsFolder = ServerStorage:FindFirstChild("AllTools")
local vipToolFolder = ServerStorage:FindFirstChild("VIPTools") or ServerStorage:FindFirstChild("VIPtools")
local adminFolder = ServerStorage:FindFirstChild("AdminTools")

-- ===================================================================
-- CONFIGURATION
-- ===================================================================
local VIP_GAMEPASS_ID = 1590939529
local MAX_IDENTIFIER_LENGTH = 128
local RATE_LIMIT_EQUIP = 0.5
local RATE_LIMIT_READ = 0.5
local RATE_LIMIT_SELL = 2

local function notify(player, message, duration, color)
	ShowNotification:FireClient(player, message, duration, color or Color3.fromRGB(255, 255, 255))
end

local function respondSuccess(data, message)
	return {
		Success = true,
		StatusCode = 200,
		Data = data,
		Message = message or "OK",
	}
end

local function respondFailure(statusCode, errorCode, message)
	return {
		Success = false,
		StatusCode = statusCode,
		ErrorCode = errorCode,
		Message = message,
	}
end

local function sanitizeIdentifier(value)
	if type(value) ~= "string" then
		return nil
	end

	local trimmed = string.match(value, "^%s*(.-)%s*$")
	if not trimmed or trimmed == "" or #trimmed > MAX_IDENTIFIER_LENGTH then
		return nil
	end

	if string.find(trimmed, "%c") then
		return nil
	end

	return trimmed
end

local function getBackpack(player)
	return player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 5)
end

local lastInvAction = {}
Players.PlayerRemoving:Connect(function(player)
	lastInvAction[player] = nil
end)

local function isSpam(player, key, interval)
	local now = os.clock()
	lastInvAction[player] = lastInvAction[player] or {}
	if lastInvAction[player][key] and now - lastInvAction[player][key] < interval then
		return true
	end
	lastInvAction[player][key] = now
	return false
end

local function formatNumberWithCommas(number)
	local s = tostring(math.floor(number))
	local reversed = string.reverse(s)
	local formatted = reversed:gsub("(%d%d%d)", "%1,")
	return string.reverse(formatted):gsub("^,", "")
end

-- ===================================================================
-- LEGACY REMOTE OBJECTS
-- ===================================================================

local function getOrCreateRemoteEvent(name)
	local obj = InventoryEvents:FindFirstChild(name)
	if not obj or not obj:IsA("RemoteEvent") then
		if obj then obj:Destroy() end
		obj = Instance.new("RemoteEvent")
		obj.Name = name
		obj.Parent = InventoryEvents
	end
	return obj
end

local function getOrCreateRemoteFunction(name)
	local obj = InventoryEvents:FindFirstChild(name)
	if not obj or not obj:IsA("RemoteFunction") then
		if obj then obj:Destroy() end
		obj = Instance.new("RemoteFunction")
		obj.Name = name
		obj.Parent = InventoryEvents
	end
	return obj
end

local reEquipRod = getOrCreateRemoteEvent("Inventory_EquipRod")
local reEquipFish = getOrCreateRemoteEvent("Inventory_EquipFish")
local reUnequipAll = getOrCreateRemoteEvent("Inventory_UnequipAll")
local reEquipTool = getOrCreateRemoteEvent("Inventory_EquipTool")
local reEquipVIPTool = getOrCreateRemoteEvent("Inventory_EquipVIPTool")

local rfGetData = getOrCreateRemoteFunction("Inventory_GetData")
local rfToggleFavorite = getOrCreateRemoteFunction("Inventory_ToggleFavorite")
local rfSellAll = getOrCreateRemoteFunction("Inventory_SellAll")
local rfGetVIPTools = getOrCreateRemoteFunction("Inventory_GetVIPTools")

-- ===================================================================
-- VIP HELPER FUNCTIONS
-- ===================================================================

local function isPlayerVIP(player)
	if RoleConfig.IsOwner(player) or RoleConfig.IsAdmin(player) then
		return true
	end
	if player:GetAttribute("VIP") == true then
		return true
	end

	local passIds = { VIP_GAMEPASS_ID }
	if ToolConfig and ToolConfig.VIPGamepassIds then
		for _, pid in ipairs(ToolConfig.VIPGamepassIds) do
			if not table.find(passIds, pid) then
				table.insert(passIds, pid)
			end
		end
	end

	for _, passId in ipairs(passIds) do
		if passId and passId > 0 then
			local success, result = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
			end)
			if success and result then
				return true
			end
		end
	end

	return false
end

-- ===================================================================
-- INVENTORY HANDLERS
-- ===================================================================

local function onEquipRod(player, rodName)
	local cleanRodName = sanitizeIdentifier(rodName)
	if not cleanRodName then
		return respondFailure(400, "INVALID_ROD_NAME", "RodName must be a non-empty string.")
	end
	if isSpam(player, "equip", RATE_LIMIT_EQUIP) then
		return respondFailure(429, "RATE_LIMITED", "Too many equip requests.")
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return respondFailure(400, "NO_CHARACTER", "Character is not available.")
	end

	if not GameProfileService:HasRod(player, cleanRodName) then
		return respondFailure(400, "ROD_NOT_OWNED", "You do not own this rod.")
	end

	humanoid:UnequipTools()

	local backpack = getBackpack(player)
	if not backpack then
		return respondFailure(400, "NO_BACKPACK", "Backpack is not available.")
	end

	local tool = backpack:FindFirstChild(cleanRodName)

	if not tool then
		local rodTemplate = rodToolFolder:FindFirstChild(cleanRodName)
		if not rodTemplate or not rodTemplate:IsA("Tool") then
			return respondFailure(400, "ROD_TEMPLATE_NOT_FOUND", "Rod template not found.")
		end

		tool = rodTemplate:Clone()
		if not CollectionService:HasTag(tool, "Rod") then
			CollectionService:AddTag(tool, "Rod")
		end
		tool.Parent = backpack
	elseif not tool:IsA("Tool") then
		return respondFailure(400, "INVALID_ROD_TOOL", "The rod item is not a Tool.")
	else
		if not CollectionService:HasTag(tool, "Rod") then
			CollectionService:AddTag(tool, "Rod")
		end
	end

	humanoid:EquipTool(tool)
	GameProfileService:SetLastEquippedRod(player, cleanRodName)

	return respondSuccess({ RodName = cleanRodName }, "Rod equipped.")
end

local function onEquipTool(player, toolName)
	local cleanToolName = sanitizeIdentifier(toolName)
	if not cleanToolName then
		return respondFailure(400, "INVALID_TOOL_NAME", "ToolName must be a non-empty string.")
	end
	if isSpam(player, "equip", RATE_LIMIT_EQUIP) then
		return respondFailure(429, "RATE_LIMITED", "Too many equip requests.")
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return respondFailure(400, "NO_CHARACTER", "Character is not available.")
	end

	local backpack = getBackpack(player)
	if not backpack then
		return respondFailure(400, "NO_BACKPACK", "Backpack is not available.")
	end

	local tool = backpack:FindFirstChild(cleanToolName)
	if not tool or not tool:IsA("Tool") then
		return respondFailure(400, "TOOL_NOT_FOUND", "You do not have this tool in your backpack.")
	end

	humanoid:UnequipTools()
	humanoid:EquipTool(tool)

	return respondSuccess({ ToolName = cleanToolName }, "Tool equipped.")
end

local function onEquipVIPTool(player, toolName)
	local cleanToolName = sanitizeIdentifier(toolName)
	if not cleanToolName then
		return respondFailure(400, "INVALID_TOOL_NAME", "ToolName must be a non-empty string.")
	end
	if isSpam(player, "equip", RATE_LIMIT_EQUIP) then
		return respondFailure(429, "RATE_LIMITED", "Too many equip requests.")
	end
	if not isPlayerVIP(player) then
		notify(player, "You need VIP to use this tool!", 3, Color3.fromRGB(255, 100, 100))
		return respondFailure(400, "VIP_REQUIRED", "You need VIP to use this tool.")
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return respondFailure(400, "NO_CHARACTER", "Character is not available.")
	end

	local currentTool = character:FindFirstChildOfClass("Tool")
	if currentTool and currentTool.Name == cleanToolName then
		humanoid:UnequipTools()
		return respondSuccess({ ToolName = cleanToolName, Unequipped = true }, "Tool unequipped.")
	end

	local backpack = getBackpack(player)
	if not backpack then
		return respondFailure(400, "NO_BACKPACK", "Backpack is not available.")
	end

	local tool = backpack:FindFirstChild(cleanToolName)

	if not tool then
		if not allToolsFolder then
			allToolsFolder = ServerStorage:FindFirstChild("AllTools")
		end
		if not adminFolder then
			adminFolder = ServerStorage:FindFirstChild("AdminTools")
		end
		if not vipToolFolder then
			vipToolFolder = ServerStorage:FindFirstChild("VIPTools") or ServerStorage:FindFirstChild("VIPtools")
		end

		-- F-01 Fix (audit 18 Okt 2026): whitelist - hanya tool hak player yang boleh di-clone
		-- VIP hanya boleh tool di ToolConfig.VIPTools; Admin/Owner boleh semua (recovery)
		local allowedByRole = (ToolConfig and ToolConfig.IsVIPTool and ToolConfig.IsVIPTool(cleanToolName))
			or RoleConfig.IsAdmin(player)
		if not allowedByRole then
			notify(player, "Tool ini bukan bagian dari akses kamu!", 3, Color3.fromRGB(255, 100, 100))
			return respondFailure(400, "TOOL_NOT_ALLOWED", "This tool is not part of your access.")
		end

		local toolTemplate = (allToolsFolder and allToolsFolder:FindFirstChild(cleanToolName))
			or (adminFolder and adminFolder:FindFirstChild(cleanToolName))
			or (vipToolFolder and vipToolFolder:FindFirstChild(cleanToolName))

		if toolTemplate and toolTemplate:IsA("Tool") then
			tool = toolTemplate:Clone()
			CollectionService:AddTag(tool, "VIPTool")
			tool.Parent = backpack
		else
			warn("[InventoryServer] VIP/Admin Tool not found:", cleanToolName)
			return respondFailure(400, "TOOL_NOT_FOUND", "Tool not found.")
		end
	elseif not tool:IsA("Tool") then
		return respondFailure(400, "INVALID_TOOL", "The item is not a Tool.")
	end

	humanoid:UnequipTools()
	humanoid:EquipTool(tool)

	return respondSuccess({ ToolName = cleanToolName }, "VIP tool equipped.")
end

local function onEquipFish(player, fishUniqueId)
	local cleanFishUniqueId = sanitizeIdentifier(fishUniqueId)
	if not cleanFishUniqueId then
		return respondFailure(400, "INVALID_FISH_ID", "FishUniqueId must be a non-empty string.")
	end
	if isSpam(player, "equip", RATE_LIMIT_EQUIP) then
		return respondFailure(429, "RATE_LIMITED", "Too many equip requests.")
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return respondFailure(400, "NO_CHARACTER", "Character is not available.")
	end

	humanoid:UnequipTools()

	local backpack = getBackpack(player)
	if not backpack then
		return respondFailure(400, "NO_BACKPACK", "Backpack is not available.")
	end

	local toolToEquip = nil
	for _, tool in ipairs(backpack:GetChildren()) do
		local fishId = tool:FindFirstChild("FishId")
		if tool:IsA("Tool") and fishId and fishId.Value == cleanFishUniqueId then
			toolToEquip = tool
			break
		end
	end

	if not toolToEquip then
		local fishData = nil
		local allFish = GameProfileService:GetSavedFish(player)
		for _, fish in ipairs(allFish) do
			if fish.uniqueId == cleanFishUniqueId then
				fishData = fish
				break
			end
		end

		if not fishData then
			return respondFailure(400, "FISH_NOT_FOUND", "Fish not found in your inventory.")
		end

		local fishTemplate = fishFolder:FindFirstChild(fishData.name)
		if not fishTemplate or not fishTemplate:IsA("Tool") then
			return respondFailure(400, "FISH_TEMPLATE_NOT_FOUND", "Fish template not found.")
		end

		toolToEquip = fishTemplate:Clone()
		toolToEquip.ToolTip = " "

		local fishIdValue = Instance.new("StringValue")
		fishIdValue.Name = "FishId"
		fishIdValue.Value = fishData.uniqueId
		fishIdValue.Parent = toolToEquip

		local weightValue = Instance.new("NumberValue")
		weightValue.Name = "Weight"
		weightValue.Value = fishData.weight
		weightValue.Parent = toolToEquip

		local rarityValue = Instance.new("StringValue")
		rarityValue.Name = "Rarity"
		rarityValue.Value = fishData.rarity
		rarityValue.Parent = toolToEquip

		local favoritedValue = Instance.new("BoolValue")
		favoritedValue.Name = "isFavorited"
		favoritedValue.Value = fishData.isFavorited or false
		favoritedValue.Parent = toolToEquip

		toolToEquip.Parent = backpack
	end

	humanoid:EquipTool(toolToEquip)

	return respondSuccess({ FishUniqueId = cleanFishUniqueId }, "Fish equipped.")
end

local function onUnequipAll(player)
	if isSpam(player, "equip", RATE_LIMIT_EQUIP) then
		return respondFailure(429, "RATE_LIMITED", "Too many equip requests.")
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return respondFailure(400, "NO_CHARACTER", "Character is not available.")
	end

	humanoid:UnequipTools()

	return respondSuccess({ Unequipped = true }, "All tools unequipped.")
end

local function onGetData(player)
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

local function onGetVIPTools(player)
	if isSpam(player, "viptools", RATE_LIMIT_READ) then
		return respondFailure(429, "RATE_LIMITED", "Too many requests for VIP tools.")
	end
	if not isPlayerVIP(player) then
		return respondFailure(400, "VIP_REQUIRED", "VIP access is required.")
	end

	local toolList = {}
	local seen = {}

	if not allToolsFolder then
		allToolsFolder = ServerStorage:FindFirstChild("AllTools")
	end

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

local function onToggleFavorite(player, fishUniqueId)
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

local function onSellAll(player)
	if isSpam(player, "sellall", RATE_LIMIT_SELL) then
		return respondFailure(429, "RATE_LIMITED", "Please wait before selling again.")
	end

	local isVIP = isPlayerVIP(player)
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

	local totalCoins = 0
	local fishSoldCount = 0
	local fishToRemove_Ids = {}

	-- Hanya jual ikan yang BUKAN favorit
	for _, fish in ipairs(allFish) do
		if not fish.isFavorited then
			local price = FishingConfig.CalculateFishPrice(fish.weight, fish.rarity)
			totalCoins = totalCoins + price
			fishSoldCount = fishSoldCount + 1
			table.insert(fishToRemove_Ids, fish.uniqueId)
		end
	end

	if fishSoldCount == 0 then
		notify(player, "All your fish are favorited!", 3, Color3.fromRGB(255, 200, 100))
		return respondFailure(400, "ALL_FISH_FAVORITED", "All your fish are favorited.")
	end

	-- Hapus Ikan dari Data Inventaris (DataStore) secara efisien O(n)
	local idSet = {}
	for _, fishId in ipairs(fishToRemove_Ids) do
		idSet[fishId] = true
	end
	if GameProfileService.RemoveFishBatch then
		GameProfileService:RemoveFishBatch(player, idSet)
	else
		for _, fishId in ipairs(fishToRemove_Ids) do
			GameProfileService:RemoveFish(player, fishId)
		end
	end

	-- Tambahkan Koin ke Akun Pemain
	GameProfileService:AddCoins(player, totalCoins)

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

	local coinsString = formatNumberWithCommas(totalCoins)
	notify(player, string.format("Sold %d fish for %s coins!", fishSoldCount, coinsString), 3, Color3.fromRGB(100, 255, 100))

	return respondSuccess(totalCoins, string.format("Sold %d fish for %s coins!", fishSoldCount, coinsString))
end

-- ===================================================================
-- REST ROUTES
-- ===================================================================

local function payloadHandler(fieldName, handler)
	return function(player, payload)
		if type(payload) ~= "table" then
			return respondFailure(400, "INVALID_PAYLOAD", "Payload must be a table.")
		end

		local value = sanitizeIdentifier(payload[fieldName])
		if not value then
			return respondFailure(400, "INVALID_PAYLOAD", string.format("%s must be a non-empty string.", fieldName))
		end

		return handler(player, value)
	end
end

NetworkGateway:RegisterRoute("GET", "/inventory/data", function(player)
	return onGetData(player)
end, { rateLimitSeconds = RATE_LIMIT_READ })

NetworkGateway:RegisterRoute("GET", "/inventory/vip-tools", function(player)
	return onGetVIPTools(player)
end, { rateLimitSeconds = RATE_LIMIT_READ })

NetworkGateway:RegisterRoute("PUT", "/inventory/equip-rod", payloadHandler("RodName", onEquipRod), {
	rateLimitSeconds = RATE_LIMIT_EQUIP,
})

NetworkGateway:RegisterRoute("PUT", "/inventory/equip-fish", payloadHandler("FishUniqueId", onEquipFish), {
	rateLimitSeconds = RATE_LIMIT_EQUIP,
})

NetworkGateway:RegisterRoute("PUT", "/inventory/equip-tool", payloadHandler("ToolName", onEquipTool), {
	rateLimitSeconds = RATE_LIMIT_EQUIP,
})

NetworkGateway:RegisterRoute("PUT", "/inventory/equip-vip-tool", payloadHandler("ToolName", onEquipVIPTool), {
	rateLimitSeconds = RATE_LIMIT_EQUIP,
})

NetworkGateway:RegisterRoute("PUT", "/inventory/toggle-favorite", payloadHandler("FishUniqueId", onToggleFavorite), {
	rateLimitSeconds = RATE_LIMIT_EQUIP,
})

NetworkGateway:RegisterRoute("DELETE", "/inventory/unequip-all", function(player)
	return onUnequipAll(player)
end, { rateLimitSeconds = RATE_LIMIT_EQUIP })

NetworkGateway:RegisterRoute("DELETE", "/inventory/sell-all", function(player)
	return onSellAll(player)
end, { rateLimitSeconds = RATE_LIMIT_SELL })

-- ===================================================================
-- LEGACY ADAPTERS (TRANSITIONAL DUAL-STACK)
-- ===================================================================

local function unwrapLegacyResponse(response, fallback)
	if response and response.Success then
		return response.Data
	end
	return fallback
end

reEquipRod.OnServerEvent:Connect(function(player, rodName)
	onEquipRod(player, rodName)
end)

reEquipFish.OnServerEvent:Connect(function(player, fishUniqueId)
	onEquipFish(player, fishUniqueId)
end)

reUnequipAll.OnServerEvent:Connect(function(player)
	onUnequipAll(player)
end)

reEquipTool.OnServerEvent:Connect(function(player, toolName)
	onEquipTool(player, toolName)
end)

reEquipVIPTool.OnServerEvent:Connect(function(player, toolName)
	onEquipVIPTool(player, toolName)
end)

rfGetData.OnServerInvoke = function(player)
	return unwrapLegacyResponse(onGetData(player), nil)
end

rfToggleFavorite.OnServerInvoke = function(player, fishUniqueId)
	return unwrapLegacyResponse(onToggleFavorite(player, fishUniqueId), nil)
end

rfSellAll.OnServerInvoke = function(player)
	return unwrapLegacyResponse(onSellAll(player), 0)
end

rfGetVIPTools.OnServerInvoke = function(player)
	return unwrapLegacyResponse(onGetVIPTools(player), {})
end
