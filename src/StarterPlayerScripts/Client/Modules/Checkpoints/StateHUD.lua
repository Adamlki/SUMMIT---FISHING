--!nonstrict
local StateHUDResolver = require(script.Parent.StateHUDHelpers.StateHUDResolver)
local StateHUDRenderer = require(script.Parent.StateHUDHelpers.StateHUDRenderer)
local StateHUDBinder = require(script.Parent.StateHUDHelpers.StateHUDBinder)

local StateHUD = {}

local frames
local ready = false
local lastState = nil
local binder

function StateHUD.init(bus)
    local ok, refsOrErr
    for _ = 1, 5 do
        ok, refsOrErr = StateHUDResolver.resolve()
        if ok then break end
        task.wait(2)
    end
    if not ok then
        warn("[CheckpointUI] " .. tostring(refsOrErr))
        return
    end
    frames = refsOrErr
    StateHUDRenderer.hideAll(frames)
    ready = false

    if binder then
        binder:Destroy()
        binder = nil
    end
    binder = StateHUDBinder.bind(bus, StateHUD.update, StateHUD.setReady)
end

function StateHUD.update(state)
    lastState = state
    if not frames or not ready then return end
    StateHUDRenderer.render(frames, state)
end

function StateHUD.setReady()
    ready = true
    if lastState then
        StateHUD.update(lastState)
    end
end

function StateHUD.destroy()
    if binder then
        binder:Destroy()
        binder = nil
    end
end

return StateHUD
