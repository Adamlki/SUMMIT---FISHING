-- ============================================================
-- Carry/Modules/Requests (ModuleScript)
-- REST carry routes, pending request expiry, and API payloads.
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))
local Config = require(script.Parent.Config)
local State = require(script.Parent.State)
local Events = require(script.Parent.Events)
local CarryCore = require(script.Parent.CarryCore)
local CharacterUtil = require(script.Parent.CharacterUtil)

local getCharHRP = CharacterUtil.getCharHRP
local startCarry = CarryCore.startCarry
local detachPair = CarryCore.detachPair
local detachIfAny = CarryCore.detachIfAny

local Requests = {}

-- ===================================================================
-- CORE CARRY ACTIONS (REUSABLE BY REST & LEGACY)
-- ===================================================================

local function carrySuccess(data, message)
	return {
		Success = true,
		StatusCode = 200,
		Data = data,
		Message = message or "OK",
	}
end

local function carryFailure(message, data)
	return {
		Success = false,
		StatusCode = 400,
		ErrorCode = "CARRY_FAILED",
		Data = data,
		Message = message,
	}
end

local function hasPendingIncoming(p) return State.pending[p.UserId] ~= nil end
local function hasPendingOutgoing(p)
	for _, info in pairs(State.pending) do if info.requester == p then return true end end
	return false
end

local function requestCarry(player, targetId)
	if type(targetId) ~= "number" then
		return carryFailure("TargetId must be a number.")
	end
	local target = Players:GetPlayerByUserId(targetId)
	if not target or target == player then
		return carryFailure("Target is unavailable.")
	end
	local _, cHRP = getCharHRP(player)
	local _, tHRP = getCharHRP(target)
	if not (cHRP and tHRP) then
		return carryFailure("Character is missing.")
	end
	local distance = (cHRP.Position - tHRP.Position).Magnitude
	if distance > Config.MAX_DISTANCE then
		Events.send(player, "TooFar", { targetId = targetId })
		return carryFailure("Target is too far away.")
	end
	local extra = State.countCarried(target)
	if (State.countCarried(player) + 1 + extra) > Config.MAX_CARRY then
		Events.send(player, "Limit", { max = Config.MAX_CARRY, reason = "transfer" })
		return carryFailure("Carry limit reached.")
	end
	if not State.canCarrierRequest(player) or not State.targetAvailable(target) then
		Events.send(player, "Busy", {})
		return carryFailure("Carrier or target is busy.")
	end
	if hasPendingIncoming(player) or hasPendingOutgoing(player) or State.pending[target.UserId] then
		Events.send(player, "Busy", {})
		return carryFailure("A carry request is already pending.")
	end

	State.pending[target.UserId] = { requester = player, time = os.clock() }
	local promptPayload = { fromId = player.UserId, fromName = player.DisplayName }
	Events.send(target, "Prompt", promptPayload)
	return carrySuccess({ TargetId = targetId }, "Carry request sent.")
end

local function respondCarry(player, requesterId, accept)
	if type(requesterId) ~= "number" then
		return carryFailure("RequesterId must be a number.")
	end
	local requester = Players:GetPlayerByUserId(requesterId)
	if not requester then
		return carryFailure("Requester is unavailable.")
	end
	local pend = State.pending[player.UserId]
	if not pend or pend.requester ~= requester then
		return carryFailure("No pending carry request from this player.")
	end
	State.pending[player.UserId] = nil

	if accept ~= true then
		Events.send(requester, "Declined", { targetId = player.UserId })
		Events.send(player, "PromptClose", {})
		return carrySuccess({ Accepted = false }, "Carry request declined.")
	end

	local ok, err = startCarry(requester, player)
	if not ok then
		if tostring(err) == "limit_transfer" then
			Events.send(requester, "Limit", { max = Config.MAX_CARRY, reason = "transfer" })
			Events.send(player, "Failed", { reason = "limit_transfer" })
		else
			Events.send(requester, "Failed", { reason = err })
			Events.send(player, "Failed", { reason = err })
		end
		return carryFailure("Carry failed: " .. tostring(err), { Reason = tostring(err) })
	end

	return carrySuccess({ Accepted = true }, "Carry started.")
end

local function stopCarry(player, targetId)
	if type(targetId) == "number" then
		local target = Players:GetPlayerByUserId(targetId)
		if target and State.carryingByCarrier[player.UserId] and State.carryingByCarrier[player.UserId][targetId] then
			detachPair(player, target, "stop")
			return carrySuccess({ TargetId = targetId }, "Carry stopped.")
		end
	end

	detachIfAny(player, "stop")
	return carrySuccess(nil, "Carry stopped.")
end

-- ===================================================================
-- REST ROUTES (NETWORK GATEWAY)
-- ===================================================================

function Requests.Start()
	NetworkGateway:RegisterRoute("POST", "/carry/request", function(player, payload)
		if type(payload) ~= "table" or type(payload.TargetId) ~= "number" then
			return carryFailure("TargetId must be a number.")
		end
		return requestCarry(player, payload.TargetId)
	end)

	NetworkGateway:RegisterRoute("POST", "/carry/response", function(player, payload)
		if type(payload) ~= "table" or type(payload.RequesterId) ~= "number" or type(payload.Accept) ~= "boolean" then
			return carryFailure("RequesterId and Accept are required.")
		end
		return respondCarry(player, payload.RequesterId, payload.Accept)
	end)

	NetworkGateway:RegisterRoute("DELETE", "/carry/stop", function(player, payload)
		if payload ~= nil and type(payload) ~= "table" then
			return carryFailure("Payload must be a table.")
		end
		if payload and payload.TargetId ~= nil and type(payload.TargetId) ~= "number" then
			return carryFailure("TargetId must be a number.")
		end
		return stopCarry(player, payload and payload.TargetId)
	end)

	task.spawn(function()
		while true do
			task.wait(2)
			local now = os.clock()
			for targetId, info in pairs(State.pending) do
				if now - info.time > Config.PENDING_TIMEOUT then
					local target = Players:GetPlayerByUserId(targetId)
					if info.requester and info.requester.Parent == Players then
						Events.send(info.requester, "RequestExpired", { targetId = targetId })
						if target then Events.send(target, "PromptExpire", {}) end
					end
					State.pending[targetId] = nil
				end
			end
		end
	end)
end

return Requests
