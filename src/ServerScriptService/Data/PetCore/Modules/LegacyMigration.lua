-- One-time import of the legacy catch total / per-species index DataStores.
local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")
local DataStoreConfig = require(SSS:WaitForChild("Configs"):WaitForChild("DataStoreConfig"))
local dataStoreService = game:GetService("DataStoreService")

local LegacyMigration = {}

local function isValidCount(value)
	return type(value) == "number" and value == value and value >= 0 and value < math.huge
end

function LegacyMigration.Migrate(player, profile)
	if profile.Data.LegacyCatchMigrated == true then return end

	local catchStoreOk, catchStore = pcall(function()
		return dataStoreService:GetDataStore(DataStoreConfig.Stores.FishingCatch)
	end)
	local indexStoreOk, indexStore = pcall(function()
		return dataStoreService:GetDataStore(DataStoreConfig.Stores.PlayerFishIndex)
	end)

	local catchOk, legacyTotal = false, nil
	if catchStoreOk then
		catchOk, legacyTotal = pcall(function()
			return catchStore:GetAsync("Catch_" .. player.UserId)
		end)
	end

	local indexOk, legacyIndex = false, nil
	if indexStoreOk then
		indexOk, legacyIndex = pcall(function()
			return indexStore:GetAsync("Index_" .. player.UserId)
		end)
	end

	-- The profile may have been released while the DataStore calls were yielding.
	if not profile:IsActive() or not player:IsDescendantOf(Players) then return end

	-- math.max keeps retries idempotent and avoids double-counting after a partial migration.
	if catchOk and isValidCount(legacyTotal) then
		local current = isValidCount(profile.Data.TotalFishCaught) and profile.Data.TotalFishCaught or 0
		profile.Data.TotalFishCaught = math.max(current, math.floor(legacyTotal))
	end

	if indexOk and type(legacyIndex) == "table" then
		if type(profile.Data.FishIndex) ~= "table" then
			profile.Data.FishIndex = {}
		end
		for fishName, count in pairs(legacyIndex) do
			if type(fishName) == "string" and isValidCount(count) then
				local current = isValidCount(profile.Data.FishIndex[fishName]) and profile.Data.FishIndex[fishName] or 0
				profile.Data.FishIndex[fishName] = math.max(current, math.floor(count))
			end
		end
	end

	-- Retry on the next session if either store failed.
	if catchStoreOk and indexStoreOk and catchOk and indexOk then
		profile.Data.LegacyCatchMigrated = true
	end
end

return LegacyMigration
