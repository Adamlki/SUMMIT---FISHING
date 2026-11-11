-- System by @thehandofvoid
-- Modified by @jay_peaceee
-- StarterPlayer/StarterPlayerScripts/FishingSystem
-- ✅ NOW WITH GLOBAL CHAT NOTIFICATIONS FOR RARE FISH

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RepStorage = ReplicatedStorage:WaitForChild("FishingSystem")
local CS = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")

-- 🎣 PENAMBAHAN UNTUK ANIMASI IKAN & CAMERA SHAKE
local TweenService = game:GetService("TweenService")

local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))

local player = Players.LocalPlayer
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- ===== MODULES =====
local modulesFolder = RepStorage:WaitForChild("FishingModules")
local FishingConfig = require(RepStorage:WaitForChild("FishingConfig"))
local SoundManager = require(modulesFolder:WaitForChild("SoundManager"))
local GUIManager = require(modulesFolder:WaitForChild("GUIManager"))
local AnimationController = require(modulesFolder:WaitForChild("AnimationController"))
local PowerBarSystem = require(modulesFolder:WaitForChild("PowerBarSystem"))
local MinigameSystem = require(modulesFolder:WaitForChild("MinigameSystem"))
local CastingSystem = require(modulesFolder:WaitForChild("CastingSystem"))
local RodVFXManager = require(modulesFolder:WaitForChild("RodVFXManager"))

-- ===== REMOTE EVENTS =====
local castReplicationEvent = RepStorage:WaitForChild("CastReplication")
local cleanupCastEvent = RepStorage:WaitForChild("CleanupCast")
local showNotificationEvent = RepStorage:FindFirstChild("ShowNotification")

local syncSessionRemote = RepStorage:WaitForChild("SyncSessionState")
local resumeFishingRemote = RepStorage:WaitForChild("ResumeFishingSession")

-- ===== STATE =====
local gameState = {
	isLocked = false, casted = false, sinker = nil, splash = nil, savedHookPosition = nil,
	waitTime = math.random(3, 6), fishingCaught = false, hasLanded = false,
	fishingInProgress = false, canCast = true, castingCooldown = false,
	cooldownTime = 0.3, activeFishingTask = nil,
	isAutoFishing = false, lastRollId = nil
}

local function requestServerFish(powerPercent)
	-- Promise:await() returns (success, value); Gateway still resolves failures as response tables.
	local callOk, awaitedOk, response = pcall(function()
		return NetworkGateway:Request("POST", "/fishing/roll", { Power = powerPercent }):await()
	end)

	if not callOk or not awaitedOk or type(response) ~= "table" then
		GUIManager:ShowNotification("Gagal menghubungi server untuk roll ikan.", 3, Color3.fromRGB(255, 100, 100))
		return nil
	end

	if response.Success and type(response.Data) == "table" then
		return response.Data
	end

	GUIManager:ShowNotification(response.Message or "Roll ikan ditolak server.", 3, Color3.fromRGB(255, 100, 100))
	return nil
end


local speedState = {
	originalWalkSpeed = 16, fishingWalkSpeed = 8, speedModified = false
}

local connections = {}
local otherPlayersHooks = {}
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- ===== FORWARD DECLARATIONS =====
local updateMobileButtonText, onRodEquipped, onRodUnequipped, performCast

-- ===== ROD MANAGER =====
local RodManager = {currentRod = nil, isEquipped = false}

function RodManager:IsValidRod()
	return self.currentRod and self.currentRod.Parent and self.isEquipped
		and player.Character and self.currentRod:IsDescendantOf(player.Character)
		and self.currentRod:FindFirstChild("Part")
end

function RodManager:CleanupFishing()
	if not (gameState.casted or gameState.fishingInProgress) then return end

	gameState.casted, gameState.fishingInProgress = false, false
	gameState.canCast, gameState.castingCooldown = true, false
	gameState.activeFishingTask = nil

	if gameState.splash then gameState.splash:Destroy(); gameState.splash = nil end
	if gameState.sinker then gameState.sinker:Destroy(); gameState.sinker = nil end
	if MinigameSystem and MinigameSystem:IsActive() then MinigameSystem:ForceStop() end
	if PowerBarSystem and PowerBarSystem:IsCharging() then PowerBarSystem:StopCharging() end

	cleanupCastEvent:FireServer()
	if GUIManager and GUIManager.SlideFishingFrameOut then
		GUIManager:SlideFishingFrameOut(nil)
	end
	updateMobileButtonText()
end

function RodManager:OnRodEquipped(rod)
	if not rod or not rod.Parent then return end
	if self.currentRod and self.currentRod ~= rod then self:OnRodUnequipped() end

	self.currentRod, self.isEquipped = rod, true
	onRodEquipped(rod)
end

function RodManager:OnRodUnequipped()
	if not self.currentRod then return end
	self:CleanupFishing()
	self.currentRod, self.isEquipped = nil, false
	onRodUnequipped()
end

function RodManager:CheckEquippedRod(char)
	if not char then return end

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

-- ===== HELPERS =====
local function getCurrentRodName()
	return RodManager.currentRod and RodManager.currentRod.Name
end

local function setSpeed(isFishing)
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

local function startSpeedMonitoring()
	pcall(function()
		syncSessionRemote:FireServer({
			Action = "Fishing",
			RodName = getCurrentRodName() or "Basic Rod",
			IsAutoFishing = gameState.isAutoFishing == true,
		})
	end)
	if connections.speedCheck then connections.speedCheck:Disconnect() end
	connections.speedCheck = RunService.Heartbeat:Connect(function()
		local isFishing = gameState.casted or gameState.fishingInProgress
			or MinigameSystem:IsActive() or PowerBarSystem:IsCharging()
			or gameState.isLocked -- 🆕 Tambahkan isLocked ke kondisi isFishing
		setSpeed(isFishing and RodManager.isEquipped)
	end)
end
local function stopSpeedMonitoring()
	pcall(function()
		syncSessionRemote:FireServer({
			Action = "Idle",
		})
	end)
	if connections.speedCheck then
		connections.speedCheck:Disconnect()
		connections.speedCheck = nil
	end
	setSpeed(false)
end

local function startCastingCooldown()
	gameState.castingCooldown, gameState.canCast = true, false
	updateMobileButtonText()
	task.delay(gameState.cooldownTime, function()
		gameState.castingCooldown, gameState.canCast = false, true
		updateMobileButtonText()
	end)
end

function updateMobileButtonText()
	if not GUIManager then return end
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

local function selectFish()
	local rodName = getCurrentRodName()
	if not rodName then
		warn("⚠ No rod equipped!")
		return nil
	end

	local powerPercent = PowerBarSystem:GetCurrentPower() / 100

	if gameState.isAutoFishing then
		powerPercent = 1.0
	end

	local serverResult = requestServerFish(powerPercent)
	if not serverResult then
		gameState.lastRollId = nil
		return nil
	end

	gameState.lastRollId = serverResult.RollId
	return { name = serverResult.Name, rarity = serverResult.Rarity }, serverResult.Weight
