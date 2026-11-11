--!nonstrict
local parts = script.Parent:FindFirstChild("UtilityHelpers")
if not parts then
	error("[Util] UtilityHelpers folder not found.")
end
local Avatars = require(parts.Avatars)
local Lists = require(parts.Lists)
local Select = require(parts.Select)
local Time = require(parts.Time)

local Util = {}

Util.setAvatar = Avatars.setAvatar
Util.setAvatarByUserId = Avatars.setAvatarByUserId
Util.clearList = Lists.clearList
Util.buildPlayerList = Lists.buildPlayerList
Util.applySelectVisual = Select.applySelectVisual
Util.makeSingleSelect = Select.makeSingleSelect
Util.formatTime = Time.formatTime

return Util
