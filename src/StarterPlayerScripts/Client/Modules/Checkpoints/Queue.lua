--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Promise = require(Packages.Promise)

local Queue = {}
Queue.__index = Queue

function Queue.new(processFn)
    local self = setmetatable({}, Queue)
    self._list = {}
    self._processing = false
    self._processFn = processFn
    return self
end

function Queue:enqueue(item)
    table.insert(self._list, item)
    self:_process()
end

function Queue:_process()
    if self._processing then return end
    self._processing = true
    Promise.try(function()
        while #self._list > 0 do
            local item = table.remove(self._list, 1)
            if self._processFn then
                local p = Promise.resolve(self._processFn(item))
                p:await()
            end
        end
    end):catch(function(err)
        warn("[Queue] process error: " .. tostring(err))
    end):finally(function()
        self._processing = false
        if #self._list > 0 then
            self:_process()
        end
    end)
end

function Queue:clear()
    table.clear(self._list)
end

return Queue
