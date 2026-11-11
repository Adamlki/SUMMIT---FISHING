--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)
local Janitor = require(Packages.Janitor)

local Controller = Knit.CreateController({ Name = "OverheadController" })

local StateResolver = require(script.Parent.Parent.Modules.Overhead.StateResolver)
local TitleRules = require(script.Parent.Parent.Modules.Overhead.TitleRules)
local View = require(script.Parent.Parent.Modules.Overhead.View)
local DeviceReporter = require(script.Parent.Parent.Modules.Overhead.DeviceReporter)
local ChatTags = require(script.Parent.Parent.Modules.Overhead.ChatTags)
local SignalManager = require(script.Parent.Overhead.SignalManager)
local OverheadManager = require(script.Parent.Parent.Modules.Overhead.OverheadManager)

local overheadTemplate = Shared.Assets.Overhead.OverheadTemplate

local overheadService
local controllerJanitor = Janitor.new()
local playerJanitors = {}
local manager

local function teardownPlayer(player)
    local janitor = playerJanitors[player]
    if janitor then 
        janitor:Destroy()
        playerJanitors[player] = nil 
    end 
    if manager then 
        manager:teardown(player)
    end
end

local function bindPlayer(player)
    teardownPlayer(player)

    local janitor = Janitor.new()
    playerJanitors[player] = janitor

    local function attachCharacter(character) 
        if manager and character then 
            manager:handleCharacter(player, character)
        end 
    end

    if player.Character then 
        task.defer(attachCharacter, player.Character)
    end

    janitor:Add(player.CharacterAdded:Connect(function(character)
        attachCharacter(character)
    end), "Disconnect")

    janitor:Add(player.CharacterRemoving:Connect(function()
        if manager then 
            manager:teardown(player)
        end
    end), "Disconnect")
end

function Controller:KnitStart()
    overheadService = Knit.GetService("OverheadService")
    manager = OverheadManager.new({
        StateResolver = StateResolver,
        TitleRules = TitleRules,
        View = View,
        SignalManager = SignalManager,
        OverheadTemplate = overheadTemplate,
        CustomTitleTemplate = nil,
    })

    if overheadService and overheadService.Config and overheadService.Config.Observe then
        controllerJanitor:Add(overheadService.Config:Observe(function(cfg)
            manager:setConfig(cfg)
        end), "Disconnect")
    end

    local deviceJanitor = DeviceReporter.start(overheadService)
    controllerJanitor:Add(deviceJanitor, "Destroy")

    local chatTagsJanitor = ChatTags.start(overheadService)
    controllerJanitor:Add(chatTagsJanitor, "Destroy")

    controllerJanitor:Add(Players.PlayerAdded:Connect(function(player)
        bindPlayer(player)
    end), "Disconnect")

    controllerJanitor:Add(Players.PlayerRemoving:Connect(function(player)
        teardownPlayer(player)
    end), "Disconnect")

    for _, player in ipairs(Players:GetPlayers()) do 
        bindPlayer(player)
    end 
end

function Controller:KnitStop()
    controllerJanitor:Destroy()
    for player, janitor in pairs(playerJanitors) do 
        janitor:Destroy()
        playerJanitors[player] = nil 
    end 
    if manager then
        manager:destroyAll()
    end
end

return Controller
