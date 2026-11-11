--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)

local StateHUDBinder = {}

function StateHUDBinder.bind(bus, onState, onReady)
    local janitor = Janitor.new()
    if bus then
        janitor:Add(bus.onStateUpdated(function(state)
            onState(state)
        end), "Disconnect")
        janitor:Add(bus.onCheckpointHit(function()
            onReady()
        end), "Disconnect")
    end
    return janitor
end

return StateHUDBinder
