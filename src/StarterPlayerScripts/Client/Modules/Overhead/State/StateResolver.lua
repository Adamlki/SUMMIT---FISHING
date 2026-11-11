--!nonstrict
local RoleResolver = require(script.Parent.Parent.Resolvers.RoleResolver)
local StateDevice = require(script.Parent.StateDevice)
local StateSummits = require(script.Parent.StateSummits)
local StateCustomTitle = require(script.Parent.StateCustomTitle)

local StateResolver = {}

function StateResolver.resolve(player, config)
    local state = {
        summits = StateSummits.getSummits(player),
        isOwner = RoleResolver.isOwner(config, player),
        isDeveloper = RoleResolver.isDeveloper(config, player),
        isAdmin = RoleResolver.isAdmin(config, player),
        isModerator = RoleResolver.isModerator(config, player),
        isVip = RoleResolver.isVip(player, config),
        isPremium = player.MembershipType == Enum.MembershipType.Premium,
        device = StateDevice.getDevice(player, config),
        countryCode = player:GetAttribute("CountryCode"),
        customTitle = StateCustomTitle.getCustomTitle(player, config),
    }
    return state
end

return StateResolver
