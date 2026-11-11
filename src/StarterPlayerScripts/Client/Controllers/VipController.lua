--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)

local VipGiftNotification = require(script.Parent.Parent.Modules.Notifications.VipGiftNotification)

local Controller = Knit.CreateController({Name = "VipController"})

function Controller:KnitStart()
    local vipService = Knit.GetService("VipService")
    vipService.GiftNotice:Connect(function(role, otherUserId, otherName)
        VipGiftNotification.notify(role, otherUserId, otherName)
    end)
end

return Controller
