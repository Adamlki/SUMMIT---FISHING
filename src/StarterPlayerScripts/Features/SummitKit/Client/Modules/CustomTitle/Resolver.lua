--!nonstrict
local Resolver = {}

local TIMEOUT = 60

local function waitForPath(root, names, timeout)
    local current = root
    for _, name in ipairs(names) do
        if not current then
            return nil
        end

        local ok, obj = pcall(function()
            return current:WaitForChild(name, timeout or TIMEOUT)
        end)
        if not ok or not obj then
            return nil
        end

        current = obj
    end

    return current
end

function Resolver.Resolve(playerGui)
    local gameUi = playerGui:FindFirstChild("GameUI") or waitForPath(playerGui, {"GameUI"})
    if not gameUi then
        return false, "GameUI not found"
    end

    local menus = gameUi:FindFirstChild("Menus") or waitForPath(gameUi, {"Menus"})
    local component = gameUi:FindFirstChild("Component") or waitForPath(gameUi, {"Component"})
    if not (menus and component) then
        return false, "GameUI.Component or GameUI.Menus not found"
    end

    local buttons = component and component:FindFirstChild("ButtonsNew")
    local menuKanan = buttons and buttons:FindFirstChild("MenuKanan")
    local toggle = menuKanan and menuKanan:FindFirstChild("TitleButton")
    local titleMenu = menus and (menus:FindFirstChild("Title") or menus:WaitForChild("Title", 20))
    if not titleMenu then
        return false, "Title menu not found"
    end

    local header = titleMenu:FindFirstChild("Header")
    local container = titleMenu:FindFirstChild("Container")
    local list = container and container:FindFirstChild("List")
    local actions = container and container:FindFirstChild("Actions")
    local searchFrame = container and container:FindFirstChild("Players")
    local playersPanel = titleMenu:FindFirstChild("Players")

    local refs = {
        Menu = titleMenu,
        Toggle = toggle,
        Close = header and header:FindFirstChild("Close"),
        Give = actions and actions:FindFirstChild("Give"),
        Remove = actions and actions:FindFirstChild("Remove"),
        Clear = actions and actions:FindFirstChild("Clear"),
        Search = searchFrame and searchFrame:FindFirstChildOfClass("TextBox"),
        Group = list and list:FindFirstChild("Group"),
        Input = list and list:FindFirstChild("Input"),
        Color1 = list and list:FindFirstChild("Color1"),
        Color2 = list and list:FindFirstChild("Color2"),
        Color3 = list and list:FindFirstChild("Color3"),
        Color4 = list and list:FindFirstChild("Color4"),
        Preview = list and list:FindFirstChild("Preview"),
        PlayersPanel = playersPanel,
        PlayersList = playersPanel and playersPanel:FindFirstChild("List"),
        PlayerTemplate = playersPanel and playersPanel:FindFirstChild("List") and playersPanel.List:FindFirstChild("Template"),
    }

    if refs.Group then
        refs.ColorButton = refs.Group:FindFirstChild("Color")
        refs.ModeButton = refs.Group:FindFirstChild("Mode")
        refs.SlotButton = refs.Group:FindFirstChild("Slot")
    end

    refs.InputText = refs.Input and refs.Input:FindFirstChildOfClass("TextBox")
    refs.Color1Text = refs.Color1 and refs.Color1:FindFirstChildOfClass("TextBox")
    refs.Color2Text = refs.Color2 and refs.Color2:FindFirstChildOfClass("TextBox")
    refs.Color3Text = refs.Color3 and refs.Color3:FindFirstChildOfClass("TextBox")
    refs.Color4Text = refs.Color4 and refs.Color4:FindFirstChildOfClass("TextBox")
    if refs.Preview then
        refs.PreviewText = refs.Preview:FindFirstChild("Label") or refs.Preview:FindFirstChildOfClass("TextLabel")
    end

    if not (refs.Menu and refs.Search and refs.Group and refs.InputText and refs.PreviewText) then
        return false, "Title menu structure incomplete"
    end

    return true, refs
end

return Resolver
