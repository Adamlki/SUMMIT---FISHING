-- Equip / unequip handlers for InventoryServer.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local fishFolder = FishingSystem:WaitForChild("Assets"):WaitForChild("Fish")
local rodToolFolder = ServerStorage:WaitForChild("AllRods")

local RoleConfig = require(ReplicatedStorage:WaitForChild("RoleConfig"))
local GameProfileService = require(game:GetService("ServerScriptService").Data.PetCore:WaitForChild("FishData"))
local Shared = require(script.Parent:WaitForChild("InventoryShared"))
local Access = require(script.Parent:WaitForChild("InventoryAccess"))

local respondSuccess = Shared.respondSuccess
local respondFailure = Shared.respondFailure
local sanitizeIdentifier = Shared.sanitizeIdentifier
local getBackpack = Shared.getBackpack
local isSpam = Shared.isSpam
local notify = Shared.notify
local RATE_LIMIT_EQUIP = Shared.RATE_LIMIT_EQUIP

local Equip = {}

function Equip.onEquipRod(player, rodName)
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

function Equip.onEquipTool(player, toolName)
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

function Equip.onEquipVIPTool(player, toolName)
	local cleanToolName = sanitizeIdentifier(toolName)
	if not cleanToolName then
		return respondFailure(400, "INVALID_TOOL_NAME", "ToolName must be a non-empty string.")
	end
	if isSpam(player, "equip", RATE_LIMIT_EQUIP) then
		return respondFailure(429, "RATE_LIMITED", "Too many equip requests.")
	end
	if not Access.isPlayerVIP(player) then
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
		local folders = Shared.getToolsFolders()

		-- F-01 Fix (audit 18 Okt 2026): whitelist - hanya tool hak player yang boleh di-clone
		-- VIP hanya boleh tool di ToolConfig.VIPTools; Admin/Owner boleh semua (recovery)
		local ToolConfig = Shared.ToolConfig
		local allowedByRole = (ToolConfig and ToolConfig.IsVIPTool and ToolConfig.IsVIPTool(cleanToolName))
			or RoleConfig.IsAdmin(player)
		if not allowedByRole then
			notify(player, "Tool ini bukan bagian dari akses kamu!", 3, Color3.fromRGB(255, 100, 100))
			return respondFailure(400, "TOOL_NOT_ALLOWED", "This tool is not part of your access.")
		end

		local toolTemplate = (folders.all and folders.all:FindFirstChild(cleanToolName))
			or (folders.admin and folders.admin:FindFirstChild(cleanToolName))
			or (folders.vip and folders.vip:FindFirstChild(cleanToolName))

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

function Equip.onEquipFish(player, fishUniqueId)
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

function Equip.onUnequipAll(player)
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

return Equip
