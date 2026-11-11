--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RoleConfig = require(ReplicatedStorage:WaitForChild("RoleConfig"))
local OverheadConfig = require(
	ServerScriptService
		:WaitForChild("Server")
		:WaitForChild("Config")
		:WaitForChild("OverheadConfig")
)

local function toHex(color: Color3): string
	return string.format("#%02X%02X%02X",
		math.clamp(math.round(color.R * 255), 0, 255),
		math.clamp(math.round(color.G * 255), 0, 255),
		math.clamp(math.round(color.B * 255), 0, 255)
	)
end

local function applyChatAttributes(player: Player)
	local role = RoleConfig.GetPlayerRole(player)

	print(string.format("[ChatServer] Player: %s (UserId: %d) -> Role: %s", player.Name, player.UserId, tostring(role)))

	if role then
		local roleData = RoleConfig.Roles[role]
		local displayName = (roleData and roleData.DisplayRole) or role
		local chatTagColor = (roleData and roleData.ChatTag) or Color3.fromRGB(255, 255, 255)

		player:SetAttribute("ChatRole", role)
		player:SetAttribute("ChatRoleColor", toHex(chatTagColor))
		player:SetAttribute("ChatRoleDisplay", displayName)
	else
		player:SetAttribute("ChatRole", nil)
		player:SetAttribute("ChatRoleColor", nil)
		player:SetAttribute("ChatRoleDisplay", nil)
	end
end

Players.PlayerAdded:Connect(function(player)
	applyChatAttributes(player)

	local vipAttr = (OverheadConfig and OverheadConfig.VipAttribute) or "VIP"
	player:GetAttributeChangedSignal(vipAttr):Connect(function()
		applyChatAttributes(player)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	applyChatAttributes(player)
end

print("✅ [ChatServer] Chat role attributes linked to RoleConfig successfully.")
