-- ============================================================
-- CarryServer (Script)
-- Lokasi: ServerScriptService > JooyssKaellModules > CarryServer
-- SUMMITKIT PREMIUM V1 - MULTI-CARRY & ZERO-DRAG PHYSICS UPGRADE
-- Features:
-- 1. Dual-Column Parallel Formation (X = ±1.8, Z = 2.0 + row * 2.0, Float Y = 1.2)
-- 2. Proportional 0.65x Mini Avatar Scaling with safe restoration
-- 3. Dynamic Scaled AuraCarry (0.65x Particle Size & Attachment Offset) + Instant Frame 1 Burst
-- 4. Complete Physics Isolation (PlatformStand = true, Massless = true, Zero Ground-Drag on Jump)
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_NAME = "CarryRemote"
local CarryRemote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if not CarryRemote then
	CarryRemote = Instance.new("RemoteEvent")
	CarryRemote.Name = REMOTE_NAME
	CarryRemote.Parent = ReplicatedStorage
end

-- ========================================
-- CONFIGURATION: DUAL-COLUMN PARALLEL FORMATION
-- ========================================

local PENDING_TIMEOUT = 10
local MAX_DISTANCE = 25
local MAX_CARRY = 35
local CARRY_SCALE_FACTOR = 0.65

-- Formasi Sejajar Dua Kolom (Pasangan Kanan & Kiri):
-- Baris 1: Kanan (X=+1.8, Z=2.0) & Kiri (X=-1.8, Z=2.0)
-- Baris 2: Kanan (X=+1.8, Z=4.0) & Kiri (X=-1.8, Z=4.0)
-- Baris N: Kanan (X=+1.8, Z=2.0+(N-1)*2.0) & Kiri (X=-1.8, Z=2.0+(N-1)*2.0)
local BASE_Z = 2.0
local ROW_SPACING_Z = 2.0
local SIDE_OFFSET_X = 1.8
local FLOAT_Y = 1.2

local function slotOffset(i: number): CFrame
	local zeroIndex = i - 1
	local row = math.floor(zeroIndex / 2)
	local isRight = (zeroIndex % 2 == 0)
	local x = isRight and SIDE_OFFSET_X or -SIDE_OFFSET_X
	local z = BASE_Z + row * ROW_SPACING_Z
	return CFrame.new(x, FLOAT_Y, z)
end

-- ========================================
-- STATE TRACKING
-- ========================================

local pending = {}
local carryingByCarrier = {}
local carriedByTarget = {}
local slotByCarrier = {}
local lockMap = {}
local detachGuard = {}
local savedProps = {}
local savedHum = {}
local savedScales = {}
local boundChars = setmetatable({}, { __mode = "k" })

-- ========================================
-- HELPER FUNCTIONS - CHARACTER & SCALE
-- ========================================

local function getCharHRP(p)
	local char = p.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) then return end
	return char, hrp, hum
end

local function applyCarriedScale(player, char, factor: number?)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local uid = player.UserId
	local scale = factor or CARRY_SCALE_FACTOR
	if not savedScales[uid] then
		savedScales[uid] = {}
		local scaleProps = {"BodyHeightScale", "BodyWidthScale", "BodyDepthScale", "HeadScale", "BodyProportionScale"}
		for _, sName in ipairs(scaleProps) do
			local val = hum:FindFirstChild(sName)
			if val and val:IsA("NumberValue") then
				savedScales[uid][sName] = val.Value
			end
		end
	end
	local orig = savedScales[uid]
	local foundScale = false
	for sName, origVal in pairs(orig) do
		local val = hum:FindFirstChild(sName)
		if val and val:IsA("NumberValue") then
			val.Value = origVal * scale
			foundScale = true
		end
	end
	if not foundScale then
		pcall(function() char:ScaleTo(scale) end)
	end
end

local function restoreCarriedScale(player, char)
	local uid = player.UserId
	local orig = savedScales[uid]
	if not orig then return end
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local foundScale = false
	if hum then
		for sName, origVal in pairs(orig) do
			local val = hum:FindFirstChild(sName)
			if val and val:IsA("NumberValue") then
				val.Value = origVal
				foundScale = true
			end
		end
	end
	if not foundScale and char then
		pcall(function() char:ScaleTo(1.0) end)
	end
	savedScales[uid] = nil
