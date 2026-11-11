--!nonstrict
local NotificationsConfig = {}

NotificationsConfig.Icons = {
    Failed = "rbxassetid://124585750153585",
    Success = "rbxassetid://87765750204377",
}

NotificationsConfig.Sounds = {
    Failed = "rbxassetid://87047730068459",
    Success = "rbxassetid://6026984224",
    AdminAnnouncement = "rbxassetid://137402801272072",
    Donate = "rbxassetid://130017643090603",
    RaceJoin = "rbxassetid://6026984224",
    RaceFinish = "rbxassetid://6026984224",
}

NotificationsConfig.Animation = {
    FadeInSeconds = 0.25,
    FadeOutSeconds = 0.2,
    JoinPromptFadeInSeconds = 0.25,
    JoinPromptFadeOutSeconds = 0.2,
    FinishNotificationFadeInSeconds = 0.25,
    FinishNotificationFadeOutSeconds = 0.2,
}

return NotificationsConfig
