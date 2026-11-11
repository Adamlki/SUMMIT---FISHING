--!nonstrict
local Time = {}

function Time.formatTime(seconds)
	seconds = tonumber(seconds) or 0
	if seconds < 0 then
		seconds = 0
	end
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = math.floor(seconds % 60)
	return string.format("%02d:%02d:%02d", h, m, s)
end

return Time
