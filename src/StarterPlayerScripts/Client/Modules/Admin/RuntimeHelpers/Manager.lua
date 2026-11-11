--!nonstrict
local parts = script.Parent:FindFirstChild("ManagerHelpers")
if not parts then
	error("[Manager] ManagerHelpers folder not found.")
end
local Bind = require(parts.Bind)

local Manager = {}

function Manager.bind(runtime)
	Bind.bind(runtime)
end

return Manager
