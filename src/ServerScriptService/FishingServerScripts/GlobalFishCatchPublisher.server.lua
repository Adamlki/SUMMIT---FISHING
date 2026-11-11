-- Place in ServerScriptService
-- GlobalFishPublisher - Relay only: receives Secret catches published by servers

local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local SendChatMessage = FishingSystem:WaitForChild("SendChatMessage")

local TOPIC_NAME = "GlobalFishCatch"

local function onGlobalCatchReceived(message)
	local data = message.Data
	if not data or not data.SenderName or not data.FishName or not data.Weight or not data.Rarity then
		print("[GlobalFish] Incomplete data")
		return
	end

	if data.Rarity ~= "Secret" then return end

	SendChatMessage:FireAllClients("Global", data.SenderName, data.FishName, data.Weight, data.Rarity)
end

local success, err = pcall(function()
	MessagingService:SubscribeAsync(TOPIC_NAME, onGlobalCatchReceived)
end)

if not success then warn("[GlobalFish] Failed to subscribe:", err) end

print("[GlobalFish] Publisher relay ready")
