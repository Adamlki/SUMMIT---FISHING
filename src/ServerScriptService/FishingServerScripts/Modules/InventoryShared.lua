-- Shared helpers, config values, and environment for InventoryServer.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local ShowNotification = FishingSystem:WaitForChild("ShowNotification")
local AntiCheatConfig = require(game:GetService("ServerScriptService"):WaitForChild("Configs"):WaitForChild("AntiCheatConfig"))
local NetworkConfig = AntiCheatConfig.Network

local Shared = {}

Shared.ToolConfig = nil
pcall(function()
	Shared.ToolConfig = require(ReplicatedStorage:WaitForChild("ToolDistributionConfig", 5))
end)

Shared.MAX_IDENTIFIER_LENGTH = NetworkConfig.MaxIdentifierLength
Shared.RATE_LIMIT_EQUIP = NetworkConfig.Inventory.EquipSeconds
Shared.RATE_LIMIT_READ = NetworkConfig.Inventory.ReadSeconds
Shared.RATE_LIMIT_SELL = NetworkConfig.Inventory.SellSeconds

local lastInvAction = {}
Players.PlayerRemoving:Connect(function(player)
	lastInvAction[player] = nil
end)

function Shared.notify(player, message, duration, color)
	ShowNotification:FireClient(player, message, duration, color or Color3.fromRGB(255, 255, 255))
end

function Shared.respondSuccess(data, message)
	return {
		Success = true,
		StatusCode = 200,
		Data = data,
		Message = message or "OK",
	}
end

function Shared.respondFailure(statusCode, errorCode, message)
	return {
		Success = false,
		StatusCode = statusCode,
		ErrorCode = errorCode,
		Message = message,
	}
end

function Shared.sanitizeIdentifier(value)
	if type(value) ~= "string" then
		return nil
	end

	local trimmed = string.match(value, "^%s*(.-)%s*$")
	if not trimmed or trimmed == "" or #trimmed > Shared.MAX_IDENTIFIER_LENGTH then
		return nil
	end

	if string.find(trimmed, "%c") then
		return nil
	end

	return trimmed
end

function Shared.getBackpack(player)
	return player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 5)
end

function Shared.isSpam(player, key, interval)
	local now = os.clock()
	lastInvAction[player] = lastInvAction[player] or {}
	if lastInvAction[player][key] and now - lastInvAction[player][key] < interval then
		return true
	end
	lastInvAction[player][key] = now
	return false
end

function Shared.formatNumberWithCommas(number)
	local s = tostring(math.floor(number))
	local reversed = string.reverse(s)
	local formatted = reversed:gsub("(%d%d%d)", "%1,")
	return string.reverse(formatted):gsub("^,", "")
end

local toolsFolders = {
	all = ServerStorage:FindFirstChild("AllTools"),
	admin = ServerStorage:FindFirstChild("AdminTools"),
	vip = ServerStorage:FindFirstChild("VIPTools") or ServerStorage:FindFirstChild("VIPtools"),
}

-- Cached on first use; re-resolved whenever a folder is still missing.
function Shared.getToolsFolders()
	if not toolsFolders.all then
		toolsFolders.all = ServerStorage:FindFirstChild("AllTools")
	end
	if not toolsFolders.admin then
		toolsFolders.admin = ServerStorage:FindFirstChild("AdminTools")
	end
	if not toolsFolders.vip then
		toolsFolders.vip = ServerStorage:FindFirstChild("VIPTools") or ServerStorage:FindFirstChild("VIPtools")
	end
	return toolsFolders
end

return Shared
