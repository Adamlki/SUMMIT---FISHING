--!nonstrict
local TweenService = game:GetService("TweenService")

local NotificationRenderer = {}

local function setTransparency(node, value)
    if node:IsA("ImageLabel") or node:IsA("ImageButton") then
        node.ImageTransparency = value
    elseif node:IsA("TextLabel") or node:IsA("TextButton") then
        node.TextTransparency = value
    elseif node:IsA("CanvasGroup") then
        node.GroupTransparency = value
    end
end

local function tweenTransparency(node, value, info)
    if node:IsA("ImageLabel") or node:IsA("ImageButton") then
        TweenService:Create(node, info, {ImageTransparency = value}):Play()
    elseif node:IsA("TextLabel") or node:IsA("TextButton") then
        TweenService:Create(node, info, {TextTransparency = value}):Play()
    elseif node:IsA("CanvasGroup") then
        TweenService:Create(node, info, {GroupTransparency = value}):Play()
    end
end

local function fadeIn(node)
    if not node then return end
    setTransparency(node, 1)
    tweenTransparency(node, 0, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
end

local function fadeOut(node)
    if not node then return end
    tweenTransparency(node, 1, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
end

function NotificationRenderer.spawn(refs, payload)
    local template = refs.template
    local active = refs.active
    if not (template and active) then return end

    local item = template:Clone()
    item.Name = "NotificationItem"
    item.Visible = true
    item.Parent = active

    local icon = item:FindFirstChild("Icon")
    if icon and icon:IsA("ImageLabel") then
        if payload.icon then
            icon.Image = payload.icon
        end
    end

    local textGroup = item:FindFirstChild("Text")
    local header = textGroup and (textGroup:FindFirstChild("Header") or textGroup:FindFirstChild("Title"))
    local desc = textGroup and (
        textGroup:FindFirstChild("Description")
        or textGroup:FindFirstChild("Descripton")
        or textGroup:FindFirstChild("Deskriptions")
    )
    if header and header:IsA("TextLabel") then
        header.Text = payload.header or "Notification"
    end
    if desc and desc:IsA("TextLabel") then
        desc.Text = payload.description or ""
    end

    if payload.soundId and payload.soundId ~= "" then
        local sound = Instance.new("Sound")
        sound.SoundId = payload.soundId
        sound.Volume = payload.volume or 0.7
        sound.Parent = item
        sound:Play()
    end

    fadeIn(item)
    if textGroup then
        fadeIn(textGroup)
    end
    if icon then
        fadeIn(icon)
    end

    local lifetime = payload.duration or 2.5
    task.delay(lifetime, function()
        if not item or not item.Parent then return end
        fadeOut(item)
        if textGroup then
            fadeOut(textGroup)
        end
        if icon then
            fadeOut(icon)
        end
        task.delay(0.25, function()
            if item and item.Parent then
                item:Destroy()
            end
        end)
    end)
end

return NotificationRenderer
