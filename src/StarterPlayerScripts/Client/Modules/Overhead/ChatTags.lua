--!nonstrict
local Players = game:GetService("Players")
local TextChatService = game:FindService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--//package
local Shared = ReplicatedStorage.Shared
local Pacakages = Shared.Packages
local Janitor = require(Pacakages.Janitor)

local RoleResolver = require(script.Parent.Resolvers.RoleResolver)

local ChatTags = {}

local ROLE_PRIORITY = {"Owner", "Developer", "Admin", "Moderator"}
local ROLE_CHECKS = {
    Owner = RoleResolver.isOwner,
    Developer = RoleResolver.isDeveloper,
    Admin = RoleResolver.isAdmin,
    Moderator = RoleResolver.isModerator,
}

local function resolvePrimaryRole(player, cfg)
    local config = cfg or {}
    local titleCfg = config.TitleConfig or {}
    local special = titleCfg.SpecialRoles or {}

    for _, role in ipairs(ROLE_PRIORITY) do
        local check = ROLE_CHECKS[role]
        if check and check(config, player) then
            return role
        end
        local spec = special[role]
        if spec and RoleResolver.matches(spec.UserIds, spec.Usernames, player) then
            return role
        end
    end

    return nil
end

local function buildPrefix(tags, cfg)
    local titleCfg = cfg.TitleConfig or {}
    local displayRole = titleCfg.DisplayRole or {}
    local chatTag = titleCfg.ChatTag or {}
    local parts = {}
    for _, role in ipairs(tags) do
        local tagText = displayRole[role] or role
        local prefix = string.format("[%s]", tagText)
        local color = chatTag[role]
        if color then
            prefix = string.format(
                '<font color="#%02x%02x%02x">%s</font>',
                math.clamp(math.floor(color.R * 255), 0, 255),
                math.clamp(math.floor(color.G * 255), 0, 255),
                math.clamp(math.floor(color.B * 255), 0, 255),
                prefix
            )
        end
        table.insert(parts, prefix)
    end
    return table.concat(parts, " ")
end

function ChatTags.start(overheadService)
    local janitor = Janitor.new()
    if not TextChatService then
        return janitor
    end

    local configCache = nil
    local callbackSet = false

    local function ensureCallback()
        if callbackSet or not configCache then
            return
        end
        callbackSet = true
        TextChatService.OnIncomingMessage = function(message)
            local props
            local source = message.TextSource
            if source then
                local player = Players:GetPlayerByUserId(source.UserId)
                if player then
                    local primary = resolvePrimaryRole(player, configCache)
                    local tags = {}
                    if primary then
                        table.insert(tags, primary)
                    end
                    if RoleResolver.isVip(player, configCache) then
                        table.insert(tags, "VIP")
                    end
                    if #tags > 0 then
                        local prefix = buildPrefix(tags, configCache or {})
                        local suffix = message.PrefixText or ""
                        if suffix ~= "" then
                            suffix = " " .. suffix
                        end
                        props = Instance.new("TextChatMessageProperties")
                        props.PrefixText = prefix .. suffix
                    end
                end
            end
            return props
        end
    end

--     if overheadService then
--         overheadService.Config:Observe(function(cfg)
--             configCache = cfg
--             ensureCallback()
--         end)
--     end
-- end

    if overheadService and overheadService.Config then 
        if overheadService.Config.Get then 
            configCache = overheadService.Config:Get()
            ensureCallback()
        end
        if overheadService.Config.Observe then 
            janitor:Add(overheadService.Config:Observe(function(cfg)
            end), "Disconnect")
        end
    end

    janitor:Add(function()
        if TextChatService.OnIncomingMessage then 
            TextChatService.OnIncomingMessage = nil
        end 
    end, true)
    return janitor 
end

return ChatTags
