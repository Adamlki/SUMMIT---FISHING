--!nonstrict
local DataStoreConfig = require(script.Parent:WaitForChild("DataStoreConfig"))

return {
    GlobalLuckTopic = "GlobalLuckEvent",

    MaxAnnounceLength = 100,
    DefaultAnnounceDuration = 6,
    MaxAnnounceDuration = 60,

    AssignableRoles = {
        "Member",
        "VIP",
        "Moderator",
        "Admin",
    },

    TeleportPoints = {},
    JailPartPath = "Workspace.AdminJail",
    JailFreezeSeconds = 3,
    JailRadiusPadding = 2,

    BanDataStoreKey = DataStoreConfig.Stores.AdminBans,
    RoleDataStoreKey = DataStoreConfig.Stores.AdminRoles,
    LogMax = 100,
}