end

-- ===== AUTO-FISHING LOOP =====
local autoFishConnection = nil

local function autoCast()
	if not RodManager:IsValidRod() or gameState.casted or not character or not gameState.canCast or gameState.castingCooldown then return end

	gameState.canCast = false

	local power = math.random(90, 100)

	AnimationController:Play("WaitingAnimation", 0.1)
	SoundManager:Play("Cast", 0.5)

	task.wait(0.4)

	performCast(power)
end

local function startAutoFishLoop()
	if autoFishConnection then autoFishConnection:Disconnect() end

	autoFishConnection = RunService.Heartbeat:Connect(function()
		if gameState.isAutoFishing and RodManager.isEquipped and gameState.canCast and not gameState.casted and not gameState.fishingInProgress and not gameState.castingCooldown then
			autoCast()
		end
	end)
end

local function stopAutoFishLoop()
	if autoFishConnection then
		autoFishConnection:Disconnect()
		autoFishConnection = nil
	end
end

-- ===== INITIALIZATION =====
local function initializeSystems()
	SoundManager:Initialize()
	GUIManager:Initialize(player)

	local autoButton = GUIManager:GetElement("autoButton")
	if autoButton then
		autoButton.MouseButton1Click:Connect(function()
			gameState.isAutoFishing = not gameState.isAutoFishing
			GUIManager:UpdateAutoButton(gameState.isAutoFishing)

			if gameState.isAutoFishing then
				startAutoFishLoop()
				GUIManager:ShowNotification("Otomatis Menyala", 3, Color3.fromRGB(100, 255, 100))
				if RodManager.isEquipped and gameState.canCast and not gameState.casted and not gameState.fishingInProgress and not gameState.castingCooldown then
					autoCast()
				end
			else
				stopAutoFishLoop()
				GUIManager:ShowNotification("Otomatis Mati", 3, Color3.fromRGB(255, 100, 100))
			end
		end)
	end

	AnimationController:Initialize(humanoid)
	PowerBarSystem:Initialize({
		barFrame = GUIManager:GetElement("barFrame"),
		fillFrame = GUIManager:GetElement("fillFrame"),
		luckMultiText = GUIManager:GetElement("luckMultiText")
	})
	MinigameSystem:Initialize({
		fishingFillFrame = GUIManager:GetElement("fishingFillFrame"),
		infoText = GUIManager:GetElement("infoText")
	}, nil)

	speedState.originalWalkSpeed = humanoid.WalkSpeed
end

initializeSystems()

-- 🎣 FUNGSI BARU: CAMERA SHAKE (DIPERBAIKI DARI VERSI SEBELUMNYA)
local activeCameraShake = nil

local function startCameraShakeHorizontal(duration)
	-- Pastikan kamera sudah siap
	local camera = workspace.CurrentCamera

	if not camera then
		workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
		camera = workspace.CurrentCamera
	end

	if not camera or camera.CameraSubject == nil then return end

	local startTime = tick()
	local shakeConnection;

	if activeCameraShake then activeCameraShake:Disconnect() end
	shakeConnection = RunService.RenderStepped:Connect(function()
		if not camera or not camera.Parent then
			if shakeConnection then shakeConnection:Disconnect() end
			return
		end

		local elapsed = tick() - startTime
		local remaining = duration - elapsed

		if remaining <= 0 then
			-- Hentikan getaran setelah durasi selesai
			if shakeConnection then shakeConnection:Disconnect() end
			return
		end

		-- Ambil CFrame kamera saat ini (agar kamera tetap mengikuti pemain)
		local currentCFrame = camera.CFrame

		-- Mengatur kekuatan getaran (Shake Strength)
		-- Kekuatan akan berkurang dari 100% menjadi 0% seiring waktu
		local normalizedTime = remaining / duration
		local baseStrength = 5 -- Kekuatan maksimum awal
		local shakeStrength = baseStrength * normalizedTime

		-- Menghasilkan pergeseran CFrame acak HANYA pada sumbu X (Kanan-Kiri)
		-- math.random() * 2 - 1 menghasilkan angka antara -1 (Kiri) dan 1 (Kanan)
		local offsetX = (math.random() * 2 - 1) * shakeStrength * 0.3 -- Dikalikan 0.3 agar lebih terasa

		-- Offset Y dan Z dibuat 0 atau sangat kecil agar getaran fokus ke horizontal
		local offsetY = 0.01 * shakeStrength -- Sedikit offset vertikal mungkin diperlukan untuk "feel"
		local offsetZ = 0

		-- Terapkan offset acak ke CFrame kamera saat ini
		camera.CFrame = currentCFrame * CFrame.new(offsetX, offsetY, offsetZ)
	end)
	activeCameraShake = shakeConnection
end

-- 🆕 FUNGSI BARU: SEQUENCE KAMERA JATUH IKAN
-- 🆕 FUNGSI: SEQUENCE KAMERA JATUH IKAN (FIXED VIEW KE ATAS)
local cameraSequenceToken = 0

local function fishDropCameraSequence(fishPart, duration)
	-- Pastikan kamera sudah siap
	if not camera or not fishPart or not fishPart.Parent then return end

	cameraSequenceToken += 1
	local myToken = cameraSequenceToken

	local initialCFrame = camera.CFrame -- Simpan posisi kamera awal

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- 1. Set CameraType ke Scriptable
	camera.CameraType = Enum.CameraType.Scriptable

	-- Menghitung Posisi Kamera Fixed:
	-- Kamera diposisikan DEKAT pemain (misal, 5 stud di depan pemain)
	-- dan DIHADAPKAN LURUS KE ATAS menuju titik 300 stud.

	local distanceInFront = 5
	local fixedPosition = hrp.CFrame.Position + hrp.CFrame.LookVector * distanceInFront + Vector3.new(0, 5, 0) -- 5 stud di depan, 5 stud di atas tanah

	-- CFrame.lookAt(posisi_kamera, target_ikan_awal)
	-- Target awal ikan berada 300 stud di atas, 5 stud di depan pemain (dari fungsi showFishBouncingDropAnimation)
	local targetPosition = hrp.CFrame.Position + hrp.CFrame.LookVector * (-distanceInFront) + Vector3.new(0, 300, 0)

	local fixedCFrame = CFrame.lookAt(fixedPosition, targetPosition)

	-- Atur posisi kamera sekali saja
	camera.CFrame = fixedCFrame


	-- 2. Tunggu durasi yang diminta (8 detik)
	task.delay(duration, function()
		if myToken ~= cameraSequenceToken then return end
		if not camera or not camera.Parent then return end

		-- 3. Kembalikan CameraType ke Custom dengan transisi halus
		local transitionTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		if camera.CameraType == Enum.CameraType.Scriptable then
			local transitionTween = TweenService:Create(camera, transitionTweenInfo, {CFrame = initialCFrame})
			transitionTween:Play()
			transitionTween.Completed:Wait()
		end

		camera.CameraType = Enum.CameraType.Custom
	end)
