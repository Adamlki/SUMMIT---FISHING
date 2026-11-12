-- Rod state: equip/unequip hooks, character monitoring, fishing cleanup.
local Module = {}

local RodManager = {}
RodManager.__index = RodManager

function Module.Create(controller)
	return setmetatable({ controller = controller, currentRod = nil, isEquipped = false }, RodManager)
end

function RodManager:IsValidRod()
	local controller = self.controller
	return self.currentRod and self.currentRod.Parent and self.isEquipped
		and controller.player.Character and self.currentRod:IsDescendantOf(controller.player.Character)
		and self.currentRod:FindFirstChild("Part")
end

function RodManager:CleanupFishing()
	local controller = self.controller
	local gameState = controller.gameState

	if not (gameState.casted or gameState.fishingInProgress) then return end

	gameState.casted, gameState.fishingInProgress = false, false
	gameState.canCast, gameState.castingCooldown = true, false
	gameState.activeFishingTask = nil

	if gameState.splash then gameState.splash:Destroy(); gameState.splash = nil end
	if gameState.sinker then gameState.sinker:Destroy(); gameState.sinker = nil end

	local MinigameSystem, PowerBarSystem = controller.MinigameSystem, controller.PowerBarSystem
	if MinigameSystem and MinigameSystem:IsActive() then MinigameSystem:ForceStop() end
	if PowerBarSystem and PowerBarSystem:IsCharging() then PowerBarSystem:StopCharging() end

	controller.NetworkGateway:Request("POST", "/fishing/cleanup", {})
	if controller.GUIManager and controller.GUIManager.SlideFishingFrameOut then
		controller.GUIManager:SlideFishingFrameOut(nil)
	end
	controller:UpdateMobileButtonText()
end

function RodManager:OnRodEquipped(rod)
	if not rod or not rod.Parent then return end
	if self.currentRod and self.currentRod ~= rod then self:OnRodUnequipped() end

	self.currentRod, self.isEquipped = rod, true
	self.controller:OnRodEquipped(rod)
end

function RodManager:OnRodUnequipped()
	if not self.currentRod then return end
	self:CleanupFishing()
	self.currentRod, self.isEquipped = nil, false
	self.controller:OnRodUnequipped()
end

function RodManager:CheckEquippedRod(char)
	if not char then return end
	local CS = self.controller.CS

	for _, tool in char:GetChildren() do
		if tool:IsA("Tool") and CS:HasTag(tool, "Rod") then
			if self.currentRod ~= tool then self:OnRodEquipped(tool) end
			return
		end
	end

	if self.isEquipped then self:OnRodUnequipped() end
end

function RodManager:SetupCharacterMonitoring(char)
	if not char then return end
	if self.monitorConnections then
		for _, c in ipairs(self.monitorConnections) do
			if c then c:Disconnect() end
		end
	end
	self.monitorConnections = {}
	self:CheckEquippedRod(char)

	local CS = self.controller.CS
	local RunService = self.controller.RunService

	table.insert(self.monitorConnections, char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and CS:HasTag(child, "Rod") then
			self:OnRodEquipped(child)
		end
	end))

	table.insert(self.monitorConnections, char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and CS:HasTag(child, "Rod") and self.currentRod == child then
			self:OnRodUnequipped()
		end
	end))

	local conn; conn = RunService.Heartbeat:Connect(function()
		if not char or not char.Parent then conn:Disconnect(); return end
		if self.isEquipped and not self:IsValidRod() then self:OnRodUnequipped() end
		self:CheckEquippedRod(char)
	end)
	table.insert(self.monitorConnections, conn)
end

