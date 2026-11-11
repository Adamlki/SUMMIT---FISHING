--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)

local TitleMenu = require(script.Parent.Parent.Modules.CustomTitle.TitleMenu)

local Controller = Knit.CreateController({ Name = "TitlePlayerListMenu" })

function Controller:KnitStart()
    task.spawn(function()
        for _ = 1, 10 do
            if TitleMenu.init() then
                return
            end
            task.wait(1)
        end
    end)
end

return Controller