end

local function getFishModelTemplate(fishName)
	local FishModelFolder = RepStorage:FindFirstChild("Assets") and RepStorage.Assets:FindFirstChild("FishModel")
	local template = FishModelFolder and FishModelFolder:FindFirstChild(fishName)
	if template and template:IsA("Model") then
		return template
	end

	-- Auto-fallback: extract model on the fly from Assets.Fish Tool
	local fishToolsFolder = RepStorage:FindFirstChild("Assets") and RepStorage.Assets:FindFirstChild("Fish")
	local tool = fishToolsFolder and fishToolsFolder:FindFirstChild(fishName)
	if tool and tool:IsA("Tool") then
		local fallback = Instance.new("Model")
		fallback.Name = tool.Name
		local primary = nil
		for _, c in ipairs(tool:GetChildren()) do
			if c:IsA("BasePart") then
				local cp = c:Clone()
				cp.CanCollide = false
				cp.Anchored = false
				cp.Parent = fallback
				if c.Name == "Handle" or c.Name == "MainBody" then
					primary = cp
				end
			end
		end
		fallback.PrimaryPart = primary or fallback:FindFirstChildWhichIsA("BasePart")
		return fallback
	end
	return nil
end

local function showFishBouncingDropAnimation(selectedFish)
	local fishModelName = selectedFish.name
	local fishTemplate = getFishModelTemplate(fishModelName)

	if not fishTemplate then
		warn("⚠ Model ikan tidak ditemukan untuk: " .. fishModelName)
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Kloning model dan setup dasar
	local fishClone = fishTemplate:Clone()
	fishClone.Parent = workspace

	local primaryPart = fishClone.PrimaryPart or fishClone:FindFirstChildOfClass("BasePart")
	if not primaryPart then
		warn("Model ikan tidak memiliki PrimaryPart yang ditetapkan.")
		fishClone:Destroy()
		return
	end

	-- 🔥 PERBAIKAN STUCK: Pastikan SEMUA bagian Unanchored agar model dapat digerakkan oleh Tween
	for _, part in fishClone:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			-- ⭐ SET SEMUA BAGIAN KE UNANCHORED = false
			part.Anchored = false
		end
	end

	-- Parameter Animasi
	local TweenService = game:GetService("TweenService")
	local horizontalDistance = 5--Jarak di depan pemain

	-- 🔥 PERUBAHAN UTAMA: DURASI JADI 15.0 DETIK
	local startHeight = 300 -- Ketinggian Awal Jatuh: (300 STUD)
	local groundHeight = 0.5 -- Ketinggian 'Tanah' (1.5 STUD DARI BAWAH)

	local dropDuration = 20.0 -- ⏳ DURASI JATUH UTAMA (Slow-Mo 15.0 DETIK)
	local durasicamera = 2.0

	-- CFrame Awal (Start): Di udara
	local startCFrame = hrp.CFrame * CFrame.new(0, startHeight, -horizontalDistance) * CFrame.Angles(math.rad(-60), math.rad(45), math.rad(15))

	-- CFrame Tengah (Ground): Posisi kontak pertama (Posisi akhir)
	local groundCFrame = hrp.CFrame * CFrame.new(0, groundHeight, -horizontalDistance) * CFrame.Angles(0, 0, 0)

	-- Mengatur posisi awal menggunakan SetPrimaryPartCFrame()
	fishClone:SetPrimaryPartCFrame(startCFrame)

	-- PANGGIL FUNGSI KAMERA SEBELUM TWEEN JATUH DIMULAI
	-- Kamera juga akan berjalan selama 15.0 detik
	fishDropCameraSequence(primaryPart, durasicamera)

	local dropTweenInfo = TweenInfo.new(
		dropDuration,
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.In
	)

	local dropTween = TweenService:Create(primaryPart, dropTweenInfo, {
		CFrame = groundCFrame,
		Rotation = Vector3.new(0, 360 * 2, 0) -- Rotasi 720 derajat selama 15 detik
	})

	-- Jalankan Animasi
	dropTween:Play()

	-- 🔥 PENTING: Anchor kembali PrimaryPart SETELAH tween selesai
	dropTween.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed then
			primaryPart.Anchored = true
		end
	end)


	-- Ikan akan hilang setelah semua animasi selesai
	Debris:AddItem(fishClone, dropDuration + 1.0)
end
-- 🎣 AKHIR FUNGSI CAMERA SHAKE

-- 🎣 PENAMBAHAN UNTUK ANIMASI IKAN: Fungsi untuk menampilkan model ikan
local function showFishCatchAnimation(selectedFish)
	local fishModelName = selectedFish.name
	local fishTemplate = getFishModelTemplate(fishModelName)

	if not fishTemplate then
		warn("⚠ Model ikan tidak ditemukan untuk: " .. fishModelName)
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local fishClone = fishTemplate:Clone()
	fishClone.Parent = workspace

	local primaryPart = fishClone.PrimaryPart or fishClone:FindFirstChildOfClass("BasePart")
	if not primaryPart then 
		warn("Model ikan tidak memiliki PrimaryPart yang ditetapkan.")
		fishClone:Destroy()
		return
	end

	-- Setup Awal
	primaryPart.Anchored = true

	-- Jarak di depan dan belakang pemain
	local distance = 10
	-- Ketinggian lompatan
	local height = 10
	-- Durasi total animasi melintas
	local duration = 0.8 

	-- CFrame Awal: DEPAN PEMAIN (x=0, y=1.5, z=-distance). Diputar menghadap pemain (180 derajat).
	local startCFrame = hrp.CFrame * CFrame.new(0, 1.5, -distance) * CFrame.Angles(0, math.pi, 0)

	-- CFrame Tengah (Puncak Lompatan): DI ATAS PEMAIN (x=0, y=1.5+height, z=0). Diputar menghadap depan (90 derajat).
	local peakCFrame = hrp.CFrame * CFrame.new(0, 1.5 + height, 0) * CFrame.Angles(0, math.pi / 2, 0) 

	-- CFrame Akhir: BELAKANG PEMAIN (x=0, y=1.5, z=distance). Diputar menghadap belakang (0 derajat).
	local endCFrame = hrp.CFrame * CFrame.new(0, 1.5, distance) * CFrame.Angles(0, 0, 0)

	fishClone:SetPrimaryPartCFrame(startCFrame)

	-- 1. TWEEN MELOMPAT KE ATAS (DEPAN -> ATAS)
	local tweenInfo1 = TweenInfo.new(
		duration / 2, 
		Enum.EasingStyle.Quad, 
		Enum.EasingDirection.Out
	)

	-- Tween 1 bergerak dari Depan (startCFrame) ke Puncak (peakCFrame)
	local tween1 = TweenService:Create(primaryPart, tweenInfo1, {CFrame = peakCFrame})

	-- 2. TWEEN TURUN KE BELAKANG (ATAS -> BELAKANG)
	local tweenInfo2 = TweenInfo.new(
		duration / 2, 
		Enum.EasingStyle.Quad, 
		Enum.EasingDirection.In
	)

	-- Tween 2 bergerak dari Puncak (peakCFrame) ke Belakang (endCFrame)
	local tween2 = TweenService:Create(primaryPart, tweenInfo2, {CFrame = endCFrame})

	-- Jalankan Tween secara berurutan
	tween1:Play()

	tween1.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed then
			tween2:Play()
		end
	end)

	-- Hancurkan ikan setelah durasi total
	Debris:AddItem(fishClone, duration + 0.1) 