function Module.Install(Controller)
	function Controller:GetCurrentRodName()
		return self.RodManager.currentRod and self.RodManager.currentRod.Name
	end

	function Controller:SetSpeed(isFishing)
		local gameState = self.gameState
		local speedState = self.speedState
		local humanoid = self.humanoid
		local isLocked = gameState.isLocked -- Cek state penguncian baru

		if isLocked then
			-- Jika sedang dikunci, paksa WalkSpeed menjadi 0
			if humanoid.WalkSpeed ~= 0 then
				humanoid.WalkSpeed = 0
				speedState.speedModified = true
			end
		elseif isFishing and not speedState.speedModified then
			humanoid.WalkSpeed = speedState.fishingWalkSpeed
			speedState.speedModified = true
		elseif not (isFishing or isLocked) and speedState.speedModified then
			humanoid.WalkSpeed = speedState.originalWalkSpeed
			speedState.speedModified = false
		end
	end

	function Controller:StartSpeedMonitoring()
		pcall(function()
			self.NetworkGateway:Request("PUT", "/afk/sync", {
				Action = "Fishing",
				RodName = self:GetCurrentRodName() or "Basic Rod",
				IsAutoFishing = self.gameState.isAutoFishing == true,
			})
		end)
		local connections = self.connections
		if connections.speedCheck then connections.speedCheck:Disconnect() end
		connections.speedCheck = self.RunService.Heartbeat:Connect(function()
			local gameState = self.gameState
			local isFishing = gameState.casted or gameState.fishingInProgress
				or self.MinigameSystem:IsActive() or self.PowerBarSystem:IsCharging()
				or gameState.isLocked
			self:SetSpeed(isFishing and self.RodManager.isEquipped)
		end)
	end

	function Controller:StopSpeedMonitoring()
		pcall(function()
			self.NetworkGateway:Request("PUT", "/afk/sync", {
				Action = "Idle",
			})
		end)
		if self.connections.speedCheck then
			self.connections.speedCheck:Disconnect()
			self.connections.speedCheck = nil
		end
		self:SetSpeed(false)
	end

	function Controller:OnRodEquipped(rod)
		local gameState = self.gameState
		local RodManager = self.RodManager

		self.AnimationController:Reload(self.humanoid)
		self.AnimationController:Play("EquippedAnimation", 0.3)
		self:StartSpeedMonitoring()

		self.GUIManager:ShowAutoButton(true)

		local function handleCastStart()
			if not RodManager.isEquipped then return end
			if gameState.isAutoFishing then return end

			if self.MinigameSystem:IsActive() then
				task.spawn(function() self.MinigameSystem:HandleClick(self.SoundManager, self.GUIManager) end)
				return
			end

			if gameState.canCast and not gameState.casted and not gameState.fishingInProgress and not gameState.castingCooldown then
				self.PowerBarSystem:StartCharging(self:GetCurrentRodName())
				self:UpdateMobileButtonText()
			end
		end

		local function handleCastRelease()
			if not RodManager.isEquipped then return end
			if gameState.isAutoFishing then return end

			if self.MinigameSystem:IsActive() then
				task.spawn(function() self.MinigameSystem:HandleClick(self.SoundManager, self.GUIManager) end)
				return
			end

			if self.PowerBarSystem:IsCharging() then
				local power = self.PowerBarSystem:StopCharging()
				-- Quick tap / short hold casts with minimum 20% power so cast doesn't fail
				if power < 20 then
					power = 20
				end

				if not gameState.castingCooldown then
					self:PerformCast(power)
				else
					gameState.canCast = true
					self.AnimationController:Play("EquippedAnimation", 0.3)
				end
				self:UpdateMobileButtonText()
			end
		end

		-- Direct Tool Event Bindings (Works seamlessly across PC, Mobile, and Gamepad)
		local connections = self.connections
		if connections.toolActivated then connections.toolActivated:Disconnect() end
		connections.toolActivated = rod.Activated:Connect(handleCastStart)

		if connections.toolDeactivated then connections.toolDeactivated:Disconnect() end
		connections.toolDeactivated = rod.Deactivated:Connect(handleCastRelease)

		if self.isMobile then
			self.GUIManager:ShowMobileButton(true)
			self:UpdateMobileButtonText()

			if connections.mobileButton then connections.mobileButton:Disconnect() end
			connections.mobileButton = self.GUIManager:GetElement("tapMobileButton").MouseButton1Click:Connect(function()
				if not RodManager.isEquipped or gameState.isAutoFishing then return end

				if self.MinigameSystem:IsActive() then
					task.spawn(function() self.MinigameSystem:HandleClick(self.SoundManager, self.GUIManager) end)
				elseif self.PowerBarSystem:IsCharging() then
					handleCastRelease()
				elseif gameState.canCast and not gameState.casted and not gameState.fishingInProgress and not gameState.castingCooldown then
					handleCastStart()
				end
			end)
		else
			local UIS = self.UIS
			if connections.inputBegan then connections.inputBegan:Disconnect() end
			connections.inputBegan = UIS.InputBegan:Connect(function(input, processed)
				if processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				handleCastStart()
			end)

			if connections.inputEnded then connections.inputEnded:Disconnect() end
			connections.inputEnded = UIS.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					handleCastRelease()
				end
			end)
		end
	end

	function Controller:OnRodUnequipped()
		local gameState = self.gameState
		local PowerBarSystem, MinigameSystem, GUIManager = self.PowerBarSystem, self.MinigameSystem, self.GUIManager

		if PowerBarSystem and PowerBarSystem:IsCharging() then PowerBarSystem:StopCharging() end
		if MinigameSystem and MinigameSystem:IsActive() then
			MinigameSystem:Stop()
			GUIManager:SlideFishingFrameOut(nil)
		end

		if gameState.isAutoFishing then
			gameState.isAutoFishing = false
			GUIManager:UpdateAutoButton(false)
			self:StopAutoFishLoop()
		end
		GUIManager:ShowAutoButton(false)

		self.AnimationController:Stop()
		self:StopSpeedMonitoring()
		PowerBarSystem:Reset()
		GUIManager:ShowMobileButton(false)

		for k, conn in self.connections do
			if conn then conn:Disconnect(); self.connections[k] = nil end
		end

		-- Pastikan kamera kembali normal jika unequip
		local camera = self.camera
		if camera and camera.Parent and camera.CameraType ~= Enum.CameraType.Custom then
			camera.CameraType = Enum.CameraType.Custom
		end

		if gameState.sinker then gameState.sinker:Destroy(); gameState.sinker = nil end
		if self.RodManager.currentRod and self.RodManager.currentRod:FindFirstChild("Part") then
			local line = self.RodManager.currentRod.Part:FindFirstChild("Line")
			if line then line:Destroy() end
		end
		if gameState.casted or gameState.fishingInProgress then self.NetworkGateway:Request("POST", "/fishing/cleanup", {}) end

		gameState.casted, gameState.fishingInProgress = false, false
		gameState.canCast, gameState.hasLanded = true, false
		gameState.fishingCaught, gameState.castingCooldown = false, false
	end
end

return Module
