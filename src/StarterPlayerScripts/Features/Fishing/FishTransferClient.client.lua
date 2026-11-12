-- System by @thehandofvoid
-- Modified by @jay_peaceee
-- StarterPlayer/StarterPlayerScripts/FishTransferClient

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- == CONFIGURATION ==
local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local FishingConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("FishingConfig"))
local TransferSettings = FishingConfig.TransferSettings
local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))

local MAX_DISTANCE = TransferSettings.MaxDistance
local PROMPT_NAME = "TransferFishPrompt"
local PROMPT_TEXT = "Gift Fish"

-- == GUI REFERENCES ==
local TransferGui
local MainFrame
local Title
local Info
local Timer
local YesButton
local NoButton
local GiftFish
local GiftFishText
local GiftFishAccept
local GiftFishReject

-- Function to refresh GUI references
local function refreshGuiReferences()
	TransferGui = playerGui:WaitForChild("TransferGui")
	MainFrame = TransferGui:WaitForChild("MainFrame")
	Title = MainFrame:WaitForChild("Title")
	Info = MainFrame:WaitForChild("Info")
	Timer = MainFrame:WaitForChild("Timer")
	YesButton = MainFrame:WaitForChild("YesButton")
	NoButton = MainFrame:WaitForChild("NoButton")
	-- GUI lama tidak dipakai selama GiftFish ada; pastikan tidak ikut tampil.
	TransferGui.Enabled = false
	MainFrame.Visible = false

	-- GUI penerima yang dibuat di FishingGui. Fallback ke TransferGui jika belum ada.
	local fishingGui = playerGui:FindFirstChild("FishingGui") or playerGui:WaitForChild("FishingGui", 5)
	GiftFish = fishingGui and fishingGui:FindFirstChild("GiftFish") or nil
	if GiftFish then
		GiftFishText = GiftFish:FindFirstChild("TextLabel")
		local frameBtn = GiftFish:FindFirstChild("FrameBtn")
		GiftFishAccept = frameBtn and frameBtn:FindFirstChild("AcceptButton") or nil
		GiftFishReject = frameBtn and frameBtn:FindFirstChild("RejectButton") or nil
		if GiftFishText and GiftFishAccept and GiftFishReject then
			GiftFish.Visible = false
		else
			GiftFish = nil
			GiftFishText = nil
			GiftFishAccept = nil
			GiftFishReject = nil
		end
	end
end

-- Initial GUI setup
refreshGuiReferences()
MainFrame.Visible = false

-- == REMOTE EVENTS ==
local TransferPrompt = FishingSystem:WaitForChild("TransferPrompt")
local ShowNotification = FishingSystem:WaitForChild("ShowNotification")
local ClientNotification = FishingSystem:FindFirstChild("ClientNotification")

local function toast(message)
	if ClientNotification then
		ClientNotification:Fire(tostring(message), 3, Color3.fromRGB(255, 100, 100))
	end
end

-- == LOCAL STATE ==
local currentEquippedFish = nil
local activePrompts = {} -- {player = {prompt = prompt, connection = RBXScriptConnection}}
local isGuiBusy = false
local currentTransferId = nil
local closeGuiConnection = nil
local yesButtonConnection = nil
local noButtonConnection = nil

-- ===================================================================
-- CORE FUNCTIONS
-- ===================================================================

-- Function to hide GUI
local function closeGui()
	if closeGuiConnection then
		closeGuiConnection:Disconnect()
		closeGuiConnection = nil
	end

	if yesButtonConnection then
		yesButtonConnection:Disconnect()
		yesButtonConnection = nil
	end

	if noButtonConnection then
		noButtonConnection:Disconnect()
		noButtonConnection = nil
	end

	isGuiBusy = false
	currentTransferId = nil
	TransferGui.Enabled = false
	MainFrame.Visible = false
	if GiftFish then
		GiftFish.Visible = false
	end
	YesButton.Visible = true
	NoButton.Text = "No"
end

