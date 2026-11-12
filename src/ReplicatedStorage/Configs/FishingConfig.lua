-- System by @thehandofvoid
-- Modified by @jay_peaceee
-- FishingConfig - FOOLPROOF VERSION

local FishingConfig = {}
-- ===================================================================
FishingConfig.DatabaseSettings = {enabled = true, warnOnDisabled = true}
FishingConfig.LeaderboardSettings = {enabled = true, showCoins = true, showFishCaught = true, CoinsName = "Coins", fishCaughtName = "FishCaught"}
FishingConfig.InventoryLimitSettings = {enabled = true, maxFishInventory = 500, fullInventoryMessage = "Your fish inventory is full! (500/500) Sell some fish first.", autoSellOldestFish = true}

FishingConfig.SellingSettings = {
	enabled = true, basePricePerKg = 2,
	rarityMultiplier = {Common = 1.0, Uncommon = 2.0, Rare = 4.0, Epic = 8.0, Legendary = 15.0,  Mitos = 14.0, Secret = 30.0},
	enableSizeBonus = true,
	sizeBonus = {
		small = {min = 0, max = 10, multiplier = 0.7},
		medium = {min = 10, max = 50, multiplier = 1.0},
		large = {min = 50, max = 150, multiplier = 1.3},
		huge = {min = 150, max = 999, multiplier = 1.6}
	}
}

-- 🎯 EASY TAP COUNT ADJUSTMENT
FishingConfig.MinigameSettings = {
	progressMin = 8, progressMax = 12, decayMin = 3, decayMax = 7,
	startingProgress = 0.4, fishingTime = 25, decayMultiplier = 25, clickFeedbackDuration = 0.15,

	rodTapCount = {
		["Owner Rod"] = 1, ["Admin Rod"] = 6, ["Developer Rod"] = 7,
		["Umbrella"] = 8, ["Katana"] = 8, ["Corruption Edge"] = 3, ["x1x1x1 Hammer"] = 4,  ["Binary Edge"] = 3, ["Cople x1x1x"] = 3, ["Copblue x1x1x"] = 3, ["Purple Saber"] = 8, ["Megalofriend"] = 9, ["Manifest"] = 10, ["Earthly"] = 11,
		["Pirate Octopus"] = 11, ["LightingPunk Rod"] = 11, ["Frozen Rod"] = 12, ["GhostRod"] = 12,
		["Gold Rod"] = 8, ["Dragon Spine"] = 3, ["Lucky Rod"] = 13, ["Angelic Rod"] = 13,
		["Aqua Prism"] = 11, ["Crystalized"] = 11, ["Forsaken"] = 11, ["ZombieRod"] = 11, ["Loving"] = 11, ["Flery"] = 11,
		["Fluorescent Rod"] = 13, ["Polarized"] = 14, ["Lightning"] = 14,
		["Basic Rod"] = 15, default = 15
	},
	autoModeExtraTaps = 2
}

FishingConfig.TransferSettings = {Enabled = true, RequiredLevel = 1, MaxDistance = 15}

