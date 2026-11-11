--!nonstrict
local parts = script.Parent:FindFirstChild("TabHelpers")
if not parts then
	error("[Tabs] TabHelpers folder not found.")
end
local Bind = require(parts.Bind)

local Tabs = {}

function Tabs.bind(runtime)
	Bind.bind(runtime)
end

return Tabs
