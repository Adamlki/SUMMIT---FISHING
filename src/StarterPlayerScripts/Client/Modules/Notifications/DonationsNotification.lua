--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DonationsNotificationResolver = require(script.Parent.DonationsNotificationResolver)
local DonationsNotificationRenderer = require(script.Parent.DonationsNotificationRenderer)

local NotificationsConfig = require(ReplicatedStorage.Shared.Config.Notifications.NotificationsConfig)

local DonationsNotification = {}

local refs
local resolved = false

local function ensure()
    if resolved and refs then
        return true
    end

    local ok, dataOrErr = DonationsNotificationResolver.resolve()
    if not ok then
        warn("[DonationsNotification] " .. tostring(dataOrErr))
        return false
    end

    refs = dataOrErr
    resolved = true
    return true
end

local function getThumb(userId)
    local ok, image = pcall(function()
        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    return ok and image or NotificationsConfig.Icons.Success
end

function DonationsNotification.notify(userId, displayName, amount)
    if not ensure() then
        return
    end

    local name = (typeof(displayName) == "string" and displayName ~= "") and displayName or "Someone"
    local donated = tonumber(amount) or 0

    local item = DonationsNotificationRenderer.spawn(refs, {
        icon = NotificationsConfig.Icons.Success,
        title = string.format("%s: Has donate %d Robux", name, donated),
        duration = 3,
        soundId = NotificationsConfig.Sounds.Donate or NotificationsConfig.Sounds.Success,
        volume = 0.85,
    })

    if not item or not userId then
        return
    end

    task.spawn(function()
        local thumb = getThumb(userId)
        if not item or not item.Parent then
            return
        end
        local icon = item:FindFirstChild("Icon")
        if icon and icon:IsA("ImageLabel") then
            icon.Image = thumb
        end
    end)
end

return DonationsNotification
