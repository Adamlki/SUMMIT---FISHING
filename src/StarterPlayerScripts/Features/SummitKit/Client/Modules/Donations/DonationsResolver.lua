--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local DonationsResolver = {}

local function find(parent, name, timeout)
    if not parent then return nil end
    local ok, obj = pcall(function()
        return parent:WaitForChild(name, timeout or 60)
    end)
    return ok and obj or nil
end

function DonationsResolver.resolve(customGui)
    local pg = customGui or (Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")) or StarterGui
    if not pg then
        return false, "PlayerGui tidak ada"
    end

    local gameUI = find(pg, "GameUI", 60)
    local component = gameUI and find(gameUI, "Component")
    local menus = gameUI and find(gameUI, "Menus")
    if not (component and menus) then
        return false, "Component atau Menus tidak ditemukan"
    end

    local buttons = find(component, "ButtonsNew")
    local menuKiri = buttons and find(buttons, "MenuKiri")
    local frameBtn = menuKiri and find(menuKiri, "FrameBtn")
    local toggleBtn = frameBtn and find(frameBtn, "DonationButton")

    local menuFrame = find(menus, "Donate")
    local header = menuFrame and find(menuFrame, "Header")
    local closeBtn = header and find(header, "Close")
    local container = menuFrame and find(menuFrame, "Container")
    local listFrame = container and find(container, "List")
    if not (menuFrame and listFrame) then
        return false, "Menu/Container/List tidak lengkap"
    end

    -- Cari template di dalam listFrame (bisa bernama Tamplate atau Template)
    local template = listFrame:FindFirstChild("Tamplate") or listFrame:FindFirstChild("Template")
    if not template then
        local shared = ReplicatedStorage:FindFirstChild("Shared")
        local assets = shared and shared:FindFirstChild("Assets")
        local donations = assets and assets:FindFirstChild("Donations")
        template = donations and donations:FindFirstChild("Template")
    end

    if not template then
        return false, "Template kartu donasi tidak ditemukan di List"
    end

    local hiddenPos = menuFrame:GetAttribute("HiddenPos") or UDim2.new(0.5, 0, -0.6, 0)
    local shownPos = menuFrame:GetAttribute("ShownPos") or UDim2.new(0.5, 0, 0.5, 0)

    return true, {
        menuFrame = menuFrame,
        listFrame = listFrame,
        template = template,
        toggleBtn = toggleBtn,
        closeBtn = closeBtn,
        hiddenPos = typeof(hiddenPos) == "UDim2" and hiddenPos or UDim2.new(0.5, 0, -0.6, 0),
        shownPos = typeof(shownPos) == "UDim2" and shownPos or UDim2.new(0.5, 0, 0.5, 0),
    }
end

return DonationsResolver
