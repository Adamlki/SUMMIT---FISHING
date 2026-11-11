--!nonstrict
local NotificationHandler = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NotificationUI = require(script.Parent.Parent.NotificationUI)
local NotificationsConfig = require(ReplicatedStorage.Shared.Config.Notifications.NotificationsConfig)

NotificationHandler.Sounds = NotificationsConfig.Sounds

function NotificationHandler.error(header, description, duration)
    NotificationUI.notify(
        header,
        description,
        NotificationsConfig.Icons.Failed,
        duration or 2.5,
        NotificationHandler.Sounds.Failed
    )
end

function NotificationHandler.success(header, description, duration)
    NotificationUI.notify(
        header,
        description,
        NotificationsConfig.Icons.Success,
        duration or 2.2,
        NotificationHandler.Sounds.Success
    )
end

return NotificationHandler
