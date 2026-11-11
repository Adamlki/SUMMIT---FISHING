-- System by @thehandofvoid
-- Modified by @jay_peaceee
-- InventoryServer (WITH UNIFIED ALLTOOLS & TOOLDISTRIBUTIONCONFIG SUPPORT - RESTORED COMPATIBILITY)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")

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
-- VIP CONFIGURATION
-- ===================================================================
local VIP_GAMEPASS_ID = 1590939529

local function notify(player, message, duration, color)
	ShowNotification:FireClient(player, message, duration, color or Color3.fromRGB(255, 255, 255))
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
-- CREATE EVENTS WITH CORRECT TYPES (100% COMPATIBLE WITH CustomInventoryManager)
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
-- INVENTORY FUNCTIONS
-- ===================================================================

local function onEquipRod(player, rodName)
	if isSpam(player, "equip", 0.5) then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if not GameProfileService:HasRod(player, rodName) then return end

	humanoid:UnequipTools()

	local backpack = player:WaitForChild("Backpack")
	local tool = backpack:FindFirstChild(rodName)

	if not tool then
		local rodTemplate = rodToolFolder:FindFirstChild(rodName)
		if rodTemplate then
			tool = rodTemplate:Clone()
			if not CollectionService:HasTag(tool, "Rod") then
				CollectionService:AddTag(tool, "Rod")
			end
			tool.Parent = backpack
		else
			return
		end
	else
		if not CollectionService:HasTag(tool, "Rod") then
			CollectionService:AddTag(tool, "Rod")
		end
	end

	humanoid:EquipTool(tool)
	GameProfileService:SetLastEquippedRod(player, rodName)
end

local function onEquipTool(player, toolName)
	if isSpam(player, "equip", 0.5) then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local backpack = player:WaitForChild("Backpack")
	local tool = backpack:FindFirstChild(toolName)

	if tool and tool:IsA("Tool") then
		humanoid:UnequipTools()
		humanoid:EquipTool(tool)
	end
end

local function onEquipVIPTool(player, toolName)
	if isSpam(player, "equip", 0.5) then return end
	if not isPlayerVIP(player) then
		notify(player, "You need VIP to use this tool!", 3, Color3.fromRGB(255, 100, 100))
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local currentTool = character:FindFirstChildOfClass("Tool")
	if currentTool and currentTool.Name == toolName then
		humanoid:UnequipTools()
		return
	end

	local backpack = player:WaitForChild("Backpack")
	local tool = backpack:FindFirstChild(toolName)

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
		local allowedByRole = (ToolConfig and ToolConfig.IsVIPTool and ToolConfig.IsVIPTool(toolName))
			or RoleConfig.IsAdmin(player)
		if not allowedByRole then
			notify(player, "Tool ini bukan bagian dari akses kamu!", 3, Color3.fromRGB(255, 100, 100))
			return
		end

		local toolTemplate = (allToolsFolder and allToolsFolder:FindFirstChild(toolName))
			or (adminFolder and adminFolder:FindFirstChild(toolName))
			or (vipToolFolder and vipToolFolder:FindFirstChild(toolName))

		if toolTemplate and toolTemplate:IsA("Tool") then
			tool = toolTemplate:Clone()
			CollectionService:AddTag(tool, "VIPTool")
			tool.Parent = backpack
		else
			warn("[InventoryServer] VIP/Admin Tool not found:", toolName)
			return
		end
	end

	humanoid:UnequipTools()
	humanoid:EquipTool(tool)
end

local function onEquipFish(player, fishUniqueId)
	if isSpam(player, "equip", 0.5) then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	humanoid:UnequipTools()

	local backpack = player:WaitForChild("Backpack")
	local toolToEquip = nil
	for _, tool in ipairs(backpack:GetChildren()) do
		local fishId = tool:FindFirstChild("FishId")
		if tool:IsA("Tool") and fishId and fishId.Value == fishUniqueId then
			toolToEquip = tool
			break
		end
	end

	if not toolToEquip then
		local fishData = nil
		local allFish = GameProfileService:GetSavedFish(player)
		for _, fish in ipairs(allFish) do
			if fish.uniqueId == fishUniqueId then
				fishData = fish
				break
			end
		end

		if not fishData then return end
		local fishTemplate = fishFolder:FindFirstChild(fishData.name)
		if not fishTemplate then return end

		toolToEquip = fishTemplate:Clone()
		toolToEquip.ToolTip = " "
		Instance.new("StringValue", toolToEquip).Name = "FishId"
		toolToEquip.FishId.Value = fishData.uniqueId
		Instance.new("NumberValue", toolToEquip).Name = "Weight"
		toolToEquip.Weight.Value = fishData.weight
		Instance.new("StringValue", toolToEquip).Name = "Rarity"
		toolToEquip.Rarity.Value = fishData.rarity

		-- Pastikan nilai isFavorited diambil dari data yang tersimpan
		Instance.new("BoolValue", toolToEquip).Name = "isFavorited"
		toolToEquip.isFavorited.Value = fishData.isFavorited or false

		toolToEquip.Parent = backpack
	end

	humanoid:EquipTool(toolToEquip)
