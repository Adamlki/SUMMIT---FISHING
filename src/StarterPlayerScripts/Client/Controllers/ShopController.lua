--!nonstrict
-- ShopController: Legacy controller stub (Superceded by ShopFeatureController)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)

local Controller = Knit.CreateController({ Name = "ShopController" })

function Controller:KnitStart()
    -- Managed directly by ShopFeatureController
end

return Controller
