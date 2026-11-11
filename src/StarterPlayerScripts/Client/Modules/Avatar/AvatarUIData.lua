--!nonstrict
local Players = game:GetService("Players")
local AvatarFetcher = require(script.Parent.AvatarFetcher)

local AvatarUIData = {}

local function buildResetEntry(config)
    local player = Players.LocalPlayer
    local uid = (config and config.TemplateUserId) or (player and player.UserId) or 0

    local thumb = uid > 0 and string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=420&h=420", uid) or ""
    return {
        UserId = uid,
        Username = player and player.Name or "Default",
        DisplayName = "Reset",
        Thumbnail = thumb,
        Description = nil,
        isReset = true,
        LayoutOrder = -1,
    }
end

function AvatarUIData.buildEntries(config)
    local entries = {}
    local resetEntry = buildResetEntry(config)

    -- 1. Kartu Reset di urutan pertama
    if resetEntry then
        table.insert(entries, resetEntry)
    end

    -- 2. Daftar preset avatar dari Config
    local cfgAvatars = (config and config.Avatars) or {}
    for idx, av in ipairs(cfgAvatars) do
        local entry = AvatarFetcher.fetch(av.id or av.name) or {
            UserId = av.id,
            Username = av.name or tostring(av.id),
            Thumbnail = av.id and string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=420&h=420", av.id) or "",
            Description = nil,
        }
        entry.LayoutOrder = av.layoutOrder or idx
        entry.DisplayName = av.name or entry.Username
        table.insert(entries, entry)
    end

    return entries, resetEntry
end

return AvatarUIData
