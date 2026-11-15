local RoleConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Configs"):WaitForChild("RoleConfig"))
--!strict
-- ShopFeatureController: Master Store Controller (REST NetworkGateway Integrated)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local MarketplaceService = game:GetService("MarketplaceService")
local FeatureFlags = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("FeatureFlags"))
if not FeatureFlags.Shop then return end

local UI = require(script.Parent.Modules.UI)
local Luck = require(script.Parent.Modules.Luck)
local Gifting = require(script.Parent.Modules.Gifting)
local Catalog = require(script.Parent.Modules.Catalog)
local Sync = require(script.Parent.Modules.Sync)

local Controller = {}
Controller.__index = Controller

function Controller.new()
	local self = setmetatable({}, Controller)

	self.Players = Players
	self.ReplicatedStorage = ReplicatedStorage
	self.NetworkGateway = NetworkGateway
	self.TweenService = TweenService
	self.SoundService = SoundService
	self.MarketplaceService = MarketplaceService
	self.RoleConfig = RoleConfig

	self.localPlayer = Players.LocalPlayer
	self.playerGui = self.localPlayer:WaitForChild("PlayerGui")

	-- Configurations
	self.FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem", 15)
	self.TrailSystem = ReplicatedStorage:WaitForChild("TrailSystem", 15)
	self.rodAssets = self.FishingSystem:WaitForChild("Assets"):WaitForChild("Rod")

	self.MasterConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("ShopMasterConfig"))
	self.TrailShopConfig = require(self.TrailSystem:WaitForChild("TrailShopConfig"))

	-- Legacy purchase-success event kept for compatibility.
	local RodShopEvents = self.FishingSystem:WaitForChild("RodShopEvents")
	self.rePurchaseSuccess = RodShopEvents:WaitForChild("PurchaseSuccess") :: RemoteEvent

	local TrailRemotes = self.TrailSystem:WaitForChild("Remotes")
	self.TrailUpdatedRE = TrailRemotes:WaitForChild("TrailUpdated") :: RemoteEvent

	-- Values for Live Server Luck
	self.ServerLuckPurchases = self.FishingSystem:WaitForChild("ServerLuckPurchases") :: IntValue
	self.LuckBoostTimer = self.FishingSystem:WaitForChild("LuckBoostTimer") :: IntValue
	self.GlobalLuckMultiplier = self.FishingSystem:WaitForChild("GlobalLuckMultiplier") :: NumberValue

	self.SOUNDS = {
		Click = "rbxassetid://340910329",
		Hover = "rbxassetid://5852311399",
		Purchase = "rbxassetid://4525871712",
		Equip = "rbxassetid://6895079853",
	}

	-- State management
	self.currentTab = "Exclusive"
	self.ownedRods = {}
	self.equippedRod = "Basic Rod"
	self.playerCoins = 0

	self.ownedTrails = {}
	self.equippedTrail = ""

	self.rodCardInstances = {}

	self.currentGiftCategory = ""
	self.currentGiftId = ""

	self.boundButtons = {}
	self.SHOP_SHOWN_POS = UDim2.new(0.5, 0, 0.5, 0)
	self.SHOP_HIDDEN_POS = UDim2.new(0.5, 0, -0.6, 0)

	return self
end

UI.Install(Controller)
Luck.Install(Controller)
Gifting.Install(Controller)
Catalog.Install(Controller)
Sync.Install(Controller)

local controller = Controller.new()

if not controller:ResolveUI() then return end

controller:WireWindowControls()
controller:WireGiftModal()
controller:WireLuckSignals()
controller:WireNpcPrompt()
controller:WirePurchaseRefresh()
controller:ConnectSyncEvents()

-- Initial Startup & Pre-render
controller:HookExclusiveButtons()
controller:ApplyExclusiveMasterConfig()
controller:RenderRodsCatalogImmediate()
controller:RenderTrailsCatalog()
controller:SwitchTab("Exclusive")
controller:RefreshData()
controller.shopFeature.AnchorPoint = Vector2.new(0.5, 0.5)
controller.shopFeature.Position = controller.SHOP_HIDDEN_POS
controller.shopFeature.Visible = false
controller.shopFeature:SetAttribute("IsOpen", false)
controller.shopFeature:SetAttribute("ShownPos", controller.SHOP_SHOWN_POS)
controller.shopFeature:SetAttribute("HiddenPos", controller.SHOP_HIDDEN_POS)

print("✅ [ShopFeatureController] 3D Rod Viewports, Backpack Rod Ownership, and VIP Rod integration active!")
