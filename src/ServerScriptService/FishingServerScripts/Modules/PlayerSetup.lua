-- Player lifecycle: rod tagging/restoring, saved fish restore and role rods.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local DataManager = require(FishingSystem:WaitForChild("FishingModules"):WaitForChild("DataManager"))
local FishingConfig = require(FishingSystem:WaitForChild("FishingConfig"))
local GameProfileService = require(ServerScriptService.Data.PetCore:WaitForChild("FishData"))

local fishFolder = FishingSystem:WaitForChild("Assets"):WaitForChild("Fish")
local rodToolFolder = ServerStorage:WaitForChild("AllRods")

local PlayerSetup = {}

local function tagRod(tool)
	-- CRITICAL: every rod handed to a player must carry the "Rod" tag
	if not CollectionService:HasTag(tool, "Rod") then
		CollectionService:AddTag(tool, "Rod")
	end
end

-- ===================================================================
-- HELPER: TAG ALL RODS IN FOLDER (Run once at startup)
-- ===================================================================
local function tagAllRodsInFolder()
	if rodToolFolder then
		for _, rod in ipairs(rodToolFolder:GetChildren()) do
			if rod:IsA("Tool") and not CollectionService:HasTag(rod, "Rod") then
				CollectionService:AddTag(rod, "Rod")
			end
		end
	end
	local rsRodFolder = FishingSystem:FindFirstChild("Assets") and FishingSystem.Assets:FindFirstChild("Rod")
	if rsRodFolder then
		for _, rod in ipairs(rsRodFolder:GetChildren()) do
			if rod:IsA("Tool") and not CollectionService:HasTag(rod, "Rod") then
				CollectionService:AddTag(rod, "Rod")
			end
		end
	end
end

function PlayerSetup.getEquippedRodName(player)
	local char = player.Character
	if char then
		local tool = char:FindFirstChildOfClass("Tool")
		if tool and CollectionService:HasTag(tool, "Rod") then
			return tool.Name
		end
	end
	return DataManager:GetLastEquippedRod(player) or "Basic Rod"
end

-- ===================================================================
-- RESTORE FUNCTIONS (WITH ROD TAGGING)
-- ===================================================================
local function restoreSavedFish(player)
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end
	local savedFish = DataManager:GetSavedFish(player)
	if not savedFish or #savedFish == 0 then return end

	-- Pulihkan hingga 50 ikan terakhir ke Backpack agar hotbar tidak penuh dan tidak lag
	local MAX_RESTORE_TOOLS = 50
	local startIndex = math.max(1, #savedFish - MAX_RESTORE_TOOLS + 1)

	for i = startIndex, #savedFish do
		local fishData = savedFish[i]
		if not fishData then continue end

		-- Hindari duplikasi jika tool ikan dengan ID yang sama sudah ada di backpack / character
		local alreadyExists = false
		for _, item in ipairs(backpack:GetChildren()) do
			local idVal = item:FindFirstChild("FishId")
			if idVal and idVal.Value == fishData.uniqueId then
				alreadyExists = true
				break
			end
		end
		if not alreadyExists and player.Character then
			for _, item in ipairs(player.Character:GetChildren()) do
				local idVal = item:FindFirstChild("FishId")
				if idVal and idVal.Value == fishData.uniqueId then
					alreadyExists = true
					break
				end
			end
		end

		if not alreadyExists then
			local fishClone = fishFolder:FindFirstChild(fishData.name)
			if fishClone then
				local toolClone = fishClone:Clone()
				toolClone.ToolTip = " "
				local idValue = Instance.new("StringValue", toolClone); idValue.Name = "FishId"; idValue.Value = fishData.uniqueId
				local weightValue = Instance.new("NumberValue", toolClone); weightValue.Name = "Weight"; weightValue.Value = fishData.weight
				local rarityValue = Instance.new("StringValue", toolClone); rarityValue.Name = "Rarity"; rarityValue.Value = fishData.rarity
				local favValue = Instance.new("BoolValue", toolClone); favValue.Name = "isFavorited"; favValue.Value = fishData.isFavorited or false
				toolClone.Parent = backpack
			end
		end
	end
end

local function restoreOwnedRods(player)
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end
	local ownedRods = DataManager:GetOwnedRods(player)
	for _, rodName in ipairs(ownedRods) do
		if not backpack:FindFirstChild(rodName) then
			local rodTool = rodToolFolder:FindFirstChild(rodName)
			if rodTool then
				local clonedRod = rodTool:Clone()
				tagRod(clonedRod)
				clonedRod.Parent = backpack
			end
		end
	end
end

local function restoreRoleRods(player)
	local config = FishingConfig.RoleSettings
	if not config or not config.Enabled or config.GroupID == 0 then return end
	local backpack = player:FindFirstChild("Backpack")
	local playerRank = 0
	pcall(function() playerRank = player:GetRankInGroup(config.GroupID) end)
	if playerRank == 0 then return end
	for _, data in pairs(config.RoleRodMapping) do
		if playerRank == data.RankID then
			local rodToGive = data.RodName
			if not backpack:FindFirstChild(rodToGive) then
				local rodTool = rodToolFolder:FindFirstChild(rodToGive)
				if rodTool then
					local clonedRod = rodTool:Clone()
					tagRod(clonedRod)
					clonedRod.Parent = backpack
					DataManager:AddRod(player, rodToGive)
				end
			end
			break
		end
	end
end

-- ===================================================================
-- PLAYER ADDED (GIVES BASIC ROD WITH TAG)
-- ===================================================================
local function handlePlayerFishingInit(player)
	task.spawn(function()
		-- Wait for FishData to load profile
		local profile = nil
		local attempts = 0
		while attempts < 30 and not profile and player:IsDescendantOf(Players) do
			profile = GameProfileService:GetProfile(player)
			if not profile then
				attempts += 1
				task.wait(0.5)
			end
		end

		if not profile then
			warn("[FishingServer] DataStore profile load delay for " .. player.Name .. " - retrying in background without kicking.")
			while not profile and player:IsDescendantOf(Players) do
				task.wait(2)
				profile = GameProfileService:GetProfile(player)
			end
		end

		if not player:IsDescendantOf(Players) or not profile then return end

		-- Add Basic Rod to data
		DataManager:AddRod(player, "Basic Rod")

		-- Function to give Basic Rod with proper tag
		local function giveBasicRodWithTag()
			local backpack = player:FindFirstChild("Backpack")
			if not backpack then return end

			-- Check if player already has Basic Rod
			if backpack:FindFirstChild("Basic Rod") then return end

			local basicRodTemplate = rodToolFolder:FindFirstChild("Basic Rod")
			if basicRodTemplate then
				local clonedRod = basicRodTemplate:Clone()
				tagRod(clonedRod)
				clonedRod.Parent = backpack
			else
				warn("⚠️ [FishingServer] Basic Rod not found in ServerStorage.AllRods!")
			end
		end

		player.CharacterAdded:Connect(function(character)
			task.wait(0.3)
			giveBasicRodWithTag()
			restoreRoleRods(player)
		end)

		if player.Character then
			task.spawn(function()
				task.wait(0.3)
				giveBasicRodWithTag()
				restoreRoleRods(player)
			end)
		end
	end)
end

function PlayerSetup.Start()
	task.spawn(tagAllRodsInFolder)

	Players.PlayerAdded:Connect(handlePlayerFishingInit)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(handlePlayerFishingInit, player)
	end
end

return PlayerSetup
