local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit) 
local Janitor = require(Packages.Janitor)

local RaceClientPermission = require(script.Parent.RaceClientPermission)
local RaceResolver = require(script.Parent.RaceResolver)
local RaceRender = require(script.Parent.RaceRender)
local RaceActionsBinder = require(script.Parent.RaceActionsBinder)
local RaceAnnounce = require(script.Parent.RaceAnnounce)
local RaceNotifications = require(script.Parent.RaceNotifications)
local RaceJoinPrompt = require(script.Parent.RaceJoinPrompt)
local RaceOverhead = require(script.Parent.RaceOverhead)

local RaceRuntime = {
    _started = false ,
    _janitor = nil,
    _playerJanitors = nil,
}

function RaceRuntime.start(raceService)
    if RaceRuntime._started then return end 
    RaceRuntime._started = true 
    RaceRuntime._janitor = Janitor.new()
    RaceRuntime._playerJanitors = {}

local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui") or Players.LocalPlayer:WaitForChild("PlayerGui", 30)
    if not playerGui then return end 
	

local refs = RaceResolver.resolve(playerGui)
local overheadTemplate = Shared.Assets.Overhead and Shared.Assets.Overhead:FindFirstChild("RaceUI") or nil
local overhead = RaceOverhead.new(overheadTemplate)
local lastState = nil 

local function applyAll(state)
    lastState = state or {}
    local canUseAdmin = RaceClientPermission.canUseRaceAdmin()
    local canSeeOverhead = RaceClientPermission.canSeeRaceOverhead()
    RaceRender.applyPermission(refs, canUseAdmin)
    RaceRender.renderState(refs, lastState)
    RaceAnnounce.syncState(refs, lastState)
    RaceNotifications.syncState(refs, lastState)
    overhead:render(lastState, canSeeOverhead)
end

local function refreshOverheadForCharacter(player, character)
    overhead:onCharacterAdded(player)
    task.spawn(function()
        if character and character.Parent then
            character:WaitForChild("Head", 5) 
        end
    overhead:render(lastState or {}, RaceClientPermission.canSeeRaceOverhead())
    end)
end

local function cleanupPlayer(player)
    local playerJanitor = RaceRuntime._playerJanitors[player]
    if playerJanitor then 
        playerJanitor:Destroy()
        RaceRuntime._playerJanitors[player] = nil
    end

    if overhead and overhead.teardown then 
        overhead:teardown(player) 
    end 
end

local function bindCharacterWatcher(player)
    cleanupPlayer(player)

    local playerJanitor = Janitor.new()
    RaceRuntime._playerJanitors[player] = playerJanitor

    playerJanitor:Add(player.CharacterAdded:Connect(function(character)
        refreshOverheadForCharacter(player, character)
    end), "Disconnect")

    playerJanitor:Add(player.CharacterAppearanceLoaded:Connect(function(character)
        refreshOverheadForCharacter(player, character)
    end), "Disconnect")

    if player.Character then 
        refreshOverheadForCharacter(player, player.Character)
    end 
end

local actionsJanitor = RaceActionsBinder.bind(refs, raceService)
    RaceRuntime._janitor:Add(actionsJanitor, "Destroy")
    RaceRuntime._janitor:Add(overhead, "destroy")

    for _,player in ipairs(Players:GetPlayers()) do
        bindCharacterWatcher(player)
    end 
    RaceRuntime._janitor:Add(Players.PlayerAdded:Connect(function(player)
        bindCharacterWatcher(player)
    end), "Disconnect")
    RaceRuntime._janitor:Add(Players.PlayerRemoving:Connect(function(player)
        bindCharacterWatcher(player)
    end), "Disconnect") 

    local initialState = raceService:GetState()
    if type(initialState) == "table" then 
        applyAll(initialState)
    elseif initialState and initialState.andThen then 
        initialState:andThen(function(state)
            applyAll(state)
        end):catch(function() end)
    else 
        applyAll({})
    end 

    if raceService.State and raceService.State.Observe then 
        RaceRuntime._janitor:Add(raceService.State:Observe(function(state)
            applyAll(state)
        end), "Disconnect")
    end
local accum = 0
    RaceRuntime._janitor:Add(RunService.Heartbeat:Connect(function(dt)
        accum += dt
        if accum < 0.1 then return end 
        accum = 0
local canSeeOverhead = RaceClientPermission.canSeeRaceOverhead()
    RaceRender.renderState(refs, lastState or {})
        overhead:render(lastState or {}, canSeeOverhead)
    end), "Disconnect")

    if raceService.Notification then
        RaceRuntime._janitor:Add(raceService.Notification:Connect(function(payload)
            RaceNotifications.render(refs, payload)
    end), "Disconnect")
end
    if raceService.JoinPrompt then
        RaceRuntime._janitor:Add(raceService.JoinPrompt:Connect(function(payload)
            RaceJoinPrompt.show(raceService, payload)
    end), "Disconnect")
end

local overheadService = nil 
local ok = pcall(function()
    overheadService = Knit.GetService("OverheadService")
end)
    if ok and overheadService and overheadService.Config and overheadService.Config.Observe then 
        RaceRuntime._janitor:Add(overheadService.Config:Observe(function()
            applyAll(lastState)
        end), "Disconnect")
    end 
end

return RaceRuntime