-- ============================================================
-- Carry/Modules/State (ModuleScript)
-- Shared carry state tables plus slot/carry lookups and per-player locks.
-- ============================================================

local Config = require(script.Parent.Config)

local State = {}

State.pending = {}
State.carryingByCarrier = {}
State.carriedByTarget = {}
State.slotByCarrier = {}
State.lockMap = {}
State.detachGuard = {}
State.savedProps = {}
State.savedHum = {}
State.savedScales = {}
State.boundChars = setmetatable({}, { __mode = "k" })

-- ========================================
-- LOOKUPS
-- ========================================

function State.getCarryMap(carrier)
	local m = State.carryingByCarrier[carrier.UserId]
	if not m then m = {} State.carryingByCarrier[carrier.UserId] = m end
	return m
end

function State.getSlotMap(carrier)
	local m = State.slotByCarrier[carrier.UserId]
	if not m then m = {} State.slotByCarrier[carrier.UserId] = m end
	return m
end

function State.countCarried(carrier)
	local m = State.carryingByCarrier[carrier.UserId]
	if not m then return 0 end
	local n = 0
	for _ in pairs(m) do n += 1 end
	return n
end

function State.isBeingCarried(p) return State.carriedByTarget[p.UserId] ~= nil end
function State.canCarrierRequest(p) return not State.isBeingCarried(p) end
function State.targetAvailable(p) return not State.isBeingCarried(p) end

-- ========================================
-- LOCK MANAGEMENT
-- ========================================

function State.acquireLock(uid)
	local startTime = os.clock()
	while State.lockMap[uid] do
		if os.clock() - startTime > Config.LOCK_TIMEOUT then
			warn("[CarryServer] Lock timeout for user " .. tostring(uid) .. " - breaking deadlock.")
			State.lockMap[uid] = false
			break
		end
		task.wait(0.05)
	end
	State.lockMap[uid] = true
end

function State.releaseLock(uid)
	State.lockMap[uid] = false
end

function State.acquireLocks(a, b)
	if a == b then State.acquireLock(a) return end
	if a < b then State.acquireLock(a) State.acquireLock(b)
	else State.acquireLock(b) State.acquireLock(a) end
end

function State.releaseLocks(a, b)
	State.releaseLock(a)
	if b ~= a then State.releaseLock(b) end
end

return State