end

-- ========================================
-- HELPER FUNCTIONS - SCALED AURACARRY EFFECT (0.65x & Zero Delay)
-- ========================================

local function scaleNumberSequence(seq: NumberSequence, factor: number): NumberSequence
	local kps = {}
	for _, kp in ipairs(seq.Keypoints) do
		table.insert(kps, NumberSequenceKeypoint.new(
			kp.Time,
			kp.Value * factor,
			kp.Envelope * factor
		))
	end
	return NumberSequence.new(kps)
end

local function applyAuraCarry(char, factor: number?)
	local auraTemplate = ReplicatedStorage:FindFirstChild("AuraCarry")
	if not auraTemplate then return end
	local root = char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local scale = factor or CARRY_SCALE_FACTOR

	-- Bersihkan aura carry lama jika ada
	for _, desc in ipairs(char:GetDescendants()) do
		if desc.Name == "ActiveCarryAura" then
			desc:Destroy()
		end
	end

	-- Clone seluruh emitter partikel dan attachment dengan skala proporsional
	for _, item in ipairs(auraTemplate:GetChildren()) do
		if item:IsA("ParticleEmitter") then
			local clone = item:Clone()
			clone.Name = "ActiveCarryAura"
			clone.Size = scaleNumberSequence(clone.Size, scale)
			clone.Speed = NumberRange.new(clone.Speed.Min * scale, clone.Speed.Max * scale)
			clone.Parent = root
			-- INSTANT BURST: Emit partikel langsung pada frame 1 agar tidak delay!
			clone:Emit(math.max(2, math.floor(clone.Rate * 0.5)))
		elseif item:IsA("Attachment") then
			local clone = item:Clone()
			clone.Name = "ActiveCarryAura"
			clone.Position = clone.Position * scale
			for _, childEmitter in ipairs(clone:GetChildren()) do
				if childEmitter:IsA("ParticleEmitter") then
					childEmitter.Size = scaleNumberSequence(childEmitter.Size, scale)
					childEmitter.Speed = NumberRange.new(childEmitter.Speed.Min * scale, childEmitter.Speed.Max * scale)
					childEmitter:Emit(math.max(2, math.floor(childEmitter.Rate * 0.5)))
				end
			end
			clone.Parent = root
		end
	end
end

local function removeAuraCarry(char)
	if not char then return end
	for _, desc in ipairs(char:GetDescendants()) do
		if desc.Name == "ActiveCarryAura" then
			desc:Destroy()
		end
	end
end

-- ========================================
-- CARRIER GOLDEN TRAIL VISUALS
-- ========================================

local function removeCarrierGoldenTrail(carrier)
	if not carrier then return end
	local char = carrier.Character
	if not char then return end

	for _, desc in ipairs(char:GetDescendants()) do
		if desc.Name == "CarrierGoldenTrail" or desc.Name == "CarrierTrailTop" or desc.Name == "CarrierTrailBottom" then
			desc:Destroy()
		end
	end
end

local function applyCarrierGoldenTrail(carrier)
	if not carrier then return end
	local char = carrier.Character
	if not char then return end

	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
	if not torso then return end

	-- Cegah duplikasi jika sudah terpasang
	if torso:FindFirstChild("CarrierGoldenTrail") then return end

	-- Titik jangkar atas & bawah di belakang torso (Z = -0.25)
	local attTop = Instance.new("Attachment")
	attTop.Name = "CarrierTrailTop"
	attTop.Position = Vector3.new(0, 0.75, -0.25)
	attTop.Parent = torso

	local attBottom = Instance.new("Attachment")
	attBottom.Name = "CarrierTrailBottom"
	attBottom.Position = Vector3.new(0, -0.75, -0.25)
	attBottom.Parent = torso

	local trail = Instance.new("Trail")
	trail.Name = "CarrierGoldenTrail"
	trail.Attachment0 = attTop
	trail.Attachment1 = attBottom
	trail.Color = ColorSequence.new(
		Color3.fromRGB(255, 231, 120),
		Color3.fromRGB(255, 183, 20)
	)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.6, 0.5),
		NumberSequenceKeypoint.new(1.0, 1.0)
	})
	trail.Lifetime = 0.45
	trail.LightEmission = 1.0
	trail.LightInfluence = 0.0
	trail.FaceCamera = true
	trail.MinLength = 0.1
	trail.Parent = torso
