--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local TableUtil = require(Packages.TableUtil)

local CheckpointBusBinder = {}

function CheckpointBusBinder.bindService(service, signals, cache, janitor)
    janitor:Cleanup()

    janitor:Add(service.State:Observe(function(state)
        local snapshot = state and TableUtil.Copy(state) or nil
        cache:setState(snapshot)
        signals.stateUpdated:Fire(snapshot)
    end), "Disconnect")

    janitor:Add(service.CheckpointReached:Connect(function(index, isFinish, summitReward)
        signals.checkpointHit:Fire(index, isFinish, summitReward)
    end), "Disconnect")

    if service.CheckpointRejected then
        janitor:Add(service.CheckpointRejected:Connect(function(reason, expectedIndex, gotIndex)
            signals.checkpointRejected:Fire(reason, expectedIndex, gotIndex)
        end), "Disconnect")
    end

    if service.Config then
        janitor:Add(service.Config:Observe(function(cfg)
            local snapshot = cfg and TableUtil.Copy(cfg) or nil
            cache:setConfig(snapshot)
            signals.configUpdated:Fire(snapshot)
        end), "Disconnect")
    end
end

return CheckpointBusBinder
