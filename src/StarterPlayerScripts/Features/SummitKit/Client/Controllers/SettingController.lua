--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)
local Janitor = require(Packages.Janitor)

local SettingMenu = require(script.Parent.Parent.Modules.Settings.SettingMenu)

local Controller = Knit.CreateController({ Name = "SettingController" })
local janitor = Janitor.new()

local function setup(player)
    for _ = 1, 5 do
        if SettingMenu.setupForPlayer(player) then
            break
        end
        task.wait(2)
    end
    janitor:Add(player.CharacterAdded:Connect(function()
        for _ = 1, 5 do
            if SettingMenu.setupForPlayer(player) then
                break
            end
            task.wait(2)
        end
    end), "Disconnect")
end

function Controller:KnitStart()
    local lp = Players.LocalPlayer
    setup(lp)

    janitor:Add(Players.PlayerAdded:Connect(function(player)
        if player == lp then
            setup(player)
        end
    end), "Disconnect")
end

function Controller:KnitStop()
    janitor:Destroy()
    SettingMenu.destroy()
end

return Controller
