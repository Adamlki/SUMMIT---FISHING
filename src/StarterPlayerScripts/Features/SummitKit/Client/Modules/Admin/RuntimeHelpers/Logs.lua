--!nonstrict
local parts = script.Parent:FindFirstChild("LogHelpers")
if not parts then
	error("[Logs] LogHelpers folder not found.")
end
local Bind = require(parts.Bind)
local Render = require(parts.Render)

local Logs = {}

function Logs.set(runtime, entries)
	Render.set(runtime, entries)
end

function Logs.push(runtime, entry)
	Render.push(runtime, entry)
end

function Logs.bind(runtime)
	Bind.bind(runtime)
end

return Logs
