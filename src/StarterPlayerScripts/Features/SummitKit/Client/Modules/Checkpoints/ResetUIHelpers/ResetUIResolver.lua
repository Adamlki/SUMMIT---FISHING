--!nonstrict
local Players = game:GetService("Players")

local ResetUIResolver = {}

function ResetUIResolver.resolve()
    local pg = Players.LocalPlayer:WaitForChild("PlayerGui", 60)
    if not pg then
        return false, "PlayerGui tidak ada"
    end

    local gameUI = pg:FindFirstChild("GameUI") or pg:WaitForChild("GameUI", 60)
    if not gameUI then
        return false, "GameUI tidak ada"
    end

    local component = gameUI:FindFirstChild("Component") or gameUI:WaitForChild("Component", 60)
    local menus = gameUI:FindFirstChild("Menus") or gameUI:WaitForChild("Menus", 60)
    if not component or not menus then
        return false, "Component atau Menus tidak ditemukan"
    end

    local buttons = component:FindFirstChild("ButtonsNew")
    local menuKiri = buttons and buttons:FindFirstChild("MenuKiri")
    local frameBtn = menuKiri and menuKiri:FindFirstChild("FrameBtn")
    local toggleBtn = frameBtn and frameBtn:FindFirstChild("ResetButton")

    local menuFrame = menus:FindFirstChild("Reset")
    if not menuFrame then
        return false, "Reset menu tidak ditemukan"
    end

    local hiddenPos = menuFrame:GetAttribute("HiddenPos")
    local shownPos = menuFrame:GetAttribute("ShownPos")
    if typeof(hiddenPos) ~= "UDim2" then
        hiddenPos = menuFrame.Position
    end
    if typeof(shownPos) ~= "UDim2" then
        shownPos = UDim2.fromScale(0.5, 0.5)
    end

    local bg = menuFrame:FindFirstChild("Background")
    local actions = bg and bg:FindFirstChild("Actions")
    if not actions then
        return false, "Actions tidak ditemukan"
    end

    local yesBtn = actions:FindFirstChild("Yes")
    local noBtn = actions:FindFirstChild("No")

    return true, {
        toggleBtn = toggleBtn,
        menuFrame = menuFrame,
        yesBtn = yesBtn,
        noBtn = noBtn,
        hiddenPos = hiddenPos,
        shownPos = shownPos,
    }
end

return ResetUIResolver
