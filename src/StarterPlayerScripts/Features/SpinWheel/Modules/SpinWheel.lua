--!nonstrict
-- SpinWheel: UI + animasi wheel. GUI hidup di StarterGui.SpinWheelGui.MainFrame
-- (desain Studio): wheel berupa satu gambar (SpinsRewards), tombol Spin + 2 paket.
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Panel = require(script.Parent.Parent.Parent.SummitKit.Client.Modules.UI.Panel)
local SpinConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("SpinConfig"))

local SpinWheel = {}

local gui, main, wheelFrame, wheel, pointer
local timerLabel, closeBtn, skipBtn
local spinBtn, spinBtnLabel, buy2Btn, buy2Label, buy7Btn, buy7Label

local callbacks = {}
local spinning = false
local fastMode = false
local currentRotation = 0
local skipHandler = nil
local messageUntil = 0
local tickSound = nil
local idleConnection = nil
local lastTickTime = 0

local SEG_COUNT = #SpinConfig.Segments
local SEG_ANGLE = 360 / SEG_COUNT
local IDLE_SPEED = 9 -- derajat/detik saat roda hanya berputar pelan (tanpa suara)

local function playSound(id, volume)
	if not id or id == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume or 0.5
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	task.delay(10, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

local function playTick()
	if not tickSound then
		return
	end
	-- Batasi kerapatan tick biar tidak jadi buzz saat roda paling cepat.
	local now = os.clock()
	if now - lastTickTime < 0.045 then
		return
	end
	lastTickTime = now
	tickSound.TimePosition = 0
	if not tickSound.IsPlaying then
		tickSound:Play()
	end
end

local function ensureOverlayButtons()
	-- Tombol SKIP untuk antrian cepat (tidak ada di desain, dibuat runtime).
	if not main:FindFirstChild("SkipButton") then
		local skip = Instance.new("TextButton")
		skip.Name = "SkipButton"
		skip.Text = "SKIP >>"
		skip.Font = Enum.Font.FredokaOne
		skip.TextColor3 = Color3.fromRGB(255, 255, 255)
		skip.BackgroundColor3 = Color3.fromRGB(90, 80, 110)
		skip.AutoButtonColor = true
		skip.TextSize = 16
		skip.Size = UDim2.fromOffset(110, 34)
		skip.Position = UDim2.new(1, -10, 0, 58)
		skip.AnchorPoint = Vector2.new(1, 0)
		skip.Visible = false
		skip.ZIndex = 20
		skip.Parent = main

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = skip

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(20, 16, 24)
		stroke.Parent = skip
	end
	return main:FindFirstChild("SkipButton")
end

function SpinWheel.init()
	if gui and gui.Parent then
		return gui
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	gui = playerGui:WaitForChild("SpinWheelGui", 30)
	if not gui then
		return nil
	end

	main = gui:WaitForChild("MainFrame", 10)
	if not main then
		return nil
	end

	timerLabel = main:WaitForChild("InfoTimer")
	closeBtn = main:WaitForChild("CloseBtn")
	wheelFrame = main:WaitForChild("Frame")
	wheel = wheelFrame:WaitForChild("SpinsRewards")
	pointer = wheelFrame:FindFirstChild("Pointer")

	local bar = main:WaitForChild("FrameBtn")
	spinBtn = bar:WaitForChild("Freespin")
	spinBtnLabel = spinBtn:WaitForChild("Label")
	buy2Btn = bar:WaitForChild("Buy1xSpin")
	buy2Label = buy2Btn:WaitForChild("Label")
	buy7Btn = bar:WaitForChild("Buy5xSpin")
	buy7Label = buy7Btn:WaitForChild("Label")

	-- SkipButton sudah ada di desain Studio (MainFrame.SkipButton); pakai itu.
	-- Fallback: buat runtime kalau suatu saat belum ada.
	skipBtn = main:FindFirstChild("SkipButton") or ensureOverlayButtons()
	skipBtn.Visible = false

	main.Visible = false

	-- Suara "tek" tiap roda melewati garis segmen (hanya saat spin).
	if not tickSound then
		tickSound = Instance.new("Sound")
		tickSound.Name = "SpinTick"
		tickSound.SoundId = "rbxassetid://12221967"
		tickSound.Volume = 0.3
		tickSound.Parent = SoundService
	end

	-- Bersihkan sisa sound putaran lama (tidak dipakai lagi).
	local stale = SoundService:FindFirstChild("SpinWhoosh")
	if stale then
		stale:Destroy()
	end

	currentRotation = wheel.Rotation % 360

	-- Idle: roda muter pelan terus-menerus, tanpa sound.
	if idleConnection then
		idleConnection:Disconnect()
	end
	idleConnection = RunService.RenderStepped:Connect(function(dt)
		if spinning or not wheel or not wheel.Parent then
			return
		end
		currentRotation = (currentRotation + IDLE_SPEED * dt) % 360
		wheel.Rotation = currentRotation
	end)

	closeBtn.Activated:Connect(function()
		SpinWheel.close()
	end)

	spinBtn.Activated:Connect(function()
		if callbacks.onSpin and not spinning then
			callbacks.onSpin()
		end
	end)
	buy2Btn.Activated:Connect(function()
		if callbacks.onBuy and not spinning then
			callbacks.onBuy("X2")
		end
	end)
	buy7Btn.Activated:Connect(function()
		if callbacks.onBuy and not spinning then
			callbacks.onBuy("X7")
		end
	end)
	skipBtn.Activated:Connect(function()
		fastMode = true
		if skipHandler then
			skipHandler()
		end
	end)

	Panel.mount(main, { backdropGui = gui, backdropZ = 0 })
	return gui
end

function SpinWheel.setCallbacks(cb)
	callbacks = cb or {}
end

function SpinWheel.toggle()
	if not SpinWheel.init() then
		return
	end
	Panel.toggle(main)
end

function SpinWheel.open()
	if not SpinWheel.init() then
		return
	end
	Panel.open(main)
end

function SpinWheel.close()
	if not SpinWheel.init() then
		return
	end
	Panel.close(main)
end

function SpinWheel.isOpen()
	return main ~= nil and main.Visible == true
end

function SpinWheel.isSpinning()
	return spinning
end

function SpinWheel.setFast(fast)
	fastMode = fast
end

-- busy = antrian spin berjalan: sembunyikan tombol aksi, tampilkan SKIP.
function SpinWheel.setBusy(busy)
	if busy then
		spinBtn.Visible = false
		buy2Btn.Visible = false
		buy7Btn.Visible = false
		skipBtn.Visible = true
	else
		skipBtn.Visible = false
		spinBtn.Visible = true
		buy2Btn.Visible = true
		buy7Btn.Visible = true
	end
end

-- state = { Spins, HasFree, FreeReadyAt, CooldownSeconds, Products }
function SpinWheel.setState(state)
	state = state or {}
	local hasFree = state.HasFree == true
	local spins = state.Spins or 0

	spinBtnLabel.Text = hasFree and "FREE SPIN" or ("Spin (x" .. tostring(spins) .. ")")

	-- Label paket diambil dari config (gambar tombol sudah memuat harga).
	buy2Label.Text = SpinConfig.Products.X2.Label
	buy7Label.Text = SpinConfig.Products.X7.Label
end

function SpinWheel.updateCountdown(state)
	if not timerLabel then
		return
	end
	if os.clock() < messageUntil then
		return -- pesan status sedang tampil
	end
	state = state or {}
	if state.HasFree == true then
		timerLabel.Text = "FREE SPIN READY!"
		timerLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
		return
	end
	local remaining = math.max(0, (state.FreeReadyAt or 0) - os.time())
	local mins = math.floor(remaining / 60)
	local secs = remaining % 60
	timerLabel.Text = string.format("Next free spin in: %d:%02d", mins, secs)
	timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
end

-- Pesan status memakai label timer biar tidak menambah elemen di desain.
function SpinWheel.showMessage(text)
	if not timerLabel then
		return
	end
	if text and text ~= "" then
		timerLabel.Text = text
		timerLabel.TextColor3 = Color3.fromRGB(255, 230, 120)
		messageUntil = os.clock() + 3
	else
		messageUntil = 0
	end
end

-- Putar wheel sampai segmen (1-based dari server) berada di bawah pointer.
-- Slice i menempati (i-1)*60 .. i*60 derajat dari jam 12 (searah jarum jam).
-- Animasi 4 detik: mulai ngebut lalu melambat (ease-out), dengan sound tick
-- yang makin jarang saat roda melambat.
function SpinWheel.spinToSegment(segmentIndex, duration, onDone)
	spinning = true
	playSound(SpinConfig.SpinSound, 0.6)

	local centerFromTop = (segmentIndex - 1) * SEG_ANGLE + SEG_ANGLE / 2
	local desired = (-centerFromTop) % 360
	local current = currentRotation % 360
	local delta = (desired - current) % 360
	local fullTurns = fastMode and 3 or 6
	local startRot = currentRotation
	local totalAngle = fullTurns * 360 + delta
	local spinTime = duration or (fastMode and 1.2 or 9)
	local elapsed = 0
	local lastTick = math.floor(startRot / SEG_ANGLE)
	local finished = false

	local function finish()
		if finished then
			return
		end
		finished = true
		spinning = false
		skipHandler = nil
		currentRotation = startRot % 360
		if wheel then
			wheel.Rotation = currentRotation
		end
		if onDone then
			onDone()
		end
	end

	skipHandler = function()
		if not spinning then
			return
		end
		startRot = startRot + totalAngle
		finish()
	end

	local connection
	connection = RunService.RenderStepped:Connect(function(dt)		if finished then
			connection:Disconnect()
			return
		end

		elapsed = math.min(elapsed + dt, spinTime)
		local t = elapsed / spinTime
		local eased = 1 - (1 - t) ^ 5 -- ease-out quint: kencang di awal, halus di akhir
		local rot = startRot + totalAngle * eased
		wheel.Rotation = rot % 360

		local tickIndex = math.floor(rot / SEG_ANGLE)
		if tickIndex > lastTick then
			lastTick = tickIndex
			playTick()
		end

		if elapsed >= spinTime then
			startRot = startRot + totalAngle
			connection:Disconnect()
			finish()
		end
	end)
end

return SpinWheel
