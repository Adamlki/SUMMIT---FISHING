--!nonstrict
-- ==============================================================================
-- TitleMenu.lua
-- Facade untuk TITLE PANEL & INFORMATION CARD (Mockup 100% Sesuai)
-- Slot 1-3 Teks, Slot 4-6 Gambar, Translucent Lock Overlay, 6 Animated Modes.
-- Implementasi ada di folder TitleMenuModules.
-- ==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer and (localPlayer:FindFirstChild("PlayerGui") or localPlayer:WaitForChild("PlayerGui", 5))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = Shared:WaitForChild("Packages")
local Janitor = require(Packages:WaitForChild("Janitor"))

local Modules = script.Parent:WaitForChild("TitleMenuModules")
local Config = require(Modules:WaitForChild("Config"))
local Visuals = require(Modules:WaitForChild("Visuals"))
local Data = require(Modules:WaitForChild("Data"))
local TitlePreview = require(Modules:WaitForChild("TitlePreview"))
local SlotBindings = require(Modules:WaitForChild("SlotBindings"))
local SlotActions = require(Modules:WaitForChild("SlotActions"))
local Panel = require(script.Parent.Parent.UI.Panel)

local FeatureFlags = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("FeatureFlags"))
local TitleMenu = {}

local initialized = false

function TitleMenu.init()
	if not FeatureFlags.Titles then return false end
	if initialized then return true end

	if not localPlayer then
		localPlayer = Players.LocalPlayer
	end
	if not playerGui and localPlayer then
		playerGui = localPlayer:WaitForChild("PlayerGui", 15)
	end
	if not playerGui then return false end

	local gameUI = playerGui:WaitForChild("GameUI", 15)
	if not gameUI then return false end

	local menus = gameUI:WaitForChild("Menus", 15)
	local titleMenuFrame = menus and menus:WaitForChild("Title", 15)
	if not titleMenuFrame then return false end

	local component = gameUI:WaitForChild("Component", 15)
	local buttonsFrame = component and component:WaitForChild("ButtonsNew", 15)
	local menuKanan = buttonsFrame and buttonsFrame:WaitForChild("MenuKanan", 15)
	local toggleBtn = menuKanan and menuKanan:WaitForChild("TitleButton", 15)

	if toggleBtn and toggleBtn:IsA("GuiButton") then
		toggleBtn.Visible = true
		for _, ch in ipairs(toggleBtn:GetChildren()) do
			if ch:IsA("GuiObject") then
				ch.Active = false
			end
		end
		local lastToggle = 0
		local function doToggle()
			local now = os.clock()
			if now - lastToggle < 0.25 then return end
			lastToggle = now
			Panel.toggle(titleMenuFrame)
		end
		toggleBtn.Activated:Connect(doToggle)
	end

	-- Referensi MainCard & InfoCard
	local mainCard = titleMenuFrame:WaitForChild("MainCard")
	local mainContent = mainCard:WaitForChild("ContentFrame")
	local header = mainContent:WaitForChild("Header")
	local closeBtn = header:WaitForChild("CloseBtn")

	local content = mainContent:WaitForChild("Content")

	local slotSec = content:WaitForChild("SlotSection")
	local buttonsHolder = slotSec:WaitForChild("ButtonsHolder")
	local statusLabel = slotSec:WaitForChild("StatusLabel")

	local imgSec = content:WaitForChild("ImageSection")
	local imgContainer = imgSec:WaitForChild("Container")

	local textSec = content:WaitForChild("TextSection")
	local inputFrame = textSec:WaitForChild("InputFrame")
	local titleBox = inputFrame:WaitForChild("TitleBox")

	local colSec = content:WaitForChild("ColorSection")
	local colContainer = colSec:WaitForChild("Container")

	local actSec = content:WaitForChild("ActionSection")
	local actHolder = actSec:WaitForChild("ButtonsHolder")
	local btnPreview = actHolder:WaitForChild("BtnPreview")
	local btnSetTitle = actHolder:WaitForChild("BtnSetTitle")
	local btnClearSlot = actHolder:WaitForChild("BtnClearSlot")
	local quotaLabel = actSec:WaitForChild("QuotaLabel")

	initialized = true

	local ctx = {
		localPlayer = localPlayer,
		playerGui = playerGui,
		gameUI = gameUI,
		titleMenuFrame = titleMenuFrame,
		drafts = Config.newDrafts(),
		colorDefs = Config.buildColorDefs(),
		state = { currentSlot = 1, serverData = nil },
		refs = {
			slotSec = slotSec,
			buttonsHolder = buttonsHolder,
			statusLabel = statusLabel,
			imgSec = imgSec,
			imgContainer = imgContainer,
			textSec = textSec,
			titleBox = titleBox,
			colSec = colSec,
			colContainer = colContainer,
			actSec = actSec,
			btnPreview = btnPreview,
			btnSetTitle = btnSetTitle,
			btnClearSlot = btnClearSlot,
			quotaLabel = quotaLabel,
		},
	}

	local visuals = Visuals.new(ctx)
	local data = Data.new(ctx, visuals)
	local preview = TitlePreview.new(ctx)

	SlotBindings.bind(ctx, visuals, preview)
	SlotActions.bind(ctx, data)

	closeBtn.MouseButton1Click:Connect(function()
		Panel.close(titleMenuFrame)
	end)

	titleMenuFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if titleMenuFrame.Visible then
			data:fetch()
		end
	end)

	-- Fetch awal data server
	data:fetch()
	return true
end

return TitleMenu
