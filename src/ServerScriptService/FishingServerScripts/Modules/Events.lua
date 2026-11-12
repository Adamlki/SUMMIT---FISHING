-- Remote wiring: network gateway routes plus cast / cleanup / legacy roll adapters.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))
local State = require(script.Parent.State)
local Rolls = require(script.Parent.Rolls)

local castReplicationEvent = FishingSystem:FindFirstChild("CastReplication")
local cleanupCastEvent = FishingSystem:FindFirstChild("CleanupCast")
local fishGiverEvent = FishingSystem:FindFirstChild("FishGiver")

local Events = {}

-- ponytail: fixed radius; add config if cast visuals need wider range.
local CAST_REPLICATION_RADIUS = 200

local function fireAllClientsExcept(event, excludePlayer, ...)
	local originPart = excludePlayer.Character and excludePlayer.Character:FindFirstChild("HumanoidRootPart")
	if not originPart then
		return
	end

	local origin = originPart.Position
	for _, p in Players:GetPlayers() do
		if p ~= excludePlayer then
			local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if hrp and (hrp.Position - origin).Magnitude <= CAST_REPLICATION_RADIUS then
				event:FireClient(p, ...)
			end
		end
	end
end

local function performCast(player, rodPos, vel, rodName, power)
	if not player or not player:IsDescendantOf(Players) then return end
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	if typeof(rodPos) ~= "Vector3" or typeof(vel) ~= "Vector3" then return end
	if type(rodName) ~= "string" or (power ~= nil and type(power) ~= "number") then return end

	local now = os.clock()
	if State.lastReplicationTime[player] and now - State.lastReplicationTime[player] < 0.2 then return end
	State.lastReplicationTime[player] = now

	-- Register active cast session for authoritative validation
	State.fishingSessions[player] = {
		state = "Casted",
		sessionId = HttpService:GenerateGUID(false),
		castTime = now,
		rodName = rodName,
		power = State.sanitizePower(power)
	}

	fireAllClientsExcept(castReplicationEvent, player, player, rodPos, vel, rodName, power)
end

local function performCleanup(player)
	if not player or not player:IsDescendantOf(Players) then return end
	local now = os.clock()
	if State.lastCleanupTime[player] and now - State.lastCleanupTime[player] < 0.2 then return end
	State.lastCleanupTime[player] = now

	-- H-04 rev2: Grace period - sesi "Casted" tidak dihapus seketika.
	-- Klien mengirim cleanup tepat sebelum roll (roll terjadi setelah minigame selesai),
	-- jadi sesi bertransisi ke "CastedClosed" dan masih boleh di-roll dalam grace window.
	local session = State.fishingSessions[player]
	if session and session.state == "Casted" then
		session.state = "CastedClosed"
		session.closedAt = now
	end
	State.pendingRolls[player] = nil

	fireAllClientsExcept(cleanupCastEvent, player, player)
end

function Events.Install()
	NetworkGateway:RegisterRoute("POST", "/fishing/roll", function(player, payload)
		if type(payload) ~= "table" then
			return State.failureResponse(400, "INVALID_PAYLOAD", "Payload must be a table.")
		end
		return Rolls.handleRollRequest(player, payload.Power, nil, false)
	end, { rateLimitSeconds = State.FISH_COOLDOWN })

	-- Gateway cooldown limits spam; early claims still reach the totalElapsed check after the cooldown.
	NetworkGateway:RegisterRoute("POST", "/fishing/claim", function(player, payload)
		if type(payload) ~= "table" then
			return State.failureResponse(400, "INVALID_PAYLOAD", "Payload must be a table.")
		end
		return Rolls.handleClaimRequest(player, payload.RollId, false)
	end, { rateLimitSeconds = 0.5 })

	NetworkGateway:RegisterRoute("POST", "/fishing/cast", function(player, payload)
		if type(payload) ~= "table"
			or typeof(payload.RodPos) ~= "Vector3"
			or typeof(payload.Velocity) ~= "Vector3"
			or type(payload.RodName) ~= "string"
		then
			return State.failureResponse(400, "INVALID_PAYLOAD", "Cast payload is invalid.")
		end
		performCast(player, payload.RodPos, payload.Velocity, payload.RodName, payload.Power)
		return State.successResponse({})
	end, { rateLimitSeconds = 0.2 })

	NetworkGateway:RegisterRoute("POST", "/fishing/cleanup", function(player)
		performCleanup(player)
		return State.successResponse({})
	end, { rateLimitSeconds = 0.2 })

	-- Dual-stack legacy adapters for old clients.
	castReplicationEvent.OnServerEvent:Connect(function(player, rodPos, vel, rodName, power)
		NetworkGateway:RunLegacy(player, "cast", function()
			performCast(player, rodPos, vel, rodName, power)
		end, 0.2)
	end)

	cleanupCastEvent.OnServerEvent:Connect(function(player)
		NetworkGateway:RunLegacy(player, "cleanup", function()
			performCleanup(player)
		end, 0.2)
	end)

	-- Dual-stack legacy adapter. New clients use NetworkGateway; old clients keep
	-- sending { type = "rollRequest" } and { type = "claim" } through FishGiver.
	fishGiverEvent.OnServerEvent:Connect(function(player, payload)
		NetworkGateway:RunLegacy(player, "fishGiver", function()
			if typeof(payload) ~= "table" then return end

			if payload.type == "rollRequest" then
				Rolls.handleRollRequest(player, payload.power, payload.token, true)
				return
			end

			if payload.type == "claim" then
				Rolls.handleClaimRequest(player, payload.rollId, true)
			end
		end, 0.2)
	end)
end

return Events
