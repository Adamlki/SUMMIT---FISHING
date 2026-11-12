--!nonstrict
local DataStoreConfig = require(game:GetService("ServerScriptService"):WaitForChild("Configs"):WaitForChild("DataStoreConfig"))

return {
    Tag = "Checkpoint",
    FolderPath = {"JaleMaps", "Checkpoints"},
    DefaultStartIndex = 0,
    EnableSkip = false,
    SummitLeaderboardKey = DataStoreConfig.Leaderboards.Summit,
}
