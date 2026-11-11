--!nonstrict
local Logger = {}
Logger.__index = Logger

function Logger.new(tag, enabled)
    local self = setmetatable({}, Logger)
    self.tag = tag or "LOG"
    self.enabled = enabled == true
    return self
end

local function format(tag, level, msg)
    return string.format("[%s][%s] %s", tag, level, msg)
end

function Logger:info(msg)
    if not self.enabled then return end
    print(format(self.tag, "INFO", msg))
end

function Logger:warn(msg)
    if not self.enabled then return end
    warn(format(self.tag, "WARN", msg))
end

function Logger:error(msg)
    if not self.enabled then return end
    warn(format(self.tag, "ERROR", msg))
end

return Logger
