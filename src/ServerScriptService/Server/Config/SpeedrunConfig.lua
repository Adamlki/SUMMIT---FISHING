--!nonstrict
local AntiCheatConfig = require(game:GetService("ServerScriptService"):WaitForChild("Configs"):WaitForChild("AntiCheatConfig"))

return {
    FolderPath = {"JaleMaps", "Speedrun"},
    StartPartName = "Start",
    FinishPartName = "Finish",

    EnableAntiCheat = AntiCheatConfig.Speedrun.Enabled,
    MinTimeSeconds = AntiCheatConfig.Speedrun.MinTimeSeconds,
    KickMessage = AntiCheatConfig.Speedrun.KickMessage,

    ProfileKey = "SpeedrunData",
    BestTimeLeaderboardKey = "SpeedrunBestTimeLeaderboard_V1",

    StartCooldown = 2,
    FinishCooldown = 3,
}
