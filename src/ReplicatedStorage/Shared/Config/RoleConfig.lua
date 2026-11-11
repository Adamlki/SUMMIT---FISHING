--!strict
-- ReplicatedStorage/Shared/Config/RoleConfig
-- SINGLE SOURCE OF TRUTH for Roles, Permissions, Overhead/Chat Tags, and Auto-Grant Tools

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

export type RoleDefinition = {
	Rank: number,
	DisplayRole: string,
	ChatTag: Color3,
	CanUsePanel: boolean,
	AutoGrantTools: {string},
	UserIds: {number},
	Usernames: {string},
}

local RoleConfig = {}

-- PLACE OWNER IDENTIFIERS
RoleConfig.PlaceOwnerId = 8978185974 -- Game Creator

RoleConfig.Roles = {
	Owner = {
		Rank = 100,
		DisplayRole = "OWNER",
		ChatTag = Color3.fromRGB(255, 215, 0), -- Radiant Gold
		CanUsePanel = true,
		AutoGrantTools = { "Admin", "Poison", "Void", "BoomBox" },
		UserIds = { 8978185974, 10375072008 },
		Usernames = {},
	},
	Developer = {
		Rank = 80,
		DisplayRole = "DEVELOPER",
		ChatTag = Color3.fromRGB(255, 60, 60), -- Crimson Red
		CanUsePanel = true,
		AutoGrantTools = { "Admin" },
		UserIds = { 10165939218, 9443442225, 2939646349 },
		Usernames = {},
	},
	Admin = {
		Rank = 60,
		DisplayRole = "ADMIN",
		ChatTag = Color3.fromRGB(255, 80, 80), -- Red
		CanUsePanel = true,
		AutoGrantTools = { "Admin" },
		UserIds = { 7319628066 },
		Usernames = { "guard_zvxjekybix" },
	},
	Moderator = {
		Rank = 40,
		DisplayRole = "MODERATOR",
		ChatTag = Color3.fromRGB(50, 150, 255), -- Azure Blue
		CanUsePanel = true,
		AutoGrantTools = {},
		UserIds = {},
		Usernames = {},
	},
	VIP = {
		Rank = 20,
		DisplayRole = "VIP",
		ChatTag = Color3.fromRGB(255, 200, 0),
		CanUsePanel = false,
		AutoGrantTools = {},
		UserIds = {},
		Usernames = {},
	}
}

-- Checks if a player matches any ID or Username list
local function matches(listIds: {number}?, listNames: {string}?, player: Player): boolean
	if not player then return false end
	if listIds then
		for _, id in ipairs(listIds) do
			if id == player.UserId then
				return true
			end
		end
	end
	if listNames then
		local uname = string.lower(player.Name)
		for _, name in ipairs(listNames) do
			if uname == string.lower(name) then
				return true
			end
		end
	end
	return false
end

-- Detects if player is the Owner
function RoleConfig.IsOwner(player: Player): boolean
	if not player then return false end

	-- 1. Studio testing override (Studio user or creator ID is always owner)
	if RunService:IsStudio() and (player.UserId == RoleConfig.PlaceOwnerId or player.UserId <= 0) then
		return true
	end

	-- 2. Explicit PlaceOwnerId match
	if RoleConfig.PlaceOwnerId and player.UserId == RoleConfig.PlaceOwnerId then
		return true
	end

	-- 3. Game Creator ID match
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end

	-- 4. Group Game Rank 255 (Group Owner)
	if game.CreatorType == Enum.CreatorType.Group then
		local ok, rank = pcall(function()
			return player:GetRankInGroup(game.CreatorId)
		end)
		if ok and rank and rank >= 255 then
			return true
		end
	end

	-- 5. Configured UserIds / Usernames
	local ownerRole = RoleConfig.Roles.Owner
	if ownerRole and matches(ownerRole.UserIds, ownerRole.Usernames, player) then
		return true
	end

	return false
end

-- Detects if player is an Admin or higher
function RoleConfig.IsAdmin(player: Player): boolean
	if RoleConfig.IsOwner(player) then return true end
	local devRole = RoleConfig.Roles.Developer
	if devRole and matches(devRole.UserIds, devRole.Usernames, player) then return true end
	local adminRole = RoleConfig.Roles.Admin
	if adminRole and matches(adminRole.UserIds, adminRole.Usernames, player) then return true end
	return false
end

-- Resolves the highest role for a player
function RoleConfig.GetPlayerRole(player: Player): string?
	if not player then return nil end

	if RoleConfig.IsOwner(player) then
		return "Owner"
	end

	local rolesPriority = {"Developer", "Admin", "Moderator"}
	for _, roleName in ipairs(rolesPriority) do
		local roleData = RoleConfig.Roles[roleName]
		if roleData and matches(roleData.UserIds, roleData.Usernames, player) then
			return roleName
		end
	end

	if player:GetAttribute("VIP") == true then
		return "VIP"
	end

	return nil
end

-- Checks if a player has permission to use Admin Panel
function RoleConfig.CanUseAdminPanel(player: Player): boolean
	if not player then return false end
	if RunService:IsStudio() then return true end
	local role = RoleConfig.GetPlayerRole(player)
	if not role then return false end
	local roleData = RoleConfig.Roles[role]
	return roleData and roleData.CanUsePanel == true or false
end

-- Returns the list of tools to auto-grant to the player's backpack
function RoleConfig.GetAutoGrantTools(player: Player): {string}
	local role = RoleConfig.GetPlayerRole(player)
	if not role then return {} end

	-- Prioritize centralized ToolDistributionConfig
	local ok, ToolConfig = pcall(function()
		return require(ReplicatedStorage:WaitForChild("ToolDistributionConfig", 5))
	end)
	if ok and ToolConfig and ToolConfig.RoleTools and ToolConfig.RoleTools[role] then
		return ToolConfig.RoleTools[role]
	end

	local roleData = RoleConfig.Roles[role]
	return (roleData and roleData.AutoGrantTools) or {}
end

return RoleConfig
