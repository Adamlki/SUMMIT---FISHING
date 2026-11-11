--!nonstrict
local parts = script.Parent:FindFirstChild("TeleportHelpers")
if not parts then
	error("[Teleport] TeleportHelpers folder not found.")
end
local Bind = require(parts.Bind)
local Build = require(parts.Build)

local Teleport = {}

function Teleport.buildButtons(runtime, destinations)
	Build.buildButtons(runtime, destinations)
end

function Teleport.bind(runtime)
	Bind.bind(runtime)
end

return Teleport
