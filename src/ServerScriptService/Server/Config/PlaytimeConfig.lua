--!nonstrict
local DataStoreConfig = require(game:GetService("ServerScriptService"):WaitForChild("Configs"):WaitForChild("DataStoreConfig"))

return {
    ProfileKey = DataStoreConfig.Stores.PlaytimeData,
    LeaderboardKey = DataStoreConfig.Leaderboards.Playtime,
    UpdateInterval = 120,
}
