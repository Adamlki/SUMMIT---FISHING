--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NotificationResolver = {}

local TIMEOUT = 60

function NotificationResolver.resolve()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", TIMEOUT)
    local ui = playerGui:WaitForChild("NotificationsUI", TIMEOUT)
    if not ui then
        return false, "NotificationsUI not found"
    end

    local active = ui:FindFirstChild("ActiveNotifications")
    if not active then
        return false, "ActiveNotifications not found"
    end

    local shared = ReplicatedStorage.Shared
    local assets = shared and shared:FindFirstChild("Assets")
    local notifFolder = assets and assets:FindFirstChild("Notifications")
    local canvas = notifFolder and (notifFolder:FindFirstChild("Canvas") or notifFolder:FindFirstChild("Canvavs"))
    local template = canvas and canvas:FindFirstChild("Notification")

    if not template then
        return false, "Notification template not found in Shared/Assets/Notifications/Canvas(s)/Notification"
    end

    return true, {
        ui = ui,
        active = active,
        template = template,
    }
end

return NotificationResolver
