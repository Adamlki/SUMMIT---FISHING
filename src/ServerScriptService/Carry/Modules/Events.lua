-- ============================================================
-- Carry/Modules/Events (ModuleScript)
-- Client-facing Carry/Event payloads via NetworkGateway.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))
local State = require(script.Parent.State)

local Events = {}

function Events.send(player, action, data)
	if not player or not player.Parent then return end
	NetworkGateway:Broadcast("Carry/Event", { Action = action, Data = data }, player)
end

local function buildCarriedList(carrier)
	local list = {}
	local cmap = State.carryingByCarrier[carrier.UserId]
	if cmap then
		for tid, t in pairs(cmap) do table.insert(list, { id = tid, name = t.DisplayName }) end
		table.sort(list, function(a, b) return a.name < b.name end)
	end
	return list
end

function Events.sendCarrierList(carrier)
	Events.send(carrier, "CarrierList", { list = buildCarriedList(carrier) })
end

function Events.sendStart(carrier, target)
	local total = State.countCarried(carrier)
	local carrierPayload = { carrierId = carrier.UserId, carrierName = carrier.DisplayName, targetId = target.UserId, targetName = target.DisplayName, youAreCarrier = true, carrierActiveCount = total }
	local targetPayload = { carrierId = carrier.UserId, carrierName = carrier.DisplayName, targetId = target.UserId, targetName = target.DisplayName, youAreCarrier = false }
	Events.send(carrier, "Start", carrierPayload)
	Events.send(target, "Start", targetPayload)
end

function Events.sendEndForCarrierOnly(carrier, removedTarget, reason)
	local total = State.countCarried(carrier)
	local payload = { reason = reason or "end", youAreCarrier = true, carrierActiveCount = total, removedId = removedTarget.UserId, removedName = removedTarget.DisplayName }
	Events.send(carrier, "End", payload)
end

function Events.sendEndPair(carrier, target, reason)
	local total = State.countCarried(carrier)
	local carrierPayload = { reason = reason or "end", youAreCarrier = true, carrierActiveCount = total, removedId = target.UserId, removedName = target.DisplayName }
	local still = State.countCarried(target)
	local targetPayload = { reason = reason or "end", youAreCarrier = false, yourCarryCount = still }
	Events.send(carrier, "End", carrierPayload)
	Events.send(target, "End", targetPayload)
end

return Events
