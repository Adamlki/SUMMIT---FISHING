-- System by @thehandofvoid
-- Modified by @jay_peaceee
-- ReplicatedStorage/FishingModules/MinigameSystem (FIXED)
-- ✅ Auto mode now requires MORE taps than manual (balanced)
-- ✅ Tap count based on rod quality from config
-- ✅ Better rod = fewer taps needed

local MinigameSystem = {}
local RepStorage = game:GetService("ReplicatedStorage"):WaitForChild("FishingSystem")
local TS = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local FishingConfig = require(RepStorage:WaitForChild("FishingConfig"))
local HudVisibility = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("UI"):WaitForChild("HudVisibility"))


local minigameState = {
	active = false,
	clickCount = 0,
	progress = 0,
	progressPerClick = 0,
	decayRate = 0,
	isAutoMode = false,
	requiredTaps = 15,
	currentRodName = nil
}

-- Properti baru untuk status kamera & Hotbar
local cameraState = {
	originalFieldOfView = 70, 
	originalCameraType = Enum.CameraType.Custom,
	isZoomed = false
}

local gui = nil
local callbacks = {}

--- Fungsi Pengaturan Kamera & Hotbar ---

local function saveCameraState()
	local camera = Workspace.CurrentCamera
	cameraState.originalFieldOfView = camera.FieldOfView
	cameraState.originalCameraType = camera.CameraType
end

-- Diubah: Hanya mengubah FOV, TIDAK mengubah CameraType ke Scriptable
local function applyZoom(targetFOV)
	local camera = Workspace.CurrentCamera

	if not cameraState.isZoomed then
		saveCameraState()
		cameraState.isZoomed = true

		-- Baris di bawah dihapus agar kamera tetap Custom/terkontrol pemain
		-- camera.CameraType = Enum.CameraType.Scriptable 
	end

	-- Gunakan TweenService untuk animasi zoom yang mulus
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local properties = {FieldOfView = targetFOV}

	local tween = TS:Create(camera, tweenInfo, properties)
	tween:Play()
end

local function hideHotbar()
	HudVisibility:SetHotbarDesired(false)
end

local function showHotbar()
	HudVisibility:SetHotbarDesired(true)
end

-- Diubah: TIDAK mengembalikan CameraType ke Custom/Custom karena tidak diubah
local function restoreCamera()
	if not cameraState.isZoomed then return end 

	local camera = Workspace.CurrentCamera

	-- Gunakan TweenService untuk animasi kembali yang mulus
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local properties = {FieldOfView = cameraState.originalFieldOfView}

	local tween = TS:Create(camera, tweenInfo, properties)
	tween:Play()

	tween.Completed:Connect(function()
		-- Baris di bawah dihapus agar kamera tetap Custom/terkontrol pemain
		-- camera.CameraType = cameraState.originalCameraType 
		cameraState.isZoomed = false

		-- Munculkan kembali Hotbar
		showHotbar() 
	end)
end

--- Fungsi Modul Utama ---

function MinigameSystem:Initialize(guiElements)
	gui = guiElements
end

function MinigameSystem:SetCallbacks(onComplete, onFail)
	-- Wrap callbacks agar restoreCamera dipanggil saat selesai/gagal
	callbacks.onComplete = function()
		restoreCamera() 
		if onComplete then onComplete() end
		-- Leaderboard & Fish Index ditangani server (RecordFishCatch) saat ikan diberikan
	end
	callbacks.onFail = function()
		restoreCamera() 
		if onFail then onFail() end
	end
end

function MinigameSystem:UpdateBar()
	minigameState.progress = math.clamp(minigameState.progress, 0, 1)

	gui.fishingFillFrame.Size = UDim2.new(minigameState.progress, 0, 1, 0)

	local color
	if minigameState.progress >= 1.0 then
		color = Color3.fromRGB(0, 255, 0)
	elseif minigameState.progress < 0.3 then
		color = Color3.fromRGB(255, 100, 100)
	elseif minigameState.progress < 0.7 then
		color = Color3.fromRGB(255, 200, 100)
	else
		color = Color3.fromRGB(100, 255, 100)
	end
	gui.fishingFillFrame.BackgroundColor3 = color
end

function MinigameSystem:HandleClick(SoundManager, GUIManager)
	if not minigameState.active then return end
	if minigameState.isAutoMode then return end

	minigameState.clickCount += 1
	minigameState.progress = math.min(minigameState.progress + minigameState.progressPerClick, 1.0)
	self:UpdateBar()

	if gui.infoText then
		gui.infoText.Text = string.format("Klik! (%d/%d)", minigameState.clickCount, minigameState.requiredTaps)
	end

	GUIManager:AnimateImageTap()
	SoundManager:Play("Tap", 0.4)

	if minigameState.progress >= 1.0 then
		minigameState.active = false
		if callbacks.onComplete then
			callbacks.onComplete()
		end
		return
	end

	-- Visual feedback
	task.spawn(function()
		local tween = TS:Create(
			gui.fishingFillFrame,
			TweenInfo.new(FishingConfig.MinigameSettings.clickFeedbackDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = Color3.fromRGB(255, 255, 255)}
		)
		tween:Play()

		task.wait(0.05)
		local tween2 = TS:Create(
			gui.fishingFillFrame,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{BackgroundColor3 = Color3.fromRGB(100, 255, 100)}
		)
		tween2:Play()

		tween2.Completed:Connect(function()
			if minigameState.active then
				self:UpdateBar()
			end
		end)
	end)
