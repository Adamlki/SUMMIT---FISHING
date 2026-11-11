--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Signal = require(Packages.Signal)

local ShopState = {}
ShopState.__index = ShopState

function ShopState.new()
    local self = setmetatable({}, ShopState)
    self.selectedUserId = nil
    self.selectedName = nil
    self.selectedToolId = nil
    self.vipConfig = nil
    self.catalog = {}
    self.ownedTools = {}
    self.changed = Signal.new()
    return self
end

function ShopState:setTarget(userId, name)
    self.selectedUserId = userId
    self.selectedName = name
    self.changed:Fire("target", userId, name)
end

function ShopState:setConfig(cfg)
    self.vipConfig = cfg
    self.changed:Fire("config", cfg)
end

function ShopState:setCatalog(catalog)
    self.catalog = catalog or {}
    self.changed:Fire("catalog", self.catalog)
end

function ShopState:setOwnedTools(ownedTools)
    self.ownedTools = ownedTools or {}
    self.changed:Fire("owned", self.ownedTools)
end

function ShopState:setSelectedTool(toolId)
    self.selectedToolId = toolId
    self.changed:Fire("tool", toolId)
end

return ShopState
