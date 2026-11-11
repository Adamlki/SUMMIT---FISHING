--!strict
-- ReplicatedStorage/AssetSpoofRegistry
-- Centralized registry for Game Animations and Sounds.
-- Set Spoofed > 0 to override every mapped instance at once.
-- All IDs below were verified to load in this place.

local AssetSpoofRegistry = {}

AssetSpoofRegistry.Animations = {
	-- Fishing System Character Animations
	Fishing_Equipped = {
		Name = "idle pegang rod",
		Original = 137321204416073,
		Spoofed = 0,
		TargetPaths = {
			"ReplicatedStorage.FishingSystem.Assets.Animations.Fishing.EquippedAnimation",
		}
	},
	Fishing_Pulling = {
		Name = "ReelR",
		Original = 124778325863079,
		Spoofed = 0,
		TargetPaths = {
			"ReplicatedStorage.FishingSystem.Assets.Animations.Fishing.PullingAnimation",
		}
	},
	Fishing_Waiting = {
		Name = "idle mancing rod",
		Original = 133775745467785,
		Spoofed = 0,
		TargetPaths = {
			"ReplicatedStorage.FishingSystem.Assets.Animations.Fishing.WaitingAnimation",
		}
	},

	-- Fish hold animation (shared by all fish tools with HoldAnimation)
	Fish_HoldAll = {
		Name = "Fish Hold Anim - semua fish",
		Original = 123780353220282,
		Spoofed = 91644346061926,
		TargetFolder = "ReplicatedStorage.FishingSystem.Assets.Fish",
	},
	Fish_HoldingBig = {
		Name = "Fish Hold Big",
		Original = 86351780374642,
		Spoofed = 0,
		TargetPaths = {
			"ReplicatedStorage.FishingSystem.Assets.Animations.Other.HoldingBig",
		}
	},
}

AssetSpoofRegistry.Sounds = {
	Fishing_Cast = { Name = "Fishing Rod Cast", Original = 119135010875996, Spoofed = 0, TargetPaths = { "ReplicatedStorage.FishingSystem.Assets.Sound.Cast" } },
	Fishing_HookHit = { Name = "HookHit - fishing", Original = 136842548633207, Spoofed = 0, TargetPaths = { "ReplicatedStorage.FishingSystem.Assets.Sound.HookHit" } },
	Fishing_Reeling = { Name = "Fishing Rod Reel", Original = 79404754846319, Spoofed = 0, TargetPaths = { "ReplicatedStorage.FishingSystem.Assets.Sound.Reeling" } },
	Fishing_Success = { Name = "coin_pickup_3", Original = 4612375051, Spoofed = 0, TargetPaths = { "ReplicatedStorage.FishingSystem.Assets.Sound.Success" } },
	Fishing_Tap = { Name = "MouseEnter pop", Original = 340910329, Spoofed = 0, TargetPaths = { "ReplicatedStorage.FishingSystem.Assets.Sound.Tap" } },
	Fishing_Lightning = { Name = "Lightning Rare", Original = 5650258743, Spoofed = 0, TargetPaths = { "ReplicatedStorage.FishingSystem.Assets.Sound.RareCatchSound" } },
	Fishing_Electric = { Name = "Electric Sound", Original = 6340511690, Spoofed = 0, TargetPaths = { "ReplicatedStorage.FishingSystem.Assets.Sound.Listrik" } },
	Fishing_Explosion = { Name = "Fire_Explosion", Original = 6650544248, Spoofed = 0, TargetPaths = { "ReplicatedStorage.FishingSystem.Assets.Sound.Soundeffectrod" } },
	UI_Lucky = { Name = "Booster 2", Original = 5599544923, Spoofed = 0, TargetPaths = { "ReplicatedStorage.luckysound" } },
}

-- Returns the active ID for an animation key (Spoofed if set, otherwise Original)
function AssetSpoofRegistry.GetAnimationId(key: string): string
	local entry = AssetSpoofRegistry.Animations[key]
	if entry then
		local id = (entry.Spoofed and entry.Spoofed > 0) and entry.Spoofed or entry.Original
		return "rbxassetid://" .. tostring(id)
	end
	return ""
end

-- Returns the active ID for a sound key
function AssetSpoofRegistry.GetSoundId(key: string): string
	local entry = AssetSpoofRegistry.Sounds[key]
	if entry then
		local id = (entry.Spoofed and entry.Spoofed > 0) and entry.Spoofed or entry.Original
		return "rbxassetid://" .. tostring(id)
	end
	return ""
end

-- Applies all spoofed IDs to physical instances in Explorer
function AssetSpoofRegistry.ApplyToAll(): number
	local appliedCount = 0

	local function resolveInstance(path: string): Instance?
		local parts = string.split(path, ".")
		local cur: Instance? = game
		for _, part in ipairs(parts) do
			if cur then
				cur = cur:FindFirstChild(part)
			else
				break
			end
		end
		return cur
	end

	for _, data in pairs(AssetSpoofRegistry.Animations) do
		if data.Spoofed and data.Spoofed > 0 then
			local newId = "rbxassetid://" .. tostring(data.Spoofed)
			if data.TargetPaths then
				for _, path in ipairs(data.TargetPaths) do
					local inst = resolveInstance(path)
					if inst and inst:IsA("Animation") then
						inst.AnimationId = newId
						appliedCount += 1
					end
				end
			end
			if data.TargetFolder then
				local folder = resolveInstance(data.TargetFolder)
				if folder then
					for _, child in ipairs(folder:GetChildren()) do
						local anim = child:FindFirstChild("HoldAnimation")
						if anim and anim:IsA("Animation") then
							anim.AnimationId = newId
							appliedCount += 1
						end
					end
				end
			end
		end
	end

	for _, data in pairs(AssetSpoofRegistry.Sounds) do
		if data.Spoofed and data.Spoofed > 0 then
			local newId = "rbxassetid://" .. tostring(data.Spoofed)
			if data.TargetPaths then
				for _, path in ipairs(data.TargetPaths) do
					local inst = resolveInstance(path)
					if inst and inst:IsA("Sound") then
						inst.SoundId = newId
						appliedCount += 1
					end
				end
			end
		end
	end

	return appliedCount
end

pcall(function()
	AssetSpoofRegistry.ApplyToAll()
end)

return AssetSpoofRegistry
