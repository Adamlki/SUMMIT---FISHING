-- VIP / role access checks for InventoryServer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local RoleConfig = require(ReplicatedStorage:WaitForChild("RoleConfig"))
local MonetizationConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("MonetizationConfig"))
local Shared = require(script.Parent:WaitForChild("InventoryShared"))

local VIP_GAMEPASS_ID = MonetizationConfig.VIP.GamePassId

local Access = {}

function Access.isPlayerVIP(player)
	if RoleConfig.IsOwner(player) or RoleConfig.IsAdmin(player) then
		return true
	end
	if player:GetAttribute("VIP") == true then
		return true
	end

	local passIds = { VIP_GAMEPASS_ID }
	local ToolConfig = Shared.ToolConfig
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

return Access
