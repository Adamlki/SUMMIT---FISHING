--!nonstrict
local AvatarNotification = {}

local NotificationHandler = require(script.Parent.Core.NotificationHandler)

function AvatarNotification.error(message, duration)
    NotificationHandler.error("Avatar", message, duration or 2.5)
end

function AvatarNotification.success(message, duration)
    NotificationHandler.success("Avatar", message, duration or 2.2)
end

return AvatarNotification
