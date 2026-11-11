-- ReplicatedStorage/FishingSystem/FishingModules/RodVFXManager.luau
-- Manajer Efek Visual (VFX) dan Audio (SFX) Skin Pancing Saat Lempar dan Tarik

local Debris = game:GetService("Debris")
local RepStorage = game:GetService("ReplicatedStorage")
local FishingSystem = RepStorage:WaitForChild("FishingSystem")
local RodVFXConfig = require(FishingSystem:WaitForChild("RodVFXConfig"))

local RodVFXManager = {}
local activeReelEmitters = {}

-- Helper: Posisi Efek di atas air untuk Surface Effect (seperti Corruption Edge)
local function positionSurfaceEffect(effectClone, character, duration)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local distanceInFront = 10
	local heightAboveWater = 1.8
	local hrpCFrame = hrp.CFrame

	local projected = (hrpCFrame * CFrame.new(0, 0, -distanceInFront)).Position
	local finalY = projected.Y

	local CastingSystem = FishingSystem.FishingModules:FindFirstChild("CastingSystem")
	if CastingSystem then
		local CSModule = require(CastingSystem)
		local waterY = CSModule:GetWaterSurfaceY(projected.X, projected.Z)
		if waterY then finalY = waterY + heightAboveWater end
	end

	local baseCFrame = CFrame.new(projected.X, finalY, projected.Z) * (hrpCFrame - hrpCFrame.Position)
	local desiredCFrame = baseCFrame * CFrame.Angles(math.rad(-90), 0, 0)

	if effectClone:IsA("Model") and effectClone.PrimaryPart then
		effectClone:SetPrimaryPartCFrame(desiredCFrame)
	elseif effectClone:IsA("BasePart") then
		effectClone.CFrame = desiredCFrame
	end

	for _, child in ipairs(effectClone:GetDescendants()) do
		if child:IsA("BasePart") then
			child.CanCollide = false
			child.Anchored = true
		end
	end

	Debris:AddItem(effectClone, duration)
end

