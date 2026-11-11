--!nonstrict
local RaceConfig = {
    JoinWindowSeconds = 15,
    CountdownSeconds = 10,
    MinWins = 1,
    MinLaps = 1,
    CleanupDelaySeconds = 5,
    RuntimeName = "RaceRuntime",
    TriggerPath = {
        Race = "Race",
        Maps = "JaleMaps",
        Start = "Start",
        Finish = "Finish",
    },
    Statuses = {
        Inactive = "Deactive",
        Preparing = "Preparing",
        Countdown = "Countdown",
        Active = "Active",
        Finished = "Finished",
    },
}

return RaceConfig
