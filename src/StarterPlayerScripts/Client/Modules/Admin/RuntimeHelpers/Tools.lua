--!nonstrict
local parts = script.Parent:FindFirstChild("ToolHelpers")
if not parts then
	error("[Tools] ToolHelpers folder not found.")
end
local Bind = require(parts.Bind)
local Build = require(parts.Build)

local Tools = {}

function Tools.buildButtons(runtime, tools)
	Build.buildButtons(runtime, tools)
end

function Tools.bind(runtime)
	Bind.bind(runtime)
end

return Tools