end

-- ========================================
-- LOCK MANAGEMENT
-- ========================================

local LOCK_TIMEOUT = 3.0

local function acquireLock(uid)
	local startTime = os.clock()
	while lockMap[uid] do
		if os.clock() - startTime > LOCK_TIMEOUT then
			warn("[CarryServer] Lock timeout for user " .. tostring(uid) .. " - breaking deadlock.")
			lockMap[uid] = false
			break
		end
		task.wait(0.05)
	end
	lockMap[uid] = true
end

local function releaseLock(uid)
	lockMap[uid] = false
end

local function acquireLocks(a, b)
	if a == b then acquireLock(a) return end
	if a < b then acquireLock(a) acquireLock(b)
	else acquireLock(b) acquireLock(a) end
end

local function releaseLocks(a, b)
	releaseLock(a)
	if b ~= a then releaseLock(b) end
end

local function getCarryMap(carrier)
	local m = carryingByCarrier[carrier.UserId]
	if not m then m = {} carryingByCarrier[carrier.UserId] = m end
	return m
end

local function getSlotMap(carrier)
	local m = slotByCarrier[carrier.UserId]
	if not m then m = {} slotByCarrier[carrier.UserId] = m end
	return m
end

local function countCarried(carrier)
	local m = carryingByCarrier[carrier.UserId]
	if not m then return 0 end
	local n = 0
	for _ in pairs(m) do n += 1 end
	return n
end

local function isBeingCarried(p) return carriedByTarget[p.UserId] ~= nil end
local function canCarrierRequest(p) return not isBeingCarried(p) end
local function targetAvailable(p) return not isBeingCarried(p) end

local function saveHumState(uid, hum)
	savedHum[uid] = {
		ws = hum.WalkSpeed, useJP = hum.UseJumpPower, jp = hum.JumpPower,
		jh = hum.JumpHeight, autoRotate = hum.AutoRotate,
		jumpEnabled = hum:GetStateEnabled(Enum.HumanoidStateType.Jumping),
		platformStand = hum.PlatformStand,
	}
end

local function forceHumanoidMovement(hum, playerName)
	if not hum or not hum.Parent then return end
	hum.Sit = false hum.PlatformStand = false hum.Jump = false
	for i = 1, 8 do
		if not hum.Parent then break end
		hum.Sit = false hum.PlatformStand = false hum.Jump = false
		hum:ChangeState(Enum.HumanoidStateType.Running)
		task.wait(0.05)
		if not hum.Sit and not hum.PlatformStand then break end
	end
	task.spawn(function()
		task.wait(0.3)
		if hum and hum.Parent then
			hum.Sit = false hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.Running)
		end
	end)
end

local function restoreHumState(uid, hum, playerName)
	local st = savedHum[uid]
	if st then
		hum.WalkSpeed = math.max(st.ws, 16) hum.AutoRotate = st.autoRotate
		hum.PlatformStand = false
		if st.useJP then hum.JumpPower = st.jp else hum.JumpHeight = st.jh end
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, st.jumpEnabled)
		savedHum[uid] = nil
	else
		hum.WalkSpeed = 16 hum.AutoRotate = true hum.PlatformStand = false
		if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end
	task.spawn(function() forceHumanoidMovement(hum, playerName) end)
end

