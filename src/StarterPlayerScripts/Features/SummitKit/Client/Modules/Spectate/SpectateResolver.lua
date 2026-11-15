--!nonstrict
local Players = game:GetService("Players")

local Resolver = {}

local function find(parent, name, timeout)
	if not parent then return nil end
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
	local component = gameUI and find(gameUI, "Component")
	local menus = gameUI and find(gameUI, "Menus")
	if not (component and menus) then
		return false, "Component atau Menus tidak ditemukan"
	end

	local buttons = find(component, "ButtonsNew")
	local menuKiri = buttons and find(buttons, "MenuKiri")
	local frameBtn = menuKiri and find(menuKiri, "FrameBtn")
	local toggleBtn = frameBtn and find(frameBtn, "SpectateButton")

	local menu = find(menus, "Spectate")
	if not menu then
		return false, "Menu Spectate tidak ditemukan"
	end

	local btnNext = menu:FindFirstChild("Next")
	local btnPrev = menu:FindFirstChild("Previous")
	local frame = menu:FindFirstChild("Frame")
	local nameLabel = frame and frame:FindFirstChild("Name")
	local usernameLabel = frame and frame:FindFirstChild("Username")

	return true, {
		Root = menu,
		ToggleBtn = toggleBtn,
		NextBtn = btnNext,
		PrevBtn = btnPrev,
		NameLabel = nameLabel,
		UsernameLabel = usernameLabel,
	}
end

return Resolver
