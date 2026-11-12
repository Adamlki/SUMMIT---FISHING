local Module = {}

function Module.Install(Controller)
	-- Movement Controls Disabler (Ensures carried player doesn't fight carrier physics)
	function Controller:InitMovementControls()
		self.playerModule = nil
		self.playerControls = nil
		pcall(function()
			local PlayerScripts = self.player:WaitForChild("PlayerScripts", 10)
			local pModuleScript = PlayerScripts and PlayerScripts:WaitForChild("PlayerModule", 10)
			if pModuleScript then
				self.playerModule = require(pModuleScript)
				self.playerControls = self.playerModule and self.playerModule:GetControls()
			end
		end)
	end

	function Controller:SetMovementControlsEnabled(enabled)
		if self.playerControls then
			pcall(function()
				if enabled then
					self.playerControls:Enable()
				else
					self.playerControls:Disable()
				end
			end)
		end
	end

	-- Get humanoid dari player character
	function Controller:GetHumanoid()
		local char = self.player.Character
		return char and char:FindFirstChildOfClass("Humanoid")
	end

	-- Get HumanoidRootPart dari player character
	function Controller:GetHRP()
		local char = self.player.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	-- Get or create Animator
	function Controller:GetAnimator(hum)
		return hum and (hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum))
	end

	-- Play sitting animation (untuk carried player)
	function Controller:PlaySit()
		-- FIX: Tunggu sebentar agar network ownership berpindah ke carrier dulu
		-- sebelum mencoba load animasi, supaya animasi bisa di-apply dengan benar
		task.spawn(function()
			task.wait(0.2)

			local hum = self:GetHumanoid()
			if not hum then return end
			if not self.isCarried then return end -- Batalkan kalau sudah tidak di-carry

			-- Semua rig memakai animasi Harpy Wings idle
			local useId = self.SIT_ID
			if useId == 0 then return end

			local animator = self:GetAnimator(hum)

			-- Stop existing sit animation
			if self.sitTrack then
				self.sitTrack:Stop(0.15)
				self.sitTrack = nil
			end

			-- Load dan play new animation
			self.sitAnimation.AnimationId = "rbxassetid://" .. tostring(useId)

			local ok, track = pcall(function()
				return animator:LoadAnimation(self.sitAnimation)
			end)

			if ok and track then
				self.sitTrack = track
				self.sitTrack.Priority = Enum.AnimationPriority.Action4
				self.sitTrack.Looped = true
				self.sitTrack:Play(0.1)
			end

			-- FIX: Paksa Sit = true beberapa kali karena server ownership bisa nge-reset
			for i = 1, 5 do
				task.wait(0.1)
				if not hum or not hum.Parent or not self.isCarried then break end
				hum.Sit = false
				hum.PlatformStand = false
				if self.sitTrack and not self.sitTrack.IsPlaying then
					self.sitTrack:Play(0.1)
				end
			end
		end)
	end

	-- Stop sitting animation
	function Controller:StopSit()
		local hum = self:GetHumanoid()
		local hrp = self:GetHRP()

		if self.sitTrack then
			self.sitTrack:Stop(0.2)
			self.sitTrack = nil
		end

		if hum then
			hum.Sit = false
			hum.PlatformStand = false
			hum.Jump = false
		end

		-- FIX: Reset velocity dan rotasi di client agar tidak spinning/melayang
		if hrp then
			pcall(function()
				hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			end)
		end

		-- FIX: Paksa state Running setelah stop sit agar karakter berdiri normal
		if hum then
			task.spawn(function()
				for i = 1, 5 do
					task.wait(0.1)
					if not hum or not hum.Parent then break end
					hum.Sit = false
					hum.PlatformStand = false
					hum:ChangeState(Enum.HumanoidStateType.Running)
					if not hum.Sit and not hum.PlatformStand then break end
				end
			end)
		end
	end

	-- Start blocking jump input
	function Controller:StartBlockingJump()
		if self.jumpBlockConn then
			self.jumpBlockConn:Disconnect()
		end

		self.jumpBlockConn = self.UserInputService.JumpRequest:Connect(function()
			local h = self:GetHumanoid()
			if h then
				h.Jump = false
			end
		end)
	end

	-- Stop blocking jump input
	function Controller:StopBlockingJump()
		if self.jumpBlockConn then
			self.jumpBlockConn:Disconnect()
			self.jumpBlockConn = nil
		end
	end
end

return Module
