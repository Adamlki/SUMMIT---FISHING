-- StarterPlayer/StarterPlayerScripts/AntiAFKClient
-- Multi-layered Anti-AFK client: Intercepts Idle kick & Auto-rejoins on disconnect

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))

-- ===================================================================
-- 0. AWAY TRACKER (lapor status AFK ke server)
-- Roblox men-DC pemain setelah ~20 menit tanpa aktivitas. Mulai 18 menit
-- (2 menit sebelum batas) kita lapor Away=true ke server, supaya saat
-- auto-rejoin, AntiAFKServer tahu ini kasus AFK dan me-restore posisi.
-- ===================================================================
local AWAY_AFTER_SECONDS = 18 * 60
local isAway = false
local lastInputTime = os.clock()

local function pushAwayState()
	pcall(function()
		NetworkGateway:Request("PUT", "/afk/sync", { Away = isAway })
	end)
end

local function setAway(value)
	if isAway == value then return end
	isAway = value
	pushAwayState()
end

local function markActivity(input)
	-- Abaikan klik simulasi anti-idle (VirtualUser di posisi 0,0)
	if input and input.UserInputType == Enum.UserInputType.MouseButton2 and input.Position == Vector2.zero then
		return
	end
	lastInputTime = os.clock()
	if isAway then
		setAway(false)
	end
end

UserInputService.InputBegan:Connect(markActivity)
UserInputService.InputChanged:Connect(markActivity)
UserInputService.WindowFocusReleased:Connect(function()
	setAway(true)
end)

task.spawn(function()
	while true do
		task.wait(15)
		if not isAway and (os.clock() - lastInputTime) >= AWAY_AFTER_SECONDS then
			isAway = true
		end
		-- Refresh berkala untuk menutup celah rate-limit sync di server.
		pushAwayState()
	end
end)

-- ===================================================================
-- 1. PREVENT ROBLOX 20-MINUTE IDLE DISCONNECT
-- ===================================================================
localPlayer.Idled:Connect(function()
	setAway(true)
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new(0, 0))
	end)
end)

-- Heartbeat micro-pulse (every 60s) to keep activity fresh
task.spawn(function()
	while true do
		task.wait(60)
		if os.clock() - lastInputTime > 300 then
			pcall(function()
				VirtualUser:CaptureController()
			end)
		end
	end
end)

-- ===================================================================
-- 2. AUTO-REJOIN ON CONNECTION ERROR / DISCONNECT
-- ===================================================================
local isRejoining = false

local function triggerAutoRejoin(reason)
	if isRejoining then return end
	isRejoining = true

	-- Attempt graceful reconnect to the same server or place
	task.delay(1.5, function()
		pcall(function()
			if game.JobId and #game.JobId > 0 then
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
			else
				TeleportService:Teleport(game.PlaceId, localPlayer)
			end
		end)
	end)
end

-- Monitor Roblox CoreGui disconnect error prompts (protected with pcall for capability safety)
pcall(function()
	GuiService.ErrorMessageChanged:Connect(function(errorMessage)
		if errorMessage and #errorMessage > 0 then
			triggerAutoRejoin(errorMessage)
		end
	end)
end)

-- TeleportInitFailed fallback
TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
	if player == localPlayer then
		task.wait(3)
		isRejoining = false
		triggerAutoRejoin("TeleportInitFailed")
	end
end)
