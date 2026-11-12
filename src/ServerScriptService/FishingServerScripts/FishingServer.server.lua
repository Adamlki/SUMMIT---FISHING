-- System by @thehandofvoid
-- Modified by @jay_peaceee
-- ServerScriptService/FishingServer - entrypoint; behaviour lives in Modules/.
local ReplicatedStorageService = game:GetService("ReplicatedStorage")
local ReplicatedStorage = ReplicatedStorageService:WaitForChild("FishingSystem")
local Players = game:GetService("Players")

local FeatureFlags = require(game:GetService("ReplicatedStorage"):WaitForChild("Configs"):WaitForChild("FeatureFlags"))
if not FeatureFlags.Fishing then return end

local Modules = script.Parent:WaitForChild("Modules")
local State = require(Modules:WaitForChild("State"))
local PlayerSetup = require(Modules:WaitForChild("PlayerSetup"))
local Events = require(Modules:WaitForChild("Events"))
local Sell = require(Modules:WaitForChild("Sell"))

local cleanupCastEvent = ReplicatedStorage:FindFirstChild("CleanupCast")

Events.Install()
Sell.Install()
PlayerSetup.Start()

Players.PlayerRemoving:Connect(function(player)
	State.clearPlayer(player)

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then cleanupCastEvent:FireClient(otherPlayer, player) end
	end
end)
