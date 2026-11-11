--!nonstrict
local Players = game:GetService("Players")

local NotificationUI = require(script.Parent.NotificationUI)
local NotificationHandler = require(script.Parent.Core.NotificationHandler)

local VipGiftNotification = {}

local function getThumb(userId)
    local ok, content = pcall(function()
        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    return ok and content or ""
end

function VipGiftNotification.notify(role, otherUserId, otherName)
    local icon = otherUserId and getThumb(otherUserId) or ""
    local header = "VIP Gift"
    local desc
    if role == "giver" then
        desc = "You gifted VIP to " .. (otherName or "a player") .. "."
    else
        desc = "You received VIP from " .. (otherName or "a player") .. "."
    end
    NotificationUI.notify(
        header,
        desc,
        icon,
        2.5,
        NotificationHandler.Sounds.Success
    )
end

return VipGiftNotification
