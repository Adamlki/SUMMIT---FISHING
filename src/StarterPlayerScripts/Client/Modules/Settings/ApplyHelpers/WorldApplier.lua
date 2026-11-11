--!nonstrict
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local WorldApplier = {}

function WorldApplier.setOverheadVisibility(enabledTitle)
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		if char then
			local overhead = char:FindFirstChild("Overhead")
			local custom = char:FindFirstChild("CustomTitle")
			if overhead and overhead:IsA("BillboardGui") then
				overhead.Enabled = enabledTitle
			end
			if custom and custom:IsA("BillboardGui") then
				custom.Enabled = enabledTitle
			end
		end
	end
end

function WorldApplier.setPlayersVisibility(showPlayers)
	local lp = Players.LocalPlayer
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp then
			local char = plr.Character
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.LocalTransparencyModifier = showPlayers and 0 or 1
					elseif part:IsA("Decal") then
						part.Transparency = showPlayers and 0 or 1
					end
				end
			end
		end
	end
end

function WorldApplier.applyEffectsFlags(values)
	local disableEffects = values.Effect
	local disableBlur = values.Blur
	local disableShadow = values.Shadow
	for _, inst in ipairs(Lighting:GetChildren()) do
		if inst:IsA("BlurEffect") or inst:IsA("DepthOfFieldEffect") then
			inst.Enabled = not disableBlur
		elseif inst:IsA("BloomEffect") or inst:IsA("ColorCorrectionEffect") or inst:IsA("SunRaysEffect") then
			inst.Enabled = not disableEffects
		end
	end

	local function toggleEnabled(inst, shouldDisable)
		if inst:GetAttribute("Settings_OrigEnabled") == nil then
			inst:SetAttribute("Settings_OrigEnabled", inst.Enabled)
		end
		if shouldDisable then
			inst.Enabled = false
		else
			local orig = inst:GetAttribute("Settings_OrigEnabled")
			if typeof(orig) == "boolean" then
				inst.Enabled = orig
			end
		end
	end

	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("ParticleEmitter")
			or inst:IsA("Beam")
			or inst:IsA("Trail")
			or inst:IsA("Fire")
			or inst:IsA("Smoke")
			or inst:IsA("Sparkles")
			or inst:IsA("PointLight")
			or inst:IsA("SpotLight")
			or inst:IsA("SurfaceLight") then
			toggleEnabled(inst, disableEffects)
		end
	end
	Lighting.GlobalShadows = not disableShadow
end

return WorldApplier
