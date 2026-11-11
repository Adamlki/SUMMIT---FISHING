--!nonstrict
local CustomTitleNotification = {}

local NotificationHandler = require(script.Parent.Core.NotificationHandler)

function CustomTitleNotification.error(message, duration)
    NotificationHandler.error("Custom Title", message, duration or 2.5)
end

function CustomTitleNotification.success(message, duration)
    NotificationHandler.success("Custom Title", message, duration or 2.2)
end

return CustomTitleNotification
