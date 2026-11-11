--!nonstrict
local Players = game:GetService("Players")

local NotifierResolver = {}

local TIMEOUT = 60

local function warnMissing(name)
    warn(string.format("[CheckpointUI] '%s' tidak ditemukan di NotificationsUI", name))
end

function NotifierResolver.resolve()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", TIMEOUT)
    local ui = playerGui:WaitForChild("NotificationsUI", TIMEOUT)
    if not ui then
        return false, "NotificationsUI not found after 60 seconds"
    end

    local function fetch(name)
        local obj = ui:FindFirstChild(name)
        if not obj then
            warnMissing(name)
        end
        return obj
    end

    local refs = {
        CheckpointFrame = fetch("CheckpointFrame"),
        CheckpointCount = fetch("CheckpointCount"),
        SummitFrame = fetch("SummitFrame"),
        SummitCount = fetch("SummitCount"),
        uiParent = ui,
    }

    if not (refs.CheckpointFrame and refs.CheckpointCount) then
        return false, "Frame utama tidak lengkap, notifikasi checkpoint tidak bisa ditampilkan"
    end

    return true, refs
end

return NotifierResolver
