--!strict
-- Single source of truth for Roblox GamePass and Developer Product IDs.
-- Feature configs should reference this table instead of hardcoding IDs.
local VIP_GAMEPASS_ID = 1874479701
local LEGACY_VIP_GAMEPASS_ID = 1590939529

local MonetizationConfig = {
	VIP = {
		GamePassId = VIP_GAMEPASS_ID,
		LegacyGamePassId = LEGACY_VIP_GAMEPASS_ID,
		AllGamePassIds = { VIP_GAMEPASS_ID, LEGACY_VIP_GAMEPASS_ID },
		GiftProductId = 0,
	},

	LuckPasses = {
		EdvancedLuck = 1874483756,
		ExtraLuck = 1874483757,
		SmallLuck = 1874483758,
		MoreMutations = 1874483759,
	},

	RemoteSell = {
		GamePassId = 1874483760,
	},

	SecretRods = {
		Loving = 1874483770,
		Flery = 1874483771,
		ZombieRod = 1874483772,
		Crystalized = 1874483773,
		Forsaken = 1874483774,
		Umbrella = 1874483775,
	},

	ServerLuckBoost = {
		ProductIds = { 0, 0, 0, 0, 0 },
	},

	CoinPacks = {
		SmallCoin = 0,
		MediumCoin = 0,
		LargeCoin = 0,
		ExtraLargeCoin = 0,
	},

	Trails = {
		GrayTrail = 0,
		GreenTrail = 0,
		BlueTrail = 0,
		GoldTrail = 0,
		RedTrail = 0,
		GalaxyTrail = 0,
	},

	Tools = {
		BoomBox = 0,
		Void = 0,
		Poison = 0,
	},

	Donations = {
		[10] = 0,
		[50] = 0,
		[100] = 0,
		[250] = 0,
		[500] = 0,
		[1000] = 0,
	},
}

function MonetizationConfig.IsVIPGamePass(gamePassId: number): boolean
	return table.find(MonetizationConfig.VIP.AllGamePassIds, gamePassId) ~= nil
end

return MonetizationConfig