end
-- 🎣 AKHIR PENAMBAHAN FUNGSI

local function startCameraShakeHorizontal1(duration, strengthOverride)
	-- Pastikan kamera sudah siap
	local camera = workspace.CurrentCamera

	if not camera then
		workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
		camera = workspace.CurrentCamera
	end

	if not camera or camera.CameraSubject == nil then return end

	local startTime = tick()
	local shakeConnection;

	-- 🔥 PERUBAHAN: Tentukan Kekuatan Dasar. Gunakan override, jika tidak ada, pakai 15 (SANGAT GANAS)
	local baseStrength = strengthOverride or 15 

	if activeCameraShake then activeCameraShake:Disconnect() end
	shakeConnection = RunService.RenderStepped:Connect(function()
		if not camera or not camera.Parent then
			if shakeConnection then shakeConnection:Disconnect() end
			return
		end

		-- Hentikan koneksi shake yang mungkin sedang berjalan sebelumnya (Penting untuk mencegah double-shake)
		if shakeConnection and not shakeConnection.Connected then return end 

		local elapsed = tick() - startTime
		local remaining = duration - elapsed

		if remaining <= 0 then
			-- Hentikan getaran setelah durasi selesai
			if shakeConnection then shakeConnection:Disconnect() end
			return
		end

		-- Ambil CFrame kamera saat ini (agar kamera tetap mengikuti pemain)
		local currentCFrame = camera.CFrame

		-- Mengatur kekuatan getaran (Shake Strength)
		-- Kekuatan akan berkurang dari 100% menjadi 0% seiring waktu
		local normalizedTime = remaining / duration

		-- 🔥 Menggunakan baseStrength baru (15) untuk meningkatkan amplitudo
		local shakeStrength = baseStrength * normalizedTime 

		-- Menghasilkan pergeseran CFrame acak HANYA pada sumbu X (Kanan-Kiri)
		-- math.random() * 2 - 1 menghasilkan angka antara -1 (Kiri) dan 1 (Kanan)
		local offsetX = (math.random() * 2 - 1) * shakeStrength * 0.3 -- Multiplier 0.3 menjaga frekuensi tetap, tetapi amplitudo mengikuti shakeStrength.

		-- Offset Y dan Z dibuat 0 atau sangat kecil agar getaran fokus ke horizontal
		local offsetY = 0.01 * shakeStrength 
		local offsetZ = 0

		-- Terapkan offset acak ke CFrame kamera saat ini
		camera.CFrame = currentCFrame * CFrame.new(offsetX, offsetY, offsetZ)
	end)
	activeCameraShake = shakeConnection
end

-- =======================================================
-- 🐟 FUNGSI UTAMA showFishCatchNotification
-- Menggunakan GUIManager:ShowFishNotification (3D ViewportFrame)
-- =======================================================
local function showFishCatchNotification(selectedFish, fishWeight)
	if not selectedFish then return end
	local rarityColor = FishingConfig and FishingConfig.GetRarityColor(selectedFish.rarity) or Color3.fromRGB(255, 255, 255)
	local message = string.format("Mendapatkan %s %.1fkg", selectedFish.name, fishWeight or 1)
	if GUIManager and GUIManager.ShowFishNotification then
		GUIManager:ShowFishNotification(message, selectedFish.name, 4, rarityColor)
	elseif GUIManager then
		GUIManager:ShowNotification(message, 4, rarityColor)
	end
end

