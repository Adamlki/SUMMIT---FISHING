--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)
local Promise = require(Packages.Promise)
local Presenter = require(script.Parent.Presenter)
local Queue = require(script.Parent.Queue)
local NotifierResolver = require(script.Parent.NotifierHelpers.NotifierResolver)
local NotifierState = require(script.Parent.NotifierHelpers.NotifierState)
local NotifierUI = require(script.Parent.NotifierHelpers.NotifierUI)
local CheckpointNotification = require(script.Parent.Parent.Notifications.CheckpointNotification)

local Notifier = {}

local frames
local queue
local state = NotifierState.new()
local moduleJanitor = Janitor.new()
local lastRejectAt = 0
local REJECT_COOLDOWN = 1.5

function Notifier.init(bus)
    local ok, refsOrErr = NotifierResolver.resolve()
    if not ok then
        warn("[CheckpointUI] " .. tostring(refsOrErr))
        return
    end
    frames = refsOrErr
    NotifierUI.normalize(frames)
    queue = Queue.new(function(item)
        if item.type == "checkpoint" then
            return Promise.try(function()
                Presenter.showCheckpoint(frames, item.index)
            end):andThen(function()
                return Promise.delay(1.6)
            end)
        elseif item.type == "summit" then
            return Promise.try(function()
                Presenter.showSummit(frames, item.reward, item.oldTotal, item.newTotal)
            end):andThen(function()
                return Promise.delay(2.0)
            end)
        end
    end)
    state.lastSummit = 0
    state.ready = false
    NotifierUI.hideAll(frames)

    if bus then
        local cfg = bus.getLastConfig and bus.getLastConfig() or nil
        if cfg and typeof(cfg.SummitReward) == "number" then
            state:setReward(cfg.SummitReward)
        end
        local unsubState = bus.onStateUpdated(function(newState)
            Notifier.setSummitCount(newState and newState.summitCount or 0)
        end)
        local unsubCheckpoint = bus.onCheckpointHit(function(index, isFinish, summitReward)
            Notifier.setReady()
            Notifier.enqueueCheckpoint(index, isFinish, summitReward)
        end)
        local unsubRejected = bus.onCheckpointRejected(function(reason, expectedIndex, gotIndex)
            local _gotIndex = gotIndex
            if reason == "SkipDisabled" then
                local now = tick()
                if now - lastRejectAt < REJECT_COOLDOWN then
                    return
                end
                lastRejectAt = now
                local expected = typeof(expectedIndex) == "number" and expectedIndex or nil
                local msg = expected and ("Checkpoint skip is disabled. Touch CP " .. expected .. " first.")
                    or "Checkpoint skip is disabled."
                CheckpointNotification.error(msg, 2.5)
            end
        end)
        local unsubConfig = bus.onConfigUpdated(function(newCfg)
            if newCfg and typeof(newCfg.SummitReward) == "number" then
                state:setReward(newCfg.SummitReward)
            end
        end)
        moduleJanitor:Add(unsubState, "Disconnect")
        moduleJanitor:Add(unsubCheckpoint, "Disconnect")
        moduleJanitor:Add(unsubRejected, "Disconnect")
        moduleJanitor:Add(unsubConfig, "Disconnect")
    end
end

function Notifier.setSummitCount(val)
    state:setSummitCount(val)
end

function Notifier.setReady()
    state:setReady()
end

function Notifier.clearQueue()
    if queue then
        queue:clear()
    end
end

function Notifier.enqueueCheckpoint(index, isFinish, summitReward)
    if not frames or not queue then
        return
    end
    if not state.ready then
        state.ready = true
    end

    if isFinish then
        local now = tick()
        if not state:shouldSummit(now) then
            return
        end
        local reward, oldTotal, newTotal = state:applySummit(now, summitReward)
        queue:clear()
        queue:enqueue({type = "summit", reward = reward, oldTotal = oldTotal, newTotal = newTotal})
    else
        if index == 0 then
            return
        end
        queue:enqueue({type = "checkpoint", index = index})
    end
end

return Notifier
