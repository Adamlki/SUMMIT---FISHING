--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)

local RaceRuntime = require(script.Parent.Parent.Modules.Race.RaceRuntime)

local Controller = Knit.CreateController({ Name = "RaceController" })

function Controller:KnitStart()
    local raceService = Knit.GetService("RaceService")
    RaceRuntime.start(raceService)
end

return Controller
