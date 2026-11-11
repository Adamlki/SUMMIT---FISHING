--!nonstrict
local TweenService = game:GetService("TweenService")

local DonationsNotificationRenderer = {}

local OPEN_POSITION = UDim2.new(0.5, 0, 0.05, 50)
local HIDDEN_POSITION = UDim2.fromScale(0.5, -0.25)
local OPEN_ANCHOR = Vector2.new(0.5, 0.35)

local function tween(object, info, props)
    local tweenObject = TweenService:Create(object, info, props)
    tweenObject:Play()
    return tweenObject
end

function DonationsNotificationRenderer.spawn(refs, payload)
    local template = refs and refs.template
    local host = refs and refs.ui
    if not template or not host then
        return
    end

    local item = template:Clone()
    item.Name = "DonationNotificationItem"
    item.Visible = true
    item.AnchorPoint = OPEN_ANCHOR
    item.Position = HIDDEN_POSITION
    item.Parent = host

    local icon = item:FindFirstChild("Icon")
    local title = item:FindFirstChild("Title")

    if icon and icon:IsA("ImageLabel") then
        icon.Image = payload.icon or ""
    end
    if title and title:IsA("TextLabel") then
        title.Text = payload.title or "Someone donated"
    end

    if payload.soundId and payload.soundId ~= "" then
        local sound = Instance.new("Sound")
        sound.SoundId = payload.soundId
        sound.Volume = payload.volume or 0.8
        sound.Parent = item
        sound:Play()
    end

    tween(
        item,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = OPEN_POSITION}
    )

    task.delay(payload.duration or 3, function()
        if not item or not item.Parent then
            return
        end
        tween(
            item,
            TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = HIDDEN_POSITION}
        )
        task.delay(0.25, function()
            if item and item.Parent then
                item:Destroy()
            end
        end)
    end)

    return item
end

return DonationsNotificationRenderer
