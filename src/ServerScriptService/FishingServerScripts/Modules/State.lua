-- Shared mutable state, constants and response helpers for FishingServer.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FishingConfig = require(ReplicatedStorage:WaitForChild("FishingSystem"):WaitForChild("FishingConfig"))
local AntiCheatConfig = require(game:GetService("ServerScriptService"):WaitForChild("Configs"):WaitForChild("AntiCheatConfig"))
local FishingLimits = AntiCheatConfig.Fishing

local State = {}

State.SERVER_ID = game.JobId
if State.SERVER_ID == "" then
	State.SERVER_ID = "Studio_" .. tostring(math.random(1000000, 9999999))
end

State.FISH_COOLDOWN = FishingLimits.FishCooldownSeconds
State.GRANT_MIN_INTERVAL = FishingLimits.GrantMinIntervalSeconds
State.MIN_MINIGAME_DURATION = FishingLimits.MinMinigameDurationSeconds -- Anti-bot: minimum reel time
State.PENDING_ROLL_TIMEOUT = FishingLimits.PendingRollTimeoutSeconds

-- Per-player cooldown / session tables (cleared on PlayerRemoving)
State.lastFishTime = {}
State.lastReplicationTime = {}
State.lastCleanupTime = {}
State.lastSellBatchTime = {}
State.lastGrantTime = {}
State.playerPity = {}
State.pendingRolls = {}
State.fishingSessions = {} -- H-04: Server-authoritative fishing state machine (Idle -> Casted -> Rolling -> Reeling -> Claimed)
State.rollIdCounter = 0

State.fishDefs = {}
for _, def in ipairs(FishingConfig.FishTable) do
	State.fishDefs[def.name] = def
end

function State.successResponse(data)
	return { Success = true, StatusCode = 200, Data = data }
end

function State.failureResponse(statusCode, errorCode, message)
	return { Success = false, StatusCode = statusCode, ErrorCode = errorCode, Message = message }
end

function State.sanitizePower(power)
	local p = tonumber(power)
	if not p or p ~= p then return 1 end
	return math.clamp(p, 0, 1)
end

function State.getPityTracker(player)
	local pity = State.playerPity[player]
	if not pity then
		pity = FishingConfig.CreatePityTracker()
		State.playerPity[player] = pity
	end
	return pity
end

function State.clearPlayer(player)
	State.fishingSessions[player] = nil
	State.lastFishTime[player] = nil
	State.lastReplicationTime[player] = nil
	State.lastCleanupTime[player] = nil
	State.lastSellBatchTime[player] = nil
	State.lastGrantTime[player] = nil
	State.playerPity[player] = nil
	State.pendingRolls[player] = nil
end

return State
