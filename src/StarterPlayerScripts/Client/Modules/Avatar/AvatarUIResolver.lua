--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local AvatarUIResolver = {}

local TIMEOUT = 60

local function waitForPath(root, names, timeout)
    local current = root
    for _, name in ipairs(names) do
        if not current then return nil end
        local ok, obj = pcall(function()
            return current:WaitForChild(name, timeout or TIMEOUT)
        end)
        if not ok then
            return nil
        end
        current = obj
    end
    return current
end

function AvatarUIResolver.resolve(customGui)
    local pg = customGui or (Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")) or StarterGui
    if not pg then
        return false, "PlayerGui tidak ada"
    end

    local gameUI = waitForPath(pg, {"GameUI"})
    local component = waitForPath(gameUI, {"Component"})
    local menus = waitForPath(gameUI, {"Menus"})
    if not (component and menus) then
        return false, "GameUI.Component atau GameUI.Menus tidak ada"
    end

    local buttons = waitForPath(component, {"Buttons"})
    local topMid = buttons and waitForPath(buttons, {"TopMid"})
    local toggleBtn = topMid and waitForPath(topMid, {"Avatar"})

    local menuFrame = waitForPath(menus, {"Avatar"})
    if not menuFrame then
        return false, "Menu Avatar tidak ditemukan"
    end

    local header = menuFrame:FindFirstChild("Header") or waitForPath(menuFrame, {"Header"}, 5)
    local closeBtn = header and header:FindFirstChild("Close")
    local usnFrame = header and header:FindFirstChild("Usn")
    local inputBox = usnFrame and usnFrame:FindFirstChild("Input")
    local enterBtn = usnFrame and usnFrame:FindFirstChild("Enter")

    local container = menuFrame:FindFirstChild("Container") or waitForPath(menuFrame, {"Container"}, 5)
    local list = container and (container:FindFirstChild("List") or waitForPath(container, {"List"}, 5))
    local preview = container and (container:FindFirstChild("Preview") or waitForPath(container, {"Preview"}, 5))

    if not (list and preview) then
        return false, "Container/List/Preview di menu Avatar tidak lengkap"
    end

    local template = list:FindFirstChild("AvatarTamplate") or list:FindFirstChild("AvatarTemplate")
    if not template then
        template = waitForPath(ReplicatedStorage, {"Shared", "Assets", "Avatar", "Template"}, 5)
    end

    if not template then
        return false, "Template kartu Avatar tidak ditemukan di List"
    end

    local applyBtn = preview:FindFirstChild("ButtonsApply") or preview:FindFirstChild("Buttons")

    local hiddenPos = menuFrame:GetAttribute("HiddenPos") or UDim2.new(0.5, 0, -0.6, 0)
    local shownPos = menuFrame:GetAttribute("ShownPos") or UDim2.new(0.5, 0, 0.5, 0)

    return true, {
        menuFrame = menuFrame,
        listFrame = list,
        previewFrame = preview,
        template = template,
        toggleBtn = toggleBtn,
        closeBtn = closeBtn,
        inputBox = inputBox,
        enterBtn = enterBtn,
        applyBtn = applyBtn,
        hiddenPos = typeof(hiddenPos) == "UDim2" and hiddenPos or UDim2.new(0.5, 0, -0.6, 0),
        shownPos = typeof(shownPos) == "UDim2" and shownPos or UDim2.new(0.5, 0, 0.5, 0),
    }
end

return AvatarUIResolver
