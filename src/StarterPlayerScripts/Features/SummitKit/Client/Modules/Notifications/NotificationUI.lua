--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)

local NotificationResolver = require(script.Parent.NotificationResolver)
local NotificationRenderer = require(script.Parent.NotificationRenderer)

local NotificationUI = {}

local janitor = Janitor.new()
local refs
local resolved = false

local function ensure()
    if resolved and refs then
        return true
    end
    local ok, dataOrErr = NotificationResolver.resolve()
    if not ok then
        warn("[NotificationUI] " .. tostring(dataOrErr))
        return false
    end
    refs = dataOrErr
    resolved = true
    return true
end

function NotificationUI.notify(header, description, icon, duration, soundId, volume)
    if not ensure() then return end
    NotificationRenderer.spawn(refs, {
        header = header,
        description = description,
        icon = icon,
        duration = duration,
        soundId = soundId,
        volume = volume,
    })
end

function NotificationUI.destroy()
    janitor:Destroy()
    refs = nil
    resolved = false
end

return NotificationUI
