--!strict
-- ServerScriptService/FishingCatchDataStore
-- Unified Catch & Index Service integrated with ProfileService (FishData)
-- Eliminates aggressive 60s DataStore queue spam by utilizing session-locked ProfileService.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))
local GameProfileService = require(ServerScriptService:WaitForChild("Data"):WaitForChild("PetCore"):WaitForChild("FishData"))

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local RecordFishCatch = FishingSystem:FindFirstChild("RecordFishCatch") :: BindableEvent?

-- ===================================================================
-- REST ROUTE
-- ===================================================================

NetworkGateway:RegisterRoute("GET", "/fishing/index", function(player)
	local index = GameProfileService:GetFishIndex(player)
	return {
		Success = true,
		StatusCode = 200,
		Data = index,
		TotalCatches = GameProfileService:GetTotalFishCaught(player),
	}
end, { rateLimitSeconds = 1 })

-- ===================================================================
-- CATCH RECORDING PIPELINE
-- ===================================================================

local function recordCatch(player: Player, fishName: string)
	if not player or not player:IsDescendantOf(Players) then return end
	if type(fishName) ~= "string" or fishName == "" then return end

	local total, speciesCount = GameProfileService:RecordFishCatch(player, fishName)

	NetworkGateway:Broadcast("Fishing/CatchSuccess", {
		FishName = fishName,
		SpeciesCount = speciesCount,
		TotalCatches = total,
	}, player)
end

if RecordFishCatch then
	RecordFishCatch.Event:Connect(recordCatch)
end

print("✅ [FishingCatchDataStore] Integrated with ProfileService (Zero DataStore queue throttling).")