-- Function to show GUI (for both sender and receiver)
-- data = { title, info, yesText, noText, duration, transferId }
local function showGui(data)
	if isGuiBusy then 
		return 
	end

	isGuiBusy = true
	currentTransferId = data.transferId or nil
	print(string.format("[Transfer] showGui | receiver=%s | giftFish=%s", tostring(data.transferId ~= nil), tostring(GiftFish ~= nil)))

	-- Satu GUI untuk pengirim dan penerima.
	local useGiftFish = GiftFish ~= nil and GiftFishText ~= nil and GiftFishAccept ~= nil and GiftFishReject ~= nil
	if useGiftFish then
		GiftFishText.Text = data.info
		GiftFishAccept.Text = data.yesText or "Accept"
		GiftFishReject.Text = data.noText or "Reject"
		GiftFish.Visible = true
		TransferGui.Enabled = false
		MainFrame.Visible = false
	else
		Title.Text = data.title
		Info.Text = data.info
		YesButton.Text = data.yesText
		NoButton.Text = data.noText or "No"
		YesButton.Visible = (data.yesText ~= "")
		TransferGui.Enabled = true
		MainFrame.Visible = true
		if GiftFish then
			GiftFish.Visible = false
		end
	end

	local startTime = tick()
	local duration = data.duration or 10

	if closeGuiConnection then
		closeGuiConnection:Disconnect()
	end

	-- Timer countdown
	closeGuiConnection = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		local remaining = math.floor(duration - elapsed)

		if remaining <= 0 then
			Timer.Text = "(0s)"
			if currentTransferId then
				NetworkGateway:Request("POST", "/transfer/respond", { TransferId = currentTransferId, Accept = false })
			end
			closeGui()
		else
			Timer.Text = string.format("(%ds)", remaining)
		end
	end)
end

-- Pasang tombol untuk prompt yang sedang aktif.
local function bindGuiButtons(onAccept, onReject)
	if yesButtonConnection then
		yesButtonConnection:Disconnect()
		yesButtonConnection = nil
	end
	if noButtonConnection then
		noButtonConnection:Disconnect()
		noButtonConnection = nil
	end

	local acceptButton = (GiftFish and GiftFishAccept) or YesButton
	local rejectButton = (GiftFish and GiftFishReject) or NoButton
	yesButtonConnection = acceptButton.MouseButton1Click:Connect(onAccept)
	noButtonConnection = rejectButton.MouseButton1Click:Connect(onReject)
end

-- Function to check if a tool is a fish
local function getFishToolData(tool)
	if not tool or not tool:IsA("Tool") then return nil end

	local fishId = tool:FindFirstChild("FishId")
	local weight = tool:FindFirstChild("Weight")
	local rarity = tool:FindFirstChild("Rarity")
	local favorited = tool:FindFirstChild("isFavorited")

	if fishId and weight and rarity then
		return {
			Tool = tool,
			Name = tool.Name,
			Id = fishId.Value,
			Weight = weight.Value,
			Rarity = rarity.Value,
			Favorited = favorited and favorited.Value == true
		}
	end
	return nil
end

-- Forward declarations
local removePrompt
local updateAllPrompts

-- Function to create ProximityPrompt on other players
local function createPromptOnPlayer(targetPlayer)
	local character = targetPlayer.Character
	if not character then return end

	-- Remove old prompt if it exists
	if activePrompts[targetPlayer] then
		removePrompt(targetPlayer)
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT_NAME
	prompt.ObjectText = targetPlayer.Name
	prompt.ActionText = PROMPT_TEXT
	prompt.MaxActivationDistance = MAX_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = hrp

	-- Store connection
	local connection = prompt.Triggered:Connect(function()
		print(string.format("[Transfer] prompt triggered | target=%s | busy=%s", targetPlayer.Name, tostring(isGuiBusy)))
		if not currentEquippedFish or isGuiBusy then 
			return 
		end

		-- Verify the tool still exists
		if not currentEquippedFish.Tool or not currentEquippedFish.Tool.Parent then
			currentEquippedFish = nil
			updateAllPrompts()
			return
		end

		if currentEquippedFish.Favorited then
			toast("Ikan favorit tidak bisa ditransfer. Hapus favorit dulu.")
			return
		end

		-- Show confirmation GUI for SENDER
		showGui({
			title = "Transfer Confirmation",
			info = string.format("Give %s (%.1fkg) to %s?", currentEquippedFish.Name, currentEquippedFish.Weight, targetPlayer.Name),
			yesText = "Give",
			noText = "Cancel",
			duration = 10,
			transferId = nil
		})

		bindGuiButtons(function()
			if currentEquippedFish and currentEquippedFish.Tool and currentEquippedFish.Tool.Parent then
				NetworkGateway:Request("POST", "/transfer/request", { TargetUserId = targetPlayer.UserId, FishId = currentEquippedFish.Id }):andThen(function(res)
					if not (res and res.Success) then
						toast((res and res.Message) or "Transfer gagal dikirim.")
					end
				end)
			end
			closeGui()
		end, closeGui)
	end)

	activePrompts[targetPlayer] = {
		prompt = prompt,
		connection = connection
	}
