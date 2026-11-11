--!nonstrict
local AdminNotification = {}

local NotificationHandler = require(script.Parent.Core.NotificationHandler)

function AdminNotification.error(message, duration)
    NotificationHandler.error("Admin", message, duration or 2.5)
end

function AdminNotification.success(message, duration)
    NotificationHandler.success("Admin", message, duration or 2.2)
end

return AdminNotification
