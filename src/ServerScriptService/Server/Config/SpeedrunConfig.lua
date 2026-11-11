--!nonstrict
return {
    FolderPath = {"JaleMaps", "Speedrun"},
    StartPartName = "Start",
    FinishPartName = "Finish",

    EnableAntiCheat = false,  -- Set this to true to enable anti-cheat measures for unreasonable speedrun times. Make sure to adjust the MinTimeSeconds accordingly if you enable this.
    MinTimeSeconds = 120,
    KickMessage = "Anti-Cheat: Unreasonable speedrun time detected. Contact an admin if this is a mistake.",

    ProfileKey = "SpeedrunData",
    BestTimeLeaderboardKey = "SpeedrunBestTimeLeaderboard_V1",

    StartCooldown = 2,
    FinishCooldown = 3,
}
