--!nonstrict
local NotifierState = {}
NotifierState.__index = NotifierState

function NotifierState.new()
    local self = setmetatable({}, NotifierState)
    self.lastSummit = 0
    self.summitCount = 0
    self.ready = false
    self.SUMMIT_COOLDOWN = 3
    self.SUMMIT_REWARD = 0
    return self
end

function NotifierState:setSummitCount(val)
    self.summitCount = val or 0
    self.ready = true
end

function NotifierState:setReady()
    self.ready = true
end

function NotifierState:shouldSummit(now)
    return (now - self.lastSummit) >= self.SUMMIT_COOLDOWN
end

function NotifierState:applySummit(now, rewardOverride)
    local reward = typeof(rewardOverride) == "number" and rewardOverride or self.SUMMIT_REWARD
    local oldTotal = self.summitCount
    local newTotal = oldTotal + reward
    self.summitCount = newTotal
    self.lastSummit = now
    return reward, oldTotal, newTotal
end

function NotifierState:setReward(reward)
    if typeof(reward) == "number" then
        self.SUMMIT_REWARD = reward
    end
end

return NotifierState
