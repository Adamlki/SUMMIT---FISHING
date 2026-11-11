--!nonstrict
local parts = script.Parent:FindFirstChild("RoleHelpers")
if not parts then
	error("[Roles] RoleHelpers folder not found.")
end
local Bind = require(parts.Bind)
local Build = require(parts.Build)

local Roles = {}

function Roles.buildButtons(runtime, roles)
	Build.buildButtons(runtime, roles)
end

function Roles.bind(runtime)
	Bind.bind(runtime)
end

return Roles
