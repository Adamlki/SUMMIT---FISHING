-- Carry System Client - Clean Version
-- Handles client-side carry UI, animations, and interactions

-- ========================================
-- SERVICES
-- ========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Movement Controls Disabler (Ensures carried player doesn't fight carrier physics)
local playerModule = nil
local playerControls = nil
pcall(function()
	local PlayerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts", 10)
	local pModuleScript = PlayerScripts and PlayerScripts:WaitForChild("PlayerModule", 10)
	if pModuleScript then
		playerModule = require(pModuleScript)
		playerControls = playerModule and playerModule:GetControls()
	end
end)

local function setMovementControlsEnabled(enabled: boolean)
	if playerControls then
		pcall(function()
			if enabled then
				playerControls:Enable()
			else
				playerControls:Disable()
			end
		end)
	end
end


-- ========================================
-- WAIT FOR REMOTE EVENT
-- ========================================

local CarryRemote = ReplicatedStorage:WaitForChild("CarryRemote")
local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))

-- ========================================
-- CONFIGURATION
-- ========================================

-- Animation ID untuk carried player (semua rig)
local SIT_ID = 88407453975281 -- Flying Harpy Wings (Bundle 225248611927500)

-- Request timeout (seconds)
local REQUEST_TIMEOUT = 8

-- Maximum click distance untuk request carry
local MAX_CLICK_DISTANCE = 20

-- ========================================
-- PLAYER & UI SETUP
-- ========================================

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local gui = script.Parent and script.Parent:IsA("ScreenGui") and script.Parent or playerGui:WaitForChild("GendongGUI")

-- ========================================
-- UI ELEMENTS
-- ========================================

-- Frame2: Status UI (showing who you're carrying or who's carrying you)
local frame2 = gui:WaitForChild("Frame2")
local btnRight = frame2:WaitForChild("RightButton")
local btnLeft = frame2:WaitForChild("LeftButton")
local btnDown = frame2:WaitForChild("DownButton")
local cName = frame2:WaitForChild("NameLabel")

-- Frame3: Prompt UI (accept/decline carry request)
local frame3 = gui:WaitForChild("Frame3")
local promptLabel = frame3:WaitForChild("TextLabel")
local btnYes = frame3:WaitForChild("YesButton")
local btnNo = frame3:WaitForChild("NoButton")

-- UI visibility defaults
frame2.Visible = false
frame3.Visible = false

-- ========================================
-- FORWARD DECLARATIONS
-- ========================================

local updateCarriedUI
local refreshCarrierUI

-- ========================================
-- STATE TRACKING
-- ========================================

-- Current UI mode
local uiMode = "idle"

-- Last requester ID (for prompt response)
local lastRequesterId = nil

-- List of players being carried (for carrier)
local carriedList = {}
local carriedIndex = 1

-- Is this player being carried?
local isCarried = false
local currentCarrierId = nil
local currentCarrierName = nil

-- Connections
local keepUiConn = nil
local wasCarrying = false

-- ========================================
-- HELPER FUNCTIONS - CHARACTER
-- ========================================

-- Get humanoid dari player character
local function getHumanoid()
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

-- Get HumanoidRootPart dari player character
local function getHRP()
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

-- Get or create Animator
local function getAnimator(hum)
	return hum and (hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum))
end

-- ========================================
-- ANIMATION MANAGEMENT
-- ========================================

-- Animation track & shared animation asset
local sitTrack = nil
local sitAnimation = Instance.new("Animation")

-- Play sitting animation (untuk carried player)
local function playSit()
	-- FIX: Tunggu sebentar agar network ownership berpindah ke carrier dulu
	-- sebelum mencoba load animasi, supaya animasi bisa di-apply dengan benar
	task.spawn(function()
		task.wait(0.2)

		local hum = getHumanoid()
		if not hum then return end
		if not isCarried then return end -- Batalkan kalau sudah tidak di-carry

		-- Semua rig memakai animasi Harpy Wings idle
		local useId = SIT_ID
		if useId == 0 then return end

		local animator = getAnimator(hum)

		-- Stop existing sit animation
		if sitTrack then 
			sitTrack:Stop(0.15)
			sitTrack = nil
		end

		-- Load dan play new animation
		sitAnimation.AnimationId = "rbxassetid://" .. tostring(useId)

		local ok, track = pcall(function() 
			return animator:LoadAnimation(sitAnimation) 
		end)

		if ok and track then
			sitTrack = track
			sitTrack.Priority = Enum.AnimationPriority.Action4
			sitTrack.Looped = true
			sitTrack:Play(0.1)
		end

		-- FIX: Paksa Sit = true beberapa kali karena server ownership bisa nge-reset
		for i = 1, 5 do
			task.wait(0.1)
			if not hum or not hum.Parent or not isCarried then break end
			hum.Sit = false
			hum.PlatformStand = false
			if sitTrack and not sitTrack.IsPlaying then
				sitTrack:Play(0.1)
			end
		end
	end)
end

