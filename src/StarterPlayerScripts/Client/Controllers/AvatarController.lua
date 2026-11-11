--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)

local AvatarUI = require(script.Parent.Parent.Modules.Avatar.AvatarUI)

local Controller = Knit.CreateController({ Name = "AvatarController" })

function Controller:KnitStart()
    for _ = 1, 5 do
        if AvatarUI.init() then
            return
        end
        task.wait(2)
    end
end

return Controller
