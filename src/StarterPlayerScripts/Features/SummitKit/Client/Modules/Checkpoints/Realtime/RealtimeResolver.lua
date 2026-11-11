--!nonstrict
local Players = game:GetService("Players")

local RealtimeResolver = {}

function RealtimeResolver.resolve()
    local pg = Players.LocalPlayer:FindFirstChild("PlayerGui") or Players.LocalPlayer:WaitForChild("PlayerGui", 60)
    if not pg then
        return false, "PlayerGui tidak ada"
    end
    local gameUI = pg:FindFirstChild("GameUI") or pg:WaitForChild("GameUI", 60)
    if not gameUI then
        return false, "GameUI tidak ada"
    end
    local comp = gameUI:FindFirstChild("Component") or gameUI:WaitForChild("Component", 60)
    if not comp then
        return false, "Component tidak ada"
    end
    local template = comp:FindFirstChild("Players")
    if not (template and template:IsA("Frame")) then
        return false, "Template Players tidak ditemukan"
    end
    template.Visible = true
    template:SetAttribute("UseAsInstance", true)
    return true, {
        template = template,
        container = template.Parent,
    }
end

return RealtimeResolver
