-- ============================================================
-- Carry/Modules/CarryCore (ModuleScript)
-- Start, slot reindex, pair detach, and passenger transfer.
-- ============================================================

local Players = game:GetService("Players")
local Config = require(script.Parent.Config)
local State = require(script.Parent.State)
local Events = require(script.Parent.Events)
local Visuals = require(script.Parent.Visuals)
local CharacterUtil = require(script.Parent.CharacterUtil)

local SlotOffset = Config.slotOffset
local getCharHRP = CharacterUtil.getCharHRP
local getCarryMap = State.getCarryMap
local getSlotMap = State.getSlotMap
local countCarried = State.countCarried
local canCarrierRequest = State.canCarrierRequest
local targetAvailable = State.targetAvailable

local CarryCore = {}

local function reindexSlots(carrier)
	State.acquireLock(carrier.UserId)
	local ok = pcall(function()
		local _, cHRP = getCharHRP(carrier)
		if not cHRP then return end
		local smap = State.slotByCarrier[carrier.UserId]
		if not smap then return end
		local temp = {}
		for tid, s in pairs(smap) do
			local t = Players:GetPlayerByUserId(tid)
			if t then table.insert(temp, { p = t, s = s }) end
		end
		table.sort(temp, function(a, b) return a.s < b.s end)
		for i, e in ipairs(temp) do
			local tChar, tHRP = getCharHRP(e.p)
			if tHRP then
				if e.s ~= i then
					CharacterUtil.removeCarryWeldBetween(cHRP, tHRP)
					tHRP.CFrame = cHRP.CFrame * SlotOffset(i)
					CharacterUtil.ensureCarryWeldBetween(cHRP, tHRP)
					State.slotByCarrier[carrier.UserId][e.p.UserId] = i
				else
					CharacterUtil.ensureCarryWeldBetween(cHRP, tHRP)
				end
			end
		end
	end)
	State.releaseLock(carrier.UserId)
end

local function detachPair(carrier, target, reason)
	local cUID = carrier.UserId local tUID = target.UserId
	State.acquireLock(cUID)
	local cChar, cHRP = getCharHRP(carrier)
	local tChar, tHRP, tHum = getCharHRP(target)
	if cHRP and tHRP then CharacterUtil.removeCarryWeldBetween(cHRP, tHRP) end

	-- Cleanup Visuals: Scaled Aura & Avatar Scale
	if tChar then
		Visuals.removeAuraCarry(tChar)
		Visuals.restoreCarriedScale(target, tChar)
	end

	if tHum then
		tHum.PlatformStand = false tHum.Sit = false tHum.Jump = false
		CharacterUtil.restoreHumState(tUID, tHum, target.Name)
		task.spawn(function()
			for phase = 1, 3 do
				task.wait(0.1 * phase)
				if not tHum or not tHum.Parent then break end
				tHum.Sit = false tHum.PlatformStand = false
				tHum.WalkSpeed = math.max(tHum.WalkSpeed, 16) tHum.AutoRotate = true tHum.Jump = false
				if tHum.UseJumpPower then tHum.JumpPower = math.max(tHum.JumpPower, 50)
				else tHum.JumpHeight = math.max(tHum.JumpHeight, 7.2) end
				tHum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
				for i = 1, 5 do tHum.Sit = false tHum:ChangeState(Enum.HumanoidStateType.Running) task.wait(0.02) end
			end
		end)
	end
	if tHRP then
		pcall(function()
			tHRP.Anchored = true
			tHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			tHRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			local pos = tHRP.CFrame.Position
			tHRP.CFrame = CFrame.new(pos)
			task.wait(0.05)
			tHRP.Anchored = false
		end)
		CharacterUtil.giveSelfOwnership(target)
	end
	CharacterUtil.restoreCarriedLight(tUID)
	local cmap = State.carryingByCarrier[cUID]
	if cmap then
		cmap[tUID] = nil
		if not next(cmap) then State.carryingByCarrier[cUID] = nil end
	end
	if State.slotByCarrier[cUID] then State.slotByCarrier[cUID][tUID] = nil end
	State.carriedByTarget[tUID] = nil
	State.releaseLock(cUID)
	Events.sendEndPair(carrier, target, reason)
	if countCarried(carrier) == 0 then
		Visuals.removeCarrierGoldenTrail(carrier)
	end
	task.defer(function()
		if State.carryingByCarrier[cUID] then reindexSlots(carrier) end
		Events.sendCarrierList(carrier)
	end)