end

-- Function to remove ProximityPrompt
removePrompt = function(player)
	if activePrompts[player] then
		if activePrompts[player].connection then
			activePrompts[player].connection:Disconnect()
		end
		if activePrompts[player].prompt then
			activePrompts[player].prompt:Destroy()
		end
		activePrompts[player] = nil
	end
end

-- Function to update all prompts
updateAllPrompts = function()
	if currentEquippedFish then
		-- Holding a fish, create prompts
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= localPlayer and player.Character then
				createPromptOnPlayer(player)
			end
		end
	else
		-- Not holding a fish, destroy all prompts
		for player, data in pairs(activePrompts) do
			removePrompt(player)
		end
		activePrompts = {}
	end
end

-- ===================================================================
-- EVENT CONNECTIONS
-- ===================================================================

-- 1. Monitor Equipped Tools
local function onCharacterAdded(character)
	-- Refresh GUI references after respawn
	task.wait(0.1)
	refreshGuiReferences()

	-- Force close GUI and reset all states on respawn
	closeGui()

	-- Clear current fish data on respawn
	currentEquippedFish = nil

	-- Remove ALL old prompts and connections
	for player, data in pairs(activePrompts) do
		removePrompt(player)
	end
	activePrompts = {}

	character.ChildAdded:Connect(function(child)
		local fishData = getFishToolData(child)
		if fishData then
			currentEquippedFish = fishData
			updateAllPrompts()
		end
	end)

	character.ChildRemoved:Connect(function(child)
		if currentEquippedFish and child == currentEquippedFish.Tool then
			currentEquippedFish = nil
			updateAllPrompts()
		end
	end)

	-- Check if already holding a fish on spawn
	task.wait(0.5)
	local currentTool = character:FindFirstChildOfClass("Tool")
	if currentTool then
		local fishData = getFishToolData(currentTool)
		if fishData then
			currentEquippedFish = fishData
			updateAllPrompts()
		end
	end
end

-- 2. Monitor Other Players Joining/Leaving
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		if currentEquippedFish then
			createPromptOnPlayer(player)
		end
	end)

	if player.Character and currentEquippedFish then
		task.wait(1)
		createPromptOnPlayer(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	removePrompt(player)
end)

-- Monitor when other players respawn
for _, player in pairs(Players:GetPlayers()) do
	if player ~= localPlayer then
		player.CharacterAdded:Connect(function()
			removePrompt(player)
			if currentEquippedFish then
				task.wait(1)
				createPromptOnPlayer(player)
			end
		end)
	end
end

-- 3. Monitor Events from Server (For RECEIVER)
TransferPrompt.OnClientEvent:Connect(function(senderPlayer, fishName, fishWeight, transferId)
	print(string.format("[Transfer] prompt received | from=%s | fish=%s | id=%s", senderPlayer.Name, tostring(fishName), tostring(transferId)))

	if isGuiBusy then
		NetworkGateway:Request("POST", "/transfer/respond", { TransferId = transferId, Accept = false })
		return
	end

	showGui({
		title = "Transfer Request",
		info = string.format("%s wants to give %s (%.1fkg).", senderPlayer.DisplayName or senderPlayer.Name, fishName, fishWeight),
		yesText = "Accept",
		noText = "Reject",
		duration = 10,
		transferId = transferId
	})

	bindGuiButtons(function()
		NetworkGateway:Request("POST", "/transfer/respond", { TransferId = currentTransferId, Accept = true }):andThen(function(res)
			if not (res and res.Success) then
				toast((res and res.Message) or "Transfer gagal diterima.")
			end
		end)
		closeGui()
	end, function()
		NetworkGateway:Request("POST", "/transfer/respond", { TransferId = currentTransferId, Accept = false })
		closeGui()
	end)
end)

-- 5. Monitor Notifications from Server
ShowNotification.OnClientEvent:Connect(function(message, duration, color)
	if isGuiBusy then
		closeGui()
	end
end)

-- ===================================================================
-- INITIALIZATION
-- ===================================================================

-- Run for existing character
if localPlayer.Character then
	onCharacterAdded(localPlayer.Character)
end

-- Run for character spawns
localPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Setup for all existing players
for _, player in pairs(Players:GetPlayers()) do
	if player ~= localPlayer and player.Character then
		player.CharacterAdded:Connect(function()
			removePrompt(player)
			if currentEquippedFish then
				task.wait(1)
				createPromptOnPlayer(player)
			end
		end)
	end
end