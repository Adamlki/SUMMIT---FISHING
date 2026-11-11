--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoleConfig = require(ReplicatedStorage:WaitForChild("RoleConfig"))

local RoleResolver = require(script.Parent.Parent.Parent.Modules.Overhead.Resolvers.RoleResolver)

local PermissionResolver = {}

function PermissionResolver.resolve(adminService, config, localPlayer)
	if RoleConfig.CanUseAdminPanel(localPlayer) then
		return true
	end

	local ok, canUse = pcall(function()
		return adminService:HasPermission()
	end)
	if ok == true and canUse == true then
		return true
	end

	if config and localPlayer then
		if RoleResolver.isOwner(config, localPlayer)
			or RoleResolver.isDeveloper(config, localPlayer)
			or RoleResolver.isAdmin(config, localPlayer)
			or RoleResolver.isModerator(config, localPlayer) then
			return true
		end
	end

	return false
end

return PermissionResolver
