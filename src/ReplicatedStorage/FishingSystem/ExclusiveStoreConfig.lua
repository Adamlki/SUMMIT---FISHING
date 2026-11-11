--!strict
-- ExclusiveStoreConfig: Sourced directly from ShopMasterConfig for single-point maintenance
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MasterConfig = require(ReplicatedStorage:WaitForChild("FishingSystem"):WaitForChild("ShopMasterConfig"))

local ExclusiveStoreConfig = {
	ServerLuckBoost = {
		DurationSeconds = MasterConfig.Exclusive.ServerLuck.DurationSeconds,
		MaxPurchases = MasterConfig.Exclusive.ServerLuck.MaxPurchases,
		Tiers = MasterConfig.Exclusive.ServerLuck.Tiers,
	},
	Gamepasses = {
		VIP = {
			PassId = MasterConfig.Exclusive.VIP.PassId,
			RobuxPrice = MasterConfig.Exclusive.VIP.RobuxPrice,
			Title = MasterConfig.Exclusive.VIP.Title,
		},
		RemoteSell = {
			PassId = MasterConfig.Exclusive.RemoteSell.PassId,
			RobuxPrice = MasterConfig.Exclusive.RemoteSell.RobuxPrice,
			Title = MasterConfig.Exclusive.RemoteSell.Title,
			Subtitle = MasterConfig.Exclusive.RemoteSell.Subtitle,
		},
		EdvancedLuck = MasterConfig.Exclusive.LuckPasses.EdvancedLuck,
		ExtraLuck = MasterConfig.Exclusive.LuckPasses.ExtraLuck,
		SmallLuck = MasterConfig.Exclusive.LuckPasses.SmallLuck,
		MoreMutations = MasterConfig.Exclusive.LuckPasses.MoreMutations,
	},
	CoinPacks = MasterConfig.Exclusive.CoinPacks,
}

function ExclusiveStoreConfig.GetLuckTierByCount(count: number)
	local tiers = ExclusiveStoreConfig.ServerLuckBoost.Tiers
	local maxCount = ExclusiveStoreConfig.ServerLuckBoost.MaxPurchases or 5
	local clamped = math.clamp(count, 1, maxCount)
	return tiers[clamped] or tiers[1]
end

function ExclusiveStoreConfig.IsLuckBoostProductId(productId: number): boolean
	if type(productId) ~= "number" or productId <= 0 then return false end
	local tiers = ExclusiveStoreConfig.ServerLuckBoost.Tiers
	for _, tier in ipairs(tiers) do
		if tier.ProductId == productId then return true end
	end
	return false
end

return ExclusiveStoreConfig
