--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)
local Janitor = require(Packages.Janitor)
local Signal = require(Packages.Signal)
local Promise = require(Packages.Promise)

local CheckpointBusCache = require(script.Parent.BusHelpers.CheckpointBusCache)
local CheckpointBusBinder = require(script.Parent.BusHelpers.CheckpointBusBinder)

local Bus = {
    _started = false,
    _service = nil,
    _janitor = Janitor.new(),
    _cache = CheckpointBusCache.new(),
}

local signals = {
    stateUpdated = Signal.new(),
    checkpointHit = Signal.new(),
    checkpointRejected = Signal.new(),
    resetRequested = Signal.new(),
    configUpdated = Signal.new(),
}

function Bus.onStateUpdated(fn)
    return signals.stateUpdated:Connect(fn)
end

function Bus.onCheckpointHit(fn)
    return signals.checkpointHit:Connect(fn)
end

function Bus.onCheckpointRejected(fn)
    return signals.checkpointRejected:Connect(fn)
end

function Bus.onResetRequested(fn)
    return signals.resetRequested:Connect(fn)
end

function Bus.onConfigUpdated(fn)
    return signals.configUpdated:Connect(fn)
end

function Bus.start()
    if Bus._started then return end
    Bus._started = true
    Promise.try(function()
        Bus._service = Knit.GetService("CheckpointService")
        return Bus._service
    end)
    :andThen(function(service)
        CheckpointBusBinder.bindService(service, signals, Bus._cache, Bus._janitor)
    end)
    :catch(function(err)
        warn("[CheckpointClientBus] start failed: " .. tostring(err))
    end)
end

function Bus.requestReset()
    signals.resetRequested:Fire()
    if Bus._service and Bus._service.ResetCheckpoint then
        Bus._service:ResetCheckpoint()
    end
end

function Bus.destroy()
    Bus._janitor:Destroy()
    Bus._janitor = Janitor.new()
    Bus._service = nil 
    Bus._started = false
    for _, sig in pairs(signals) do
        sig:Destroy()
    end
end

function Bus.getLastState()
    return Bus._cache:getLastState()
end

function Bus.getLastConfig()
    return Bus._cache:getLastConfig()
end

return Bus
