--!nonstrict
local DanceLifecycle = {}

function DanceLifecycle.onCharacterAdded(runtime)
	runtime:_clearFollowTarget()
	runtime:_resetButton()
	if runtime._currentTrack then
		runtime._currentTrack:Stop()
		runtime._currentTrack:Destroy()
		runtime._currentTrack = nil
	end
	runtime:_clearPublishedState()
end

function DanceLifecycle.destroy(runtime)
	runtime:_clearFollowTarget()
	runtime:_clearPublishedState()
	if runtime._janitor then
		runtime._janitor:Destroy()
		runtime._janitor = nil
	end
end

return DanceLifecycle
