-- Minigame success/fail flow: rarity lock, bounce/slow-mo camera, rare catch effects.
local Module = {}

function Module.Install(Controller)
	function Controller:HandleMinigameSuccess()
		local gameState = self.gameState

		gameState.fishingCaught = true
		self:UpdateMobileButtonText()
		if self.RodManager.isEquipped and self.RodManager.currentRod then
			self.AnimationController:TransitionTo("EquippedAnimation", 0.3)
		end

		task.delay(0.3, function()
			local selectedFish, fishWeight = self:SelectFish()

			-- Jika penangkapan tidak menghasilkan ikan, jalankan cooldown normal dan keluar.
			if not selectedFish then
				self:StartCastingCooldown()
				return
			end

			-- Daftar raritas yang memicu Lock
			local rarityToLock = {
				["Secret"] = true,
			}

			-- Daftar raritas yang memicu AUTO-STOP
			local rarityToAutoStop = {

			}

			-- Daftar raritas yang menggunakan animasi JATUH & MANTUL
			local rarityForBounce = {
				["Mitos"] = true,
			}

			local lockDuration = 4 -- Durasi Lock, Camera Shake, dan PartSecret
			local requiresLock = rarityToLock[selectedFish.rarity]
			local SLOW_MO_LOCK_DURATION = 2.0
			local finalLockDuration = 2.0 -- Default: durasi kunci standar (non-slow-mo)

			if rarityForBounce[selectedFish.rarity] then
				-- Kasus 1: Ikan Slow-Mo
				self:ShowFishBouncingDropAnimation(selectedFish)

				finalLockDuration = SLOW_MO_LOCK_DURATION

				-- 1. Terapkan Lock Segera
				gameState.canCast = false
				gameState.castingCooldown = true
				gameState.isLocked = true

				self:UpdateMobileButtonText()

				-- Efek lock: Camera Shake
				self:StartCameraShakeHorizontal(finalLockDuration)

				-- 2. Aktifkan kembali setelah lock selesai
				task.delay(finalLockDuration, function()
					self.SoundManager:Play("Success", 0.6)
					pcall(function() self.RodVFXManager:PlayCatchSuccessVFX(self.character, self:GetCurrentRodName()) end)
					self:ShowFishCatchNotification(selectedFish, fishWeight)

					gameState.canCast = true
					gameState.castingCooldown = false
					gameState.isLocked = false
					self:UpdateMobileButtonText()

					-- Cek apakah auto-fishing harus dimatikan
					if gameState.isAutoFishing and rarityToAutoStop[selectedFish.rarity] then
						gameState.isAutoFishing = false
						self:StopAutoFishLoop()
						self.GUIManager:ShowNotification("Auto-Fishing Mati (Ikan Langka)", 3, Color3.fromRGB(255, 150, 50))
					end

					self:UpdateMobileButtonText()

					-- Jika auto-fishing aktif, panggil autoCast
					if gameState.isAutoFishing then
						task.delay(0.5, function() self:AutoCast() end)
					end
				end)
			elseif rarityToLock[selectedFish.rarity] then
				-- Kasus 2: Ikan Non-Slow-Mo
				if requiresLock then

					-- 1. Terapkan Lock Segera (menghentikan semua casting)
					gameState.canCast = false
					gameState.castingCooldown = true
					gameState.isLocked = true
					self:UpdateMobileButtonText()

					self:StartCameraShakeHorizontal(lockDuration)

					-- MENCARI FOLDER ASSETS
					local AssetsFolder = self.RepStorage:FindFirstChild("Assets")

					-- SOUND & EFFECT TEMPLATES
					local SoundFolder = AssetsFolder and AssetsFolder:FindFirstChild("Sound")
					local rareSoundTemplate = SoundFolder and SoundFolder:FindFirstChild("RareCatchSound")
					local listrikSoundTemplate = SoundFolder and SoundFolder:FindFirstChild("Listrik")

					local EffectFolder = AssetsFolder and AssetsFolder:FindFirstChild("Effect")
					local partSecretTemplate = EffectFolder and EffectFolder:FindFirstChild("PartSecret")
					local partSecretTemplate1 = EffectFolder and EffectFolder:FindFirstChild("PartSecret1")

					local stageDuration = lockDuration -- 4.0 detik
					local totalLockDuration = lockDuration * 2 -- 8.0 detik

					-- Posisikan efek di depan pemain, di permukaan air bila ada
					local function positionEffect(effectClone, template, duration)
						local hrp = self.character:FindFirstChild("HumanoidRootPart")
						if not hrp then return end

						local distanceInFront = 12
						local distanceRight = 0
						local heightAboveWater = 1.0
						local hrpCFrame = hrp.CFrame

						local projectedPosition = (hrpCFrame * CFrame.new(distanceRight, 0, -distanceInFront)).Position
						local finalY = projectedPosition.Y
						local waterY = self.CastingSystem:GetWaterSurfaceY(projectedPosition.X, projectedPosition.Z)

						if waterY then finalY = waterY + heightAboveWater end

						-- Rotasi pemain, lalu digeser Z 90 derajat lokal
						local desiredCFrame = CFrame.new(projectedPosition.X, finalY, projectedPosition.Z) * (hrpCFrame - hrpCFrame.Position)
						desiredCFrame = desiredCFrame * CFrame.Angles(0, 0, math.rad(90))

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

					local hrp1 = self.character:FindFirstChild("HumanoidRootPart")

					-- TAHAP 1: PARTSECRET1 + SOUND LISTRIK (0 - 4.0 detik)
					if partSecretTemplate1 and (partSecretTemplate1:IsA("BasePart") or partSecretTemplate1:IsA("Model")) then
						if hrp1 then
							-- SOUND LISTRIK
							if listrikSoundTemplate and listrikSoundTemplate:IsA("Sound") then
								local Listrik = listrikSoundTemplate:Clone()
								Listrik.Parent = workspace
								Listrik:Play()
								self.Debris:AddItem(Listrik, totalLockDuration)
							else
								warn("⚠ Efek Suara Listrik tidak ditemukan!")
							end

							-- EFEK PARTSECRET1
							local effectClone1 = partSecretTemplate1:Clone()
							effectClone1.Parent = workspace

							positionEffect(effectClone1, partSecretTemplate1, totalLockDuration)
						end
					else
						warn("⚠️ PartSecret1 tidak ditemukan di jalur yang benar.")
					end

					-- TAHAP 2: PARTSECRET + SOUND RARECATCH (4.0 - 8.0 detik)
					task.delay(stageDuration, function()
						if partSecretTemplate and (partSecretTemplate:IsA("BasePart") or partSecretTemplate:IsA("Model")) then
							local hrp = self.character:FindFirstChild("HumanoidRootPart")
							self:StartCameraShakeHorizontal1(lockDuration)
							if hrp then
								-- SOUND RARECATCH
								if rareSoundTemplate and rareSoundTemplate:IsA("Sound") then
									local RareCatch = rareSoundTemplate:Clone()
									RareCatch.Parent = workspace
									RareCatch:Play()
									self.Debris:AddItem(RareCatch, stageDuration)
								else
									warn("⚠ Efek Suara RareCatchSound tidak ditemukan!")
								end

								-- EFEK PARTSECRET
								local effectClone = partSecretTemplate:Clone()
								effectClone.Parent = workspace

								positionEffect(effectClone, partSecretTemplate, stageDuration)
							end
						else
							warn("⚠️ PartSecret tidak ditemukan di jalur yang benar.")
						end
					end)

					-- 2. LOGIKA UNLOCK/COOLDOWN TOTAL (8.0 detik)
					task.delay(totalLockDuration, function()
						-- Jeda singkat agar semua efek dan animasi selesai
						task.wait(0.1)

						self.SoundManager:Play("Success", 0.6)
						self:ShowFishCatchNotification(selectedFish, fishWeight)

						gameState.canCast = true
						gameState.castingCooldown = false
						gameState.isLocked = false

						-- Cek apakah auto-fishing harus dimatikan
						if gameState.isAutoFishing and rarityToAutoStop[selectedFish.rarity] then
							gameState.isAutoFishing = false
							self:StopAutoFishLoop()
							self.GUIManager:ShowNotification("Auto-Fishing Mati (Ikan Langka)", 3, Color3.fromRGB(255, 150, 50))
						end

						self:UpdateMobileButtonText()

						-- Panggil autoCast di luar loop Heartbeat
						if gameState.isAutoFishing then
							task.delay(0.5, function() self:AutoCast() end)
						end
					end)
				else -- Jika tidak ada Lock (Common/Rare)
					self:StartCastingCooldown()
				end
			else
				self:ShowFishCatchAnimation(selectedFish)

				self.SoundManager:Play("Success", 0.6)
				self:ShowFishCatchNotification(selectedFish, fishWeight)

				gameState.canCast = true
				gameState.castingCooldown = false

				-- Cek apakah auto-fishing harus dimatikan
				if gameState.isAutoFishing and rarityToAutoStop[selectedFish.rarity] then
					gameState.isAutoFishing = false
					self:StopAutoFishLoop()
					self.GUIManager:ShowNotification("Auto-Fishing Mati (Ikan Langka)", 3, Color3.fromRGB(255, 150, 50))
				end

				self:UpdateMobileButtonText()

				-- Panggil autoCast di luar loop Heartbeat
				if gameState.isAutoFishing then
					task.delay(0.5, function() self:AutoCast() end)
				end
			end

			-- Send fish to server
			self.NetworkGateway:Request("POST", "/fishing/claim", {
				RollId = gameState.lastRollId
			})
			gameState.lastRollId = nil

			gameState.savedHookPosition = nil
		end)
	end

	function Controller:HandleMinigameFail()
		self.gameState.savedHookPosition = nil
		if self.RodManager.isEquipped and self.RodManager.currentRod then
			self.AnimationController:TransitionTo("EquippedAnimation", 0.3)
		end
		self.GUIManager:ShowNotification("Ikan itu lolos!", 2, Color3.fromRGB(255, 100, 100))
		self.MinigameSystem:Stop()
		self:StartCastingCooldown()
	end
end

return Module
