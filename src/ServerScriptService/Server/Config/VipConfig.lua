--!nonstrict
local MonetizationConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Configs"):WaitForChild("MonetizationConfig"))

return {
	GamePassId = MonetizationConfig.VIP.GamePassId, -- VIP Gamepass ID
	GiftProductId = MonetizationConfig.VIP.GiftProductId, -- Dedicated VIP Gift Product ID
}