-- ===== MINIGAME CALLBACKS =====
MinigameSystem:SetCallbacks(
	function() -- Success
		gameState.fishingCaught = true
		updateMobileButtonText()
		if RodManager.isEquipped and RodManager.currentRod then
			AnimationController:TransitionTo("EquippedAnimation", 0.3)
		end

		task.delay(0.3, function()
			local selectedFish, fishWeight = selectFish()

			-- 🔥 GUARD CLAUSE BARU 🔥
			-- Jika penangkapan tidak menghasilkan ikan, jalankan cooldown normal dan keluar.
			if not selectedFish then
				startCastingCooldown()
				return
			end
			-- 🔥 AKHIR GUARD CLAUSE 🔥

			if selectedFish then
				

				-- Daftar raritas yang memicu Lock (Jeda 4 detik, Camera Shake, PartSecret)
				local rarityToLock = {
					["Secret"] = true,
				}

				-- Daftar raritas yang memicu AUTO-STOP
				local rarityToAutoStop = {
					

				}

				-- Daftar raritas yang menggunakan animasi JATUH & MANTUL
				local rarityForBounce = {
					["Mitos"] = true,
					-- ⭐ HANYA SECRET YANG MEMICU JATUH/SLOWMO CAMERA ⭐
					-- Hapus Epic jika Anda tidak ingin Epic jatuh/mantul
				}

				-- 🔥 PERHATIAN:
				-- Pastikan durasi di fungsi showFishBouncingDropAnimation juga diatur ke 7.0 detik
				-- agar animasi dan penguncian kamera (Camera Shake) sinkron.

				-- Tetapkan durasi lock yang konsisten. Saya menggunakan 7.0 detik total sesuai permintaan Anda.
				local lockDuration = 4 -- Durasi Lock, Camera Shake, dan PartSecret
				-- Cek apakah ikan yang didapat memicu Lock
				local requiresLock = rarityToLock[selectedFish.rarity]
				local SLOW_MO_LOCK_DURATION = 2.0 
				local finalLockDuration = 2.0 -- Default: Durasi kunci standar (non-slow-mo)

				-- 🎣 LOGIKA PEMANGGILAN ANIMASI IKAN (PERBAIKAN BUGS)
				if rarityForBounce[selectedFish.rarity] then
					-- Kasus 1: Ikan Slow-Mo (LOCK 7.0 detik)
					showFishBouncingDropAnimation(selectedFish)

					-- 🔥 PERBAIKAN: Gunakan durasi kunci 7.0 detik.
					finalLockDuration = SLOW_MO_LOCK_DURATION 

					-- 1. Terapkan Lock Segera
					gameState.canCast = false
					gameState.castingCooldown = true
					gameState.isLocked = true
					
					updateMobileButtonText()

					-- Panggil EFEK Lock (Camera Shake, Sound, PartSecret) menggunakan 7.0 detik
					startCameraShakeHorizontal(finalLockDuration) 

					-- MUNCULKAN EFEK SUARA DAN PARTSECRET DI SINI (kode Anda yang terpotong)
					-- ...

					-- 2. Aktifkan Kembali Setelah Lock Selesai
					task.delay(finalLockDuration, function()
						-- Logika UNLOCK dilakukan tepat setelah finalLockDuration (7.0 detik)
						
						SoundManager:Play("Success", 0.6)
						pcall(function() RodVFXManager:PlayCatchSuccessVFX(character, getCurrentRodName()) end)
						showFishCatchNotification(selectedFish, fishWeight)

						gameState.canCast = true
						gameState.castingCooldown = false
						gameState.isLocked = false
						updateMobileButtonText()

						-- Cek apakah auto-fishing harus dimatikan (HANYA Mitos/Secret)
						if gameState.isAutoFishing and rarityToAutoStop[selectedFish.rarity] then
							gameState.isAutoFishing = false
							stopAutoFishLoop()
							GUIManager:ShowNotification("Auto-Fishing Mati (Ikan Langka)", 3, Color3.fromRGB(255, 150, 50))
						end

						updateMobileButtonText()

						-- Jika auto-fishing aktif, panggil autoCast
						if gameState.isAutoFishing then
							task.delay(0.5, autoCast)
						end
					end)

				else if rarityToLock[selectedFish.rarity] then
					-- Kasus 2: Ikan Non-Slow-Mo (Melintas)
					


					-- 🆕 LOGIKA PENGUNCIAN MEMANCING (LOCK) HANYA UNTUK RARITAS TINGGI
					if requiresLock then

						-- 1. Terapkan Lock Segera (Menghentikan Semua Casting)
						gameState.canCast = false
						gameState.castingCooldown = true
						gameState.isLocked = true
						updateMobileButtonText()

						-- 🔥 PERBAIKAN: Menggunakan fungsi horizontal yang benar
							startCameraShakeHorizontal(lockDuration)

						-- MENCARI FOLDER ASSETS
						local AssetsFolder = RepStorage:FindFirstChild("Assets")

						-- MUNCULKAN EFEK SUARA BARU
							local SoundFolder = AssetsFolder and AssetsFolder:FindFirstChild("Sound")
							local rareSoundTemplate = SoundFolder and SoundFolder:FindFirstChild("RareCatchSound") -- Digunakan untuk Tahap 2
							local listrikSoundTemplate = SoundFolder and SoundFolder:FindFirstChild("Listrik") -- Digunakan untuk Tahap 1 (Asumsi: 'Listrik' adalah nama template)

							local EffectFolder = AssetsFolder and AssetsFolder:FindFirstChild("Effect")
							local partSecretTemplate = EffectFolder and EffectFolder:FindFirstChild("PartSecret") -- Digunakan untuk Tahap 2
							local partSecretTemplate1 = EffectFolder and EffectFolder:FindFirstChild("PartSecret1") -- Digunakan untuk Tahap 1

							-- 🔥 Durasi Tahap (Perhatikan: lockDuration = 4.0 detik)
							local stageDuration = lockDuration -- 4.0 detik
							local totalLockDuration = lockDuration * 2 -- 8.0 detik

							-- ⭐ FUNGSI PEMBANTU UNTUK MEMPOSISIKAN EFEK (Disederhanakan)
							local function positionEffect(effectClone, template, duration)
								local hrp = character:FindFirstChild("HumanoidRootPart")
								if not hrp then return end

								local distanceInFront = 12
								local distanceRight = 0 
								local heightAboveWater = 1.0 
								local hrpCFrame = hrp.CFrame

								local projectedPosition = (hrpCFrame * CFrame.new(distanceRight, 0, -distanceInFront)).Position
								local finalY = projectedPosition.Y
								local waterY = CastingSystem:GetWaterSurfaceY(projectedPosition.X, projectedPosition.Z)

								if waterY then finalY = waterY + heightAboveWater end
								local finalPosition = Vector3.new(projectedPosition.X, finalY, projectedPosition.Z)

								-- Menggunakan rotasi pemain yang dimodifikasi, kemudian digeser Z 90 derajat lokal
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
								Debris:AddItem(effectClone, duration)
							end

							local hrp1 = character:FindFirstChild("HumanoidRootPart")

							-- ----------------------------------------------------
							-- 🔥 TAHAP 1: PARTSECRET1 + SOUND LISTRIK (0 - 4.0 detik)
							-- ----------------------------------------------------
							if partSecretTemplate1 and (partSecretTemplate1:IsA("BasePart") or partSecretTemplate1:IsA("Model")) then
								if hrp1 then
									-- SOUND LISTRIK
									if listrikSoundTemplate and listrikSoundTemplate:IsA("Sound") then
										local Listrik = listrikSoundTemplate:Clone()
										Listrik.Parent = workspace
										Listrik:Play()
										Debris:AddItem(Listrik, totalLockDuration) -- Sound berjalan total 8.0s
									else
										warn("⚠ Efek Suara Listrik tidak ditemukan!")
									end

									-- EFEK PARTSECRET1
									local effectClone1 = partSecretTemplate1:Clone()
									effectClone1.Parent = workspace

									-- Efek pertama ini akan bertahan selama durasi total (8.0s)
									positionEffect(effectClone1, partSecretTemplate1, totalLockDuration)
								end 
							else
								warn("⚠️ PartSecret1 tidak ditemukan di jalur yang benar.")
							end

							-- ----------------------------------------------------
							-- 🔥 TAHAP 2: PARTSECRET + SOUND RARECATCH (4.0 - 8.0 detik)
							-- ----------------------------------------------------
							task.delay(stageDuration, function()
								-- Pastikan PartSecret yang lama tidak hancur (sesuai permintaan "ditimpah jangan diganti")

								if partSecretTemplate and (partSecretTemplate:IsA("BasePart") or partSecretTemplate:IsA("Model")) then
									local hrp = character:FindFirstChild("HumanoidRootPart")
									startCameraShakeHorizontal1(lockDuration)
									if hrp then
										-- SOUND RARECATCH (Dimulai pada 4.0 detik, berjalan 4.0 detik)
										if rareSoundTemplate and rareSoundTemplate:IsA("Sound") then
											local RareCatch = rareSoundTemplate:Clone()
											RareCatch.Parent = workspace
											RareCatch:Play()
											Debris:AddItem(RareCatch, stageDuration) 
										else
											warn("⚠ Efek Suara RareCatchSound tidak ditemukan!")
										end

										-- EFEK PARTSECRET
										local effectClone = partSecretTemplate:Clone()
										effectClone.Parent = workspace

										-- Efek kedua ini akan bertahan selama durasi stage (4.0s)
										positionEffect(effectClone, partSecretTemplate, stageDuration)
									end -- End if hrp
								else
									warn("⚠️ PartSecret tidak ditemukan di jalur yang benar.")
								end
							end)


							-- ----------------------------------------------------
							-- 2. LOGIKA UNLOCK/COOLDOWN TOTAL (8.0 detik)
							-- ----------------------------------------------------
							task.delay(totalLockDuration, function()
								-- 🔥 Perbaikan: Tambahkan jeda singkat untuk memastikan semua efek dan animasi selesai.
								task.wait(0.1)

								SoundManager:Play("Success", 0.6)
								showFishCatchNotification(selectedFish, fishWeight)

								gameState.canCast = true
								gameState.castingCooldown = false
								gameState.isLocked = false

								-- Cek apakah auto-fishing harus dimatikan (HANYA Mitos/Secret)
								if gameState.isAutoFishing and rarityToAutoStop[selectedFish.rarity] then
									gameState.isAutoFishing = false
									stopAutoFishLoop()
									GUIManager:ShowNotification("Auto-Fishing Mati (Ikan Langka)", 3, Color3.fromRGB(255, 150, 50))
								end

								updateMobileButtonText()

								-- 🔥 Jika auto-fishing aktif, panggil autoCast di sini (di luar loop Heartbeat)
								if gameState.isAutoFishing then
									task.delay(0.5, autoCast) -- Delay sedikit untuk memastikan loop Heartbeat tidak race condition
								end
							end)

					else -- Jika tidak ada Lock (Common/Rare)
						startCastingCooldown()
					end
					
					else
						
						showFishCatchAnimation(selectedFish)
						
						SoundManager:Play("Success", 0.6)
						showFishCatchNotification(selectedFish, fishWeight)
						
						
						gameState.canCast = true
						gameState.castingCooldown = false

						-- Cek apakah auto-fishing harus dimatikan (HANYA Mitos/Secret)
						if gameState.isAutoFishing and rarityToAutoStop[selectedFish.rarity] then
							gameState.isAutoFishing = false
							stopAutoFishLoop()
							GUIManager:ShowNotification("Auto-Fishing Mati (Ikan Langka)", 3, Color3.fromRGB(255, 150, 50))
						end

						updateMobileButtonText()

						-- 🔥 Jika auto-fishing aktif, panggil autoCast di sini (di luar loop Heartbeat)
						if gameState.isAutoFishing then
							task.delay(0.5, autoCast) -- Delay sedikit untuk memastikan loop Heartbeat tidak race condition
						end
					end

				end
				-- 🎣 AKHIR LOGIKA PEMANGGILAN ANIMASI IKAN


				-- ... (lanjutan kode)
				-- 🆕 AKHIR LOGIKA PENGUNCIAN MEMANCING

				-- Send fish to server
				NetworkGateway:Request("POST", "/fishing/claim", {
					RollId = gameState.lastRollId
				})
				gameState.lastRollId = nil

				gameState.savedHookPosition = nil
			end

		end)

	end,
	function() -- Fail
		gameState.savedHookPosition = nil
		if RodManager.isEquipped and RodManager.currentRod then
			AnimationController:TransitionTo("EquippedAnimation", 0.3)
		end
		GUIManager:ShowNotification("Ikan itu lolos!", 2, Color3.fromRGB(255, 100, 100))
		MinigameSystem:Stop()
		startCastingCooldown()
	end
)


