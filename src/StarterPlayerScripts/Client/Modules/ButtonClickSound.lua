--!nonstrict
local ButtonClickSoundBinder = require(script.Parent.ButtonClickSoundBinder)
local ButtonClickSoundPlayer = require(script.Parent.ButtonClickSoundPlayer)

local ButtonClickSound = {}

local runtime

function ButtonClickSound.init()
	if runtime then
		return runtime
	end

	runtime = ButtonClickSoundBinder.start(ButtonClickSoundPlayer.play)
	return runtime
end

function ButtonClickSound.destroy()
	if runtime then
		runtime:Destroy()
		runtime = nil
	end
end

return ButtonClickSound
