--!strict
-- ServerScriptService/RoleToolServer
-- Automatically grants role-specific, VIP, and Free tools from ServerStorage.AllTools to Backpack & StarterGear

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local RoleConfig = require(ReplicatedStorage:WaitForChild("RoleConfig"))
local ToolConfig = require(ReplicatedStorage:WaitForChild("ToolDistributionConfig"))

local allToolsFolder = ServerStorage:WaitForChild("AllTools", 10) :: Folder?

local function findToolTemplate(toolName: string): Tool?
	if not allToolsFolder then
		allToolsFolder = ServerStorage:FindFirstChild("AllTools")
	end
	if allToolsFolder then
		local candidate = allToolsFolder:FindFirstChild(toolName)
		if candidate and candidate:IsA("Tool") then
			return candidate
		end
	end
	return nil
end

local function isPlayerVIP(player: Player): boolean
	if player:GetAttribute("VIP") == true then
		return true
	end
	if RoleConfig.IsOwner(player) then
		return true
	end
	for _, passId in ipairs(ToolConfig.VIPGamepassIds) do
		if passId and passId > 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
			end)
			if ok and owns then
				return true
			end
		end
	end
	return false
end

local function grantToolsToPlayer(player: Player)
	if not player or not player.Parent then return end

	local backpack = player:WaitForChild("Backpack", 5)
	local starterGear = player:FindFirstChild("StarterGear")
	local character = player.Character

	local toolsToGrant: {string} = {}
	local addedSet: {[string]: boolean} = {}

	local function addTool(name: string)
		if not addedSet[name] then
			addedSet[name] = true
			table.insert(toolsToGrant, name)
		end
	end

	-- 1. Free Tools (Semua pemain)
	for _, toolName in ipairs(ToolConfig.FreeTools) do
		addTool(toolName)
	end

	-- 2. VIP Tools (Pemilik VIP Gamepass / Owner)
	if isPlayerVIP(player) then
		for _, toolName in ipairs(ToolConfig.VIPTools) do
			addTool(toolName)
		end
	end

	-- 3. Role / Admin Tools (Owner, Developer, Admin)
	local role = RoleConfig.GetPlayerRole(player)
	if role and ToolConfig.RoleTools[role] then
		for _, toolName in ipairs(ToolConfig.RoleTools[role]) do
			addTool(toolName)
		end
	end

	-- Berikan ke Backpack & StarterGear
	for _, toolName in ipairs(toolsToGrant) do
		local toolTemplate = findToolTemplate(toolName)
		if toolTemplate then
			local alreadyHas = (backpack and backpack:FindFirstChild(toolName))
				or (character and character:FindFirstChild(toolName))

			if not alreadyHas and backpack then
				local clone = toolTemplate:Clone()
				clone.Parent = backpack
				print(string.format("🎒 [RoleToolServer] Granted %s to %s's Backpack", toolName, player.Name))
			end

			if starterGear and not starterGear:FindFirstChild(toolName) then
				local cloneGear = toolTemplate:Clone()
				cloneGear.Parent = starterGear
			end
		else
			warn(string.format("⚠️ [RoleToolServer] Tool '%s' tidak ditemukan di ServerStorage.AllTools!", toolName))
		end
	end
end

local function setupPlayerVIPAttributes(player: Player)
	if RoleConfig.IsOwner(player) then
		player:SetAttribute("VIP", true)
		player:GetAttributeChangedSignal("VIP"):Connect(function()
			if player:GetAttribute("VIP") ~= true then
				player:SetAttribute("VIP", true)
			end
		end)
	elseif isPlayerVIP(player) then
		player:SetAttribute("VIP", true)
	end
end

local function onPlayerAdded(player: Player)
	setupPlayerVIPAttributes(player)

	player.CharacterAdded:Connect(function(character)
		task.wait(0.1)
		setupPlayerVIPAttributes(player)
		grantToolsToPlayer(player)
	end)

	if player.Character then
		task.defer(function()
			grantToolsToPlayer(player)
		end)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

print("✅ [RoleToolServer] Role & Tool Auto-Grant Server initialized successfully with AllTools.")
