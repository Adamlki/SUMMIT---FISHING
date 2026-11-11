--!strict
-- TrailShopConfig: Sourced directly from ShopMasterConfig for single-point maintenance
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MasterConfig = require(ReplicatedStorage:WaitForChild("FishingSystem"):WaitForChild("ShopMasterConfig"))

local registry = {}
local ordered = {}

for _, t in ipairs(MasterConfig.Trails) do
	registry[t.Id] = t
	table.insert(ordered, t)
end

return {
	Registry = registry,
	Ordered = ordered,
	DefaultTrailId = "GrayTrail",
}
