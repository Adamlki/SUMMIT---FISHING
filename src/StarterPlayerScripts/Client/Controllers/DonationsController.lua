--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)

local DonationsUI = require(script.Parent.Parent.Modules.Donations.DonationsUI)
local DonationsNotification = require(script.Parent.Parent.Modules.Notifications.DonationsNotification)

local Controller = Knit.CreateController({ Name = "DonationsController" })

function Controller:KnitStart()
    local donationsService = Knit.GetService("DonationsService")
    donationsService.DonateNotice:Connect(function(userId, displayName, amount)
        DonationsNotification.notify(userId, displayName, amount)
    end)

    for _ = 1, 5 do
        if DonationsUI.init() then
            return
        end
        task.wait(2)
    end
end

return Controller
