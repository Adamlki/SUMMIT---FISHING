--!nonstrict
local parts = script.Parent:FindFirstChild("AnnounceHelpers")
if not parts then
	error("[Announce] AnnounceHelpers folder not found.")
end
local Bind = require(parts.Bind)
local Send = require(parts.Send)

local Announce = {}

function Announce.bind(runtime)
	Bind.bind(runtime)
end

function Announce.send(runtime)
	Send.send(runtime)
end

return Announce
