-- Carry System Client - Clean Version
-- Handles client-side carry UI, animations, and interactions

-- ========================================
-- SERVICES
-- ========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local FeatureFlags = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("FeatureFlags"))
if not (FeatureFlags.Carry and FeatureFlags.Gendong) then return end

-- ========================================
-- WAIT FOR REMOTE EVENT
-- ========================================

local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))

-- ========================================
-- MODULES
-- ========================================

local Movement = require(script.Parent.Modules.Movement)
local CarrierUI = require(script.Parent.Modules.CarrierUI)
local CarriedUI = require(script.Parent.Modules.CarriedUI)
local Remotes = require(script.Parent.Modules.Remotes)

-- ========================================
-- CONTROLLER
-- ========================================

local Controller = {}
Controller.__index = Controller

function Controller.new()
	local self = setmetatable({}, Controller)
	self.Players = Players
	self.ReplicatedStorage = ReplicatedStorage
	self.UserInputService = UserInputService
	self.RunService = RunService
	self.NetworkGateway = NetworkGateway

	-- ========================================
	-- CONFIGURATION
	-- ========================================

	-- Animation ID untuk carried player (semua rig)
	self.SIT_ID = 88407453975281 -- Flying Harpy Wings (Bundle 225248611927500)

	-- Request timeout (seconds)
	self.REQUEST_TIMEOUT = 8

	-- Maximum click distance untuk request carry
	self.MAX_CLICK_DISTANCE = 20

	-- ========================================
	-- PLAYER & UI SETUP
	-- ========================================

	self.player = Players.LocalPlayer
	self:InitMovementControls()
	self.playerGui = self.player:WaitForChild("PlayerGui")
	self.camera = workspace.CurrentCamera
	self.gui = script.Parent and script.Parent:IsA("ScreenGui") and script.Parent or self.playerGui:WaitForChild("GendongGUI")

	-- Frame2: Status UI (showing who you're carrying or who's carrying you)
	self.Frame2 = self.gui:WaitForChild("Frame2")
	self.BtnRight = self.Frame2:WaitForChild("RightButton")
	self.BtnLeft = self.Frame2:WaitForChild("LeftButton")
	self.BtnDown = self.Frame2:WaitForChild("DownButton")
	self.NameLabel = self.Frame2:WaitForChild("NameLabel")

	-- Frame3: Prompt UI (accept/decline carry request)
	self.Frame3 = self.gui:WaitForChild("Frame3")
	self.PromptLabel = self.Frame3:WaitForChild("TextLabel")
	self.BtnYes = self.Frame3:WaitForChild("YesButton")
	self.BtnNo = self.Frame3:WaitForChild("NoButton")

	-- UI visibility defaults
	self.Frame2.Visible = false
	self.Frame3.Visible = false

	-- ========================================
	-- STATE TRACKING
	-- ========================================

	-- Current UI mode
	self.uiMode = "idle"

	-- Last requester ID (for prompt response)
	self.lastRequesterId = nil

	-- List of players being carried (for carrier)
	self.carriedList = {}
	self.carriedIndex = 1

	-- Is this player being carried?
	self.isCarried = false
	self.currentCarrierId = nil
	self.currentCarrierName = nil

	-- Connections
	self.keepUiConn = nil
	self.wasCarrying = false

	-- Animation
	self.sitTrack = nil
	self.sitAnimation = Instance.new("Animation")

	-- Jump blocking
	self.jumpBlockConn = nil

	return self
end

Movement.Install(Controller)
CarrierUI.Install(Controller)
CarriedUI.Install(Controller)
Remotes.Install(Controller)

local controller = Controller.new()
controller:ConnectRemotes()
