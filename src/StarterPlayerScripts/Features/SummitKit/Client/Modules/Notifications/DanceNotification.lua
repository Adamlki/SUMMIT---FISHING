--!nonstrict
local DanceNotification = {}

local NotificationHandler = require(script.Parent.Core.NotificationHandler)

function DanceNotification.error(message, duration)
	NotificationHandler.error("Dance", message, duration or 2.5)
end

function DanceNotification.success(message, duration)
	NotificationHandler.success("Dance", message, duration or 2.2)
end

return DanceNotification
