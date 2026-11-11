local tool = script.Parent
local humanoid
local runTrack, idleTrack
local runningConn

-- Animasi ID (ganti ikut animasi awak)
local idleAnim = Instance.new("Animation")
idleAnim.AnimationId = ""

local runAnim = Instance.new("Animation")
runAnim.AnimationId = ""

tool.Equipped:Connect(function()
	local char = tool.Parent
	humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Load animasi
	idleTrack = humanoid:LoadAnimation(idleAnim)
	runTrack = humanoid:LoadAnimation(runAnim)

	-- Priority rendah ? climb/jump/fall/swim masih override
	idleTrack.Priority = Enum.AnimationPriority.Idle
	runTrack.Priority = Enum.AnimationPriority.Action

	idleTrack:Play()

	-- Pantau kecepatan
	runningConn = humanoid.Running:Connect(function(speed)
		local state = humanoid:GetState()

		-- Biarkan animasi default bila panjat, lompat, jatuh, renang
		if state == Enum.HumanoidStateType.Climbing 
			or state == Enum.HumanoidStateType.Freefall
			or state == Enum.HumanoidStateType.Jumping
			or state == Enum.HumanoidStateType.Swimming then
			if idleTrack and idleTrack.IsPlaying then idleTrack:Stop() end
			if runTrack and runTrack.IsPlaying then runTrack:Stop() end
			return
		end

		-- Idle / Run custom
		if speed > 1 then
			if idleTrack and idleTrack.IsPlaying then idleTrack:Stop() end
			if runTrack and not runTrack.IsPlaying then runTrack:Play() end
		else
			if runTrack and runTrack.IsPlaying then runTrack:Stop() end
			if idleTrack and not idleTrack.IsPlaying then idleTrack:Play() end
		end
	end)
end)

tool.Unequipped:Connect(function()
	-- Hentikan animasi
	if idleTrack then idleTrack:Stop() idleTrack = nil end
	if runTrack then runTrack:Stop() runTrack = nil end

	-- Putuskan connection
	if runningConn then
		runningConn:Disconnect()
		runningConn = nil
	end
end)