--!nonstrict
local OverheadViewIcons = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OverheadDeviceIcons = require(ReplicatedStorage.Shared.Config.Overhead.DeviceIcons)
local FlagIcons = require(ReplicatedStorage.Shared.Config.Overhead.FlagIcons)

local ROLE_PRIORITY = {"Owner", "Developer", "Admin", "Moderator", "Premium"}
local ICON_FLAGS = {
    Device = function(state)
        return state.device ~= nil
    end,
    Owner = function(state)
        return state.isOwner
    end,
    Developer = function(state)
        return state.isDeveloper
    end,
    Admin = function(state)
        return state.isAdmin
    end,
    Moderator = function(state)
        return state.isModerator
    end,
    Premium = function(state)
        return state.isPremium
    end,
    VIP = function(state)
        return state.isVip
    end,
}

function OverheadViewIcons.applyIcons(canvas, state)
    if not canvas then
        return
    end
    local function setVisible(name, visible)
        local obj = canvas:FindFirstChild(name)
        if obj and obj:IsA("GuiObject") then
            obj.Visible = visible or false
        end
    end
    for name, flag in pairs(ICON_FLAGS) do
        setVisible(name, flag(state))
    end

    local deviceLabel = canvas:FindFirstChild("Device")
    OverheadDeviceIcons.apply(deviceLabel, state.device)

    local flagLabel = canvas:FindFirstChild("Flag")
    FlagIcons.apply(flagLabel, state.countryCode)
end

function OverheadViewIcons.pickRole(state, displayRoles)
    for _, role in ipairs(ROLE_PRIORITY) do
        if state["is" .. role] then
            return (displayRoles and displayRoles[role]) or role
        end
    end
    return nil
end

return OverheadViewIcons
