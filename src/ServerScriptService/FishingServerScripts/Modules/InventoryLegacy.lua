-- Legacy RemoteEvent/RemoteFunction adapters for InventoryServer (dual-stack).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))

local Legacy = {}

local function legacyEvent(player, key, handler)
	NetworkGateway:RunLegacy(player, key, handler, 0.5)
end

local function legacyInvoke(player, key, handler, fallback)
	local ok, result = NetworkGateway:RunLegacy(player, key, handler, 0.5)
	if ok then
		return result
	end
	return fallback
end

local function getOrCreateRemoteEvent(container, name)
	local obj = container:FindFirstChild(name)
	if not obj or not obj:IsA("RemoteEvent") then
		if obj then obj:Destroy() end
		obj = Instance.new("RemoteEvent")
		obj.Name = name
		obj.Parent = container
	end
	return obj
end

local function getOrCreateRemoteFunction(container, name)
	local obj = container:FindFirstChild(name)
	if not obj or not obj:IsA("RemoteFunction") then
		if obj then obj:Destroy() end
		obj = Instance.new("RemoteFunction")
		obj.Name = name
		obj.Parent = container
	end
	return obj
end

local function unwrapLegacyResponse(response, fallback)
	if response and response.Success then
		return response.Data
	end
	return fallback
end

-- handlers: equipRod, equipFish, unequipAll, equipTool, equipVIPTool,
--           getData, toggleFavorite, sellAll, getVIPTools
function Legacy.Install(container, handlers)
	local reEquipRod = getOrCreateRemoteEvent(container, "Inventory_EquipRod")
	local reEquipFish = getOrCreateRemoteEvent(container, "Inventory_EquipFish")
	local reUnequipAll = getOrCreateRemoteEvent(container, "Inventory_UnequipAll")
	local reEquipTool = getOrCreateRemoteEvent(container, "Inventory_EquipTool")
	local reEquipVIPTool = getOrCreateRemoteEvent(container, "Inventory_EquipVIPTool")

	local rfGetData = getOrCreateRemoteFunction(container, "Inventory_GetData")
	local rfToggleFavorite = getOrCreateRemoteFunction(container, "Inventory_ToggleFavorite")
	local rfSellAll = getOrCreateRemoteFunction(container, "Inventory_SellAll")
	local rfGetVIPTools = getOrCreateRemoteFunction(container, "Inventory_GetVIPTools")

	reEquipRod.OnServerEvent:Connect(function(player, rodName)
		legacyEvent(player, "invEquipRod", function()
			handlers.equipRod(player, rodName)
		end)
	end)

	reEquipFish.OnServerEvent:Connect(function(player, fishUniqueId)
		legacyEvent(player, "invEquipFish", function()
			handlers.equipFish(player, fishUniqueId)
		end)
	end)

	reUnequipAll.OnServerEvent:Connect(function(player)
		legacyEvent(player, "invUnequipAll", function()
			handlers.unequipAll(player)
		end)
	end)

	reEquipTool.OnServerEvent:Connect(function(player, toolName)
		legacyEvent(player, "invEquipTool", function()
			handlers.equipTool(player, toolName)
		end)
	end)

	reEquipVIPTool.OnServerEvent:Connect(function(player, toolName)
		legacyEvent(player, "invEquipVIPTool", function()
			handlers.equipVIPTool(player, toolName)
		end)
	end)

	rfGetData.OnServerInvoke = function(player)
		return legacyInvoke(player, "invGetData", function()
			return unwrapLegacyResponse(handlers.getData(player), nil)
		end, nil)
	end

	rfToggleFavorite.OnServerInvoke = function(player, fishUniqueId)
		return legacyInvoke(player, "invToggleFavorite", function()
			return unwrapLegacyResponse(handlers.toggleFavorite(player, fishUniqueId), nil)
		end, nil)
	end

	rfSellAll.OnServerInvoke = function(player)
		return legacyInvoke(player, "invSellAll", function()
			return unwrapLegacyResponse(handlers.sellAll(player), 0)
		end, 0)
	end

	rfGetVIPTools.OnServerInvoke = function(player)
		return legacyInvoke(player, "invGetVIPTools", function()
			return unwrapLegacyResponse(handlers.getVIPTools(player), {})
		end, {})
	end
end

return Legacy