-- ===== HOTKEY BLOCKER =====
UIS.InputBegan:Connect(function(input, processed)
	if processed or not MinigameSystem:IsActive() then return end
	local blocked = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three,
		Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six,
		Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine, Enum.KeyCode.Backspace}
	for _, key in blocked do if input.KeyCode == key then return end end
end)

-- ===== FISHING LOOP =====
local function runFishingSequence(taskId, splash)
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
			local bubble = RepStorage.Splash:Clone()
			bubble.Caster.Value = player.Name
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

	-- 🌟 START REELING TENSION VFX
	if RodManager.currentRod and RodManager.currentRod:FindFirstChild("Part") then
		pcall(function() RodVFXManager:StartReelingVFX(RodManager.currentRod.Part, getCurrentRodName()) end)
	end

	if gameState.sinker and gameState.sinker.Parent then
		gameState.savedHookPosition = gameState.sinker.Position
	end

	MinigameSystem:Start(gameState.isAutoFishing, getCurrentRodName())

	while MinigameSystem:IsActive() do
		if not validate() then MinigameSystem:Stop(); break end
		task.wait(0.1)
	end

	-- 🌟 STOP REELING TENSION VFX
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

	cleanupCastEvent:FireServer()

	GUIManager:SlideFishingFrameOut(function()
		updateMobileButtonText()
	end)

	return true
end

