--!nonstrict
local RunService = game:GetService("RunService")

local SpeedrunUIResolver = require(script.Parent.SpeedrunUIResolver)

local SpeedrunUI = {}

local refs
local conn
local running = false
local startTime = 0
local hideToken = nil
local initialized = false

local function formatTime(seconds)
    if not seconds or seconds <= 0 then
        return "00:00"
    end
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end

local function setVisible(visible)
    if refs and refs.Timers then
        refs.Timers.Visible = visible and true or false
    end
end

local function setText(text)
    if refs and refs.Text then
        refs.Text.Text = text or "00:00"
    end
end

function SpeedrunUI.init()
    if initialized then
        return true
    end
    local ok, refsOrErr = SpeedrunUIResolver.resolve()
    if not ok then
        warn("[SpeedrunUI] " .. tostring(refsOrErr))
        return false
    end
    refs = refsOrErr
    setText("00:00")
    setVisible(false)
    initialized = true
    return true
end

function SpeedrunUI.start()
    if not refs then return end
    running = true
    startTime = os.clock()
    hideToken = {}
    setVisible(true)

    if conn then
        conn:Disconnect()
        conn = nil
    end
    conn = RunService.RenderStepped:Connect(function()
        if running then
            local elapsed = os.clock() - startTime
            setText(formatTime(elapsed))
        end
    end)
end

function SpeedrunUI.finish(elapsedSeconds)
    if not refs then return end
    running = false
    if conn then
        conn:Disconnect()
        conn = nil
    end
    if elapsedSeconds then
        setText(formatTime(elapsedSeconds))
    end
    setVisible(true)

    local token = {}
    hideToken = token
    task.delay(3, function()
        if hideToken == token then
            setVisible(false)
        end
    end)
end

return SpeedrunUI
