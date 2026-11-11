--!nonstrict
local AnimatorUtil = require(script.Parent.AnimatorUtil)

local Playback = {}

function Playback.resetButton(runtime)
	if runtime._currentButton then
		runtime._currentButton.BackgroundColor3 = runtime._colors.Default
		runtime._currentButton = nil
	end
end

function Playback.stopCurrent(runtime)
	if runtime._currentTrack then
		runtime._currentTrack:Stop()
		runtime._currentTrack:Destroy()
		runtime._currentTrack = nil
	end
	Playback.resetButton(runtime)
	runtime:_clearPublishedState()
end

function Playback.playManual(runtime, animation, looped, button)
	runtime:_clearFollowTarget()

	if runtime._currentButton == button then
		Playback.stopCurrent(runtime)
		return
	end

	local animator = AnimatorUtil.getAnimator()
	if not animator then
		return
	end

	Playback.stopCurrent(runtime)

	local track = animator:LoadAnimation(animation)
	track.Looped = looped
	track.Priority = Enum.AnimationPriority.Action
	track:Play()

	runtime._currentTrack = track
	runtime._currentButton = button
	if button then
		button.BackgroundColor3 = runtime._colors.Active
	end

	runtime:_publishState(animation.AnimationId, animation.Name, looped, track.Speed)
end

function Playback.applySyncedTime(runtime, track, state)
	local function computeTargetTime()
		local targetTime = 0
		local speed = tonumber(state.speed) or 1
		local startedAtServerTime = tonumber(state.startedAtServerTime)
		if startedAtServerTime then
			targetTime = math.max(0, (workspace:GetServerTimeNow() - startedAtServerTime) * speed)
		end

		if track.Length > 0 then
			if state.looped == true then
				targetTime %= track.Length
			else
				targetTime = math.clamp(targetTime, 0, math.max(track.Length - 0.03, 0))
			end
		end

		return targetTime
	end

	pcall(function()
		track.TimePosition = computeTargetTime()
	end)

	if track.Length > 0 then
		return
	end

	local applied = false
	local conn
	conn = track:GetPropertyChangedSignal("Length"):Connect(function()
		if applied or track.Length <= 0 then
			return
		end
		applied = true
		if conn then
			conn:Disconnect()
			conn = nil
		end
		pcall(function()
			track.TimePosition = computeTargetTime()
		end)
	end)

	runtime._janitor:Add({
		Disconnect = function()
			if conn then
				conn:Disconnect()
				conn = nil
			end
		end,
	}, "Disconnect")
end

function Playback.playSynced(runtime, state)
	if typeof(state) ~= "table" then
		return false, "InvalidState"
	end

	local animationId = tostring(state.animationId or "")
	if animationId == "" then
		return false, "MissingAnimationId"
	end

	local animator = AnimatorUtil.getAnimator()
	if not animator then
		return false, "NoAnimator"
	end

	if runtime._currentTrack then
		runtime._currentTrack:Stop()
		runtime._currentTrack:Destroy()
		runtime._currentTrack = nil
	end
	Playback.resetButton(runtime)

	local animation = Instance.new("Animation")
	animation.Name = tostring(state.animationName or "SyncedDance")
	animation.AnimationId = animationId

	local track = animator:LoadAnimation(animation)
	track.Looped = state.looped == true
	track.Priority = Enum.AnimationPriority.Action
	track:Play(0, 1, tonumber(state.speed) or 1)

	runtime._currentTrack = track
	runtime._currentButton = nil
	Playback.applySyncedTime(runtime, track, state)
	runtime:_publishState(animationId, animation.Name, state.looped == true, track.Speed)

	return true
end

return Playback