-- Stop sitting animation
local function stopSit() 
	local hum = getHumanoid()
	local hrp = getHRP()

	if sitTrack then 
		sitTrack:Stop(0.2)
		sitTrack = nil
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

-- ========================================
-- JUMP BLOCKING (for carried players)
-- ========================================

local jumpBlockConn = nil

-- Start blocking jump input
local function startBlockingJump()
	if jumpBlockConn then 
		jumpBlockConn:Disconnect() 
	end

	jumpBlockConn = UserInputService.JumpRequest:Connect(function()
		local h = getHumanoid()
		if h then 
			h.Jump = false 
		end
	end)
end

-- Stop blocking jump input
local function stopBlockingJump()
	if jumpBlockConn then 
		jumpBlockConn:Disconnect()
		jumpBlockConn = nil
	end
end

-- ========================================
-- UI MANAGEMENT - CARRIER
-- ========================================

-- Refresh carrier UI (showing carried players list)
refreshCarrierUI = function()
	local count = #carriedList

	-- Kalau tidak ada yang di-carry, hide UI
	if count <= 0 then 
		frame2.Visible = false
		return 
	end

	-- Clamp carried index
	if carriedIndex < 1 then 
		carriedIndex = 1 
	end
	if carriedIndex > count then 
		carriedIndex = count 
	end

	-- Update UI text
	local item = carriedList[carriedIndex]
	if item then
		cName.Text = string.format("Carrying (%d/%d): %s", carriedIndex, count, item.name or "Player")
		frame2.Visible = true
		frame3.Visible = false
	end
end

-- Stop keep UI connection
local function stopKeepUi()
	if keepUiConn then 
		keepUiConn:Disconnect()
		keepUiConn = nil 
	end
end

-- ========================================
-- UI MANAGEMENT - CARRIED PLAYER
-- ========================================

-- Update UI saat player sedang di-carry
updateCarriedUI = function()
	if isCarried then
		-- Tampilkan "Get Down" button
		btnLeft.Visible = false
		btnRight.Visible = false
		btnDown.Visible = true
		btnDown.Text = "Get Down"

		-- Show carrier name
		cName.Text = ("Carried by: %s"):format(currentCarrierName or "Player")

		frame2.Visible = true
		frame3.Visible = false
	else
		-- Show carrier UI
		refreshCarrierUI()
	end
end

-- Ensure status UI tetap visible saat di-carry
local function ensureStatusVisible()
	if not isCarried or not currentCarrierId then return end
	updateCarriedUI()
end

-- Start keep UI connection (ensure UI tetap visible)
local function startKeepUi()
	stopKeepUi()

	keepUiConn = RunService.Heartbeat:Connect(function()
		if isCarried then
			ensureStatusVisible()
			-- FIX: Pastikan animasi sit terus berjalan selama di-carry
			local hum = getHumanoid()
			if hum then
				hum.Sit = false
				hum.PlatformStand = false
				if sitTrack and not sitTrack.IsPlaying then
					sitTrack:Play(0.1)
				end
			end
		else
			stopKeepUi()
		end
	end)
end

-- Set mode ke "being carried"
local function setModeStatusCarried(carrierName, carrierId)
	currentCarrierId = carrierId
	currentCarrierName = carrierName
	isCarried = true
	setMovementControlsEnabled(false)

	updateCarriedUI()
	startKeepUi()
	startBlockingJump()
end

-- ========================================
-- PROMPT UI
-- ========================================

-- Show prompt request (someone wants to carry you)
local function showPromptRequest(fromId, fromName)
	lastRequesterId = fromId
	promptLabel.Text = ("%s wants to carry you. Allow?"):format(fromName or "Someone")

	frame3.Visible = true
	frame2.Visible = false
end

-- ========================================
-- CARRIER LIST MANAGEMENT
-- ========================================

-- Add carried player ke list
local function addCarried(id, name)
	-- Check kalau sudah ada, update name aja
	for _, it in ipairs(carriedList) do 
		if it.id == id then 
			it.name = name
			refreshCarrierUI()
			return 
		end
	end

	-- Add new carried player
	table.insert(carriedList, {id = id, name = name})
	carriedIndex = #carriedList
	refreshCarrierUI()
end

-- Remove carried player dari list
local function removeCarried(id)
	local idx

	-- Find index
	for i, it in ipairs(carriedList) do 
		if it.id == id then 
			idx = i 
			break 
		end
	end

	-- Remove dari list
	if idx then 
		table.remove(carriedList, idx) 
	end

	-- Adjust index
	if carriedIndex > #carriedList then 
		carriedIndex = #carriedList 
	end

	-- Update UI
	if #carriedList > 0 then
		refreshCarrierUI()
	else
		frame2.Visible = false
	end
end

