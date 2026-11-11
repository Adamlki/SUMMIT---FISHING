--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DonationsNotificationResolver = {}

local TIMEOUT = 60

function DonationsNotificationResolver.resolve()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", TIMEOUT)
    local ui = playerGui:WaitForChild("NotificationsUI", TIMEOUT)
    if not ui then
        return false, "NotificationsUI not found"
    end

    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local assets = shared and shared:FindFirstChild("Assets")
    local donations = assets and assets:FindFirstChild("Donations")
    local template = donations and (donations:FindFirstChild("Notificatitons") or donations:FindFirstChild("Notifications"))

    if not template or not template:IsA("Frame") then
        return false, "Donation notification template not found in Shared/Assets/Donations/Notificatitons"
    end

    return true, {
        ui = ui,
        template = template,
    }
end

return DonationsNotificationResolver
