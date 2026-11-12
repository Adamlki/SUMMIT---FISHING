--!strict
-- ShopMasterConfig: Centralized Store Configuration for Easy Maintenance
-- Edit this file directly to adjust item names, tiers, coin/robux prices, and stats.
-- All UI labels and server purchase validation automatically consume this module.

local MonetizationConfig = require(script.Parent:WaitForChild("MonetizationConfig"))

export type RodMasterInfo = {
	Name: string,
	Tier: string,
	TierColor: Color3,
	CoinPrice: number,
	RobuxPrice: number,
	LuckPercent: number,
	SpeedPercent: number,
	MaxWeightKg: number,
	Type: string,
	GamePassId: number?,
	ProductId: number?,
	TextureId: string?,
}

export type TrailMasterInfo = {
	Id: string,
	FrameName: string,
	Name: string,
	Tier: string,
	TierColor: Color3,
	SpeedBonus: number,
	CoinPrice: number,
	RobuxPrice: number,
	PartName: string,
	ProductId: number?,
}

local ShopMasterConfig = {
	-- ===================================================================
	-- 1. EXCLUSIVE STORE CONFIGURATION
	-- ===================================================================
	Exclusive = {
		-- Server Luck Progressive Stacking (1x to 5x max, with live countdown and auto-reset)
		ServerLuck = {
			MaxPurchases = 5,
			DurationSeconds = 1800, -- 30 minutes
			Tiers = {
				[1] = { Multiplier = 2, Display = "X30 > X60", RobuxPrice = 50, ProductId = MonetizationConfig.ServerLuckBoost.ProductIds[1] },
				[2] = { Multiplier = 4, Display = "X60 > X120", RobuxPrice = 100, ProductId = MonetizationConfig.ServerLuckBoost.ProductIds[2] },
				[3] = { Multiplier = 8, Display = "X120 > X240", RobuxPrice = 200, ProductId = MonetizationConfig.ServerLuckBoost.ProductIds[3] },
				[4] = { Multiplier = 16, Display = "X240 > X480", RobuxPrice = 400, ProductId = MonetizationConfig.ServerLuckBoost.ProductIds[4] },
				[5] = { Multiplier = 32, Display = "X480 > X960", RobuxPrice = 800, ProductId = MonetizationConfig.ServerLuckBoost.ProductIds[5] },
			}
		},

		-- Luck Gamepasses (ListLuckFrame)
		LuckPasses = {
			["EdvancedLuck"] = {
				FrameName = "EdvancedLuckFrame",
				Title = "Edvanced Luck",
				Subtitle = "+150% Luck",
				RobuxPrice = 199,
				PassId = MonetizationConfig.LuckPasses.EdvancedLuck,
				BoostPercent = 150,
			},
			["ExtraLuck"] = {
				FrameName = "ExtraLuckFrame",
				Title = "Extra Luck",
				Subtitle = "+50% Luck",
				RobuxPrice = 99,
				PassId = MonetizationConfig.LuckPasses.ExtraLuck,
				BoostPercent = 50,
			},
			["SmallLuck"] = {
				FrameName = "SmallLuckFrame",
				Title = "Small Luck",
				Subtitle = "+30% Luck",
				RobuxPrice = 49,
				PassId = MonetizationConfig.LuckPasses.SmallLuck,
				BoostPercent = 30,
			},
			["MoreMutations"] = {
				FrameName = "MoreMutationsFrame",
				Title = "More Mutations",
				Subtitle = "+60% Mutations",
				RobuxPrice = 149,
				PassId = MonetizationConfig.LuckPasses.MoreMutations,
				BoostPercent = 60,
			},
		},

		-- Remote Sell Bag (RemoteSellFrame)
		RemoteSell = {
			Title = "Remote Sell",
			Subtitle = "Sell all fish directly from your bag!",
			RobuxPrice = 149,
			PassId = MonetizationConfig.RemoteSell.GamePassId,
		},

		-- Balanced Anti-Inflation Coin Packs (ListCoinFrame)
		CoinPacks = {
			["SmallCoin"] = {
				FrameName = "SmallCoinFrame",
				Title = "Small Coins",
				Display = "+10.000 Coins",
				Coins = 10000,
				RobuxPrice = 25,
				ProductId = MonetizationConfig.CoinPacks.SmallCoin,
			},
			["MediumCoin"] = {
				FrameName = "MediunCoinFrame",
				Title = "Medium Coins",
				Display = "+50.000 Coins",
				Coins = 50000,
				RobuxPrice = 99,
				ProductId = MonetizationConfig.CoinPacks.MediumCoin,
			},
			["LargeCoin"] = {
				FrameName = "LargeCoinFrame",
				Title = "Large Coins",
				Display = "+150.000 Coins",
				Coins = 150000,
				RobuxPrice = 249,
				ProductId = MonetizationConfig.CoinPacks.LargeCoin,
			},
			["ExtraLargeCoin"] = {
				FrameName = "ExtraLargeCoinFrame",
				Title = "Extra Large Coins",
				Display = "+500.000 Coins",
				Coins = 500000,
				RobuxPrice = 699,
				ProductId = MonetizationConfig.CoinPacks.ExtraLargeCoin,
			},
		},

		-- VIP Pack (VIPPackFrame)
		VIP = {
			Title = "VIP Pack",
			RobuxPrice = 499,
			PassId = MonetizationConfig.VIP.GamePassId,
			Rewards = {
				ChatTag = "[VIP]",
				ChatTagColor = Color3.fromRGB(255, 200, 0),
				Trail = "GreenTrail",
				Rod = "Gold Rod", -- Gold Rod is the official VIP Rod
			}
		}
	},

	-- ===================================================================
	-- 2. RODS CATALOG (30 Player Rods - Sorted by Price / Power)
	-- ===================================================================
	Rods = {
		{ Name = "Basic Rod", Tier = "Common", TierColor = Color3.fromRGB(160, 175, 195), CoinPrice = 500, RobuxPrice = 15, LuckPercent = 100, SpeedPercent = 25, MaxWeightKg = 100, Type = "Currency", TextureId = "" },
		{ Name = "Angelic Rod", Tier = "Uncommon", TierColor = Color3.fromRGB(80, 255, 120), CoinPrice = 1000, RobuxPrice = 25, LuckPercent = 115, SpeedPercent = 35, MaxWeightKg = 120, Type = "Currency", TextureId = "" },
		{ Name = "Lucky Rod", Tier = "Uncommon", TierColor = Color3.fromRGB(80, 255, 120), CoinPrice = 2500, RobuxPrice = 49, LuckPercent = 125, SpeedPercent = 35, MaxWeightKg = 150, Type = "Currency", TextureId = "" },
		{ Name = "Aqua Prism", Tier = "Rare", TierColor = Color3.fromRGB(60, 160, 255), CoinPrice = 3500, RobuxPrice = 59, LuckPercent = 135, SpeedPercent = 45, MaxWeightKg = 160, Type = "Currency", TextureId = "" },
		{ Name = "Lightning", Tier = "Rare", TierColor = Color3.fromRGB(60, 160, 255), CoinPrice = 5000, RobuxPrice = 79, LuckPercent = 150, SpeedPercent = 30, MaxWeightKg = 180, Type = "Currency", TextureId = "" },
		{ Name = "Polarized", Tier = "Rare", TierColor = Color3.fromRGB(60, 160, 255), CoinPrice = 7500, RobuxPrice = 99, LuckPercent = 160, SpeedPercent = 30, MaxWeightKg = 200, Type = "Currency", TextureId = "" },
		{ Name = "Fluorescent Rod", Tier = "Epic", TierColor = Color3.fromRGB(160, 30, 255), CoinPrice = 10000, RobuxPrice = 129, LuckPercent = 170, SpeedPercent = 35, MaxWeightKg = 220, Type = "Currency", TextureId = "" },
		{ Name = "GhostRod", Tier = "Epic", TierColor = Color3.fromRGB(160, 30, 255), CoinPrice = 12500, RobuxPrice = 149, LuckPercent = 185, SpeedPercent = 40, MaxWeightKg = 250, Type = "Currency", TextureId = "" },
		{ Name = "Frozen Rod", Tier = "Epic", TierColor = Color3.fromRGB(160, 30, 255), CoinPrice = 15000, RobuxPrice = 169, LuckPercent = 190, SpeedPercent = 40, MaxWeightKg = 250, Type = "Currency", TextureId = "" },
		{ Name = "LightingPunk Rod", Tier = "Epic", TierColor = Color3.fromRGB(160, 30, 255), CoinPrice = 18000, RobuxPrice = 199, LuckPercent = 200, SpeedPercent = 45, MaxWeightKg = 280, Type = "Currency", TextureId = "" },
		{ Name = "Pirate Octopus", Tier = "Legendary", TierColor = Color3.fromRGB(255, 128, 0), CoinPrice = 22000, RobuxPrice = 229, LuckPercent = 210, SpeedPercent = 45, MaxWeightKg = 300, Type = "Currency", TextureId = "" },
		{ Name = "Aurora Rod", Tier = "Legendary", TierColor = Color3.fromRGB(255, 128, 0), CoinPrice = 25000, RobuxPrice = 249, LuckPercent = 225, SpeedPercent = 45, MaxWeightKg = 350, Type = "Currency", TextureId = "" },
		{ Name = "Earthly", Tier = "Legendary", TierColor = Color3.fromRGB(255, 128, 0), CoinPrice = 35000, RobuxPrice = 299, LuckPercent = 240, SpeedPercent = 45, MaxWeightKg = 400, Type = "Currency", TextureId = "" },
		{ Name = "Manifest", Tier = "Legendary", TierColor = Color3.fromRGB(255, 128, 0), CoinPrice = 50000, RobuxPrice = 399, LuckPercent = 250, SpeedPercent = 50, MaxWeightKg = 500, Type = "Currency", TextureId = "" },
		{ Name = "Megalofriend", Tier = "Legendary", TierColor = Color3.fromRGB(255, 128, 0), CoinPrice = 75000, RobuxPrice = 499, LuckPercent = 265, SpeedPercent = 55, MaxWeightKg = 650, Type = "Currency", TextureId = "" },
		{ Name = "Purple Saber", Tier = "Legendary", TierColor = Color3.fromRGB(255, 128, 0), CoinPrice = 100000, RobuxPrice = 599, LuckPercent = 280, SpeedPercent = 60, MaxWeightKg = 800, Type = "Currency", TextureId = "" },
		{ Name = "Katana", Tier = "Secret", TierColor = Color3.fromRGB(215, 95, 255), CoinPrice = 120000, RobuxPrice = 699, LuckPercent = 300, SpeedPercent = 60, MaxWeightKg = 1000, Type = "Currency", TextureId = "rbxassetid://97801821774267" },
		{ Name = "Corruption Edge", Tier = "Secret", TierColor = Color3.fromRGB(215, 95, 255), CoinPrice = 135000, RobuxPrice = 749, LuckPercent = 320, SpeedPercent = 85, MaxWeightKg = 1200, Type = "Currency", TextureId = "" },
		{ Name = "Binary Edge", Tier = "Secret", TierColor = Color3.fromRGB(215, 95, 255), CoinPrice = 150000, RobuxPrice = 799, LuckPercent = 350, SpeedPercent = 85, MaxWeightKg = 1500, Type = "Currency", TextureId = "" },
		{ Name = "Cople x1x1x", Tier = "Secret", TierColor = Color3.fromRGB(215, 95, 255), CoinPrice = 165000, RobuxPrice = 849, LuckPercent = 380, SpeedPercent = 85, MaxWeightKg = 1800, Type = "Currency", TextureId = "" },
		{ Name = "Copblue x1x1x", Tier = "Secret", TierColor = Color3.fromRGB(215, 95, 255), CoinPrice = 175000, RobuxPrice = 899, LuckPercent = 400, SpeedPercent = 85, MaxWeightKg = 2000, Type = "Currency", TextureId = "" },
		{ Name = "Dragon Spine", Tier = "Secret", TierColor = Color3.fromRGB(215, 95, 255), CoinPrice = 185000, RobuxPrice = 899, LuckPercent = 420, SpeedPercent = 85, MaxWeightKg = 2200, Type = "Currency", TextureId = "rbxassetid://103247953194129" },
		{ Name = "x1x1x1 Hammer", Tier = "Secret", TierColor = Color3.fromRGB(215, 95, 255), CoinPrice = 200000, RobuxPrice = 999, LuckPercent = 450, SpeedPercent = 80, MaxWeightKg = 2500, Type = "Currency", TextureId = "" },
		{ Name = "Loving", Tier = "Secret", TierColor = Color3.fromRGB(215, 95, 255), CoinPrice = 250000, RobuxPrice = 399, LuckPercent = 250, SpeedPercent = 45, MaxWeightKg = 500, Type = "Gamepass", GamePassId = MonetizationConfig.SecretRods.Loving, TextureId = "" },
		{ Name = "Flery", Tier = "Secret", TierColor = Color3.fromRGB(215, 95, 255), CoinPrice = 250000, RobuxPrice = 399, LuckPercent = 250, SpeedPercent = 45, MaxWeightKg = 500, Type = "Gamepass", GamePassId = MonetizationConfig.SecretRods.Flery, TextureId = "" },
		{ Name = "ZombieRod", Tier = "Secret", TierColor = Color3.fromRGB(215, 95, 255), CoinPrice = 300000, RobuxPrice = 499, LuckPercent = 275, SpeedPercent = 45, MaxWeightKg = 750, Type = "Gamepass", GamePassId = MonetizationConfig.SecretRods.ZombieRod, TextureId = "" },
		{ Name = "Crystalized", Tier = "Secret", TierColor = Color3.fromRGB(215, 95, 255), CoinPrice = 300000, RobuxPrice = 499, LuckPercent = 275, SpeedPercent = 45, MaxWeightKg = 750, Type = "Gamepass", GamePassId = MonetizationConfig.SecretRods.Crystalized, TextureId = "" },
		{ Name = "Forsaken", Tier = "Secret", TierColor = Color3.fromRGB(215, 95, 255), CoinPrice = 350000, RobuxPrice = 599, LuckPercent = 320, SpeedPercent = 45, MaxWeightKg = 1000, Type = "Gamepass", GamePassId = MonetizationConfig.SecretRods.Forsaken, TextureId = "rbxassetid://116453364785174" },
		{ Name = "Umbrella", Tier = "Secret", TierColor = Color3.fromRGB(215, 95, 255), CoinPrice = 400000, RobuxPrice = 699, LuckPercent = 350, SpeedPercent = 60, MaxWeightKg = 1200, Type = "Gamepass", GamePassId = MonetizationConfig.SecretRods.Umbrella, TextureId = "rbxassetid://132455653641238" },
		{ Name = "Gold Rod", Tier = "VIP", TierColor = Color3.fromRGB(255, 205, 50), CoinPrice = 0, RobuxPrice = 0, LuckPercent = 250, SpeedPercent = 50, MaxWeightKg = 500, Type = "VIP", TextureId = "rbxassetid://114471091895897" },
	} :: { RodMasterInfo },

	-- ===================================================================
	-- 3. TRAILS STORE CONFIGURATION (6-Tier AssetTrails)
	-- ===================================================================
	Trails = {
		{ Id = "GrayTrail", FrameName = "GrayTrailFrame", Name = "Gray Trail", Tier = "Common", TierColor = Color3.fromRGB(180, 185, 195), SpeedBonus = 2.5, CoinPrice = 1000, RobuxPrice = 25, PartName = "GreyTrail", ProductId = MonetizationConfig.Trails.GrayTrail },
		{ Id = "GreenTrail", FrameName = "GreenTrailFrame", Name = "Green Trail", Tier = "Uncommon", TierColor = Color3.fromRGB(80, 255, 120), SpeedBonus = 5.0, CoinPrice = 5000, RobuxPrice = 49, PartName = "GreenTrail", ProductId = MonetizationConfig.Trails.GreenTrail },
		{ Id = "BlueTrail", FrameName = "BlueTrailFrame", Name = "Blue Trail", Tier = "Rare", TierColor = Color3.fromRGB(60, 160, 255), SpeedBonus = 7.5, CoinPrice = 15000, RobuxPrice = 99, PartName = "BlueTrail", ProductId = MonetizationConfig.Trails.BlueTrail },
		{ Id = "GoldTrail", FrameName = "GoldTrailFrame", Name = "Gold Trail", Tier = "Epic", TierColor = Color3.fromRGB(255, 205, 50), SpeedBonus = 12.5, CoinPrice = 35000, RobuxPrice = 199, PartName = "GoldenTrail", ProductId = MonetizationConfig.Trails.GoldTrail },
		{ Id = "RedTrail", FrameName = "RedTrailFrame", Name = "Red Trail", Tier = "Legendary", TierColor = Color3.fromRGB(255, 75, 75), SpeedBonus = 15.0, CoinPrice = 75000, RobuxPrice = 349, PartName = "RedTrail", ProductId = MonetizationConfig.Trails.RedTrail },
		{ Id = "GalaxyTrail", FrameName = "GalaxyTrailFrame", Name = "Galaxy Trail", Tier = "Secret", TierColor = Color3.fromRGB(215, 95, 255), SpeedBonus = 20.0, CoinPrice = 150000, RobuxPrice = 599, PartName = "GalaxyTrail", ProductId = MonetizationConfig.Trails.GalaxyTrail },
	} :: { TrailMasterInfo },
}

return ShopMasterConfig
