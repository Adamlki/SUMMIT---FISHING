--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)
local Logger = require(script.Parent.Parent.Logger)
local MenuState = require(script.Parent.RuntimeHelpers.MenuState)
local Populate = require(script.Parent.RuntimeHelpers.Populate)
local Playback = require(script.Parent.RuntimeHelpers.Playback)
local SyncState = require(script.Parent.RuntimeHelpers.SyncState)
local DanceMenuBinder = require(script.Parent.RuntimeHelpers.DanceMenuBinder)
local DanceLifecycle = require(script.Parent.RuntimeHelpers.DanceLifecycle)

local DanceRuntime = {}
DanceRuntime.__index = DanceRuntime

local DEFAULT_COLOR = Color3.fromRGB(30, 30, 30)
local ACTIVE_COLOR = Color3.fromRGB(255, 255, 255)

local SYNC_ERROR_MESSAGES = {
	InvalidTarget = "Invalid target.",
	TargetNotFound = "Target not found.",
	TargetNotDancing = "Target is not dancing.",
	InvalidState = "Invalid dance state.",
	MissingAnimationId = "Missing animation id.",
	NoAnimator = "Your character is not ready yet.",
}

function DanceRuntime.new(refs, assets)
	local self = setmetatable({}, DanceRuntime)
	self._janitor = Janitor.new()
	self._log = Logger.new("DanceRuntime", false)
	self._refs = refs
	self._assets = assets
	self._currentTrack = nil
	self._currentButton = nil
	self._activeTab = "Dance"
	self._menuTween = nil
	self._menuTweenId = 0
	self._defaultAnchor = nil
	self._defaultPos = nil
	self._service = assets.DanceService
	self._notification = assets.DanceNotification
	self._contextMenu = assets.DanceContextMenu
	self._stateCache = assets.DanceStateCache or {}
	self._followTargetUserId = nil
	self._colors = {
		Default = DEFAULT_COLOR,
		Active = ACTIVE_COLOR,
	}

	self:_bindUI()
	Populate.run(self)
	MenuState.switchTab(self, "Dance")

	return self
end

function DanceRuntime:_clearFollowTarget()
	SyncState.clearFollowTarget(self)
end

function DanceRuntime:_setFollowTarget(userId)
	SyncState.setFollowTarget(self, userId)
end

function DanceRuntime:SetCachedState(userId, state)
	SyncState.setCachedState(self, userId, state)
end

function DanceRuntime:_publishState(animationId, animationName, looped, speed)
	SyncState.publish(self, animationId, animationName, looped, speed)
end

function DanceRuntime:_clearPublishedState()
	SyncState.clearPublished(self)
end

function DanceRuntime:_switchTab(tabName)
	MenuState.switchTab(self, tabName)
end

function DanceRuntime:_openMenu()
	MenuState.open(self)
end

function DanceRuntime:_closeMenu()
	MenuState.close(self)
end

function DanceRuntime:_toggleMenu()
	MenuState.toggle(self)
end

function DanceRuntime:_resetButton()
	Playback.resetButton(self)
end

function DanceRuntime:_stopCurrent()
	Playback.stopCurrent(self)
end

function DanceRuntime:_playAnimation(animation, looped, button)
	Playback.playManual(self, animation, looped, button)
end

function DanceRuntime:_applySyncedTime(track, state)
	Playback.applySyncedTime(self, track, state)
end

function DanceRuntime:PlaySyncedState(state)
	return Playback.playSynced(self, state)
end

function DanceRuntime:Unsync()
	SyncState.unsync(self)
end

function DanceRuntime:HandleFollowStateChanged(targetUserId, state)
	SyncState.handleFollowStateChanged(self, targetUserId, state)
end

function DanceRuntime:SyncToPlayer(targetPlayer)
	SyncState.syncToPlayer(self, targetPlayer)
end

function DanceRuntime:ToggleSyncTarget(targetPlayer)
	SyncState.toggleSyncTarget(self, targetPlayer)
end

function DanceRuntime:_populate()
	Populate.run(self)
end

function DanceRuntime:_bindUI()
	DanceMenuBinder.bind(self)
end

function DanceRuntime:_getSyncErrorMessage(reason)
	return SYNC_ERROR_MESSAGES[reason] or ("Sync dance failed: " .. tostring(reason))
end

function DanceRuntime:OnCharacterAdded()
	DanceLifecycle.onCharacterAdded(self)
end

function DanceRuntime:Destroy()
	DanceLifecycle.destroy(self)
end

return DanceRuntime
