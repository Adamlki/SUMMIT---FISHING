--!nonstrict
local ServerScriptService = game:GetService("ServerScriptService")
local Configs = ServerScriptService:WaitForChild("Configs")
local AntiCheatConfig = require(Configs:WaitForChild("AntiCheatConfig"))
local DataStoreConfig = require(Configs:WaitForChild("DataStoreConfig"))

return {
    FolderPath = {"JaleMaps", "Speedrun"},
    StartPartName = "Start",
    FinishPartName = "Finish",

    EnableAntiCheat = AntiCheatConfig.Speedrun.Enabled,
    MinTimeSeconds = AntiCheatConfig.Speedrun.MinTimeSeconds,
    KickMessage = AntiCheatConfig.Speedrun.KickMessage,

    ProfileKey = DataStoreConfig.Stores.SpeedrunData,
    BestTimeLeaderboardKey = DataStoreConfig.Leaderboards.SpeedrunBestTime,

    StartCooldown = 2,
    FinishCooldown = 3,
}
