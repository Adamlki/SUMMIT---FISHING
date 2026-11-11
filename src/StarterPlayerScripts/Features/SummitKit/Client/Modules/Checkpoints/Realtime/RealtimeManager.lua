--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)

local RealtimeEntry = require(script.Parent.RealtimeEntry)

local RealtimeManager = {}
RealtimeManager.__index = RealtimeManager

function RealtimeManager.new(refs)
    local self = setmetatable({}, RealtimeManager)
    self.refs = refs
    self.entries = {}
    self.janitor = Janitor.new()
    return self
end

function RealtimeManager:addPlayer(player)
    local localPlayer = Players.LocalPlayer
    if player ~= localPlayer then
        return
    end
    if not (self.refs and self.refs.container and self.refs.template) then return end
    if self.entries[player] then return end
    local entry = RealtimeEntry.new(player, self.refs.template, self.refs.container)
    if entry then
        self.entries[player] = entry
    end
end

function RealtimeManager:removePlayer(player)
    local entry = self.entries[player]
    if not entry then return end
    entry:destroy()
    self.entries[player] = nil
end

function RealtimeManager:refreshPlayer(player)
    local entry = self.entries[player]
    if entry then
        entry:refresh()
    end
end

function RealtimeManager:bindPlayers()
    local localPlayer = Players.LocalPlayer
    if localPlayer then
        self:addPlayer(localPlayer)
    end
end

function RealtimeManager:destroy()
    self.janitor:Destroy()
    for _, entry in pairs(self.entries) do
        entry:destroy()
    end
    self.entries = {}
end

return RealtimeManager
