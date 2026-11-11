--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)

local RaceActionsBinder = {}
local ACCESS_DISPLAY_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function readInputText(input)
    if not input then
        return ""
    end
    if input:IsA("TextBox") or input:IsA("TextLabel") then
        return tostring(input.Text or "")
    end
    return tostring(input.Value or "")
end

local function parsePositiveInteger(input, fallback)
    local raw = readInputText(input)
    local numeric = tonumber(raw)
    if not numeric then
        local extracted = string.match(raw, "%d+")
        numeric = extracted and tonumber(extracted) or nil
    end
    local value = math.floor(tonumber(numeric) or tonumber(fallback) or 1)
    if value < 1 then
        value = 1
    end
    return value
end

local function connectButton(janitor, button, callback)
    if not button then
        return
    end
    if button:IsA("GuiButton") then
        button.Active = true
        janitor:Add(button.Activated:Connect(callback), "Disconnect")
        return
    end

    button.Active = true
    janitor:Add(button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            callback()
        end
    end), "Disconnect")
end

function RaceActionsBinder.bind(refs, raceService)
    local janitor = Janitor.new()
    refs._displayToggleOn = true
    refs._displayPinnedOpen = false
    refs._accessDisplayDefaultPosition = refs._accessDisplayDefaultPosition
        or (refs.AccessDisplay and refs.AccessDisplay.Position)
        or UDim2.new(0, 0, 0, 0)
    refs._accessDisplayOpenPosition = UDim2.new(1, -20, 0.5, 0)
    refs._accessDisplayExpanded = false
    refs._accessDisplayTween = nil

    refs._applyAccessDisplayPosition = function(animated)
        local accessDisplay = refs.AccessDisplay
        if not accessDisplay then
            return
        end

        local targetPosition = refs._accessDisplayExpanded == true
            and refs._accessDisplayOpenPosition
            or refs._accessDisplayDefaultPosition

        if animated == true then
            local activeTween = refs._accessDisplayTween
            if activeTween then
                activeTween:Cancel()
                refs._accessDisplayTween = nil
            end
            local tween = TweenService:Create(accessDisplay, ACCESS_DISPLAY_TWEEN_INFO, {
                Position = targetPosition,
            })
            refs._accessDisplayTween = tween
            janitor:Add(tween.Completed:Connect(function()
                if refs._accessDisplayTween == tween then
                    refs._accessDisplayTween = nil
                end
            end), "Disconnect")
            tween:Play()
            return
        end

        if refs._accessDisplayTween then
            return
        end
        accessDisplay.Position = targetPosition
    end

    local function toggleAccessDisplay()
        refs._accessDisplayExpanded = not (refs._accessDisplayExpanded == true)
        refs._applyAccessDisplayPosition(true)
    end

    if refs.Root then
        refs.Root.Visible = true
    end
    if refs.Panel then
        refs.Panel.Visible = false
    end
    if refs.AccessDisplay then
        refs.AccessDisplay.Visible = false
        refs._applyAccessDisplayPosition(false)
    end
    if refs.Template then
        refs.Template.Visible = false
    end
    if refs.Announce then
        refs.Announce.Visible = false
    end
    if refs.AnnounceHeaderFrame then
        refs.AnnounceHeaderFrame.Visible = true
    end
    if refs.AnnounceTimerFrame then
        refs.AnnounceTimerFrame.Visible = false
    end
    if refs.Notifications then
        refs.Notifications.Visible = false
    end

    connectButton(janitor, refs.Toggle, function()
        if refs.Panel then
            refs.Panel.Visible = not refs.Panel.Visible
        end
    end)

    connectButton(janitor, refs.AccessDisplayButton, toggleAccessDisplay)

    janitor:Add(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end
        if input.KeyCode == Enum.KeyCode.G then
            toggleAccessDisplay()
        end
    end), "Disconnect")

    connectButton(janitor, refs.Close, function()
        if refs.Panel then
            refs.Panel.Visible = false
        end
    end)

    connectButton(janitor, refs.Cancel, function()
        refs._displayPinnedOpen = false
        raceService:CancelRace()
    end)

    connectButton(janitor, refs.Confirm, function()
        local wins = parsePositiveInteger(refs.Wins, 1)
        local laps = parsePositiveInteger(refs.Laps, 1)
        refs._displayPinnedOpen = true
        raceService:CreateRace(wins, laps)
    end)

    return janitor
end

return RaceActionsBinder
