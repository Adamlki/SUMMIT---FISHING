--!nonstrict
return {
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

    BanDataStoreKey = "AdminBans",
    RoleDataStoreKey = "AdminRoles",
    LogMax = 100,
}
