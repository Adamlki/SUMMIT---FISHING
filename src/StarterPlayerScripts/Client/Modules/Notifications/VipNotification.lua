--!nonstrict
local VipNotification = {}

local NotificationHandler = require(script.Parent.Core.NotificationHandler)

function VipNotification.error(message, duration)
    NotificationHandler.error("VIP", message, duration or 2.5)
end

function VipNotification.success(message, duration)
    NotificationHandler.success("VIP", message, duration or 2.2)
end

return VipNotification
