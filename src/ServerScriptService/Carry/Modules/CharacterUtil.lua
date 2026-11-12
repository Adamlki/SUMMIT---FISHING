-- ============================================================
-- Carry/Modules/CharacterUtil (ModuleScript)
-- Character lookups, humanoid state save/restore, physics props, and welds.
-- ============================================================

local State = require(script.Parent.State)

local CharacterUtil = {}

function CharacterUtil.getCharHRP(p)
	local char = p.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) then return end
	return char, hrp, hum
end

-- ========================================
-- HUMANOID STATE
-- ========================================

function CharacterUtil.saveHumState(uid, hum)
	State.savedHum[uid] = {
		ws = hum.WalkSpeed, useJP = hum.UseJumpPower, jp = hum.JumpPower,
		jh = hum.JumpHeight, autoRotate = hum.AutoRotate,
		jumpEnabled = hum:GetStateEnabled(Enum.HumanoidStateType.Jumping),
		platformStand = hum.PlatformStand,
	}
end

function CharacterUtil.forceHumanoidMovement(hum, playerName)
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

function CharacterUtil.restoreHumState(uid, hum, playerName)
	local st = State.savedHum[uid]
	if st then
		hum.WalkSpeed = math.max(st.ws, 16) hum.AutoRotate = st.autoRotate
		hum.PlatformStand = false
		if st.useJP then hum.JumpPower = st.jp else hum.JumpHeight = st.jh end
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, st.jumpEnabled)
		State.savedHum[uid] = nil
	else
		hum.WalkSpeed = 16 hum.AutoRotate = true hum.PlatformStand = false
		if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end
	task.spawn(function() CharacterUtil.forceHumanoidMovement(hum, playerName) end)
end

-- ========================================
-- PHYSICS ISOLATION
-- ========================================

function CharacterUtil.makeCarriedLight(char, userId)
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
	State.savedProps[userId] = map
end

function CharacterUtil.restoreCarriedLight(userId)
	local map = State.savedProps[userId]
	if not map then return end
	for part, st in pairs(map) do
		if part and part.Parent then
			part.CanCollide = st.cc
			part.Massless = st.ml
			if st.ct ~= nil then part.CanTouch = st.ct end
			if st.cq ~= nil then part.CanQuery = st.cq end
		end
	end
	State.savedProps[userId] = nil
end

-- ========================================
-- NETWORK OWNERSHIP
-- ========================================

local function setHRPOwnerTo(p, owner)
	local _, hrp = CharacterUtil.getCharHRP(p)
	if not hrp then return end
	pcall(function()
		if owner then hrp:SetNetworkOwner(owner) else hrp:SetNetworkOwnershipAuto() end
	end)
end

function CharacterUtil.giveSelfOwnership(p) setHRPOwnerTo(p, p) end

function CharacterUtil.giveCarrierOwnership(target, carrier)
	-- M-02 Fix: Set network ownership to server (nil) so carrier client cannot manipulate target physics
	setHRPOwnerTo(target, nil)
end

-- ========================================
-- CARRY WELDS
-- ========================================

function CharacterUtil.clearCarryWeldsForChar(char)
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

function CharacterUtil.ensureCarryWeldBetween(carrierHRP, targetHRP)
	local w = findCarryWeldBetween(targetHRP, carrierHRP)
	if not w then
		w = Instance.new("WeldConstraint")
		w.Name = "CarryWeld" w.Part0 = carrierHRP w.Part1 = targetHRP w.Parent = targetHRP
	end
	return w
end

function CharacterUtil.removeCarryWeldBetween(carrierHRP, targetHRP)
	local w = findCarryWeldBetween(targetHRP, carrierHRP)
	if w then w:Destroy() end
end

return CharacterUtil
