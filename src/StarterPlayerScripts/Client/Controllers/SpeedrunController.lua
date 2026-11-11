--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)

local SpeedrunUI = require(script.Parent.Parent.Modules.Speedrun.SpeedrunUI)

local Controller = Knit.CreateController({Name = "SpeedrunController"})

function Controller:KnitStart()
    for _ = 1, 5 do
        if SpeedrunUI.init() then
            break
        end
        task.wait(2)
    end
    local service = Knit.GetService("SpeedrunService")
    service.RunStarted:Connect(function()
        SpeedrunUI.start()
    end)
    service.RunFinished:Connect(function(elapsedSeconds)
        SpeedrunUI.finish(elapsedSeconds)
    end)
end

return Controller
