--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)
local Janitor = require(Packages.Janitor)
local Notifier = require(script.Parent.Parent.Modules.Checkpoints.Notifier)
local StateHUD = require(script.Parent.Parent.Modules.Checkpoints.StateHUD)
local ResetUI = require(script.Parent.Parent.Modules.Checkpoints.ResetUI)
local RealtimeDisplay = require(script.Parent.Parent.Modules.Checkpoints.RealtimeDisplay)
local Bus = require(script.Parent.Parent.Modules.Checkpoints.CheckpointClientBus)

local Controller = Knit.CreateController({Name = "CheckpointController"})
local janitor = Janitor.new()

function Controller:KnitStart()
    local player = Players.LocalPlayer

    task.spawn(Bus.start)
    task.spawn(function() StateHUD.init(Bus) end)
    task.spawn(function() Notifier.init(Bus) end)
    task.spawn(function() RealtimeDisplay.init(Bus) end)
    task.spawn(function() ResetUI.init(Bus) end)

    janitor:Add(player.CharacterRemoving:Connect(function()
        Notifier.clearQueue()
    end), "Disconnect")
end

function Controller:KnitStop()
    if RealtimeDisplay.destroy then
        RealtimeDisplay.destroy()
    end
    if ResetUI.destroy then
        ResetUI.destroy()
    end
    janitor:Destroy()
end

return Controller
