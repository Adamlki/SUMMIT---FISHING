--!nonstrict
local Formatter = {}

function Formatter.formatTime(seconds)
	seconds = math.floor(seconds or 0)
	return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

return Formatter