-- ============================================================================
-- 1. EFEK LEMPAR KAIL (CAST VFX & SFX)
-- ============================================================================
function RodVFXManager:PlayCastVFX(character, rodName, castOrigin)
	if not character then return end
	local theme = RodVFXConfig.GetTheme(rodName)

	-- Cari titik spawn partikel (ujung joran atau tangan kanan)
	local spawnPos = castOrigin
	local rodTool = character:FindFirstChildWhichIsA("Tool")
	local rodPart = rodTool and (rodTool:FindFirstChild("Part") or rodTool:FindFirstChild("Handle") or rodTool.PrimaryPart)
	
	if not spawnPos then
		if rodPart then
			spawnPos = rodPart.Position + rodPart.CFrame.LookVector * 1.5
		else
			local rHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
			spawnPos = rHand and rHand.Position or character:GetPivot().Position
		end
	end

	-- Buat anchor partikal sementara
	local burstAnchor = Instance.new("Part")
	burstAnchor.Name = "RodCastVFXAnchor"
	burstAnchor.Size = Vector3.new(0.1, 0.1, 0.1)
	burstAnchor.Position = spawnPos
	burstAnchor.Transparency = 1
	burstAnchor.CanCollide = false
	burstAnchor.CanTouch = false
	burstAnchor.CanQuery = false
	burstAnchor.Anchored = true
	burstAnchor.Parent = workspace

	-- Buat ParticleEmitter untuk setiap tekstur burst di dalam tema
	local colorSeq = ColorSequence.new(theme.PrimaryColor, theme.SecondaryColor or theme.PrimaryColor)
	for _, textureId in ipairs(theme.BurstTextures or {}) do
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "CastBurst"
		emitter.Texture = textureId
		emitter.Color = colorSeq
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(0.5, 1.2),
			NumberSequenceKeypoint.new(1, 0),
		})
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.8, 0.4),
			NumberSequenceKeypoint.new(1, 1),
		})
		emitter.Speed = theme.BurstSpeed or NumberRange.new(6, 18)
		emitter.Lifetime = theme.BurstLifetime or NumberRange.new(0.2, 0.5)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Drag = 3
		emitter.Rate = 0
		emitter.LightEmission = 0.8
		emitter.LightInfluence = 0.1
		emitter.Enabled = false
		emitter.Parent = burstAnchor

		task.spawn(function()
			emitter:Emit(math.floor((theme.BurstCount or 15) / #theme.BurstTextures))
		end)
	end

	-- Putar Sound Khas Pancing
	if theme.CastSound and theme.CastSound ~= "" then
		local sound = Instance.new("Sound")
		sound.Name = "RodCastSound"
		sound.SoundId = theme.CastSound
		sound.Volume = theme.CastSoundVolume or 0.6
		sound.RollOffMaxDistance = 100
		sound.Parent = burstAnchor
		sound:Play()
	end

	-- Efek Permukaan Air Tambahan (Legacy Corruption Edge & Glitch)
	if theme.HasSurfaceEffect then
		local AssetsFolder = FishingSystem:FindFirstChild("Assets")
		local EffectFolder = AssetsFolder and AssetsFolder:FindFirstChild("Effect")
		local rodEffectTemplate = EffectFolder and EffectFolder:FindFirstChild("EffectCorrupRod")
		if rodEffectTemplate then
			local effectClone = rodEffectTemplate:Clone()
			effectClone.Parent = workspace
			positionSurfaceEffect(effectClone, character, 3.0)
		end
	end

	Debris:AddItem(burstAnchor, 2.0)
end

-- ============================================================================
-- 2. EFEK TARIKAN SENAR (REEL TENSION VFX)
-- ============================================================================
function RodVFXManager:StartReelingVFX(rodPart, rodName)
	if not rodPart or not rodPart:IsA("BasePart") then return end
	self:StopReelingVFX(rodPart)

	local theme = RodVFXConfig.GetTheme(rodName)
	if not theme.ReelTexture then return end

	local att = Instance.new("Attachment")
	att.Name = "ReelTensionAtt"
	att.Position = Vector3.new(0, 0, rodPart.Size.Z / 2)
	att.Parent = rodPart

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "ReelTensionEmitter"
	emitter.Texture = theme.ReelTexture
	emitter.Color = ColorSequence.new(theme.PrimaryColor, theme.SecondaryColor or theme.PrimaryColor)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Speed = NumberRange.new(2, 6)
	emitter.Lifetime = NumberRange.new(0.2, 0.4)
	emitter.Rate = theme.ReelRate or 10
	emitter.SpreadAngle = Vector2.new(45, 45)
	emitter.LightEmission = 0.8
	emitter.LightInfluence = 0.2
	emitter.Parent = att

	activeReelEmitters[rodPart] = att
end

function RodVFXManager:StopReelingVFX(rodPart)
	if rodPart and activeReelEmitters[rodPart] then
		local att = activeReelEmitters[rodPart]
		if att and att.Parent then
			local emitter = att:FindFirstChild("ReelTensionEmitter")
			if emitter then
				emitter.Enabled = false
			end
			Debris:AddItem(att, 0.5)
		end
		activeReelEmitters[rodPart] = nil
	end
end

-- ============================================================================
-- 3. EFEK SUKSES TANGKAP (CATCH FINISH VFX)
-- ============================================================================
function RodVFXManager:PlayCatchSuccessVFX(character, rodName)
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local theme = RodVFXConfig.GetTheme(rodName)
	local anchor = Instance.new("Part")
	anchor.Name = "CatchFinishAnchor"
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.Position = hrp.Position + Vector3.new(0, 1.5, 0)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxassetid://12090248314" -- Star Sparkle
	emitter.Color = ColorSequence.new(theme.PrimaryColor, theme.SecondaryColor or theme.PrimaryColor)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 1.0),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Speed = NumberRange.new(5, 15)
	emitter.Lifetime = NumberRange.new(0.3, 0.6)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.LightEmission = 0.9
	emitter.Rate = 0
	emitter.Parent = anchor

	emitter:Emit(20)
	Debris:AddItem(anchor, 1.0)
end

return RodVFXManager
