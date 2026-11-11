--!nonstrict
local AdminAnnouncementNotification = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NotificationUI = require(script.Parent.NotificationUI)
local NotificationsConfig = require(ReplicatedStorage.Shared.Config.Notifications.NotificationsConfig)

function AdminAnnouncementNotification.notify(title, message, icon, duration)
    NotificationUI.notify(
        title or "Admin",
        message or "",
        icon or NotificationsConfig.Icons.Success,
        duration or 2.2,
        NotificationsConfig.Sounds.AdminAnnouncement,
        0.8
    )
end

return AdminAnnouncementNotification