-- ===== CASTING =====
function performCast(power)
	if not RodManager:IsValidRod() or gameState.casted or not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	gameState.hasLanded, gameState.fishingInProgress = false, false
	gameState.canCast = false
	updateMobileButtonText()

	if not gameState.isAutoFishing then
		AnimationController:Play("WaitingAnimation", 0.1)
		SoundManager:Play("Cast", 0.5)
		task.wait(0.4)
	end

	if not RodManager.currentRod or not RodManager.currentRod:FindFirstChild("Part") then return end

	local rodPos = RodManager.currentRod.Part.Position + RodManager.currentRod.Part.CFrame.LookVector * 1.5
	local velocity = CastingSystem:CalculateVelocity(rodPos, hrp.CFrame.LookVector, power, 100)

	-- 🌟 TRIGGER CAST VFX BURST & SFX
	pcall(function() RodVFXManager:PlayCastVFX(character, getCurrentRodName(), rodPos) end)

	castReplicationEvent:FireServer(rodPos, velocity, getCurrentRodName(), power)

	gameState.sinker = CastingSystem:CreateHook(rodPos, getCurrentRodName())
	gameState.sinker.AssemblyLinearVelocity = velocity

	local att1 = Instance.new("Attachment", RodManager.currentRod.Part)
	local att2 = Instance.new("Attachment", gameState.sinker)
	CastingSystem:CreateBeam(RodManager.currentRod.Part, att1, att2, getCurrentRodName())
	gameState.casted = true

	local landingConn; landingConn = gameState.sinker.Touched:Connect(function(hit)
		if gameState.hasLanded or not gameState.casted or gameState.fishingInProgress then return end
		if hit:IsDescendantOf(RodManager.currentRod) or hit:IsDescendantOf(character) then return end
		if CS:HasTag(hit, "Fish") or (hit.Parent and CS:HasTag(hit.Parent, "Fish")) then return end

		gameState.hasLanded = true
		gameState.sinker.AssemblyLinearVelocity = Vector3.zero
		gameState.sinker.Anchored = true
		if landingConn then landingConn:Disconnect() end

		local isWater = hit:IsA("Terrain") and CastingSystem:IsPositionInWater(gameState.sinker.Position)

		if isWater then
			SoundManager:Play("HookHit", 0.4)
			local waterY = CastingSystem:GetWaterSurfaceY(gameState.sinker.Position.X, gameState.sinker.Position.Z)
			if waterY then
				gameState.sinker.Position = Vector3.new(gameState.sinker.Position.X, waterY + 0.15, gameState.sinker.Position.Z)
			end
			
			local AssetsFolder = RepStorage:FindFirstChild("Assets")
			
			local SoundFolder = AssetsFolder and AssetsFolder:FindFirstChild("Sound")
			local rodSoundTemplate = SoundFolder and SoundFolder:FindFirstChild("Soundeffectrod") -- Digunakan untuk Tahap 2

			local EffectFolder = AssetsFolder and AssetsFolder:FindFirstChild("Effect")
			local RodEffectTemplate = EffectFolder and EffectFolder:FindFirstChild("EffectCorrupRod") -- Digunakan untuk Tahap 2
			
			-- 🔥 LOGIKA BARU: MUNCULKAN EFEK CORRUP HANYA UNTUK ROD TERTENTU
			-- ASUMSI: DEKLARASI TEMPLATE DAN VARIABEL GLOBAL (HARUS DI ATAS)
			-- local RodEffectTemplate = nil -- Ganti dengan template PartSecret1
			-- local ListrikSoundTemplate = nil -- Ganti dengan template Sound Listrik
			-- File: FishingSystem (Bagian di mana logika utama berjalan)

			local VISUAL_EFFECT_DURATION = 2.0 -- Konstanta baru untuk durasi efek visual

			local totalLockDuration = 4.0
			-- local character = player.Character

			-- Inisialisasi hrp1 (Harus ada di scope yang sama dengan pemanggilan)
			local hrp1 = character:FindFirstChild("HumanoidRootPart")

			-- Pastikan Anda menempatkan fungsi helper ini di bagian global script Anda
			local function positionEffect1(effectClone, template, duration)
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if not hrp then return end

				local distanceInFront = 10
				local distanceRight = 0

				-- ✅ PERBAIKAN: Menggunakan ketinggian yang lebih aman
				local heightAboveWater = 1.8

				local hrpCFrame = hrp.CFrame

				local projectedPosition = (hrpCFrame * CFrame.new(distanceRight, 0, -distanceInFront)).Position
				local finalY = projectedPosition.Y
				local waterY = CastingSystem:GetWaterSurfaceY(projectedPosition.X, projectedPosition.Z)

				if waterY then finalY = waterY + heightAboveWater end
				local finalPosition = Vector3.new(projectedPosition.X, finalY, projectedPosition.Z)

				-- 1. Hitung CFrame Posisi Tanpa Rotasi
				local baseCFrame = CFrame.new(projectedPosition.X, finalY, projectedPosition.Z) * (hrpCFrame - hrpCFrame.Position)

				-- 2. Terapkan Rotasi (Sumbu X)
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
				Debris:AddItem(effectClone, duration)
			end

			-- ====================================================================
			-- BLOK LOGIKA UTAMA (Dimodifikasi)
			-- ====================================================================

			if getCurrentRodName() == "Corruption Edge" then

				-- 1. EFEK SUARA
				if rodSoundTemplate and rodSoundTemplate:IsA("Sound") then
					local Api = rodSoundTemplate:Clone()
					Api.Parent = workspace
					Api:Play()
					Debris:AddItem(Api, totalLockDuration) -- Dihilangkan setelah 4.0 detik (Sesuai Lock Sequence)
				else
					warn("⚠ Efek Suara Listrik tidak ditemukan!")
				end

				-- 2. EFEK VISUAL (PARTSECRET1)
				if RodEffectTemplate and (RodEffectTemplate:IsA("BasePart") or RodEffectTemplate:IsA("Model")) then
					if hrp1 then
						local effectClone1 = RodEffectTemplate:Clone()
						effectClone1.Parent = workspace

						-- ✅ PERBAIKAN: Menggunakan durasi 3.0 detik
						positionEffect1(effectClone1, RodEffectTemplate, VISUAL_EFFECT_DURATION)
					end
				else
					warn("⚠️ Template efek visual (PartSecret1) tidak valid atau tidak ditemukan.")
				end
			end
			-- 🔥 AKHIR LOGIKA EFEK CORRUP

			gameState.activeFishingTask = tick()
			gameState.fishingInProgress, gameState.canCast = true, false
			updateMobileButtonText()

			local splash = RepStorage.Splash:Clone()
			splash.Caster.Value = player.Name
			splash.Parent = workspace
			splash.Position = gameState.sinker.Position
			gameState.splash = splash

			task.spawn(runFishingSequence, gameState.activeFishingTask, splash)
		else
			GUIManager:ShowNotification("Masukkan ke dalam air!", 3, Color3.fromRGB(255, 200, 100))
			task.wait(2)
			if not RodManager.isEquipped or not RodManager.currentRod then return end

			gameState.casted = false
			if gameState.sinker then gameState.sinker:Destroy() end
			if RodManager.currentRod and RodManager.currentRod:FindFirstChild("Part") then
				local line = RodManager.currentRod.Part:FindFirstChild("Line")
				if line then line:Destroy() end
			end
			cleanupCastEvent:FireServer()
			startCastingCooldown()
			task.delay(0.6, function()
				if RodManager.isEquipped and RodManager.currentRod then
					AnimationController:Play("EquippedAnimation", 0.3)
				end
			end)
		end
	end)
end

-- ===== ROD EQUIPPED/UNEQUIPPED =====
function onRodEquipped(rod)
	AnimationController:Reload(humanoid)
	AnimationController:Play("EquippedAnimation", 0.3)
	startSpeedMonitoring()

	GUIManager:ShowAutoButton(true)

	local function handleCastStart()
		if not RodManager.isEquipped then return end
		if gameState.isAutoFishing then return end

		if MinigameSystem:IsActive() then
			task.spawn(function() MinigameSystem:HandleClick(SoundManager, GUIManager) end)
			return
		end

		if gameState.canCast and not gameState.casted and not gameState.fishingInProgress and not gameState.castingCooldown then
			PowerBarSystem:StartCharging(getCurrentRodName())
			updateMobileButtonText()
		end
	end

	local function handleCastRelease()
		if not RodManager.isEquipped then return end
		if gameState.isAutoFishing then return end

		if MinigameSystem:IsActive() then
			task.spawn(function() MinigameSystem:HandleClick(SoundManager, GUIManager) end)
			return
		end

		if PowerBarSystem:IsCharging() then
			local power = PowerBarSystem:StopCharging()
			-- Quick tap / short hold casts with minimum 20% power so cast doesn't fail
			if power < 20 then
				power = 20
			end

			if not gameState.castingCooldown then
				performCast(power)
			else
				gameState.canCast = true
				AnimationController:Play("EquippedAnimation", 0.3)
			end
			updateMobileButtonText()
		end
	end

	-- Direct Tool Event Bindings (Works seamlessly across PC, Mobile, and Gamepad)
	if connections.toolActivated then connections.toolActivated:Disconnect() end
	connections.toolActivated = rod.Activated:Connect(handleCastStart)

	if connections.toolDeactivated then connections.toolDeactivated:Disconnect() end
	connections.toolDeactivated = rod.Deactivated:Connect(handleCastRelease)

	if isMobile then
		GUIManager:ShowMobileButton(true)
		updateMobileButtonText()

		if connections.mobileButton then connections.mobileButton:Disconnect() end
		connections.mobileButton = GUIManager:GetElement("tapMobileButton").MouseButton1Click:Connect(function()
			if not RodManager.isEquipped or gameState.isAutoFishing then return end

			if MinigameSystem:IsActive() then
				task.spawn(function() MinigameSystem:HandleClick(SoundManager, GUIManager) end)
			elseif PowerBarSystem:IsCharging() then
				handleCastRelease()
			elseif gameState.canCast and not gameState.casted and not gameState.fishingInProgress and not gameState.castingCooldown then
				handleCastStart()
			end
		end)
	else
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

