--!nonstrict
local CheckpointNotification = {}

local NotificationHandler = require(script.Parent.Core.NotificationHandler)

function CheckpointNotification.error(message, duration)
    NotificationHandler.error("Checkpoint", message, duration or 2.5)
end

return CheckpointNotification
