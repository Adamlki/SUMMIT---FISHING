--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local NotificationsConfig = require(ReplicatedStorage.Shared.Config.Notifications.NotificationsConfig)

local RaceNotifications = {}
local _isVisible = false
local _ticket = 0
local _lastFinishedCount = 0
local _lastWinsTarget = 0

local animationConfig = NotificationsConfig.Animation or {}
local FADE_IN_INFO = TweenInfo.new(tonumber(animationConfig.FinishNotificationFadeInSeconds) or tonumber(animationConfig.FadeInSeconds) or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FADE_OUT_INFO = TweenInfo.new(tonumber(animationConfig.FinishNotificationFadeOutSeconds) or tonumber(animationConfig.FadeOutSeconds) or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local DEFAULT_DURATION = 2

local function eachAnimNode(root, callback)
    if not root then
        return
    end
    callback(root)
    for _, descendant in ipairs(root:GetDescendants()) do
        callback(descendant)
    end
end

local function setTransparency(node, value)
    if node:IsA("ImageLabel") or node:IsA("ImageButton") then
        node.ImageTransparency = value
    elseif node:IsA("TextLabel") or node:IsA("TextButton") then
        node.TextTransparency = value
    elseif node:IsA("CanvasGroup") then
        node.GroupTransparency = value
    end
end

local function tweenTransparency(node, value, tweenInfo)
    if node:IsA("ImageLabel") or node:IsA("ImageButton") then
        TweenService:Create(node, tweenInfo, { ImageTransparency = value }):Play()
    elseif node:IsA("TextLabel") or node:IsA("TextButton") then
        TweenService:Create(node, tweenInfo, { TextTransparency = value }):Play()
    elseif node:IsA("CanvasGroup") then
        TweenService:Create(node, tweenInfo, { GroupTransparency = value }):Play()
    end
end

local function playFadeIn(frame)
    eachAnimNode(frame, function(node)
        setTransparency(node, 1)
        tweenTransparency(node, 0, FADE_IN_INFO)
    end)
end

local function playFadeOut(frame)
    eachAnimNode(frame, function(node)
        tweenTransparency(node, 1, FADE_OUT_INFO)
    end)
end

local function playFinishSound()
    local sounds = NotificationsConfig.Sounds or {}
    local soundId = sounds.RaceFinish or sounds.Success
    if not soundId or soundId == "" then
        return
    end
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.7
    sound.Parent = SoundService
    sound:Play()
    task.delay(2, function()
        sound:Destroy()
    end)
end

local function show(refs, text, duration)
    if not refs or not refs.Notifications then
        return
    end

    _ticket += 1
    local ticket = _ticket
    duration = tonumber(duration) or DEFAULT_DURATION

    refs.Notifications.Visible = true
    if refs.NotificationTitle and refs.NotificationTitle:IsA("TextLabel") then
        refs.NotificationTitle.Text = tostring(text or "")
    end

    playFadeIn(refs.Notifications)
    playFinishSound()
    _isVisible = true

    task.delay(duration, function()
        if ticket ~= _ticket then
            return
        end
        if refs.Notifications then
            playFadeOut(refs.Notifications)
            task.delay(FADE_OUT_INFO.Time, function()
                if ticket ~= _ticket then
                    return
                end
                if refs.Notifications then
                    refs.Notifications.Visible = false
                end
                _isVisible = false
            end)
        end
    end)
end

function RaceNotifications.syncState(refs, state)
    state = state or {}
    local finishedCount = tonumber(state.finishedCount) or 0
    local winsTarget = tonumber(state.maxWins) or 0
    local latestFinishedPlace = tonumber(state.latestFinishedPlace) or finishedCount
    local latestFinishedName = state.latestFinishedDisplayName

    if state.status == "Deactive" then
        _lastFinishedCount = 0
        _lastWinsTarget = 0
        _ticket += 1
        if refs and refs.Notifications then
            refs.Notifications.Visible = false
        end
        _isVisible = false
        return
    end

    if winsTarget ~= _lastWinsTarget and finishedCount == 0 then
        _lastFinishedCount = 0
    end

    if finishedCount > 0 and winsTarget > 1 and finishedCount > _lastFinishedCount then
        local text = latestFinishedName and string.format("#%d %s", latestFinishedPlace, tostring(latestFinishedName))
            or string.format("%d Players Finished", finishedCount)
        show(refs, text, DEFAULT_DURATION)
    elseif state.status == "Finished" and state.winnerDisplayName and winsTarget <= 1 then
        show(refs, string.format("#1 %s", tostring(state.winnerDisplayName)), DEFAULT_DURATION)
    end

    _lastFinishedCount = finishedCount
    _lastWinsTarget = winsTarget
end

function RaceNotifications.render(refs, payload)
    if not payload then
        return
    end

    if payload.finishedCount and tonumber(payload.finishedCount) > 0 and (tonumber(payload.maxWins) or 0) > 1 then
        local place = tonumber(payload.latestFinishedPlace) or tonumber(payload.finishedCount) or 1
        local text = payload.latestFinishedDisplayName and string.format("#%d %s", place, tostring(payload.latestFinishedDisplayName))
            or payload.topDisplayName and string.format("#1 %s", tostring(payload.topDisplayName))
            or string.format("%d Players Finished", tonumber(payload.finishedCount) or 1)
        show(refs, text, payload.duration or DEFAULT_DURATION)
        return
    end

    if payload.topDisplayName and (tonumber(payload.maxWins) or 0) <= 1 then
        show(refs, string.format("#1 %s", tostring(payload.topDisplayName)), payload.duration or DEFAULT_DURATION)
        return
    end

    if payload.message then
        show(refs, tostring(payload.message), payload.duration or DEFAULT_DURATION)
    end
end

return RaceNotifications
