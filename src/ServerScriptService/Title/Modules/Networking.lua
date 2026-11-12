--!nonstrict
-- ============================================================
-- Title/Modules/Networking (ModuleScript)
-- Dual-stack remotes + NetworkGateway REST routes.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))

local CustomTitleRemotes = ReplicatedStorage:WaitForChild("CustomTitleRemotes")
local GetTitleDataRF = CustomTitleRemotes:WaitForChild("GetTitleData")
local SetTitleRF = CustomTitleRemotes:WaitForChild("SetTitle")
local ClearSlotRF = CustomTitleRemotes:WaitForChild("ClearSlot")

local Networking = {}

function Networking.Start(api)
	local function legacyInvoke(player, key, handler, fallback)
		local ok, result = NetworkGateway:RunLegacy(player, key, handler, 1)
		if ok then
			return result
		end
		return fallback
	end

	-- Dual-Stack Legacy Remotes
	GetTitleDataRF.OnServerInvoke = function(player)
		return legacyInvoke(player, "titleData", function()
			return api.GetTitleData(player)
		end, nil)
	end

	SetTitleRF.OnServerInvoke = function(player, slot, titleType, payload, targetUserId)
		return legacyInvoke(player, "titleSet", function()
			return api.SetTitle(player, slot, titleType, payload, targetUserId)
		end, { Success = false, Message = "Terlalu cepat, coba lagi sebentar." })
	end

	ClearSlotRF.OnServerInvoke = function(player, slot, targetUserId)
		return legacyInvoke(player, "titleClear", function()
			return api.ClearSlot(player, slot, targetUserId)
		end, { Success = false, Message = "Terlalu cepat, coba lagi sebentar." })
	end

	-- REST Routes (Network Gateway)
	NetworkGateway:RegisterRoute("GET", "/title/data", function(player)
		local data = api.GetTitleData(player)
		return {
			Success = true,
			StatusCode = 200,
			Data = data,
			Message = "Title data loaded.",
		}
	end, { rateLimitSeconds = 1 })

	NetworkGateway:RegisterRoute("PUT", "/title/set-slot", function(player, payload)
		if type(payload) ~= "table" then
			return { Success = false, StatusCode = 400, Message = "Payload must be a table." }
		end
		if payload.TargetUserId ~= nil and type(payload.TargetUserId) ~= "number" then
			return { Success = false, StatusCode = 400, Message = "TargetUserId must be a number." }
		end

		local result = api.SetTitle(player, payload.Slot, payload.TitleType, payload.Payload, payload.TargetUserId)
		return {
			Success = result.Success == true,
			StatusCode = result.Success and 200 or 400,
			Data = result,
			Message = result.Message,
		}
	end, { rateLimitSeconds = 1 })

	NetworkGateway:RegisterRoute("DELETE", "/title/clear-slot", function(player, payload)
		if type(payload) ~= "table" then
			return { Success = false, StatusCode = 400, Message = "Payload must be a table." }
		end
		if payload.TargetUserId ~= nil and type(payload.TargetUserId) ~= "number" then
			return { Success = false, StatusCode = 400, Message = "TargetUserId must be a number." }
		end

		local result = api.ClearSlot(player, payload.Slot, payload.TargetUserId)
		return {
			Success = result.Success == true,
			StatusCode = result.Success and 200 or 400,
			Data = result,
			Message = result.Message,
		}
	end, { rateLimitSeconds = 1 })
end

return Networking
