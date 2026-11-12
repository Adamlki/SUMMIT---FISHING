-- System by @thehandofvoid
-- Modified by @jay_peaceee
-- InventoryServer (REST + LEGACY DUAL-STACK)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FeatureFlags = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("FeatureFlags"))
if not FeatureFlags.Inventory then return end

local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))

local Modules = script.Parent:WaitForChild("Modules")
local Shared = require(Modules:WaitForChild("InventoryShared"))
local Equip = require(Modules:WaitForChild("InventoryEquip"))
local Data = require(Modules:WaitForChild("InventoryData"))
local Legacy = require(Modules:WaitForChild("InventoryLegacy"))

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local InventoryEvents = FishingSystem:FindFirstChild("InventoryEvents")
if not InventoryEvents then
	InventoryEvents = Instance.new("Folder")
	InventoryEvents.Name = "InventoryEvents"
	InventoryEvents.Parent = FishingSystem
end

local respondFailure = Shared.respondFailure
local sanitizeIdentifier = Shared.sanitizeIdentifier
local RATE_LIMIT_EQUIP = Shared.RATE_LIMIT_EQUIP
local RATE_LIMIT_READ = Shared.RATE_LIMIT_READ
local RATE_LIMIT_SELL = Shared.RATE_LIMIT_SELL

local handlers = {
	equipRod = Equip.onEquipRod,
	equipFish = Equip.onEquipFish,
	unequipAll = Equip.onUnequipAll,
	equipTool = Equip.onEquipTool,
	equipVIPTool = Equip.onEquipVIPTool,
	getData = Data.onGetData,
	toggleFavorite = Data.onToggleFavorite,
	sellAll = Data.onSellAll,
	getVIPTools = Data.onGetVIPTools,
}

Legacy.Install(InventoryEvents, handlers)

-- ===================================================================
-- REST ROUTES
-- ===================================================================

local function payloadHandler(fieldName, handler)
	return function(player, payload)
		if type(payload) ~= "table" then
			return respondFailure(400, "INVALID_PAYLOAD", "Payload must be a table.")
		end

		local value = sanitizeIdentifier(payload[fieldName])
		if not value then
			return respondFailure(400, "INVALID_PAYLOAD", string.format("%s must be a non-empty string.", fieldName))
		end

		return handler(player, value)
	end
end

NetworkGateway:RegisterRoute("GET", "/inventory/data", function(player)
	return Data.onGetData(player)
end, { rateLimitSeconds = RATE_LIMIT_READ })

NetworkGateway:RegisterRoute("GET", "/inventory/vip-tools", function(player)
	return Data.onGetVIPTools(player)
end, { rateLimitSeconds = RATE_LIMIT_READ })

NetworkGateway:RegisterRoute("PUT", "/inventory/equip-rod", payloadHandler("RodName", Equip.onEquipRod), {
	rateLimitSeconds = RATE_LIMIT_EQUIP,
})

NetworkGateway:RegisterRoute("PUT", "/inventory/equip-fish", payloadHandler("FishUniqueId", Equip.onEquipFish), {
	rateLimitSeconds = RATE_LIMIT_EQUIP,
})

NetworkGateway:RegisterRoute("PUT", "/inventory/equip-tool", payloadHandler("ToolName", Equip.onEquipTool), {
	rateLimitSeconds = RATE_LIMIT_EQUIP,
})

NetworkGateway:RegisterRoute("PUT", "/inventory/equip-vip-tool", payloadHandler("ToolName", Equip.onEquipVIPTool), {
	rateLimitSeconds = RATE_LIMIT_EQUIP,
})

NetworkGateway:RegisterRoute("PUT", "/inventory/toggle-favorite", payloadHandler("FishUniqueId", Data.onToggleFavorite), {
	rateLimitSeconds = RATE_LIMIT_EQUIP,
})

NetworkGateway:RegisterRoute("DELETE", "/inventory/unequip-all", function(player)
	return Equip.onUnequipAll(player)
end, { rateLimitSeconds = RATE_LIMIT_EQUIP })

NetworkGateway:RegisterRoute("DELETE", "/inventory/sell-all", function(player)
	return Data.onSellAll(player)
end, { rateLimitSeconds = RATE_LIMIT_SELL })
