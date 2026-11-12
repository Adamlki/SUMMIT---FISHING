-- System by @thehandofvoid
-- Modified by @jay_peaceee
-- StarterPlayer/StarterPlayerScripts/FishingSystem
-- ✅ NOW WITH GLOBAL CHAT NOTIFICATIONS FOR RARE FISH

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RepStorage = ReplicatedStorage:WaitForChild("FishingSystem")
local CS = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local FeatureFlags = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("FeatureFlags"))
if not FeatureFlags.Fishing then return end

local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))

local player = Players.LocalPlayer
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- ===== MODULES =====
local modulesFolder = RepStorage:WaitForChild("FishingModules")
local FishingConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("FishingConfig"))
local SoundManager = require(modulesFolder:WaitForChild("SoundManager"))
local GUIManager = require(modulesFolder:WaitForChild("GUIManager"))
local AnimationController = require(modulesFolder:WaitForChild("AnimationController"))
local PowerBarSystem = require(modulesFolder:WaitForChild("PowerBarSystem"))
local MinigameSystem = require(modulesFolder:WaitForChild("MinigameSystem"))
local CastingSystem = require(modulesFolder:WaitForChild("CastingSystem"))
local RodVFXManager = require(modulesFolder:WaitForChild("RodVFXManager"))

-- ===== REMOTE EVENTS =====
local castReplicationEvent = RepStorage:WaitForChild("CastReplication")
local cleanupCastEvent = RepStorage:WaitForChild("CleanupCast")
local showNotificationEvent = RepStorage:FindFirstChild("ShowNotification")

local resumeFishingRemote = RepStorage:WaitForChild("ResumeFishingSession")

-- ===== FEATURE MODULES =====
local RodManagerModule = require(script.Parent.Modules.RodManager)
local CameraModule = require(script.Parent.Modules.Camera)
local NotificationsModule = require(script.Parent.Modules.Notifications)
local FishingLoopModule = require(script.Parent.Modules.FishingLoop)
local CatchFlowModule = require(script.Parent.Modules.CatchFlow)
local SessionModule = require(script.Parent.Modules.Session)

-- ===== CONTROLLER =====
local Controller = {}
Controller.__index = Controller

function Controller.new()
	local self = setmetatable({}, Controller)

	self.Players = Players
	self.UIS = UIS
	self.RunService = RunService
	self.ReplicatedStorage = ReplicatedStorage
	self.RepStorage = RepStorage
	self.CS = CS
	self.Debris = Debris
	self.StarterGui = StarterGui
	self.TweenService = TweenService
	self.NetworkGateway = NetworkGateway
	self.FishingConfig = FishingConfig

	self.SoundManager = SoundManager
	self.GUIManager = GUIManager
	self.AnimationController = AnimationController
	self.PowerBarSystem = PowerBarSystem
	self.MinigameSystem = MinigameSystem
	self.CastingSystem = CastingSystem
	self.RodVFXManager = RodVFXManager

	self.castReplicationEvent = castReplicationEvent
	self.cleanupCastEvent = cleanupCastEvent
	self.showNotificationEvent = showNotificationEvent
	self.resumeFishingRemote = resumeFishingRemote

	self.player = player
	self.isMobile = isMobile
	self.playerGui = player:WaitForChild("PlayerGui")
	self.character = player.Character or player.CharacterAdded:Wait()
	self.humanoid = self.character:WaitForChild("Humanoid")
	self.camera = workspace.CurrentCamera

	self.gameState = {
		isLocked = false, casted = false, sinker = nil, splash = nil, savedHookPosition = nil,
		waitTime = math.random(3, 6), fishingCaught = false, hasLanded = false,
		fishingInProgress = false, canCast = true, castingCooldown = false,
		cooldownTime = 0.3, activeFishingTask = nil,
		isAutoFishing = false, lastRollId = nil
	}

	self.speedState = {
		originalWalkSpeed = 16, fishingWalkSpeed = 8, speedModified = false
	}

	self.connections = {}
	self.otherPlayersHooks = {}
	self.autoFishConnection = nil
	self.activeCameraShake = nil
	self.cameraSequenceToken = 0

	self.RodManager = RodManagerModule.Create(self)
	return self
end

RodManagerModule.Install(Controller)
CameraModule.Install(Controller)
NotificationsModule.Install(Controller)
FishingLoopModule.Install(Controller)
CatchFlowModule.Install(Controller)
SessionModule.Install(Controller)

local controller = Controller.new()

-- ===== INITIALIZATION =====
controller:InitializeSystems()

-- ===== MINIGAME CALLBACKS =====
MinigameSystem:SetCallbacks(
	function() -- Success
		controller:HandleMinigameSuccess()
	end,
	function() -- Fail
		controller:HandleMinigameFail()
	end
)

-- ===== HOTKEY BLOCKER =====
UIS.InputBegan:Connect(function(input, processed)
	if processed or not MinigameSystem:IsActive() then return end
	local blocked = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three,
		Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six,
		Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine, Enum.KeyCode.Backspace}
	for _, key in blocked do if input.KeyCode == key then return end end
end)

-- ===== WIRING =====
-- Centralized Toast: Handled by EventNotificationGui.NotifyController
-- (No showNotificationEvent listener here to prevent double notifications)
controller:ConnectCharacterEvents()
controller:ConnectSessionRestore()
controller:ConnectCastReplication()

-- ===== INITIAL SETUP =====
controller.RodManager:SetupCharacterMonitoring(controller.character)
