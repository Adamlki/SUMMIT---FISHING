--!nonstrict
local Players = game:GetService("Players")

local SpeedrunUIResolver = {}

local TIMEOUT = 60

local function waitForPath(root, path)
    local current = root
    for _, name in ipairs(path) do
        if not current then
            return nil
        end
        current = current:WaitForChild(name, TIMEOUT)
    end
    return current
end

function SpeedrunUIResolver.resolve()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", TIMEOUT)
    if not playerGui then
        return false, "PlayerGui not found"
    end

    local gui = waitForPath(playerGui, {"GameUI"})
    if not gui then
        return false, "GameUI not found in StarterGui"
    end

    local component = gui:FindFirstChild("Component")
    local timers = component and component:FindFirstChild("Timers")
    local text = timers and timers:FindFirstChild("Text")
    if not (component and timers and text and text:IsA("TextLabel")) then
        return false, "GameUI/Component/Timers/Text not found or invalid"
    end

    return true, {
        Root = gui,
        Component = component,
        Timers = timers,
        Text = text,
    }
end

return SpeedrunUIResolver
