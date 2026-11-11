--!strict
-- Server-private DataStore names and retry policy.
local DataStoreConfig = {
	Stores = {
		PlayerGameData = "PlayerGameData_V1",
		FishingCatch = "FishingCatchDataStore",
		PlayerFishIndex = "PlayerFishIndexDataStore",
		PurchaseReceiptLog = "PurchaseReceiptLog_V1",
		AdminBans = "AdminBans",
		AdminRoles = "AdminRoles",
		DonationsLeaderboard = "DonationsLeaderboard_V1",
	},

	Retry = {
		MaxAttempts = 3,
		BackoffSeconds = 0.5,
	},
}

return DataStoreConfig
