--!nonstrict
local parts = script.Parent:FindFirstChild("ServerHelpers")
if not parts then
	error("[Server] ServerHelpers folder not found.")
end
local Bind = require(parts.Bind)

local ServerPage = {}

function ServerPage.bind(runtime)
	Bind.bind(runtime)
end

return ServerPage
