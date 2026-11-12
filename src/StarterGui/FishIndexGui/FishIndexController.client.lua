local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local FeatureFlags = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("FeatureFlags"))
if not FeatureFlags.FishIndex then return end

local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))

local player = Players.LocalPlayer
local gui = script.Parent
local mainFrame = gui:WaitForChild("MainFrame")
local header = mainFrame:WaitForChild("Header")
local subtitle = header:WaitForChild("Subtitle")
local progressBarFill = header:WaitForChild("ProgressBarBg"):WaitForChild("Fill")
local closeBtn = header:WaitForChild("CloseBtn")

local contentArea = mainFrame:WaitForChild("ContentArea")
local filterColumn = contentArea:WaitForChild("FilterColumn")
local gridContainer = contentArea:WaitForChild("GridContainer")
local fishGrid = gridContainer:WaitForChild("FishGrid")
local detailsPanel = contentArea:WaitForChild("DetailsPanel")

local dpName = detailsPanel:WaitForChild("DetailName")
local dpRarityBadge = detailsPanel:WaitForChild("DetailRarityBadge")
local previewBox = detailsPanel:WaitForChild("PreviewBox")
local previewImage = previewBox:WaitForChild("PreviewImage")
local previewChance = previewBox:WaitForChild("PreviewChance")
local statsList = detailsPanel:WaitForChild("StatsList")
local weightLabel = statsList:WaitForChild("WeightLabel")
local caughtStatus = statsList:WaitForChild("CaughtStatus")
local caughtTimes = statsList:WaitForChild("CaughtTimes")

local templates = gui:WaitForChild("Templates")
local cardTemplate = templates:WaitForChild("CardTemplate")

local fishingSystem = ReplicatedStorage:WaitForChild("FishingSystem", 15)
local fishingConfig = fishingSystem and require(fishingSystem:WaitForChild("FishingConfig", 15))

local Viewport = require(script.Parent.Modules.Viewport)
local Details = require(script.Parent.Modules.Details)
local Grid = require(script.Parent.Modules.Grid)
local Window = require(script.Parent.Modules.Window)
local Sync = require(script.Parent.Modules.Sync)

local Controller = {}
Controller.__index = Controller

function Controller.new()
	local self = setmetatable({}, Controller)
	self.ReplicatedStorage = ReplicatedStorage
	self.TweenService = TweenService
	self.NetworkGateway = NetworkGateway
	self.player = player
	self.gui = gui
	self.mainFrame = mainFrame
	self.header = header
	self.subtitle = subtitle
	self.progressBarFill = progressBarFill
	self.closeBtn = closeBtn
	self.contentArea = contentArea
	self.filterColumn = filterColumn
	self.gridContainer = gridContainer
	self.fishGrid = fishGrid
	self.detailsPanel = detailsPanel
	self.dpName = dpName
	self.dpRarityBadge = dpRarityBadge
	self.previewBox = previewBox
	self.previewImage = previewImage
	self.previewChance = previewChance
	self.statsList = statsList
	self.weightLabel = weightLabel
	self.caughtStatus = caughtStatus
	self.caughtTimes = caughtTimes
	self.templates = templates
	self.cardTemplate = cardTemplate
	self.fishingSystem = fishingSystem
	self.fishingConfig = fishingConfig
	self.previewViewport = nil
	self.cachedFishFolder = nil

	self.RARITY_COLORS = {
		Common = Color3.fromRGB(180, 190, 205),
		Uncommon = Color3.fromRGB(70, 215, 95),
		Rare = Color3.fromRGB(65, 150, 255),
		Epic = Color3.fromRGB(195, 85, 255),
		Legendary = Color3.fromRGB(255, 175, 40),
		Secret = Color3.fromRGB(255, 145, 0),
		Mitos = Color3.fromRGB(255, 65, 75),
		Forgotten = Color3.fromRGB(255, 65, 75),
	}

	self.INDEX_SHOWN_POS = UDim2.new(0.5, 0, 0.5, 0)
	self.INDEX_HIDDEN_POS = UDim2.new(0.5, 0, -0.6, 0)
	self.indexTween = nil
	self.indexTweenId = 0
	self.lastToggleTime = 0

	self.caughtData = {}
	self.activeFilter = "All"
	self.allCards = {}
	self.selectedCard = nil
	self.activeFishName = ""
	self.activePreviewThread = nil
	self.renderedState = {}
	self.refreshGrid = function()
		self:RefreshGrid()
	end
	return self
end

Viewport.Install(Controller)
Details.Install(Controller)
Grid.Install(Controller)
Window.Install(Controller)
Sync.Install(Controller)

local controller = Controller.new()

-- Ensure GridContainer symmetry
controller.gridContainer.Position = UDim2.new(0, 131, 0, 0)
controller.gridContainer.Size = UDim2.new(0, 380, 1, 0)

-- Ensure UIPadding inside FishGrid
controller.gridPadding = controller.fishGrid:FindFirstChildOfClass("UIPadding")
if not controller.gridPadding then
	controller.gridPadding = Instance.new("UIPadding")
	controller.gridPadding.Name = "UIPadding"
	controller.gridPadding.Parent = controller.fishGrid
end
controller.gridPadding.PaddingTop = UDim.new(0, 10)
controller.gridPadding.PaddingBottom = UDim.new(0, 14)
controller.gridPadding.PaddingLeft = UDim.new(0, 10)
controller.gridPadding.PaddingRight = UDim.new(0, 12)

controller.gridLayout = controller.fishGrid:FindFirstChildOfClass("UIGridLayout")
if controller.gridLayout then
	controller.gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	controller.gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	controller.gridLayout.CellSize = UDim2.new(0, 80, 0, 80)
	controller.gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
end

-- 3D Preview Viewport in Details Panel
controller.previewViewport = controller.previewBox:FindFirstChild("PreviewViewport")
if not controller.previewViewport then
	controller.previewViewport = Instance.new("ViewportFrame")
	controller.previewViewport.Name = "PreviewViewport"
	controller.previewViewport.Size = UDim2.new(1, -12, 1, -26)
	controller.previewViewport.Position = UDim2.new(0.5, 0, 0.44, 0)
	controller.previewViewport.AnchorPoint = Vector2.new(0.5, 0.5)
	controller.previewViewport.BackgroundTransparency = 1
	controller.previewViewport.Parent = controller.previewBox
end
controller.previewImage.Visible = false

controller:SetupFilterButtons()
controller:SetupWindow()
controller:StartSync()