-- Set carried list dari snapshot (server sync)
local function setCarriedListFromSnapshot(list)
	carriedList = {}

	for _, it in ipairs(list or {}) do 
		table.insert(carriedList, {
			id = it.id, 
			name = it.name
		}) 
	end

	-- Adjust index
	if carriedIndex > #carriedList then 
		carriedIndex = #carriedList 
	end
	if carriedIndex < 1 and #carriedList > 0 then 
		carriedIndex = 1 
	end

	-- Update UI
	if #carriedList > 0 then
		refreshCarrierUI()
	else
		frame2.Visible = false
	end
end

-- ========================================
-- BUTTON HANDLERS
-- ========================================

-- Yes button (accept carry request)
btnYes.MouseButton1Click:Connect(function()
	if lastRequesterId then
		frame3.Visible = false
		NetworkGateway:Request("POST", "/carry/response", {
			RequesterId = lastRequesterId, 
			Accept = true
		})
	end
end)

-- No button (decline carry request)
btnNo.MouseButton1Click:Connect(function()
	if lastRequesterId then
		frame3.Visible = false
		NetworkGateway:Request("POST", "/carry/response", {
			RequesterId = lastRequesterId, 
			Accept = false
		})
	end
end)

-- Down button (get down or drop carried player)
btnDown.MouseButton1Click:Connect(function() 
	if isCarried then
		-- Get down dari carrier
		NetworkGateway:Request("DELETE", "/carry/stop", {})
	else
		-- Drop carried player
		local item = carriedList[carriedIndex]
		if item and item.id then 
			NetworkGateway:Request("DELETE", "/carry/stop", {
				TargetId = item.id
			})
		end
	end
end)

-- Right button (next carried player)
btnRight.MouseButton1Click:Connect(function() 
	if #carriedList == 0 then return end 

	carriedIndex += 1
	if carriedIndex > #carriedList then 
		carriedIndex = 1 
	end

	refreshCarrierUI() 
end)

-- Left button (previous carried player)
btnLeft.MouseButton1Click:Connect(function() 
	if #carriedList == 0 then return end 

	carriedIndex -= 1
	if carriedIndex < 1 then 
		carriedIndex = #carriedList 
	end

	refreshCarrierUI() 
end)

-- ========================================
-- REMOTE EVENT HANDLERS
-- ========================================

CarryRemote.OnClientEvent:Connect(function(action, data)
	-- ========================================
	-- PROMPT ACTION (someone wants to carry you)
	-- ========================================
	if action == "Prompt" then
		showPromptRequest(data.fromId, data.fromName)

		-- ========================================
		-- START ACTION (carry started)
		-- ========================================
	elseif action == "Start" then
		if data and data.youAreCarrier then
			-- You started carrying someone
			addCarried(data.targetId, data.targetName)

		else
			-- You are being carried
			if data and data.carrierName and data.carrierId then
				setModeStatusCarried(data.carrierName, data.carrierId)
				playSit()
			end
		end

		-- ========================================
		-- END ACTION (carry ended)
		-- ========================================
	elseif action == "End" then
		if data and data.youAreCarrier then
			-- Someone you were carrying is no longer carried
			if data.removedId then 
				removeCarried(data.removedId) 
			end

			-- Hide carrier UI when list is empty
			if #carriedList <= 0 then
				frame2.Visible = false
			end
		else
			-- You are no longer being carried
			isCarried = false
			currentCarrierId = nil
			setMovementControlsEnabled(true)
			currentCarrierName = nil

			stopKeepUi()
			stopSit()  -- sudah include reset velocity & state
			stopBlockingJump()

			-- FIX: Pastikan HRP tidak punya sisa rotasi/velocity di client
			local hrp = getHRP()
			if hrp then
				pcall(function()
					hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
				end)
			end

			frame2.Visible = false
			frame3.Visible = false
		end

		-- ========================================
		-- CARRIER LIST UPDATE (sync from server)
		-- ========================================
	elseif action == "CarrierList" then
		if data and data.list then
			setCarriedListFromSnapshot(data.list)
		end

		-- ========================================
		-- ERROR/NOTIFICATION ACTIONS
		-- ========================================
	elseif action == "Declined" or action == "TooFar" or action == "Busy" or action == "Failed" or action == "RequestExpired" or action == "Limit" then
		-- Hide prompt
		frame3.Visible = false

	elseif action == "PromptExpire" or action == "PromptClose" then
		-- Hide prompt
		frame3.Visible = false
	end
end)

-- ========================================
-- CHARACTER RESPAWN HANDLER
-- ========================================

player.CharacterAdded:Connect(function()
	-- Stop all animations
	if sitTrack then 
		sitTrack:Stop(0.1)
		sitTrack = nil
	end

	-- Stop connections
	stopKeepUi()
	stopBlockingJump()

	-- Reset state
	isCarried = false
	currentCarrierId = nil
	currentCarrierName = nil
	carriedList = {}
	carriedIndex = 1
	uiMode = "idle" 

	-- Hide UI
	frame2.Visible = false
	frame3.Visible = false

	-- Reset humanoid properties
	task.wait(1)
	local hum = getHumanoid()
	if hum then
		hum.Sit = false
		hum.PlatformStand = false
		hum.WalkSpeed = 16
	end
end)