-- ===================================================================
-- ROD STATS - STAFF RODS HAVE HUGE LUCK
-- ===================================================================
FishingConfig.RodConfig = {
	default = {hookName = "BasicHook", beamColor = Color3.fromRGB(106, 106, 106), beamWidth = 0.05, baseLuck = 0.5, maxWeight = 5.0, maxRarity = "Common"},
	["Basic Rod"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(139, 69, 19), beamWidth = 0.04, baseLuck = 1.0, maxWeight = 100.0, maxRarity = "Epic"},
	["Angelic Rod"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(255, 255, 255), beamWidth = 0.04, baseLuck = 1.15, maxWeight = 120.0, maxRarity = "Epic"},
	["Gold Rod"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(255, 205, 50), beamWidth = 0.05, baseLuck = 2.50, maxWeight = 500.0, maxRarity = "Mitos"},
	["Lucky Rod"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(0, 255, 0), beamWidth = 0.04, baseLuck = 1.25, maxWeight = 150.0, maxRarity = "Epic"},
	["Lightning"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(255, 255, 0), beamWidth = 0.04, baseLuck = 1.50, maxWeight = 180.0, maxRarity = "Legendary"},
	["Polarized"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(100, 200, 255), beamWidth = 0.04, baseLuck = 1.60, maxWeight = 200.0, maxRarity = "Legendary"},
	["Fluorescent Rod"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(0, 255, 200), beamWidth = 0.04, baseLuck = 1.70, maxWeight = 220.0, maxRarity = "Legendary"},
	["GhostRod"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(200, 200, 255), beamWidth = 0.04, baseLuck = 1.85, maxWeight = 250.0, maxRarity = "Legendary"},
	["Frozen Rod"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(150, 200, 255), beamWidth = 0.04, baseLuck = 1.90, maxWeight = 250.0, maxRarity = "Legendary"},
	["LightingPunk Rod"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(255, 0, 255), beamWidth = 0.04, baseLuck = 2.00, maxWeight = 280.0, maxRarity = "Legendary"},
	["Pirate Octopus"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(100, 50, 150), beamWidth = 0.04, baseLuck = 2.10, maxWeight = 300.0, maxRarity = "Legendary"},
	["Aqua Prism"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(100, 50, 150), beamWidth = 0.04, baseLuck = 2.10, maxWeight = 300.0, maxRarity = "Legendary"},
	["Flery"] = {hookName = "FleryHook", beamColor = Color3.fromRGB(255, 81, 0), beamWidth = 0.05, baseLuck = 2.10, maxWeight = 300.0, maxRarity = "Legendary", isGamepass = true},
	["Loving"] = {hookName = "LovingHook", beamColor = Color3.fromRGB(255, 23, 236), beamWidth = 0.05, baseLuck = 2.10, maxWeight = 300.0, maxRarity = "Legendary", isGamepass = true},
	["ZombieRod"] = {hookName = "ZombieHook", beamColor = Color3.fromRGB(76, 255, 121), beamWidth = 0.05, baseLuck = 2.10, maxWeight = 300.0, maxRarity = "Legendary", isGamepass = true},
	["Forsaken"] = {hookName = "ForsakenHook", beamColor = Color3.fromRGB(100, 50, 150), beamWidth = 0.05, baseLuck = 2.10, maxWeight = 300.0, maxRarity = "Legendary", isGamepass = true},
	["Crystalized"] = {hookName = "CrystalizedHook", beamColor = Color3.fromRGB(175, 221, 255), beamWidth = 0.05, baseLuck = 2.10, maxWeight = 300.0, maxRarity = "Legendary", isGamepass = true},
	["Earthly"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(139, 69, 19), beamWidth = 0.04, baseLuck = 2.50, maxWeight = 350.0, maxRarity = "Mitos"},
	["Manifest"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(180, 100, 255), beamWidth = 0.04, baseLuck = 3.00, maxWeight = 400.0, maxRarity = "Mitos"},
	["Megalofriend"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(0, 150, 255), beamWidth = 0.04, baseLuck = 3.50, maxWeight = 450.0, maxRarity = "Mitos"},
	["Purple Saber"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(160, 30, 255), beamWidth = 0.04, baseLuck = 4.00, maxWeight = 500.0, maxRarity = "Mitos"},
	["Katana"] = {hookName = "KatanaHook", beamColor = Color3.fromRGB(0, 0, 0), beamWidth = 0.04, baseLuck = 5.00, maxWeight = 650.0, maxRarity = "Secret"},
	["Corruption Edge"] = {hookName = "CorruptionEdgeHook", beamColor = Color3.fromRGB(0, 0, 0), beamWidth = 0.04, baseLuck = 5.00, maxWeight = 650.0, maxRarity = "Secret"},
	["Umbrella"] = {hookName = "UmbrellaHook", beamColor = Color3.fromRGB(255, 70, 215), beamWidth = 0.04, baseLuck = 5.00, maxWeight = 650.0, maxRarity = "Secret", isGamepass = true},
	["x1x1x1 Hammer"] = {hookName = "x1x1x1HammerHook", beamColor = Color3.fromRGB(11, 68, 255), beamWidth = 0.09, baseLuck = 5.00, maxWeight = 650.0, maxRarity = "Secret"},
	["Binary Edge"] = {hookName = "BinaryEdgeHook", beamColor = Color3.fromRGB(0, 190, 60), beamWidth = 0.09, baseLuck = 5.00, maxWeight = 650.0, maxRarity = "Secret"},
	["Cople x1x1x"] = {hookName = "Coplex1x1xHook", beamColor = Color3.fromRGB(127, 0, 159), beamWidth = 0.09, baseLuck = 5.00, maxWeight = 650.0, maxRarity = "Secret"},
	["Copblue x1x1x"] = {hookName = "x1x1x1HammerHook", beamColor = Color3.fromRGB(11, 68, 255), beamWidth = 0.09, baseLuck = 5.00, maxWeight = 650.0, maxRarity = "Secret"},
	["Dragon Spine"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(215, 95, 255), beamWidth = 0.08, baseLuck = 4.20, maxWeight = 2200.0, maxRarity = "Secret"},

	-- STAFF RODS - MASSIVE LUCK
	["Developer Rod"] = {hookName = "DeveloperHook", beamColor = Color3.fromRGB(117, 0, 140), beamWidth = 0.04, baseLuck = 10.0, maxWeight = 1000.0, maxRarity = "Secret"},
	["Admin Rod"] = {hookName = "AdminHook", beamColor = Color3.fromRGB(255, 180, 180), beamWidth = 0.04, baseLuck = 20.0, maxWeight = 2000.0, maxRarity = "Secret"},
	["Owner Rod"] = {hookName = "OwnerHook", beamColor = Color3.fromRGB(255, 213, 0), beamWidth = 0.04, baseLuck = 9999999.0, maxWeight = 10000.0, maxRarity = "Secret"}
}

