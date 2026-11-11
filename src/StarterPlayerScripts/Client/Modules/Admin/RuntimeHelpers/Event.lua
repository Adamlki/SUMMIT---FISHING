--!nonstrict
local parts = script.Parent:WaitForChild("EventHelpers")
local Bind = require(parts:WaitForChild("Bind"))
local Send = require(parts:WaitForChild("Send"))

local Event = {}

function Event.bind(runtime)
	Bind.bind(runtime)
end

function Event.send(runtime)
	Send.send(runtime)
end

return Event