function onRodUnequipped()
	if PowerBarSystem and PowerBarSystem:IsCharging() then PowerBarSystem:StopCharging() end
	if MinigameSystem and MinigameSystem:IsActive() then
		MinigameSystem:Stop()
		GUIManager:SlideFishingFrameOut(nil)
	end

	if gameState.isAutoFishing then
		gameState.isAutoFishing = false
		GUIManager:UpdateAutoButton(false)
		stopAutoFishLoop()
	end
	GUIManager:ShowAutoButton(false)

	AnimationController:Stop()
	stopSpeedMonitoring()
	PowerBarSystem:Reset()
	GUIManager:ShowMobileButton(false)

	for k, conn in connections do
		if conn then conn:Disconnect(); connections[k] = nil end
	end

	-- Pastikan kamera kembali normal jika unequip
	if camera and camera.Parent and camera.CameraType ~= Enum.CameraType.Custom then
		camera.CameraType = Enum.CameraType.Custom
	end

	if gameState.sinker then gameState.sinker:Destroy(); gameState.sinker = nil end
	if RodManager.currentRod and RodManager.currentRod:FindFirstChild("Part") then
		local line = RodManager.currentRod.Part:FindFirstChild("Line")
		if line then line:Destroy() end
	end
	if gameState.casted or gameState.fishingInProgress then cleanupCastEvent:FireServer() end

	gameState.casted, gameState.fishingInProgress = false, false
	gameState.canCast, gameState.hasLanded = true, false
	gameState.fishingCaught, gameState.castingCooldown = false, false
end

-- ===== CHARACTER EVENTS =====
player.CharacterAdded:Connect(function(char)
	gameState.activeFishingTask = nil
	if MinigameSystem:IsActive() then MinigameSystem:ForceStop() end
	if gameState.sinker then gameState.sinker:Destroy(); gameState.sinker = nil end
	if gameState.splash then gameState.splash:Destroy(); gameState.splash = nil end
	cleanupCastEvent:FireServer()

	-- Pastikan kamera kembali normal jika karakter baru spawn
	if camera and camera.Parent and camera.CameraType ~= Enum.CameraType.Custom then
		camera.CameraType = Enum.CameraType.Custom
	end

	gameState.casted, gameState.fishingInProgress = false, false
	gameState.canCast, gameState.hasLanded = true, false
	gameState.fishingCaught, gameState.castingCooldown = false, false

	gameState.isAutoFishing = false

	character, humanoid = char, char:WaitForChild("Humanoid")
	camera = workspace.CurrentCamera -- Update referensi kamera
	speedState.originalWalkSpeed = humanoid.WalkSpeed
	initializeSystems()
	GUIManager:UpdateAutoButton(false)

	RodManager:SetupCharacterMonitoring(character)
end)

-- Session Restore Remote Handler (Registered once globally)
resumeFishingRemote.OnClientEvent:Connect(function(sessionData)
	if typeof(sessionData) ~= "table" then return end
	task.spawn(function()
		-- Hanya lanjut auto-mancing jika saat disconnect memang sedang auto-mancing.
		-- Tool yang dipegang tetap dipulihkan sesuai snapshot (tanpa memaksa mancing).
		local resumeFishing = sessionData.Action == "Fishing" and sessionData.IsAutoFishing == true
		local toolName = sessionData.EquippedTool
		if not toolName and resumeFishing then
			toolName = sessionData.RodName or "Basic Rod"
		end

		local targetTool
		if toolName then
			local startTime = os.clock()
			targetTool = player.Backpack:FindFirstChild(toolName) or (character and character:FindFirstChild(toolName))
			while not targetTool and (os.clock() - startTime < 6) do
				task.wait(0.2)
				targetTool = player.Backpack:FindFirstChild(toolName) or (character and character:FindFirstChild(toolName))
			end
		end

		if not targetTool and resumeFishing then
			for _, tool in ipairs(player.Backpack:GetChildren()) do
				if tool:IsA("Tool") and (CS:HasTag(tool, "Rod") or tool.Name:lower():find("rod")) then
					targetTool = tool
					break
				end
			end
		end

		if targetTool and character then
			local hum = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 3)
			if hum then
				hum:EquipTool(targetTool)
				if resumeFishing then
					task.wait(0.6)
					gameState.isAutoFishing = true
					GUIManager:UpdateAutoButton(true)
					startAutoFishLoop()
					task.delay(0.5, autoCast)
				end
			end
		end
	end)
end)

player.CharacterRemoving:Connect(function()
	gameState.activeFishingTask = nil
	if MinigameSystem:IsActive() then MinigameSystem:ForceStop() end
	if gameState.sinker then gameState.sinker:Destroy(); gameState.sinker = nil end
	if gameState.splash then gameState.splash:Destroy(); gameState.splash = nil end
	for k, conn in connections do if conn then conn:Disconnect(); connections[k] = nil end end
	cameraSequenceToken += 1
	cleanupCastEvent:FireServer()
end)

-- ===== CAST REPLICATION =====
castReplicationEvent.OnClientEvent:Connect(function(otherPlayer, rodPos, velocity, rodName)
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

cleanupCastEvent.OnClientEvent:Connect(function(otherPlayer)
	if otherPlayer == player then return end
	local data = otherPlayersHooks[otherPlayer]
	if data then
		if data.sinker then data.sinker:Destroy() end
		if data.beam then data.beam:Destroy() end
		if data.connection then data.connection:Disconnect() end
		otherPlayersHooks[otherPlayer] = nil
	end
end)

-- Centralized Toast: Handled by EventNotificationGui.NotifyController
-- (Removed duplicate showNotificationEvent listener to prevent double notifications)
-- end

-- ===== INITIAL SETUP =====
RodManager:SetupCharacterMonitoring(character)