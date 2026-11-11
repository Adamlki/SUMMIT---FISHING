--!nonstrict
local RunService = game:GetService("RunService")
local MusicDisplay = require(script.Parent.MusicDisplay)

local MusicPlaybackBinder = {}

function MusicPlaybackBinder.bind(runtime)
	runtime._janitor:Add(runtime._playback:getSound().Ended:Connect(function()
		runtime._playback:setPlaying(false)
		if runtime._playback:isRepeat() then
			runtime:_loadSong(runtime._playback:getIndex(), true)
		else
			runtime:_loadSong(runtime:_getNextIndex(), true)
		end
		MusicDisplay.updatePlayPauseIcon(runtime)
	end), "Disconnect")

	runtime._janitor:Add(RunService.Heartbeat:Connect(function()
		if runtime._playback:isPlaying() then
			runtime:_updateProgressBar()
		end
	end), "Disconnect")
end

return MusicPlaybackBinder
