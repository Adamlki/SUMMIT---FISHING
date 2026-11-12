--!strict
-- Server-private DataStore names and retry policy.
local RunService = game:GetService("RunService")

local DataStoreConfig = {
	Stores = {
		PlayerGameData = "PlayerGameData_V1",
		FishingCatch = "FishingCatchDataStore",
		PlayerFishIndex = "PlayerFishIndexDataStore",
		PurchaseReceiptLog = "PurchaseReceiptLog_V1",
		AdminBans = "AdminBans",
		AdminRoles = "AdminRoles",
		AdminJailProfiles = "AdminJailProfiles",
		CheckpointProgress = "CheckpointProgress",
		PlaytimeData = "PlaytimeData",
		ShopToolsData = "ShopToolsData",
		SpeedrunData = "SpeedrunData",
		VipData = "VipData",
		OverheadCustomTitles = "OverheadCustomTitles",
		DonationsLeaderboard = "DonationsLeaderboard_V1",
	},

	Leaderboards = {
		Summit = "SummitLeaderboard_V1",
		Playtime = "PlaytimeLeaderboard_V1",
		SpeedrunBestTime = "SpeedrunBestTimeLeaderboard_V1",
	},

	Retry = {
		MaxAttempts = 3,
		BackoffSeconds = 0.5,
	},
}

-- Shared retry wrapper for non-receipt DataStore writes (leaderboards, etc.).
function DataStoreConfig.RetryCall(fn: () -> any, label: string?): (boolean, any)
	local attempts = DataStoreConfig.Retry.MaxAttempts
	local backoff = DataStoreConfig.Retry.BackoffSeconds
	for attempt = 1, attempts do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		if attempt < attempts then
			task.wait(backoff * attempt)
		end
	end
	warn("[DataStore] " .. tostring(label or "request") .. " failed after retries")
	return false, nil
end

-- Studio play tests must never write to production DataStore keys.
if RunService:IsStudio() then
	for name, storeName in pairs(DataStoreConfig.Stores) do
		DataStoreConfig.Stores[name] = storeName .. "_Studio"
	end
	for name, storeName in pairs(DataStoreConfig.Leaderboards) do
		DataStoreConfig.Leaderboards[name] = storeName .. "_Studio"
	end
end

return DataStoreConfig