FishingConfig.Pity = {
	Rare = {maxPity = 250, baseBoost = 0.10, maxMultiplier = 1.25},
	Epic = {maxPity = 500, baseBoost = 0.15, maxMultiplier = 1.30},
	Legendary = {maxPity = 1000, baseBoost = 0.20, maxMultiplier = 1.40},
	Mitos = {maxPity = 1500, baseBoost = 0.25, maxMultiplier = 1.10},
	Secret = {maxPity = 2000, baseBoost = 0.30, maxMultiplier = 1.60}
}

FishingConfig.RarityWeights = {Common = 70, Uncommon = 20, Rare = 7, Epic = 2.5, Legendary = 0.45, Mitos = 0.35, Secret = 0.1}

FishingConfig.FishTable = {
	{name = "Boar Fish", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Mujaer", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Roster Fish", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Cobia", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Goldfish", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Nila Fish", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Cleo Fish", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Bone Fish", probability = 28, minKg = 0.5, maxKg = 45.0, rarity = "Common"}, 
	{name = "Chines Blue Fish", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Chines Fish", probability = 28, minKg = 0.5, maxKg = 45.0, rarity = "Common"},
	{name = "Chines Green Fish", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Puffy Blowhog", probability = 28, minKg = 0.5, maxKg = 45.0, rarity = "Common"},
	{name = "Fish benrtol", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Totol", probability = 28, minKg = 0.5, maxKg = 45.0, rarity = "Common"},
	{name = "Fish Black", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Yellow Fish", probability = 28, minKg = 0.5, maxKg = 45.0, rarity = "Common"},
	{name = "Morning Star", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Nemo", probability = 28, minKg = 0.5, maxKg = 45.0, rarity = "Common"},
	{name = "Blue Fish", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Fish Tipis", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Ular kadut", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Fish gead", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Fish Lake", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Geo Fish", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Udang", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Genetik Fish", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Rock Fish", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Barracuda Fish", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Deep Fish", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Green Fish", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "ArapaimaFish", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Blackcap Basslet", probability = 28, minKg = 0.5, maxKg = 45.0, rarity = "Common"},
	{name = "Pumpkin Carved Shark", probability = 25, minKg = 1.0, maxKg = 60.0, rarity = "Common"},
	{name = "Freshwater Piranha", probability = 25, minKg = 1.0, maxKg = 60.0, rarity = "Common"},
	{name = "Hermit Crab", probability = 22, minKg = 0.8, maxKg = 40.0, rarity = "Common"},
	{name = "GoldenTrout", probability = 20, minKg = 2.0, maxKg = 70.0, rarity = "Common"},
	{name = "Fangtooth", probability = 18, minKg = 1.5, maxKg = 55.0, rarity = "Common"},
	{name = "Dead Spooky Koi Fish", probability = 12, minKg = 5.0, maxKg = 80.0, rarity = "Uncommon"},
	{name = "Dead Scary Clownfish", probability = 10, minKg = 4.0, maxKg = 75.0, rarity = "Uncommon"},
	{name = "Jellyfish", probability = 8, minKg = 3.0, maxKg = 65.0, rarity = "Uncommon"},
	{name = "Lion Fish", probability = 5, minKg = 10.0, maxKg = 120.0, rarity = "Rare"},
	{name = "Luminous Fish", probability = 4, minKg = 12.0, maxKg = 130.0, rarity = "Rare"},
	{name = "Zombie Shark", probability = 3.5, minKg = 20.0, maxKg = 150.0, rarity = "Rare"},
	{name = "Shark", probability = 4, minKg = 15.0, maxKg = 100.0, rarity = "Rare"},
	{name = "Wraithfin Abyssal", probability = 3, minKg = 15.0, maxKg = 140.0, rarity = "Rare"},
	{name = "Ghost Ray", probability = 3, minKg = 15.0, maxKg = 140.0, rarity = "Rare"},
	{name = "Light Dolphin", probability = 3, minKg = 15.0, maxKg = 140.0, rarity = "Rare"},
	{name = "purple Kraken", probability = 3, minKg = 15.0, maxKg = 140.0, rarity = "Rare"},
	{name = "Ghost Fish", probability = 3, minKg = 15.0, maxKg = 140.0, rarity = "Rare"},
	{name = "Loving Shark", probability = 1.5, minKg = 30.0, maxKg = 250.0, rarity = "Epic"},
	{name = "Monster Shark", probability = 1.2, minKg = 35.0, maxKg = 280.0, rarity = "Epic"},
	{name = "Queen Crab", probability = 1.0, minKg = 25.0, maxKg = 220.0, rarity = "Epic"},
	{name = "Pink Dolphin", probability = 0.8, minKg = 40.0, maxKg = 300.0, rarity = "Epic"},
	{name = "Plasma Shark", probability = 0.4, minKg = 80.0, maxKg = 400.0, rarity = "Legendary"},
	{name = "Crimsom Ray", probability = 0.09, minKg = 80.0, maxKg = 400.0, rarity = "Legendary"},
	{name = "Ancient Relic Crocodile", probability = 0.10, minKg = 150.0, maxKg = 600.0, rarity = "Mitos"},
	{name = "Ancient Whale", probability = 0.10, minKg = 200.0, maxKg = 800.0, rarity = "Mitos"},
	{name = "Kraken", probability = 0.15, minKg = 200.0, maxKg = 800.0, rarity = "Mitos"},
	{name = "Sotong", probability = 0.01, minKg = 200.0, maxKg = 800.0, rarity = "Secret"},
	{name = "Sapu Sapu Goib", probability = 0.01, minKg = 200.0, maxKg = 800.0, rarity = "Secret"},
	{name = "Shark Bone", probability = 0.01, minKg = 200.0, maxKg = 800.0, rarity = "Secret"},
	{name = "King Crab", probability = 0.01, minKg = 200.0, maxKg = 800.0, rarity = "Secret"},
	{name = "Naga", probability = 0.011, minKg = 200.0, maxKg = 800.0, rarity = "Secret"},
	{name = "El Maja", probability = 0.01, minKg = 200.0, maxKg = 800.0, rarity = "Secret"},
	{name = "Mega Hunt", probability = 0.011, minKg = 200.0, maxKg = 800.0, rarity = "Secret"},
	{name = "Buaya Hutan", probability = 0.011, minKg = 200.0, maxKg = 800.0, rarity = "Secret"},
	{name = "KingJally Strong", probability = 0.021, minKg = 200.0, maxKg = 800.0, rarity = "Secret"}
}

FishingConfig.RarityColors = {
	Common = Color3.fromRGB(200, 200, 200), Uncommon = Color3.fromRGB(30, 255, 30),
	Rare = Color3.fromRGB(30, 100, 255), Epic = Color3.fromRGB(160, 30, 255),
	Legendary = Color3.fromRGB(255, 128, 0), Mitos = Color3.fromRGB(216, 0, 4), Secret = Color3.fromRGB(83, 255, 255)
}

FishingConfig.rarityOrder = {Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mitos = 6, Secret = 7}

FishingConfig.RoleSettings = {
	Enabled = true, GroupID = 410265215, --> Your Community ID
	RoleRodMapping = {
		["Owner"] = {RankID = 255, RodName = "Owner Rod"},
		["Admin"] = {RankID = 254, RodName = "Admin Rod"},
		["Developer"] = {RankID = 254, RodName = "Developer Rod"}
	}
}

FishingConfig.GamepassEffects = {enabled = false}

-- ===================================================================
-- FUNCTIONS
-- ===================================================================

function FishingConfig.CreatePityTracker()
	return {Rare = 0, Epic = 0, Legendary = 0, Mitos = 0, Secret = 0}
end

function FishingConfig.GetRarityWithPity(pityData, rodName, luckBonus)
	local base = FishingConfig.RarityWeights
	local rodConfig = FishingConfig.GetRodConfig(rodName)
	local maxRarity = rodConfig.maxRarity or "Secret"
	local maxRarityLevel = FishingConfig.rarityOrder[maxRarity] or 7

	luckBonus = luckBonus or rodConfig.baseLuck or 1.0
	local final = {}

	-- 🔥 SUPER STRONG LUCK FORMULA
	-- This makes high luck rods MUCH better at catching rare fish
	for rarity, weight in pairs(base) do
		local rarityLevel = FishingConfig.rarityOrder[rarity] or 1
		local rarityMultiplier = (rarityLevel - 1) / 5 -- 0.0 to 1.0

		-- Different scaling for different luck ranges
		local luckEffect

		if luckBonus <= 5 then
			-- Normal rods (1-5x luck): Linear scaling
			luckEffect = 1 + ((luckBonus - 1) * rarityMultiplier * 5)
		else
			-- High luck rods (5x+): Exponential scaling
			-- Use square root to prevent overflow but keep strong boost
			local scaledLuck = math.sqrt(luckBonus)
			luckEffect = 1 + ((scaledLuck - 1) * rarityMultiplier * 15)
		end

		final[rarity] = weight * luckEffect
	end

	-- Enforce rod limits
	for rarity, level in pairs(FishingConfig.rarityOrder) do
		if level > maxRarityLevel then
			final[rarity] = 0
		end
	end

	-- Apply pity
	for rarity, cfg in pairs(FishingConfig.Pity) do
		local rarityLevel = FishingConfig.rarityOrder[rarity] or 1
		if rarityLevel <= maxRarityLevel and final[rarity] and final[rarity] > 0 then
			local count = pityData[rarity] or 0
			local progress = math.clamp(count / cfg.maxPity, 0, 1)
			local boost = cfg.baseBoost * progress
			local boostedWeight = final[rarity] * (1 + boost)
			final[rarity] = math.min(boostedWeight, final[rarity] * cfg.maxMultiplier)
		end
	end

	-- Weighted random
	local total = 0
	for _, w in pairs(final) do total = total + w end
	if total == 0 then return "Common" end

	local roll = math.random() * total
	for rarity, w in pairs(final) do
		if roll < w then return rarity end
		roll = roll - w
	end
	return "Common"
end

-- =================================================================================
-- 🌟 PERBAIKAN: Menambahkan 'or 0' untuk mencegah kesalahan "attempt to perform arithmetic (add) on number and nil"
-- =================================================================================
function FishingConfig.PickFishFromRarity(rarity)
	local list = {}
	for _, fish in ipairs(FishingConfig.FishTable) do
		if fish.rarity == rarity then table.insert(list, fish) end
	end
	if #list == 0 then
		for _, fish in ipairs(FishingConfig.FishTable) do
			if fish.rarity == "Common" then table.insert(list, fish) end
		end
	end
	if #list == 0 then return nil end

	local totalProb = 0
	-- PERBAIKAN DITERAPKAN DI SINI: memastikan f.probability adalah angka (minimal 0)
	for _, f in ipairs(list) do totalProb = totalProb + (f.probability or 0) end

	local roll = math.random() * totalProb
	for _, f in ipairs(list) do
		local prob = f.probability or 0
		if roll < prob then return f end
		roll = roll - prob
	end
	return list[1]
end
-- =================================================================================

function FishingConfig.RollFish(pityData, rodName, luckBonus)
	pityData = pityData or FishingConfig.CreatePityTracker()
	for rarity in pairs(pityData) do pityData[rarity] = pityData[rarity] + 1 end

	local rarity = FishingConfig.GetRarityWithPity(pityData, rodName, luckBonus)

	local rarityLevel = FishingConfig.rarityOrder[rarity] or 1
	for r, level in pairs(FishingConfig.rarityOrder) do
		if level >= rarityLevel and pityData[r] then pityData[r] = 0 end
	end

	return FishingConfig.PickFishFromRarity(rarity)
end

function FishingConfig.GetRodConfig(rodName)
	return FishingConfig.RodConfig[rodName] or FishingConfig.RodConfig.default
end

function FishingConfig.GetRarityColor(rarity)
	return FishingConfig.RarityColors[rarity] or Color3.fromRGB(255, 255, 255)
end

-- ⚠️ THIS IS THE CRITICAL FUNCTION - LUCK CALCULATION
function FishingConfig.CalculateTotalLuck(baseLuck, powerPercent, player)
	-- 1. Ambil nilai Boost dari ReplicatedStorage
	local repStorage = game:GetService("ReplicatedStorage")
	local luckValObj = repStorage:WaitForChild("FishingSystem"):FindFirstChild("GlobalLuckMultiplier")
	local serverMultiplier = luckValObj and luckValObj.Value or 1.0

	-- 2. Ambil nilai Personal Luck Boost & Gamepass Luck Perks
	local personalMultiplier = 1.0
	local gamepassMultiplier = 1.0
	if player and typeof(player) == "Instance" then
		personalMultiplier = player:GetAttribute("PersonalLuckMultiplier") or 1.0

		-- Gamepass Luck Stacking
		if player:GetAttribute("VIP") == true or player:GetAttribute("IsVIP") == true then
			gamepassMultiplier = gamepassMultiplier * 1.5 -- +50% VIP Luck
		end
		if player:GetAttribute("SmallLuck") == true then
			gamepassMultiplier = gamepassMultiplier * 1.25 -- +25% Small Luck
		end
		if player:GetAttribute("ExtraLuck") == true then
			gamepassMultiplier = gamepassMultiplier * 1.5 -- +50% Extra Luck
		end
		if player:GetAttribute("EdvancedLuck") == true then
			gamepassMultiplier = gamepassMultiplier * 2.0 -- +100% Advanced Luck
		end
	end

	-- 3. Hitung Luck dasar (Rod + Power Bar)
	local powerBonus = baseLuck * (powerPercent * 0.2)
	local rodLuck = baseLuck + powerBonus

	-- 4. Kalikan dengan Server Boost & Personal Luck
	local total = rodLuck * serverMultiplier * personalMultiplier * gamepassMultiplier

	return total, baseLuck, powerBonus
end

function FishingConfig.CanCatchRarity(rodName, fishRarity)
	local rodConfig = FishingConfig.GetRodConfig(rodName)
	local maxRarity = rodConfig.maxRarity or "Secret"
	local rodMaxLevel = FishingConfig.rarityOrder[maxRarity] or 6
	local fishLevel = FishingConfig.rarityOrder[fishRarity] or 1
	return fishLevel <= rodMaxLevel
end

function FishingConfig.GenerateFishWeight(fish, totalLuck, maxRodWeight)
	local minKg = fish.minKg
	local maxKg = math.min(fish.maxKg, maxRodWeight)
	if maxKg < minKg then return minKg end

	local luckFactor = math.clamp(totalLuck / 10.0, 0, 1)
	local randomFactor = math.random()
	local biasedRandom = randomFactor * (1 - luckFactor * 0.3) + (luckFactor * 0.3)
	local fishWeight = minKg + (biasedRandom * (maxKg - minKg))
	return math.floor(fishWeight * 10 + 0.5) / 10
end

function FishingConfig.CalculateFishPrice(weight, rarity)
	local basePricePerKg = FishingConfig.SellingSettings.basePricePerKg
	local rarityMult = FishingConfig.SellingSettings.rarityMultiplier[rarity] or 1.0
	local basePrice = weight * basePricePerKg * rarityMult
	local finalPrice = basePrice

	if FishingConfig.SellingSettings.enableSizeBonus then
		for bonusType, bonusData in pairs(FishingConfig.SellingSettings.sizeBonus) do
			if weight >= bonusData.min and weight < bonusData.max then
				finalPrice = basePrice * bonusData.multiplier
				break
			end
		end
	end
	return math.floor(finalPrice + 0.5)
end

function FishingConfig.HasGamepassEffects(rodName)
	return false
end

function FishingConfig.GetGamepassEffects(rodName)
	return nil
end

function FishingConfig.GetRequiredTaps(rodName, isAutoMode)
	local settings = FishingConfig.MinigameSettings
	local baseTaps = settings.rodTapCount[rodName] or settings.rodTapCount.default
	if isAutoMode then return baseTaps + settings.autoModeExtraTaps end
	return baseTaps
end

return FishingConfig