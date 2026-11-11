--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)

local OverheadManager = {}
OverheadManager.__index = OverheadManager

function OverheadManager.new(deps)
    local self = setmetatable({}, OverheadManager)
    self._deps = deps
    self._overheads = {}
    self._config = nil
    return self
end

function OverheadManager:setConfig(cfg)
    self._config = cfg
    for player in pairs(self._overheads) do
        self:refresh(player)
    end
end

function OverheadManager:_applyLocalVisibility(player)
    local entry = self._overheads[player]
    if not entry or not entry.view then
        return
    end

    if entry.view.applyLocalVisibility then
        entry.view.applyLocalVisibility()
        return
    end

    local localPlayer = Players.LocalPlayer
    local hideTitles = localPlayer and localPlayer:GetAttribute("HideTitles") == true
    if entry.view.setEnabled then
        entry.view.setEnabled(not hideTitles)
    end
end

function OverheadManager:refresh(player)
    local entry = self._overheads[player]
        if not entry or not entry.view then return end

    local cfg = self._config
        if not cfg then return end

    local state = self._deps.StateResolver.resolve(player, cfg)
    local title, color = self._deps.TitleRules.getTitle(cfg.TitleConfig, state)
    local displayRoles = cfg.TitleConfig and cfg.TitleConfig.DisplayRole or nil
    entry.view.update(state, title, color, displayRoles)
    self:_applyLocalVisibility(player)
end

function OverheadManager:_createOverhead(player, character, attempt)
    if not character then return end

    attempt = attempt or 1

    local function hideDefaultTags()
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
            pcall(function()
                humanoid.NameDisplayDistance = 0
            end)
            pcall(function()
                humanoid.HealthDisplayDistance = 0
            end)
        end
    end
    hideDefaultTags()
    local entryJanitor = Janitor.new()
    entryJanitor:Add(character.ChildAdded:Connect(function(child)
        if child:IsA("Humanoid") then
            hideDefaultTags()
        end
    end), "Disconnect")

    local view = self._deps.View.new(self._deps.OverheadTemplate, self._deps.CustomTitleTemplate, player, character)
    if not view then
        entryJanitor:Destroy()
        if attempt < 10 and player.Character == character then 
            task.delay(0.25, function()
                self:_createOverhead(player, character, attempt + 1)
            end)
        end
    return end

    local entry = {
        view = view,
        conns = {},
        janitor = Janitor.new(),
        summitConn = nil,
        summitChildConn = nil,
    }
    entry.janitor:Add(entryJanitor, "Destroy")
    self._overheads[player] = entry

    self._deps.SignalManager.bindPlayerSignals(player, entry, function()
        return self._config
    end, function(target)
        self:refresh(target)
    end)
    self:refresh(player)
    self:_applyLocalVisibility(player)

    entry.janitor:Add(character.ChildAdded:Connect(function(child)
        if child.Name == "Head" then
            self:teardown(player)
            self:_createOverhead(player, character, 1)
        end
    end), "Disconnect")
end

function OverheadManager:handleCharacter(player, character)
    self:teardown(player)
    self:_createOverhead(player, character, 1)
end

function OverheadManager:teardown(player)
    local entry = self._overheads[player]
    if not entry then
        return
    end
    self._deps.SignalManager.teardownConnections(entry)
    if entry.view then
        entry.view.destroy()
    end
    self._overheads[player] = nil
end

function OverheadManager:destroyAll()
    for player in pairs(self._overheads) do
        self:teardown(player)
    end
end

return OverheadManager
