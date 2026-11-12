-- System initialization, character lifecycle, session restore and cast replication.
local Module = {}

function Module.Install(Controller)
	function Controller:InitializeSystems()
		self.SoundManager:Initialize()
		self.GUIManager:Initialize(self.player)

		local autoButton = self.GUIManager:GetElement("autoButton")
		if autoButton and self.autoButtonElement ~= autoButton then
			self.autoButtonElement = autoButton
			autoButton.MouseButton1Click:Connect(function()
				local gameState = self.gameState
				gameState.isAutoFishing = not gameState.isAutoFishing
				self.GUIManager:UpdateAutoButton(gameState.isAutoFishing)

				if gameState.isAutoFishing then
					self:StartAutoFishLoop()
					self.GUIManager:ShowNotification("Otomatis Menyala", 3, Color3.fromRGB(100, 255, 100))
					if self.RodManager.isEquipped and gameState.canCast and not gameState.casted and not gameState.fishingInProgress and not gameState.castingCooldown then
						self:AutoCast()
					end
				else
					self:StopAutoFishLoop()
					self.GUIManager:ShowNotification("Otomatis Mati", 3, Color3.fromRGB(255, 100, 100))
				end
			end)
		end

		self.AnimationController:Initialize(self.humanoid)
		self.PowerBarSystem:Initialize({
			barFrame = self.GUIManager:GetElement("barFrame"),
			fillFrame = self.GUIManager:GetElement("fillFrame"),
			luckMultiText = self.GUIManager:GetElement("luckMultiText")
		})
		self.MinigameSystem:Initialize({
			fishingFillFrame = self.GUIManager:GetElement("fishingFillFrame"),
			infoText = self.GUIManager:GetElement("infoText")
		}, nil)

		self.speedState.originalWalkSpeed = self.humanoid.WalkSpeed
	end

	function Controller:ConnectCharacterEvents()
		self.player.CharacterAdded:Connect(function(char)
			local gameState = self.gameState

			gameState.activeFishingTask = nil
			if self.MinigameSystem:IsActive() then self.MinigameSystem:ForceStop() end
			if gameState.sinker then gameState.sinker:Destroy(); gameState.sinker = nil end
			if gameState.splash then gameState.splash:Destroy(); gameState.splash = nil end
			self.NetworkGateway:Request("POST", "/fishing/cleanup", {})

			-- Pastikan kamera kembali normal jika karakter baru spawn
			local camera = self.camera
			if camera and camera.Parent and camera.CameraType ~= Enum.CameraType.Custom then
				camera.CameraType = Enum.CameraType.Custom
			end

			gameState.casted, gameState.fishingInProgress = false, false
			gameState.canCast, gameState.hasLanded = true, false
			gameState.fishingCaught, gameState.castingCooldown = false, false

			gameState.isAutoFishing = false

			self.character = char
			self.humanoid = char:WaitForChild("Humanoid")
			self.camera = workspace.CurrentCamera -- Update referensi kamera
			self.speedState.originalWalkSpeed = self.humanoid.WalkSpeed
			self:InitializeSystems()
			self.GUIManager:UpdateAutoButton(false)

			self.RodManager:SetupCharacterMonitoring(self.character)
		end)

		self.player.CharacterRemoving:Connect(function()
			local gameState = self.gameState

			gameState.activeFishingTask = nil
			if self.MinigameSystem:IsActive() then self.MinigameSystem:ForceStop() end
			if gameState.sinker then gameState.sinker:Destroy(); gameState.sinker = nil end
			if gameState.splash then gameState.splash:Destroy(); gameState.splash = nil end
			for k, conn in self.connections do if conn then conn:Disconnect(); self.connections[k] = nil end end
			self.cameraSequenceToken += 1
			self.NetworkGateway:Request("POST", "/fishing/cleanup", {})
		end)
	end

	function Controller:ConnectSessionRestore()
		self.resumeFishingRemote.OnClientEvent:Connect(function(sessionData)
			if typeof(sessionData) ~= "table" then return end
			task.spawn(function()
				-- Hanya lanjut auto-mancing jika saat disconnect memang sedang auto-mancing.
				-- Tool yang dipegang tetap dipulihkan sesuai snapshot (tanpa memaksa mancing).
				local resumeFishing = sessionData.Action == "Fishing" and sessionData.IsAutoFishing == true
				local toolName = sessionData.EquippedTool
				if not toolName and resumeFishing then
					toolName = sessionData.RodName or "Basic Rod"
				end

				local player = self.player
				local targetTool
				if toolName then
					local startTime = os.clock()
					targetTool = player.Backpack:FindFirstChild(toolName) or (self.character and self.character:FindFirstChild(toolName))
					while not targetTool and (os.clock() - startTime < 6) do
						task.wait(0.2)
						targetTool = player.Backpack:FindFirstChild(toolName) or (self.character and self.character:FindFirstChild(toolName))
					end
				end

				if not targetTool and resumeFishing then
					for _, tool in ipairs(player.Backpack:GetChildren()) do
						if tool:IsA("Tool") and (self.CS:HasTag(tool, "Rod") or tool.Name:lower():find("rod")) then
							targetTool = tool
							break
						end
					end
				end

				if targetTool and self.character then
					local hum = self.character:FindFirstChildOfClass("Humanoid") or self.character:WaitForChild("Humanoid", 3)
					if hum then
						hum:EquipTool(targetTool)
						if resumeFishing then
							task.wait(0.6)
							self.gameState.isAutoFishing = true
							self.GUIManager:UpdateAutoButton(true)
							self:StartAutoFishLoop()
							task.delay(0.5, function() self:AutoCast() end)
						end
					end
				end
			end)
		end)
	end

	function Controller:ConnectCastReplication()
		local player, CS, Debris, CastingSystem = self.player, self.CS, self.Debris, self.CastingSystem
		local otherPlayersHooks = self.otherPlayersHooks

		self.castReplicationEvent.OnClientEvent:Connect(function(otherPlayer, rodPos, velocity, rodName)
			if otherPlayer == player then return end

			local data = otherPlayersHooks[otherPlayer]
			if data then
				if data.sinker then data.sinker:Destroy() end
				if data.beam then data.beam:Destroy() end
				if data.connection then data.connection:Disconnect() end
			end

			local sinker = CastingSystem:CreateHook(rodPos, rodName)
			sinker.AssemblyLinearVelocity = velocity

			local char = otherPlayer.Character
			if not char then Debris:AddItem(sinker, 5); return end

			local rod = char:FindFirstChild(rodName)
			if not rod or not rod:FindFirstChild("Part") then Debris:AddItem(sinker, 5); return end

			local att1 = Instance.new("Attachment", rod.Part)
			local att2 = Instance.new("Attachment", sinker)
			local beam = CastingSystem:CreateBeam(rod.Part, att1, att2, rodName)

			local conn; conn = sinker.Touched:Connect(function(hit)
				if hit:IsDescendantOf(char) or CS:HasTag(hit, "Fish") or (hit.Parent and CS:HasTag(hit.Parent, "Fish")) then return end
				sinker.AssemblyLinearVelocity = Vector3.zero
				sinker.Anchored = true
				if conn then conn:Disconnect() end
			end)

			otherPlayersHooks[otherPlayer] = {sinker = sinker, beam = beam, connection = conn}
		end)

		self.cleanupCastEvent.OnClientEvent:Connect(function(otherPlayer)
			if otherPlayer == player then return end
			local data = otherPlayersHooks[otherPlayer]
			if data then
				if data.sinker then data.sinker:Destroy() end
				if data.beam then data.beam:Destroy() end
				if data.connection then data.connection:Disconnect() end
				otherPlayersHooks[otherPlayer] = nil
			end
		end)
	end
end

return Module
