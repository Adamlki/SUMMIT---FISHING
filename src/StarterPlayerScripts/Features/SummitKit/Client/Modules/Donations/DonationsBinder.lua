--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)

local DonationsBinder = {}

function DonationsBinder.bind(view, onOpen)
    local janitor = Janitor.new()
    if not view or not view.show then
        return janitor
    end
    local originalShow = view.show
    view.show = function(self)
        if onOpen then
            onOpen()
        end
        originalShow(self)
    end
    return janitor
end

return DonationsBinder
