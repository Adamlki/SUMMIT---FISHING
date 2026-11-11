--!nonstrict
local Players = game:GetService("Players")

local StateHUDResolver = {}

local TIMEOUT = 60

function StateHUDResolver.resolve()
    local pg = Players.LocalPlayer:WaitForChild("PlayerGui", TIMEOUT)
    local ui = pg:WaitForChild("NotificationsUI", TIMEOUT)
    if not ui then
        return false, "NotificationsUI not found"
    end
    return true, {
        CheckpointFrame = ui:FindFirstChild("CheckpointFrame"),
        CheckpointCount = ui:FindFirstChild("CheckpointCount"),
        SummitFrame = ui:FindFirstChild("SummitFrame"),
        SummitCount = ui:FindFirstChild("SummitCount"),
    }
end

return StateHUDResolver