end

-- MAIN START FUNCTION (Kamera zoom dan sembunyikan Hotbar)
function MinigameSystem:Start(isAuto, rodName)
	-- 1. Sembunyikan Hotbar
	hideHotbar()

	-- 2. Terapkan Zoom Kamera (20 derajat lebih kecil dari FOV saat ini)
	local targetFOV = (Workspace.CurrentCamera.FieldOfView - 20)
	applyZoom(targetFOV) 

	minigameState.active = true
	minigameState.clickCount = 0
	minigameState.isAutoMode = isAuto or false
	minigameState.currentRodName = rodName

	minigameState.requiredTaps = FishingConfig.GetRequiredTaps(rodName, isAuto)

	minigameState.progressPerClick = 1.0 / minigameState.requiredTaps

	if gui.infoText then
		if isAuto then
			gui.infoText.Text = string.format("Otomatis... (0/%d)", minigameState.requiredTaps)
		else
			gui.infoText.Text = string.format("Klik! (0/%d)", minigameState.requiredTaps)
		end
	end

	local settings = FishingConfig.MinigameSettings
	minigameState.progress = settings.startingProgress
	minigameState.decayRate = math.random(settings.decayMin, settings.decayMax) / 1000

	gui.fishingFillFrame.Size = UDim2.new(settings.startingProgress, 0, 1, 0)

	-- == AUTO MODE: Simulate realistic clicks ==
	if isAuto then
		task.spawn(function()
			-- Auto-click loop: Clicks at human-like intervals
			while minigameState.active and minigameState.progress < 1.0 do
				local clickDelay = math.random(100, 180) / 1000
				task.wait(clickDelay)

				if not minigameState.active then break end

				-- Simulate a click
				minigameState.clickCount += 1
				minigameState.progress = math.min(minigameState.progress + minigameState.progressPerClick, 1.0)
				self:UpdateBar()

				-- Update text
				if gui.infoText then
					gui.infoText.Text = string.format("Otomatis (%d/%d)", minigameState.clickCount, minigameState.requiredTaps)
				end

				-- Check if completed
				if minigameState.progress >= 1.0 then
					minigameState.active = false
					if callbacks.onComplete then
						callbacks.onComplete()
					end
					break
				end
			end
		end)

		-- Still run decay in background
		local minigameStartTime = tick()
		local lastUpdateTime = tick()

		task.spawn(function()
			while minigameState.active and (tick() - minigameStartTime) < settings.fishingTime do
				local currentTime = tick()
				local deltaTime = currentTime - lastUpdateTime
				lastUpdateTime = currentTime

				-- Apply decay 
				minigameState.progress -= (minigameState.decayRate * deltaTime * settings.decayMultiplier)
				self:UpdateBar()

				-- Check for failure
				if minigameState.progress <= 0 then
					minigameState.active = false
					if callbacks.onFail then
						callbacks.onFail()
					end
					break
				end

				task.wait(0.02)
			end

			-- Timeout check
			if minigameState.active then
				minigameState.active = false
				if callbacks.onFail then
					callbacks.onFail()
				end
			end
		end)

		return
	end

	-- == MANUAL MODE: Normal player clicking ==
	local minigameStartTime = tick()
	local lastUpdateTime = tick()

	task.spawn(function()
		while minigameState.active and (tick() - minigameStartTime) < settings.fishingTime do
			local currentTime = tick()
			local deltaTime = currentTime - lastUpdateTime
			lastUpdateTime = currentTime

			minigameState.progress -= (minigameState.decayRate * deltaTime * settings.decayMultiplier)
			self:UpdateBar()

			if minigameState.progress >= 1.0 then
				minigameState.active = false
				if callbacks.onComplete then
					callbacks.onComplete()
				end
				break
			end

			if minigameState.progress <= 0 then
				minigameState.active = false
				if callbacks.onFail then
					callbacks.onFail()
				end
				break
			end

			task.wait(0.02)
		end

		if minigameState.active then
			minigameState.active = false
			if callbacks.onFail then
				callbacks.onFail()
			end
		end
	end)
end

function MinigameSystem:Stop()
	minigameState.active = false
	minigameState.isAutoMode = false
	-- Tidak memanggil restoreCamera di sini (biarkan onComplete/onFail yang mengurus)
end

function MinigameSystem:ForceStop()
	minigameState.active = false
	minigameState.clickCount = 0
	minigameState.progress = 0
	minigameState.isAutoMode = false
	restoreCamera() -- Kembalikan kamera dan Hotbar
end

function MinigameSystem:IsActive()
	return minigameState.active
end

return MinigameSystem