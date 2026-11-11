-- System by @thehandofvoid
-- Modified by @jay_peaceee
-- ReplicatedStorage/FishingModules/PowerBarSystem

local PowerBarSystem = {}
local RepStorage = game:GetService("ReplicatedStorage"):WaitForChild("FishingSystem")
local RS = game:GetService("RunService")
local Players = game:GetService("Players") -- Diperlukan untuk mengakses pemain lokal
local Debris = game:GetService("Debris") -- Diperlukan untuk menghapus GUI
local TweenService = game:GetService("TweenService") -- Diperlukan untuk animasi fade
local FishingConfig = require(RepStorage:WaitForChild("FishingConfig"))

local powerState = {
	isCharging = false,
	currentPower = 0,
	maxPower = 100,
	chargeSpeed = 120,
	chargingDirection = 1
}

local chargingConnection = nil
local gui = nil

function PowerBarSystem:Initialize(guiElements)
	gui = guiElements
end

--- FUNGSI BARU: Menampilkan Teks Kualitas di Atas Kepala Pemain
function PowerBarSystem:DisplayQualityText(qualityText, qualityColor)
	local player = Players.LocalPlayer
	-- Pastikan kode ini berjalan di client dan player/character tersedia
	if not player or not player.Character then return end

	local character = player.Character
	local head = character:FindFirstChild("Head")
	if not head then return end

	-- 1. Buat BillboardGui (UI yang mengikuti dunia 3D)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FishingQualityIndicator"
	billboard.Adornee = head
	-- Sesuaikan ukuran agar teks terlihat jelas
	billboard.Size = UDim2.new(2.5, 0, 1.5, 0) 
	billboard.AlwaysOnTop = true
	-- Geser sedikit ke atas kepala
	billboard.ExtentsOffset = Vector3.new(0, 2, 0) 

	-- 2. Buat TextLabel
	local label = Instance.new("TextLabel")
	label.Name = "QualityText"
	label.Text = qualityText
	label.TextColor3 = qualityColor
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Parent = billboard

	-- 3. Tambahkan ke karakter
	billboard.Parent = head

	-- Animasi: Fade out dalam 1 detik
	local fadeTime = 1.0

	local tweenInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeTween = TweenService:Create(label, tweenInfo, {TextTransparency = 1, TextStrokeTransparency = 1})

	fadeTween:Play()

	-- Hapus BillboardGui setelah animasi selesai
	Debris:AddItem(billboard, fadeTime)
end


function PowerBarSystem:UpdateBar(rodName)
	local powerPercent = powerState.currentPower / powerState.maxPower
	local config = FishingConfig.GetRodConfig(rodName)

	-- totalLuck, baseLuck, dan powerBonus tetap dihitung jika dibutuhkan di tempat lain,
	-- tetapi nilai totalLuck tidak lagi ditampilkan di GUI.
	local totalLuck, baseLuck, powerBonus = FishingConfig.CalculateTotalLuck(config.baseLuck, powerPercent)

	gui.fillFrame.Size = UDim2.new(1, 0, powerPercent, 0)

	local color
	if powerPercent < 0.25 then
		color = Color3.fromRGB(255, 100, 100) -- Merah (Sangat Rendah)
	elseif powerPercent < 0.5 then
		color = Color3.fromRGB(255, 200, 100) -- Oranye (Rendah)
	elseif powerPercent < 0.75 then
		color = Color3.fromRGB(255, 255, 100) -- Kuning (Cukup)
	else
		color = Color3.fromRGB(100, 255, 100) -- Hijau (Tinggi)
	end
	gui.fillFrame.BackgroundColor3 = color

	--- 🎣 Logika Baru: Mengganti Teks Luck dengan Kualitas Lemparan (Hanya Teks) ---
	local qualityText = ""
	local qualityColor = Color3.new(1, 1, 1) -- Default Putih

	if powerPercent >= 0.95 then
		qualityText = "SEMPURNA!" -- 95% ke atas
		qualityColor = Color3.fromRGB(255, 255, 0) -- Kuning Cerah
	elseif powerPercent >= 0.85 then
		qualityText = "Luar Biasa" -- 85% - 94.9%
		qualityColor = Color3.fromRGB(0, 255, 0) -- Hijau
	elseif powerPercent >= 0.65 then
		qualityText = "Bagus" -- 65% - 84.9%
		qualityColor = Color3.fromRGB(100, 255, 100) -- Hijau Muda
	elseif powerPercent >= 0.40 then
		qualityText = "Normal" -- 40% - 64.9%
		qualityColor = Color3.fromRGB(255, 255, 100) -- Kuning
	else
		qualityText = "Sederhana" -- Di bawah 40%
		qualityColor = Color3.fromRGB(255, 100, 100) -- Merah
	end

	-- HANYA TAMPILKAN TEKS KUALITAS
	gui.luckMultiText.Text = qualityText
	gui.luckMultiText.TextColor3 = qualityColor
end

function PowerBarSystem:StartCharging(rodName)
	powerState.isCharging = true
	powerState.currentPower = 0
	powerState.chargingDirection = 1

	gui.barFrame.Visible = true
	gui.fillFrame.Size = UDim2.new(1, 0, 0, 0)

	self:UpdateBar(rodName)

	if chargingConnection then
		chargingConnection:Disconnect()
	end

	chargingConnection = RS.Heartbeat:Connect(function(deltaTime)
		if not powerState.isCharging then return end

		powerState.currentPower += powerState.chargeSpeed * deltaTime * powerState.chargingDirection

		if powerState.currentPower >= powerState.maxPower then
			powerState.currentPower = powerState.maxPower
			powerState.chargingDirection = -1
		elseif powerState.currentPower <= 0 then
			powerState.currentPower = 0
			powerState.chargingDirection = 1
		end

		self:UpdateBar(rodName)
	end)
end

function PowerBarSystem:StopCharging()
	powerState.isCharging = false
	gui.barFrame.Visible = false

	if chargingConnection then
		chargingConnection:Disconnect()
		chargingConnection = nil
	end

	local power = powerState.currentPower
	powerState.currentPower = 0
	powerState.chargingDirection = 1

	local powerPercent = power / powerState.maxPower

	-- --- 🎣 Logika untuk menentukan Kualitas Lemparan ---
	local qualityText = ""
	local qualityColor = Color3.new(1, 1, 1)

	if powerPercent >= 0.95 then
		qualityText = "SEMPURNA!"
		qualityColor = Color3.fromRGB(255, 255, 0)
	elseif powerPercent >= 0.85 then
		qualityText = "Luar Biasa"
		qualityColor = Color3.fromRGB(0, 255, 0)
	elseif powerPercent >= 0.65 then
		qualityText = "Bagus"
		qualityColor = Color3.fromRGB(100, 255, 100)
	elseif powerPercent >= 0.40 then
		qualityText = "Normal"
		qualityColor = Color3.fromRGB(255, 255, 100)
	else
		qualityText = "Sederhana"
		qualityColor = Color3.fromRGB(255, 100, 100)
	end
	-- --- -------------------------------------------- ---

	-- Tampilkan teks kualitas di atas kepala pemain
	self:DisplayQualityText(qualityText, qualityColor)

	return power
end

function PowerBarSystem:IsCharging()
	return powerState.isCharging
end

function PowerBarSystem:GetCurrentPower()
	return powerState.currentPower
end

function PowerBarSystem:Reset()
	if chargingConnection then
		chargingConnection:Disconnect()
		chargingConnection = nil
	end

	powerState.isCharging = false
	powerState.currentPower = 0
	powerState.chargingDirection = 1
end

return PowerBarSystem