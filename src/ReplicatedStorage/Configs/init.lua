--!strict
-- Shared config aggregator. Require this folder when a module needs more than one config.
local Configs = {}

Configs.RoleConfig = require(script:WaitForChild("RoleConfig"))
Configs.FishingConfig = require(script:WaitForChild("FishingConfig"))
Configs.ShopMasterConfig = require(script:WaitForChild("ShopMasterConfig"))
Configs.ToolDistributionConfig = require(script:WaitForChild("ToolDistributionConfig"))
Configs.DonationConfig = require(script:WaitForChild("DonationConfig"))
Configs.TitleConfig = require(script:WaitForChild("TitleConfig"))
Configs.MonetizationConfig = require(script:WaitForChild("MonetizationConfig"))
Configs.FeatureFlags = require(script:WaitForChild("FeatureFlags"))

return Configs
