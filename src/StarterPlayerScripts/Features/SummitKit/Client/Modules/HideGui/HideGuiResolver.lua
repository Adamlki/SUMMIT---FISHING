--!nonstrict
local Players = game:GetService("Players")

local Resolver = {}

local function find(parent, name, timeout)
	if not parent then
		return nil
	end

	local ok, obj = pcall(function()
		return parent:WaitForChild(name, timeout or 60)
	end)

	return ok and obj or nil
end

function Resolver.resolve()
	local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then
		return false, "PlayerGui tidak ada"
	end

	local gameUI = find(playerGui, "GameUI", 60)
	local component = gameUI and find(gameUI, "Component", 60)
	local buttons = component and find(component, "Buttons", 60)
	local topRight = buttons and find(buttons, "TopRight", 60)
	local hideBtn = topRight and topRight:FindFirstChild("Hide")

	if not (gameUI and component and buttons and topRight and hideBtn) then
		return false, "GameUI.Component.Buttons.TopRight.Hide tidak ditemukan"
	end

	return true, {
		GameUI = gameUI,
		Component = component,
		Buttons = buttons,
		TopRight = topRight,
		HideBtn = hideBtn,
	}
end

return Resolver
