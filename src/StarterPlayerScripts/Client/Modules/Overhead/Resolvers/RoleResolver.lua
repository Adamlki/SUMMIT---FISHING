--!nonstrict
local RoleResolver = {}

local function matches(listIds, listNames, player)
    for _, id in ipairs(listIds or {}) do
        if id == player.UserId then
            return true
        end
    end
    local uname = string.lower(player.Name)
    for _, name in ipairs(listNames or {}) do
        if uname == string.lower(name) then
            return true
        end
    end
    return false
end

function RoleResolver.isOwner(config, player)
    if config.PlaceOwnerId and player.UserId == config.PlaceOwnerId then
        return true
    end
    if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
        return true
    end
    local special = config.TitleConfig and config.TitleConfig.SpecialRoles
    local ownerSpec = special and special.Owner
    if ownerSpec and matches(ownerSpec.UserIds, ownerSpec.Usernames, player) then
        return true
    end
    return false
end

function RoleResolver.isDeveloper(config, player)
    local special = config.TitleConfig and config.TitleConfig.SpecialRoles
    local spec = special and special.Developer
    return spec and matches(spec.UserIds, spec.Usernames, player) or false
end

function RoleResolver.isAdmin(config, player)
    local special = config.TitleConfig and config.TitleConfig.SpecialRoles
    local spec = special and special.Admin
    return spec and matches(spec.UserIds, spec.Usernames, player) or false
end

function RoleResolver.isModerator(config, player)
    local special = config.TitleConfig and config.TitleConfig.SpecialRoles
    local spec = special and special.Moderator
    return spec and matches(spec.UserIds, spec.Usernames, player) or false
end

function RoleResolver.isVip(player, config)
    local RoleConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("RoleConfig"))
    if RoleConfig and RoleConfig.IsOwner(player) then
        return true
    end
    local vipAttr = player:GetAttribute(config.VipAttribute)
    return vipAttr == true or false
end

function RoleResolver.matches(listIds, listNames, player)
    return matches(listIds, listNames, player)
end

return RoleResolver
