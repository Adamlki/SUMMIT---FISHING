--!nonstrict
local parts = script.Parent:FindFirstChild("PlayerHelpers")
if not parts then
	error("[Players] PlayerHelpers folder not found.")
end
local Bind = require(parts.Bind)

local PlayersPage = {}

function PlayersPage.bind(runtime)
	Bind.bind(runtime)
end

return PlayersPage