end

local function detachAllForCarrier(carrier, reason)
	local cmap = State.carryingByCarrier[carrier.UserId]
	if not cmap then return end
	local list = {}
	for _, t in pairs(cmap) do table.insert(list, t) end
	for _, t in ipairs(list) do detachPair(carrier, t, reason) end
	Visuals.removeCarrierGoldenTrail(carrier)
end

local function detachIfAny(p, reason)
	if State.carriedByTarget[p.UserId] then
		detachPair(State.carriedByTarget[p.UserId], p, reason)
	elseif State.carryingByCarrier[p.UserId] then
		detachAllForCarrier(p, reason)
	end
end

local function safeDetachIfAny(p, reason)
	if State.detachGuard[p.UserId] then return end
	State.detachGuard[p.UserId] = true
	task.defer(function()
		detachIfAny(p, reason)
		State.detachGuard[p.UserId] = nil
	end)
end

local function startCarry(carrier, target)
	local cChar, cHRP = getCharHRP(carrier)
	local tChar, tHRP, tHum = getCharHRP(target)
	if not (cChar and cHRP and tChar and tHRP and tHum) then return false, "character missing" end
	State.acquireLock(carrier.UserId)
	local ok, err = pcall(function()
		if (cHRP.Position - tHRP.Position).Magnitude > Config.MAX_DISTANCE then error("too far") end
		if not canCarrierRequest(carrier) then error("busy") end
		if not targetAvailable(target) then error("busy") end
		local extra = countCarried(target)
		if (countCarried(carrier) + 1 + extra) > Config.MAX_CARRY then error("limit_transfer") end
		local used, sm = {}, getSlotMap(carrier)
		for _, idx in pairs(sm) do used[idx] = true end
		local slotIdx
		for i = 1, Config.MAX_CARRY do if not used[i] then slotIdx = i break end end
		if not slotIdx then error("limit") end

		-- Atur posisi berjejer dua kolom di belakang carrier
		tHRP.CFrame = cHRP.CFrame * SlotOffset(slotIdx)
		CharacterUtil.ensureCarryWeldBetween(cHRP, tHRP)
		CharacterUtil.saveHumState(target.UserId, tHum)
		tHum.AutoRotate = false tHum.WalkSpeed = 0
		if tHum.UseJumpPower then tHum.JumpPower = 0 else tHum.JumpHeight = 0 end

		-- ZERO-DRAG PHYSICS ISOLATION:
		-- Set PlatformStand = true agar kalkulasi upright-spring dan ground raycast Humanoid Roblox
		-- dinonaktifkan sepenuhnya. Ini membuat carrier bisa bergerak dan melompat bebas tanpa tertahan!
		tHum.PlatformStand = true
		tHum.Sit = false
		tHum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		tHum.Jump = false

		CharacterUtil.makeCarriedLight(tChar, target.UserId)
		Visuals.applyCarriedScale(target, tChar, Config.CARRY_SCALE_FACTOR)
		Visuals.applyAuraCarry(tChar, Config.CARRY_SCALE_FACTOR)
		CharacterUtil.giveCarrierOwnership(target, carrier)

		getCarryMap(carrier)[target.UserId] = target
		getSlotMap(carrier)[target.UserId] = slotIdx
		State.carriedByTarget[target.UserId] = carrier

		local function bindCleanupForCharacter(char, p, isCarrier)
			local bound = State.boundChars[char]
			if not bound then
				bound = {}
				State.boundChars[char] = bound
			end
			local role = isCarrier and "carrier" or "target"
			if bound[role] then return end
			bound[role] = true

			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.Died:Connect(function()
					if isCarrier then
						local carriedPlayers = State.carryingByCarrier[p.UserId]
						if carriedPlayers then
							for _, carried in pairs(carriedPlayers) do
								local ch = carried.Character
								if ch then
									local chHum = ch:FindFirstChildOfClass("Humanoid")
									if chHum and chHum.Health > 0 then chHum.Health = 0 end
								end
							end
						end
					end
					safeDetachIfAny(p, "death")
				end)
			end
			char.AncestryChanged:Connect(function(_, parent)
				if not parent then safeDetachIfAny(p, "character removed") end
			end)
		end
		bindCleanupForCharacter(cChar, carrier, true)
		bindCleanupForCharacter(tChar, target, false)
		Events.sendStart(carrier, target)
		Visuals.applyCarrierGoldenTrail(carrier)
	end)
	State.releaseLock(carrier.UserId)
	if not ok then return false, tostring(err) end

	if countCarried(target) > 0 then
		local function transferPassengersToAtomic(newCarrier, oldCarrier)
			local oldMap = State.carryingByCarrier[oldCarrier.UserId]
			if not oldMap then return end
			local smapOld = State.slotByCarrier[oldCarrier.UserId] or {}
			local arr = {}
			for tid, t in pairs(oldMap) do table.insert(arr, { t = t, s = smapOld[tid] or 999 }) end
			table.sort(arr, function(a, b) return a.s < b.s end)
			local _, newHRP = getCharHRP(newCarrier)
			local _, oldHRP = getCharHRP(oldCarrier)
			if not newHRP or not oldHRP then return end
			State.acquireLocks(newCarrier.UserId, oldCarrier.UserId)
			for _, entry in ipairs(arr) do
				local t = entry.t
				local tChar2, tHRP2, tHum2 = getCharHRP(t)
				if tChar2 and tHRP2 and tHum2 then
					local used, smNew = {}, getSlotMap(newCarrier)
					for _, idx in pairs(smNew) do used[idx] = true end
					local slotIdx
					for i = 1, Config.MAX_CARRY do if not used[i] then slotIdx = i break end end
					if slotIdx then
						CharacterUtil.removeCarryWeldBetween(oldHRP, tHRP2)
						tHRP2.CFrame = newHRP.CFrame * SlotOffset(slotIdx)
						CharacterUtil.ensureCarryWeldBetween(newHRP, tHRP2)
						tHum2.AutoRotate = false tHum2.WalkSpeed = 0
						if tHum2.UseJumpPower then tHum2.JumpPower = 0 else tHum2.JumpHeight = 0 end
						tHum2.PlatformStand = true
						tHum2.Sit = false
						Visuals.applyCarriedScale(t, tChar2, Config.CARRY_SCALE_FACTOR)
						Visuals.applyAuraCarry(tChar2, Config.CARRY_SCALE_FACTOR)
						CharacterUtil.giveCarrierOwnership(t, newCarrier)
						local oldMap2 = State.carryingByCarrier[oldCarrier.UserId]
						if oldMap2 then
							oldMap2[t.UserId] = nil
							if not next(oldMap2) then State.carryingByCarrier[oldCarrier.UserId] = nil end
						end
						if State.slotByCarrier[oldCarrier.UserId] then State.slotByCarrier[oldCarrier.UserId][t.UserId] = nil end
						getCarryMap(newCarrier)[t.UserId] = t
						getSlotMap(newCarrier)[t.UserId] = slotIdx
						State.carriedByTarget[t.UserId] = newCarrier
						Events.sendEndForCarrierOnly(oldCarrier, t, "transfer")
						Events.sendStart(newCarrier, t)
					end
				end
			end
			State.releaseLocks(newCarrier.UserId, oldCarrier.UserId)
			if State.carryingByCarrier[oldCarrier.UserId] then
				reindexSlots(oldCarrier)
			else
				Visuals.removeCarrierGoldenTrail(oldCarrier)
			end
			Events.sendCarrierList(newCarrier) Events.sendCarrierList(oldCarrier)
		end
		transferPassengersToAtomic(carrier, target)
	end
	Events.sendCarrierList(carrier)
	return true
end

CarryCore.reindexSlots = reindexSlots
CarryCore.detachPair = detachPair
CarryCore.detachAllForCarrier = detachAllForCarrier
CarryCore.detachIfAny = detachIfAny
CarryCore.safeDetachIfAny = safeDetachIfAny
CarryCore.startCarry = startCarry

return CarryCore