local function makeCarriedLight(char, userId)
	local map = {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") then
			map[d] = { cc = d.CanCollide, ml = d.Massless, ct = d.CanTouch, cq = d.CanQuery }
			d.CanCollide = false
			d.Massless = true
			d.CanTouch = false
			d.CanQuery = false
		end
	end
	savedProps[userId] = map
end

local function restoreCarriedLight(userId)
	local map = savedProps[userId]
	if not map then return end
	for part, st in pairs(map) do
		if part and part.Parent then
			part.CanCollide = st.cc
			part.Massless = st.ml
			if st.ct ~= nil then part.CanTouch = st.ct end
			if st.cq ~= nil then part.CanQuery = st.cq end
		end
	end
	savedProps[userId] = nil
end

local function setHRPOwnerTo(p, owner)
	local _, hrp = getCharHRP(p)
	if not hrp then return end
	pcall(function()
		if owner then hrp:SetNetworkOwner(owner) else hrp:SetNetworkOwnershipAuto() end
	end)
end

local function giveSelfOwnership(p) setHRPOwnerTo(p, p) end
local function giveCarrierOwnership(target, carrier)
	-- M-02 Fix: Set network ownership to server (nil) so carrier client cannot manipulate target physics
	setHRPOwnerTo(target, nil)
end

local function clearCarryWeldsForChar(char)
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		for _, w in ipairs(hrp:GetChildren()) do
			if w:IsA("WeldConstraint") and w.Name == "CarryWeld" then w:Destroy() end
		end
	end
end

local function findCarryWeldBetween(targetHRP, carrierHRP)
	for _, w in ipairs(targetHRP:GetChildren()) do
		if w:IsA("WeldConstraint") and w.Name == "CarryWeld" and w.Part0 == carrierHRP and w.Part1 == targetHRP then
			return w
		end
	end
	return nil
end

local function ensureCarryWeldBetween(carrierHRP, targetHRP)
	local w = findCarryWeldBetween(targetHRP, carrierHRP)
	if not w then
		w = Instance.new("WeldConstraint")
		w.Name = "CarryWeld" w.Part0 = carrierHRP w.Part1 = targetHRP w.Parent = targetHRP
	end
	return w
end

local function removeCarryWeldBetween(carrierHRP, targetHRP)
	local w = findCarryWeldBetween(targetHRP, carrierHRP)
	if w then w:Destroy() end
end

local function buildCarriedList(carrier)
	local list = {}
	local cmap = carryingByCarrier[carrier.UserId]
	if cmap then
		for tid, t in pairs(cmap) do table.insert(list, { id = tid, name = t.DisplayName }) end
		table.sort(list, function(a, b) return a.name < b.name end)
	end
	return list
end

local function sendCarrierList(carrier)
	CarryRemote:FireClient(carrier, "CarrierList", { list = buildCarriedList(carrier) })
end

local function reindexSlots(carrier)
	acquireLock(carrier.UserId)
	local ok = pcall(function()
		local _, cHRP = getCharHRP(carrier)
		if not cHRP then return end
		local smap = slotByCarrier[carrier.UserId]
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
					removeCarryWeldBetween(cHRP, tHRP)
					tHRP.CFrame = cHRP.CFrame * slotOffset(i)
					ensureCarryWeldBetween(cHRP, tHRP)
					slotByCarrier[carrier.UserId][e.p.UserId] = i
				else
					ensureCarryWeldBetween(cHRP, tHRP)
				end
			end
		end
	end)
	releaseLock(carrier.UserId)
end

local function sendStart(carrier, target)
	local total = countCarried(carrier)
	CarryRemote:FireClient(carrier, "Start", { carrierId = carrier.UserId, carrierName = carrier.DisplayName, targetId = target.UserId, targetName = target.DisplayName, youAreCarrier = true, carrierActiveCount = total })
	CarryRemote:FireClient(target, "Start", { carrierId = carrier.UserId, carrierName = carrier.DisplayName, targetId = target.UserId, targetName = target.DisplayName, youAreCarrier = false })
end

local function sendEndForCarrierOnly(carrier, removedTarget, reason)
	local total = countCarried(carrier)
	CarryRemote:FireClient(carrier, "End", { reason = reason or "end", youAreCarrier = true, carrierActiveCount = total, removedId = removedTarget.UserId, removedName = removedTarget.DisplayName })
end

local function sendEndPair(carrier, target, reason)
	local total = countCarried(carrier)
	CarryRemote:FireClient(carrier, "End", { reason = reason or "end", youAreCarrier = true, carrierActiveCount = total, removedId = target.UserId, removedName = target.DisplayName })
	local still = countCarried(target)
	CarryRemote:FireClient(target, "End", { reason = reason or "end", youAreCarrier = false, yourCarryCount = still })
end

local function detachPair(carrier, target, reason)
	local cUID = carrier.UserId local tUID = target.UserId
	acquireLock(cUID)
	local cChar, cHRP = getCharHRP(carrier)
	local tChar, tHRP, tHum = getCharHRP(target)
	if cHRP and tHRP then removeCarryWeldBetween(cHRP, tHRP) end

	-- Cleanup Visuals: Scaled Aura & Avatar Scale
	if tChar then
		removeAuraCarry(tChar)
		restoreCarriedScale(target, tChar)
	end

	if tHum then
		tHum.PlatformStand = false tHum.Sit = false tHum.Jump = false
		restoreHumState(tUID, tHum, target.Name)
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
		giveSelfOwnership(target)
	end
	restoreCarriedLight(tUID)
	local cmap = carryingByCarrier[cUID]
	if cmap then
		cmap[tUID] = nil
		if not next(cmap) then carryingByCarrier[cUID] = nil end
	end
	if slotByCarrier[cUID] then slotByCarrier[cUID][tUID] = nil end
	carriedByTarget[tUID] = nil
	releaseLock(cUID)
	sendEndPair(carrier, target, reason)
	if countCarried(carrier) == 0 then
		removeCarrierGoldenTrail(carrier)
	end
	task.defer(function()
		if carryingByCarrier[cUID] then reindexSlots(carrier) end
		sendCarrierList(carrier)
	end)
end

local function detachAllForCarrier(carrier, reason)
	local cmap = carryingByCarrier[carrier.UserId]
	if not cmap then return end
	local list = {}
	for _, t in pairs(cmap) do table.insert(list, t) end
	for _, t in ipairs(list) do detachPair(carrier, t, reason) end
	removeCarrierGoldenTrail(carrier)
end

local function detachIfAny(p, reason)
	if carriedByTarget[p.UserId] then
		detachPair(carriedByTarget[p.UserId], p, reason)
	elseif carryingByCarrier[p.UserId] then
		detachAllForCarrier(p, reason)
	end
end

local function safeDetachIfAny(p, reason)
	if detachGuard[p.UserId] then return end
	detachGuard[p.UserId] = true
	task.defer(function()
		detachIfAny(p, reason)
		detachGuard[p.UserId] = nil
	end)
end

task.spawn(function()
	while true do
		task.wait(2)
		local now = os.clock()
		for targetId, info in pairs(pending) do
			if now - info.time > PENDING_TIMEOUT then
				local target = Players:GetPlayerByUserId(targetId)
				if info.requester and info.requester.Parent == Players then
					CarryRemote:FireClient(info.requester, "RequestExpired", { targetId = targetId })
					if target then CarryRemote:FireClient(target, "PromptExpire", {}) end
				end
				pending[targetId] = nil
			end
		end
	end
end)

local function hasPendingIncoming(p) return pending[p.UserId] ~= nil end
local function hasPendingOutgoing(p)
	for _, info in pairs(pending) do if info.requester == p then return true end end
	return false
end

local function startCarry(carrier, target)
	local cChar, cHRP = getCharHRP(carrier)
	local tChar, tHRP, tHum = getCharHRP(target)
	if not (cChar and cHRP and tChar and tHRP and tHum) then return false, "character missing" end
	acquireLock(carrier.UserId)
	local ok, err = pcall(function()
		if (cHRP.Position - tHRP.Position).Magnitude > MAX_DISTANCE then error("too far") end
		if not canCarrierRequest(carrier) then error("busy") end
		if not targetAvailable(target) then error("busy") end
		local extra = countCarried(target)
		if (countCarried(carrier) + 1 + extra) > MAX_CARRY then error("limit_transfer") end
		local used, sm = {}, getSlotMap(carrier)
		for _, idx in pairs(sm) do used[idx] = true end
		local slotIdx
		for i = 1, MAX_CARRY do if not used[i] then slotIdx = i break end end
		if not slotIdx then error("limit") end

		-- Atur posisi berjejer dua kolom di belakang carrier
		tHRP.CFrame = cHRP.CFrame * slotOffset(slotIdx)
		ensureCarryWeldBetween(cHRP, tHRP)
		saveHumState(target.UserId, tHum)
		tHum.AutoRotate = false tHum.WalkSpeed = 0
		if tHum.UseJumpPower then tHum.JumpPower = 0 else tHum.JumpHeight = 0 end

		-- ZERO-DRAG PHYSICS ISOLATION:
		-- Set PlatformStand = true agar kalkulasi upright-spring dan ground raycast Humanoid Roblox
		-- dinonaktifkan sepenuhnya. Ini membuat carrier bisa bergerak dan melompat bebas tanpa tertahan!
		tHum.PlatformStand = true
		tHum.Sit = false
		tHum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		tHum.Jump = false

		makeCarriedLight(tChar, target.UserId)
		applyCarriedScale(target, tChar, CARRY_SCALE_FACTOR)
		applyAuraCarry(tChar, CARRY_SCALE_FACTOR)
		giveCarrierOwnership(target, carrier)

		getCarryMap(carrier)[target.UserId] = target
		getSlotMap(carrier)[target.UserId] = slotIdx
		carriedByTarget[target.UserId] = carrier

		local function bindCleanupForCharacter(char, p, isCarrier)
			local bound = boundChars[char]
			if not bound then
				bound = {}
				boundChars[char] = bound
			end
			local role = isCarrier and "carrier" or "target"
			if bound[role] then return end
			bound[role] = true

			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.Died:Connect(function()
					if isCarrier then
						local carriedPlayers = carryingByCarrier[p.UserId]
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
		sendStart(carrier, target)
		applyCarrierGoldenTrail(carrier)
	end)
	releaseLock(carrier.UserId)
	if not ok then return false, tostring(err) end

	if countCarried(target) > 0 then
		local function transferPassengersToAtomic(newCarrier, oldCarrier)
			local oldMap = carryingByCarrier[oldCarrier.UserId]
			if not oldMap then return end
			local smapOld = slotByCarrier[oldCarrier.UserId] or {}
			local arr = {}
			for tid, t in pairs(oldMap) do table.insert(arr, { t = t, s = smapOld[tid] or 999 }) end
			table.sort(arr, function(a, b) return a.s < b.s end)
			local _, newHRP = getCharHRP(newCarrier)
			local _, oldHRP = getCharHRP(oldCarrier)
			if not newHRP or not oldHRP then return end
			acquireLocks(newCarrier.UserId, oldCarrier.UserId)
			for _, entry in ipairs(arr) do
				local t = entry.t
				local tChar2, tHRP2, tHum2 = getCharHRP(t)
				if tChar2 and tHRP2 and tHum2 then
					local used, smNew = {}, getSlotMap(newCarrier)
					for _, idx in pairs(smNew) do used[idx] = true end
					local slotIdx
					for i = 1, MAX_CARRY do if not used[i] then slotIdx = i break end end
					if slotIdx then
						removeCarryWeldBetween(oldHRP, tHRP2)
						tHRP2.CFrame = newHRP.CFrame * slotOffset(slotIdx)
						ensureCarryWeldBetween(newHRP, tHRP2)
						tHum2.AutoRotate = false tHum2.WalkSpeed = 0
						if tHum2.UseJumpPower then tHum2.JumpPower = 0 else tHum2.JumpHeight = 0 end
						tHum2.PlatformStand = true
						tHum2.Sit = false
						applyCarriedScale(t, tChar2, CARRY_SCALE_FACTOR)
						applyAuraCarry(tChar2, CARRY_SCALE_FACTOR)
						giveCarrierOwnership(t, newCarrier)
						local oldMap2 = carryingByCarrier[oldCarrier.UserId]
						if oldMap2 then
							oldMap2[t.UserId] = nil
							if not next(oldMap2) then carryingByCarrier[oldCarrier.UserId] = nil end
						end
						if slotByCarrier[oldCarrier.UserId] then slotByCarrier[oldCarrier.UserId][t.UserId] = nil end
						getCarryMap(newCarrier)[t.UserId] = t
						getSlotMap(newCarrier)[t.UserId] = slotIdx
						carriedByTarget[t.UserId] = newCarrier
						sendEndForCarrierOnly(oldCarrier, t, "transfer")
						sendStart(newCarrier, t)
					end
				end
			end
			releaseLocks(newCarrier.UserId, oldCarrier.UserId)
			if carryingByCarrier[oldCarrier.UserId] then
				reindexSlots(oldCarrier)
			else
				removeCarrierGoldenTrail(oldCarrier)
			end
			sendCarrierList(newCarrier) sendCarrierList(oldCarrier)
		end
		transferPassengersToAtomic(carrier, target)
	end
	sendCarrierList(carrier)
	return true
end

CarryRemote.OnServerEvent:Connect(function(player, action, data)
	if action == "Request" then
		local targetId = data and data.targetId
		if type(targetId) ~= "number" then return end
		local target = Players:GetPlayerByUserId(targetId)
		if not target or target == player then return end
		local _, cHRP = getCharHRP(player) local _, tHRP = getCharHRP(target)
		if not (cHRP and tHRP) then return end
		local distance = (cHRP.Position - tHRP.Position).Magnitude
		if distance > MAX_DISTANCE then CarryRemote:FireClient(player, "TooFar", { targetId = targetId }) return end
		local extra = countCarried(target)
		if (countCarried(player) + 1 + extra) > MAX_CARRY then CarryRemote:FireClient(player, "Limit", { max = MAX_CARRY, reason = "transfer" }) return end
		if not canCarrierRequest(player) or not targetAvailable(target) then CarryRemote:FireClient(player, "Busy", {}) return end
		if hasPendingIncoming(player) or hasPendingOutgoing(player) or pending[target.UserId] then CarryRemote:FireClient(player, "Busy", {}) return end
		pending[target.UserId] = { requester = player, time = os.clock() }
		CarryRemote:FireClient(target, "Prompt", { fromId = player.UserId, fromName = player.DisplayName })
	elseif action == "Response" then
		local accept = data and data.accept == true
		local requesterId = data and data.requesterId
		if type(requesterId) ~= "number" then return end
		local requester = Players:GetPlayerByUserId(requesterId)
		if not requester then return end
		local pend = pending[player.UserId]
		if not pend or pend.requester ~= requester then return end
		pending[player.UserId] = nil
		if not accept then
			CarryRemote:FireClient(requester, "Declined", { targetId = player.UserId })
			CarryRemote:FireClient(player, "PromptClose", {}) return
		end
		local ok2, err2 = startCarry(requester, player)
		if not ok2 then
			if tostring(err2) == "limit_transfer" then
				CarryRemote:FireClient(requester, "Limit", { max = MAX_CARRY, reason = "transfer" })
				CarryRemote:FireClient(player, "Failed", { reason = "limit_transfer" })
			else
				CarryRemote:FireClient(requester, "Failed", { reason = err2 })
				CarryRemote:FireClient(player, "Failed", { reason = err2 })
			end
		end
	elseif action == "Stop" then
		local targetId = data and data.targetId
		if type(targetId) == "number" then
			local t = Players:GetPlayerByUserId(targetId)
			if t and carryingByCarrier[player.UserId] and carryingByCarrier[player.UserId][targetId] then
				detachPair(player, t, "stop") return
			end
		end
		detachIfAny(player, "stop")
	end
end)

local function onCharacterAdded(p, char)
	safeDetachIfAny(p, "respawn")
	removeCarrierGoldenTrail(p)
	task.defer(function()
		task.wait(0.5)
		clearCarryWeldsForChar(char)
		removeAuraCarry(char)
		restoreCarriedScale(p, char)
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Sit = false hum.AutoRotate = true hum.WalkSpeed = 16
			hum.PlatformStand = false hum.Jump = false
			if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
			hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			task.spawn(function()
				for phase = 1, 4 do
					task.wait(0.1 * phase)
					if not hum or not hum.Parent then break end
					hum.Sit = false hum.PlatformStand = false hum.AutoRotate = true
					hum.WalkSpeed = math.max(hum.WalkSpeed, 16)
					for i = 1, 8 do hum.Sit = false hum:ChangeState(Enum.HumanoidStateType.Running) task.wait(0.02) end
				end
			end)
		end
		savedProps[p.UserId] = nil savedHum[p.UserId] = nil
		giveSelfOwnership(p)
	end)
end

Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function(char) onCharacterAdded(p, char) end)
end)

Players.PlayerRemoving:Connect(function(p)
	pending[p.UserId] = nil
	detachIfAny(p, "left")
	removeCarrierGoldenTrail(p)
	lockMap[p.UserId] = nil
	detachGuard[p.UserId] = nil
	savedProps[p.UserId] = nil
	savedHum[p.UserId] = nil
	savedScales[p.UserId] = nil
	carryingByCarrier[p.UserId] = nil
	carriedByTarget[p.UserId] = nil
	slotByCarrier[p.UserId] = nil
end)
