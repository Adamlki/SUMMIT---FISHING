-- ============================================================
-- Carry/Modules/Visuals (ModuleScript)
-- Scaled carry aura, mini-avatar scaling, and carrier golden trail.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(script.Parent.Config)
local State = require(script.Parent.State)

local Visuals = {}

-- ========================================
-- CARRIED SCALE
-- ========================================

function Visuals.applyCarriedScale(player, char, factor: number?)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local uid = player.UserId
	local scale = factor or Config.CARRY_SCALE_FACTOR
	if not State.savedScales[uid] then
		State.savedScales[uid] = {}
		local scaleProps = {"BodyHeightScale", "BodyWidthScale", "BodyDepthScale", "HeadScale", "BodyProportionScale"}
		for _, sName in ipairs(scaleProps) do
			local val = hum:FindFirstChild(sName)
			if val and val:IsA("NumberValue") then
				State.savedScales[uid][sName] = val.Value
			end
		end
	end
	local orig = State.savedScales[uid]
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

function Visuals.restoreCarriedScale(player, char)
	local uid = player.UserId
	local orig = State.savedScales[uid]
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
	State.savedScales[uid] = nil
end

-- ========================================
-- SCALED AURACARRY EFFECT (0.65x & Zero Delay)
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

function Visuals.applyAuraCarry(char, factor: number?)
	local auraTemplate = ReplicatedStorage:FindFirstChild("AuraCarry")
	if not auraTemplate then return end
	local root = char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local scale = factor or Config.CARRY_SCALE_FACTOR

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

function Visuals.removeAuraCarry(char)
	if not char then return end
	for _, desc in ipairs(char:GetDescendants()) do
		if desc.Name == "ActiveCarryAura" then
			desc:Destroy()
		end
	end
end

-- ========================================
-- CARRIER GOLDEN TRAIL
-- ========================================

function Visuals.removeCarrierGoldenTrail(carrier)
	if not carrier then return end
	local char = carrier.Character
	if not char then return end

	for _, desc in ipairs(char:GetDescendants()) do
		if desc.Name == "CarrierGoldenTrail" or desc.Name == "CarrierTrailTop" or desc.Name == "CarrierTrailBottom" then
			desc:Destroy()
		end
	end
end

function Visuals.applyCarrierGoldenTrail(carrier)
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

return Visuals
