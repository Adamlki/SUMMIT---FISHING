--!strict
-- RodShopConfig: Sourced directly from ShopMasterConfig for single-point maintenance
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MasterConfig = require(ReplicatedStorage:WaitForChild("FishingSystem"):WaitForChild("ShopMasterConfig"))

local RodShopConfig = {}

-- Staff Rods (Hidden from shop, kept for internal staff roles)
RodShopConfig["Admin Rod"] = { Type = "Staff", CoinPrice = 0, RobuxPrice = 0, GamePassId = 0, ProductId = 0 }
RodShopConfig["Developer Rod"] = { Type = "Staff", CoinPrice = 0, RobuxPrice = 0, GamePassId = 0, ProductId = 0 }
RodShopConfig["Owner Rod"] = { Type = "Staff", CoinPrice = 0, RobuxPrice = 0, GamePassId = 0, ProductId = 0 }

for _, r in ipairs(MasterConfig.Rods) do
	RodShopConfig[r.Name] = {
		Type = r.Type,
		CoinPrice = r.CoinPrice,
		RobuxPrice = r.RobuxPrice,
		GamePassId = r.GamePassId or 0,
		ProductId = r.ProductId or 0,
	}
end

return RodShopConfig
