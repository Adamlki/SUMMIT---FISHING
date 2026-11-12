-- FishData - thin facade. Implementation lives in Modules/*; public API must stay unchanged.
local Modules = script.Parent:WaitForChild("Modules")
local Profiles = require(Modules:WaitForChild("Profiles"))
local newScriptSignal = require(Modules:WaitForChild("ScriptSignal"))
local Coins = require(Modules:WaitForChild("Coins"))
local FishInventory = require(Modules:WaitForChild("FishInventory"))
local Rods = require(Modules:WaitForChild("Rods"))
local Trails = require(Modules:WaitForChild("Trails"))
local Session = require(Modules:WaitForChild("Session"))
local Lifecycle = require(Modules:WaitForChild("Lifecycle"))

local GameProfileService = {}
GameProfileService.ProfileLoadedSignal = newScriptSignal()

local TIMEOUT_SECONDS = 15

function GameProfileService:GetProfile(player)
	local profile = Profiles.Profiles[player]
	if profile and profile:IsActive() then
		return profile
	end

	local startTime = os.clock()

	while not (profile and profile:IsActive()) and (os.clock() - startTime < TIMEOUT_SECONDS) do
		task.wait(0.1)
		profile = Profiles.Profiles[player]
	end

	if not (profile and profile:IsActive()) then
		warn(string.format("⚠️ Profile for player %s not loaded after %d seconds!", player.Name, TIMEOUT_SECONDS))
		return nil
	end

	return profile
end

for _, methods in { Coins, FishInventory, Rods, Trails, Session } do
	for name, fn in methods do
		GameProfileService[name] = fn
	end
end

GameProfileService.RegisterBeforeRelease = Lifecycle.RegisterBeforeRelease

Lifecycle.Start(GameProfileService)

return GameProfileService
