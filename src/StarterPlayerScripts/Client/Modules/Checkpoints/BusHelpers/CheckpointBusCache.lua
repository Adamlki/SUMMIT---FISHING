--!nonstrict
local CheckpointBusCache = {}
CheckpointBusCache.__index = CheckpointBusCache

function CheckpointBusCache.new()
    local self = setmetatable({}, CheckpointBusCache)
    self._lastState = nil
    self._lastConfig = nil
    return self
end

function CheckpointBusCache:setState(state)
    self._lastState = state
end

function CheckpointBusCache:setConfig(config)
    self._lastConfig = config
end

function CheckpointBusCache:getLastState()
    return self._lastState
end

function CheckpointBusCache:getLastConfig()
    return self._lastConfig
end

return CheckpointBusCache
