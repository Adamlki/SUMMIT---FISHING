--!nonstrict
-- Central HUD visibility. Semua sistem yang show/hide HUD harus lewat modul ini,
-- supaya panel yang terbuka tidak ditimpa oleh fishing/minigame/inventory.
local Players = game:GetService("Players")

local HudVisibility = {}

-- ScreenGui HUD yang selalu aktif dan hanya visibilitas child-nya yang diatur.
-- Jangan masukkan panel (Shop/Index/Inventory) ke sini.
local HUD_SCREEN_GUIS = {
	"FishingGui",
}

local panelFocused = false
local activePanelGui = nil
local hotbarDesired = true

local function getPlayerGui()
	local player = Players.LocalPlayer
	if not player then
		return nil
	end
	return player:FindFirstChildOfClass("PlayerGui")
end

local function getHotbar(pg)
	local custom = pg:FindFirstChild("CustomInventoryGui")
	return custom and custom:FindFirstChild("HotbarFrame")
end

local function getGameButtons(pg)
	local gameGui = pg:FindFirstChild("GameUI")
	local component = gameGui and gameGui:FindFirstChild("Component")
	return component and component:FindFirstChild("ButtonsNew")
end

function HudVisibility.Apply()
	local pg = getPlayerGui()
	if not pg then
		return
	end

	local hotbar = getHotbar(pg)
	if hotbar and hotbar:IsA("GuiObject") then
		hotbar.Visible = hotbarDesired and not panelFocused
	end

	local buttons = getGameButtons(pg)
	if buttons and buttons:GetAttribute("Focus") ~= panelFocused then
		buttons:SetAttribute("Focus", panelFocused)
	end

	local hudGui = pg:FindFirstChild("hud")
	if hudGui and hudGui:GetAttribute("Focus") ~= panelFocused then
		hudGui:SetAttribute("Focus", panelFocused)
	end

	for _, name in ipairs(HUD_SCREEN_GUIS) do
		local gui = pg:FindFirstChild(name)
		if gui and gui:IsA("ScreenGui") and gui ~= activePanelGui then
			gui.Enabled = not panelFocused
		end
	end
end

function HudVisibility:SetPanelFocus(focused, sourceGui)
	activePanelGui = focused and sourceGui or nil
	if panelFocused == focused then
		self:Apply()
		return
	end
	panelFocused = focused
	self:Apply()
end

function HudVisibility:IsPanelFocused()
	return panelFocused
end

function HudVisibility:SetHotbarDesired(visible)
	hotbarDesired = visible == true
	self:Apply()
end

function HudVisibility:GetHotbarDesired()
	return hotbarDesired
end

local player = Players.LocalPlayer
if player then
	local playerGui = player:WaitForChild("PlayerGui")
	playerGui.ChildAdded:Connect(function(child)
		if child:IsA("ScreenGui") then
			task.defer(function()
				HudVisibility:Apply()
			end)
		end
	end)
	HudVisibility:Apply()
end

return HudVisibility
