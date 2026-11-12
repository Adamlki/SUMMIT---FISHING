-- Casting sequence, cooldown, auto-fishing loop and mobile button text.
local Module = {}

function Module.Install(Controller)
	function Controller:UpdateMobileButtonText()
		local GUIManager = self.GUIManager
		if not GUIManager then return end
		local gameState = self.gameState
		local MinigameSystem, PowerBarSystem = self.MinigameSystem, self.PowerBarSystem

		local text = "CAST"
		if MinigameSystem:IsActive() then text = "KLIK!"
		elseif PowerBarSystem:IsCharging() then text = "LEMPAR!"
		elseif gameState.casted or gameState.fishingInProgress then text = "TARIK"
		elseif gameState.castingCooldown then text = "TUNGGU" end

		if gameState.isAutoFishing then
			if MinigameSystem:IsActive() or gameState.casted or gameState.fishingInProgress then
				text = "OTOMATIS"
			else
				text = "OTOMATIS"
			end
		end

		GUIManager:UpdateMobileButtonText(text)
	end

	function Controller:StartCastingCooldown()
		self.gameState.castingCooldown, self.gameState.canCast = true, false
		self:UpdateMobileButtonText()
		task.delay(self.gameState.cooldownTime, function()
			self.gameState.castingCooldown, self.gameState.canCast = false, true
			self:UpdateMobileButtonText()
		end)
	end

	function Controller:AutoCast()
		local gameState = self.gameState
		if not self.RodManager:IsValidRod() or gameState.casted or not self.character or not gameState.canCast or gameState.castingCooldown then return end

		gameState.canCast = false

		local power = math.random(90, 100)

		self.AnimationController:Play("WaitingAnimation", 0.1)
		self.SoundManager:Play("Cast", 0.5)

		task.wait(0.4)

		self:PerformCast(power)
	end

	function Controller:StartAutoFishLoop()
		if self.autoFishConnection then self.autoFishConnection:Disconnect() end

		self.autoFishConnection = self.RunService.Heartbeat:Connect(function()
			local gameState = self.gameState
			if gameState.isAutoFishing and self.RodManager.isEquipped and gameState.canCast and not gameState.casted and not gameState.fishingInProgress and not gameState.castingCooldown then
				self:AutoCast()
			end
		end)
	end

	function Controller:StopAutoFishLoop()
		if self.autoFishConnection then
			self.autoFishConnection:Disconnect()
			self.autoFishConnection = nil
		end
	end

	function Controller:RunFishingSequence(taskId, splash)
		local gameState = self.gameState
		local RodManager = self.RodManager
		local AnimationController, SoundManager, GUIManager = self.AnimationController, self.SoundManager, self.GUIManager
		local MinigameSystem, RodVFXManager, Debris = self.MinigameSystem, self.RodVFXManager, self.Debris

		local checks = {
			function() return gameState.activeFishingTask == taskId end,
			function() return RodManager.isEquipped and RodManager.currentRod end,
			function() return RodManager:IsValidRod() end,
			function() return gameState.casted and gameState.sinker end
		}

		local function validate()
			for _, check in checks do if not check() then return false end end
			return true
		end

		local function cleanup()
			if splash then splash:Destroy() end
			gameState.splash = nil
		end

		if not validate() then cleanup(); return false end

		task.wait(gameState.waitTime)
		if not validate() then cleanup(); gameState.fishingInProgress = false; return false end

		for i = 1, 3 do
			if not validate() then cleanup(); return false end
			if gameState.sinker and gameState.casted then
				local bubble = self.RepStorage.Splash:Clone()
				bubble.Caster.Value = self.player.Name
				bubble.Parent = workspace
				bubble.Position = gameState.sinker.Position
				Debris:AddItem(bubble, 1)
			end
			task.wait(0.1)
		end

		if not validate() then cleanup(); gameState.fishingInProgress = false; return false end

		AnimationController:Play("PullingAnimation", 0.1)
		SoundManager:Play("Reeling", 0.4)
		GUIManager:SlideFishingFrameIn()

		-- START REELING TENSION VFX
		if RodManager.currentRod and RodManager.currentRod:FindFirstChild("Part") then
			pcall(function() RodVFXManager:StartReelingVFX(RodManager.currentRod.Part, self:GetCurrentRodName()) end)
		end

		if gameState.sinker and gameState.sinker.Parent then
			gameState.savedHookPosition = gameState.sinker.Position
		end

		MinigameSystem:Start(gameState.isAutoFishing, self:GetCurrentRodName())

		while MinigameSystem:IsActive() do
			if not validate() then MinigameSystem:Stop(); break end
			task.wait(0.1)
		end

		-- STOP REELING TENSION VFX
		if RodManager.currentRod and RodManager.currentRod:FindFirstChild("Part") then
			pcall(function() RodVFXManager:StopReelingVFX(RodManager.currentRod.Part) end)
		end

		gameState.fishingInProgress, gameState.casted = false, false
		gameState.activeFishingTask = nil
		if gameState.sinker then gameState.sinker:Destroy(); gameState.sinker = nil end
		if gameState.splash then gameState.splash:Destroy(); gameState.splash = nil end
		if RodManager.currentRod and RodManager.currentRod:FindFirstChild("Part") then
			local line = RodManager.currentRod.Part:FindFirstChild("Line")
			if line then line:Destroy() end
		end

		self.NetworkGateway:Request("POST", "/fishing/cleanup", {})

		GUIManager:SlideFishingFrameOut(function()
			self:UpdateMobileButtonText()
		end)

		return true
	end

	function Controller:PerformCast(power)
		local gameState = self.gameState
		local RodManager = self.RodManager
		if not RodManager:IsValidRod() or gameState.casted or not self.character then return end

		local character = self.character
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		gameState.hasLanded, gameState.fishingInProgress = false, false
		gameState.canCast = false
		self:UpdateMobileButtonText()

		if not gameState.isAutoFishing then
			self.AnimationController:Play("WaitingAnimation", 0.1)
			self.SoundManager:Play("Cast", 0.5)
			task.wait(0.4)
		end

		if not RodManager.currentRod or not RodManager.currentRod:FindFirstChild("Part") then return end

		local rodPos = RodManager.currentRod.Part.Position + RodManager.currentRod.Part.CFrame.LookVector * 1.5
		local velocity = self.CastingSystem:CalculateVelocity(rodPos, hrp.CFrame.LookVector, power, 100)

		-- TRIGGER CAST VFX BURST & SFX
		pcall(function() self.RodVFXManager:PlayCastVFX(character, self:GetCurrentRodName(), rodPos) end)

		self.NetworkGateway:Request("POST", "/fishing/cast", {
			RodPos = rodPos,
			Velocity = velocity,
			RodName = self:GetCurrentRodName(),
			Power = power,
		})

		gameState.sinker = self.CastingSystem:CreateHook(rodPos, self:GetCurrentRodName())
		gameState.sinker.AssemblyLinearVelocity = velocity

		local att1 = Instance.new("Attachment", RodManager.currentRod.Part)
		local att2 = Instance.new("Attachment", gameState.sinker)
		self.CastingSystem:CreateBeam(RodManager.currentRod.Part, att1, att2, self:GetCurrentRodName())
		gameState.casted = true

		local landingConn; landingConn = gameState.sinker.Touched:Connect(function(hit)
			if gameState.hasLanded or not gameState.casted or gameState.fishingInProgress then return end
			if hit:IsDescendantOf(RodManager.currentRod) or hit:IsDescendantOf(character) then return end
			if self.CS:HasTag(hit, "Fish") or (hit.Parent and self.CS:HasTag(hit.Parent, "Fish")) then return end

			gameState.hasLanded = true
			gameState.sinker.AssemblyLinearVelocity = Vector3.zero
			gameState.sinker.Anchored = true
			if landingConn then landingConn:Disconnect() end

			local isWater = hit:IsA("Terrain") and self.CastingSystem:IsPositionInWater(gameState.sinker.Position)

			if isWater then
				self.SoundManager:Play("HookHit", 0.4)
				local waterY = self.CastingSystem:GetWaterSurfaceY(gameState.sinker.Position.X, gameState.sinker.Position.Z)
				if waterY then
					gameState.sinker.Position = Vector3.new(gameState.sinker.Position.X, waterY + 0.15, gameState.sinker.Position.Z)
				end

				local AssetsFolder = self.RepStorage:FindFirstChild("Assets")

				local SoundFolder = AssetsFolder and AssetsFolder:FindFirstChild("Sound")
				local rodSoundTemplate = SoundFolder and SoundFolder:FindFirstChild("Soundeffectrod")

				local EffectFolder = AssetsFolder and AssetsFolder:FindFirstChild("Effect")
				local RodEffectTemplate = EffectFolder and EffectFolder:FindFirstChild("EffectCorrupRod")

				-- Efek corrup hanya untuk rod tertentu
				local VISUAL_EFFECT_DURATION = 2.0

				local totalLockDuration = 4.0

				local hrp1 = character:FindFirstChild("HumanoidRootPart")

				local function positionEffect1(effectClone, template, duration)
					local hrp = character:FindFirstChild("HumanoidRootPart")
					if not hrp then return end

					local distanceInFront = 10
					local distanceRight = 0

					local heightAboveWater = 1.8

					local hrpCFrame = hrp.CFrame

					local projectedPosition = (hrpCFrame * CFrame.new(distanceRight, 0, -distanceInFront)).Position
					local finalY = projectedPosition.Y
					local waterY = self.CastingSystem:GetWaterSurfaceY(projectedPosition.X, projectedPosition.Z)

					if waterY then finalY = waterY + heightAboveWater end

					-- 1. Hitung CFrame posisi tanpa rotasi
					local baseCFrame = CFrame.new(projectedPosition.X, finalY, projectedPosition.Z) * (hrpCFrame - hrpCFrame.Position)

					-- 2. Terapkan rotasi (sumbu X)
					local desiredCFrame = baseCFrame * CFrame.Angles(math.rad(-90), 0, 0)

					if effectClone:IsA("Model") and effectClone.PrimaryPart then
						effectClone:SetPrimaryPartCFrame(desiredCFrame)
					elseif effectClone:IsA("BasePart") then
						effectClone.CFrame = desiredCFrame
					end

					if effectClone:IsA("Model") then
						for _, child in effectClone:GetChildren() do
							if child:IsA("BasePart") then
								child.CanCollide = false
								child.Anchored = true
							end
						end
					end
					self.Debris:AddItem(effectClone, duration)
				end

				if self:GetCurrentRodName() == "Corruption Edge" then

					-- 1. EFEK SUARA
					if rodSoundTemplate and rodSoundTemplate:IsA("Sound") then
						local Api = rodSoundTemplate:Clone()
						Api.Parent = workspace
						Api:Play()
						self.Debris:AddItem(Api, totalLockDuration)
					else
						warn("⚠ Efek Suara Listrik tidak ditemukan!")
					end

					-- 2. EFEK VISUAL (PARTSECRET1)
					if RodEffectTemplate and (RodEffectTemplate:IsA("BasePart") or RodEffectTemplate:IsA("Model")) then
						if hrp1 then
							local effectClone1 = RodEffectTemplate:Clone()
							effectClone1.Parent = workspace

							positionEffect1(effectClone1, RodEffectTemplate, VISUAL_EFFECT_DURATION)
						end
					else
						warn("⚠️ Template efek visual (PartSecret1) tidak valid atau tidak ditemukan.")
					end
				end

				gameState.activeFishingTask = tick()
				gameState.fishingInProgress, gameState.canCast = true, false
				self:UpdateMobileButtonText()

				local splash = self.RepStorage.Splash:Clone()
				splash.Caster.Value = self.player.Name
				splash.Parent = workspace
				splash.Position = gameState.sinker.Position
				gameState.splash = splash

				task.spawn(function() self:RunFishingSequence(gameState.activeFishingTask, splash) end)
			else
				self.GUIManager:ShowNotification("Masukkan ke dalam air!", 3, Color3.fromRGB(255, 200, 100))
				task.wait(2)
				if not RodManager.isEquipped or not RodManager.currentRod then return end

				gameState.casted = false
				if gameState.sinker then gameState.sinker:Destroy() end
				if RodManager.currentRod and RodManager.currentRod:FindFirstChild("Part") then
					local line = RodManager.currentRod.Part:FindFirstChild("Line")
					if line then line:Destroy() end
				end
				self.NetworkGateway:Request("POST", "/fishing/cleanup", {})
				self:StartCastingCooldown()
				task.delay(0.6, function()
					if RodManager.isEquipped and RodManager.currentRod then
						self.AnimationController:Play("EquippedAnimation", 0.3)
					end
				end)
			end
		end)
	end
end

return Module