end

local function onUnequipAll(player)
	if isSpam(player, "equip", 0.5) then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:UnequipTools()
	end
end

local function onGetData(player)
	if isSpam(player, "getdata", 0.5) then
		return {
			Fish = GameProfileService:GetSavedFish(player),
			Rods = GameProfileService:GetOwnedRods(player),
			LastRod = GameProfileService:GetLastEquippedRod(player)
		}
	end
	local fishData = GameProfileService:GetSavedFish(player)
	local rodData = GameProfileService:GetOwnedRods(player)
	local lastRod = GameProfileService:GetLastEquippedRod(player)

	return {
		Fish = fishData,
		Rods = rodData,
		LastRod = lastRod
	}
end

local function onGetVIPTools(player)
	if isSpam(player, "viptools", 0.5) then return {} end
	if not isPlayerVIP(player) then
		return {}
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

	return toolList
end

local function onToggleFavorite(player, fishUniqueId)
	if isSpam(player, "fav", 0.5) then return nil end
	local newStatus = GameProfileService:ToggleFavoriteFish(player, fishUniqueId)
	local backpack = player:WaitForChild("Backpack")

	-- Update tool di Backpack jika ada
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool:FindFirstChild("FishId") and tool.FishId.Value == fishUniqueId then
			local favValue = tool:FindFirstChild("isFavorited")
			if favValue then favValue.Value = newStatus end
			break
		end
	end

	-- Update tool di Character jika sedang di-equip
	local character = player.Character
	if character then
		local equippedTool = character:FindFirstChildOfClass("Tool")
		if equippedTool and equippedTool:FindFirstChild("FishId") and equippedTool.FishId.Value == fishUniqueId then
			local favValue = equippedTool:FindFirstChild("isFavorited")
			if favValue then favValue.Value = newStatus end
		end
	end

	return newStatus
end

local function onSellAll(player)
	if isSpam(player, "sellall", 2) then return 0 end
	local isVIP = isPlayerVIP(player)
	local hasRemoteSell = player:GetAttribute("HasRemoteSell") == true
		or player:GetAttribute("CanSellAnywhere") == true
		or GameProfileService:HasRemoteSell(player)
		or isVIP
	if not hasRemoteSell then
		notify(player, "🔒 Fitur Jual Ikan di Tas terkunci! Buka fitur ini di Toko atau kunjungi NPC Sell di map.", 4, Color3.fromRGB(255, 120, 100))
		return 0
	end

	local allFish = GameProfileService:GetSavedFish(player)

	if #allFish == 0 then
		notify(player, "No fish to sell.", 3, Color3.fromRGB(255, 200, 100))
		return 0
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
		return 0
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

	local backpack = player:WaitForChild("Backpack")
	local character = player.Character
	local fishToRemove_Tools = {}

	-- Hapus Tool Ikan dari Backpack
	for _, tool in ipairs(backpack:GetChildren()) do
		local fishId = tool:FindFirstChild("FishId")
		if tool:IsA("Tool") and fishId and table.find(fishToRemove_Ids, fishId.Value) then
			table.insert(fishToRemove_Tools, tool)
		end
	end

	-- Hapus Tool Ikan dari Karakter (Jika sedang di-equip)
	if character then
		local equippedTool = character:FindFirstChildOfClass("Tool")
		local fishId = equippedTool and equippedTool:FindFirstChild("FishId")
		if fishId and equippedTool:IsA("Tool") and table.find(fishToRemove_Ids, fishId.Value) then
			table.insert(fishToRemove_Tools, equippedTool)
		end
	end

	-- Hancurkan semua tool ikan yang terjual
	for _, tool in ipairs(fishToRemove_Tools) do
		tool:Destroy()
	end

	local coinsString = formatNumberWithCommas(totalCoins)
	notify(player, string.format("Sold %d fish for %s coins!", fishSoldCount, coinsString), 3, Color3.fromRGB(100, 255, 100))

	return totalCoins
end

-- ===================================================================
-- CONNECT EVENTS
-- ===================================================================

reEquipRod.OnServerEvent:Connect(onEquipRod)
reEquipFish.OnServerEvent:Connect(onEquipFish)
reUnequipAll.OnServerEvent:Connect(onUnequipAll)
reEquipTool.OnServerEvent:Connect(onEquipTool)
reEquipVIPTool.OnServerEvent:Connect(onEquipVIPTool)

rfGetData.OnServerInvoke = onGetData
rfToggleFavorite.OnServerInvoke = onToggleFavorite
rfSellAll.OnServerInvoke = onSellAll
rfGetVIPTools.OnServerInvoke = onGetVIPTools
