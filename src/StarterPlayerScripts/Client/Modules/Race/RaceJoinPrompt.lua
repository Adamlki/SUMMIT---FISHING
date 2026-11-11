--!nonstrict
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local NotificationResolver = require(script.Parent.Parent.Notifications.NotificationResolver)
local NotificationsConfig = require(ReplicatedStorage.Shared.Config.Notifications.NotificationsConfig)

local RaceJoinPrompt = {}

local animationConfig = NotificationsConfig.Animation or {}
local FADE_IN_INFO = TweenInfo.new(tonumber(animationConfig.JoinPromptFadeInSeconds) or tonumber(animationConfig.FadeInSeconds) or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FADE_OUT_INFO = TweenInfo.new(tonumber(animationConfig.JoinPromptFadeOutSeconds) or tonumber(animationConfig.FadeOutSeconds) or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local PROMPT_NAME = "RaceJoinPromptItem"

local function firstTextLabel(...)
    for _, item in ipairs({ ... }) do
        if item and item:IsA("TextLabel") then
            return item
        end
    end
    return nil
end

local function firstChildByNames(parent, names)
    if not parent then
        return nil
    end
    for _, childName in ipairs(names) do
        local found = parent:FindFirstChild(childName)
        if found then
            return found
        end
    end
    return nil
end

local function clearExtraButtons(buttonsGroup, template)
    if not buttonsGroup then
        return
    end
    for _, child in ipairs(buttonsGroup:GetChildren()) do
        if child ~= template and child:IsA("GuiButton") then
            child:Destroy()
        end
    end
end

local function setNodeTransparency(node, value)
    if node:IsA("ImageLabel") or node:IsA("ImageButton") then
        node.ImageTransparency = value
    elseif node:IsA("TextLabel") or node:IsA("TextButton") then
        node.TextTransparency = value
    elseif node:IsA("CanvasGroup") then
        node.GroupTransparency = value
    end
end

local function tweenNodeTransparency(node, value, info)
    if node:IsA("ImageLabel") or node:IsA("ImageButton") then
        TweenService:Create(node, info, { ImageTransparency = value }):Play()
    elseif node:IsA("TextLabel") or node:IsA("TextButton") then
        TweenService:Create(node, info, { TextTransparency = value }):Play()
    elseif node:IsA("CanvasGroup") then
        TweenService:Create(node, info, { GroupTransparency = value }):Play()
    end
end

local function playFadeIn(nodes)
    for _, node in ipairs(nodes) do
        if node then
            setNodeTransparency(node, 1)
            tweenNodeTransparency(node, 0, FADE_IN_INFO)
        end
    end
end

local function playFadeOut(nodes)
    for _, node in ipairs(nodes) do
        if node then
            tweenNodeTransparency(node, 1, FADE_OUT_INFO)
        end
    end
end

local function closePrompt(item, nodes)
    if not item or not item.Parent then
        return
    end
    playFadeOut(nodes)
    task.delay(FADE_OUT_INFO.Time, function()
        if item and item.Parent then
            item:Destroy()
        end
    end)
end

local function playPromptSound()
    local soundId = (NotificationsConfig.Sounds and (NotificationsConfig.Sounds.RaceJoin or NotificationsConfig.Sounds.Success)) or ""
    if soundId == "" then
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

function RaceJoinPrompt.show(raceService, payload)
    local ok, data = NotificationResolver.resolve()
    if not ok then
        return
    end

    local active = data.active
    local template = data.template
    if not active or not template then
        return
    end

    local existing = active:FindFirstChild(PROMPT_NAME)
    if existing then
        existing:Destroy()
    end

    local item = template:Clone()
    item.Name = PROMPT_NAME
    item.Visible = true
    item.Parent = active

    local textGroup = item:FindFirstChild("Text")
    local header = firstTextLabel(
        textGroup and firstChildByNames(textGroup, { "Header", "Title" }),
        textGroup and textGroup:FindFirstChild("Header", true),
        textGroup and textGroup:FindFirstChild("Title", true)
    )
    local description = firstTextLabel(
        textGroup and firstChildByNames(textGroup, { "Description", "Desc" }),
        textGroup and textGroup:FindFirstChild("Description", true),
        textGroup and textGroup:FindFirstChild("Desc", true)
    )
    local buttonsGroup = textGroup and (textGroup:FindFirstChild("Buttons") or textGroup:FindFirstChild("Buttons", true))
    local buttonTemplate = buttonsGroup and (buttonsGroup:FindFirstChild("Button") or buttonsGroup:FindFirstChild("Button", true))

    if not buttonsGroup or not buttonTemplate then
        item:Destroy()
        return
    end

    if header then
        header.Text = tostring(payload and payload.title or "Race")
    end
    if description then
        description.Text = tostring(payload and payload.message or "Join race?")
    end

    buttonsGroup.Visible = true
    clearExtraButtons(buttonsGroup, buttonTemplate)
    buttonTemplate.Visible = false

    local acceptButton = buttonTemplate:Clone()
    acceptButton.Visible = true
    acceptButton.Text = "Accept"
    acceptButton.Parent = buttonsGroup

    local rejectButton = buttonTemplate:Clone()
    rejectButton.Visible = true
    rejectButton.Text = "Reject"
    rejectButton.Parent = buttonsGroup

    local animNodes = {
        item,
        textGroup,
        item:FindFirstChild("Icon"),
        header,
        description,
        buttonsGroup,
        acceptButton,
        rejectButton,
    }
    playFadeIn(animNodes)
    playPromptSound()

    acceptButton.MouseButton1Click:Connect(function()
        raceService:JoinRace()
        closePrompt(item, animNodes)
    end)

    rejectButton.MouseButton1Click:Connect(function()
        closePrompt(item, animNodes)
    end)
end

return RaceJoinPrompt
