--!nonstrict
local SettingResolver = {}

function SettingResolver.Resolve(playerGui)
    local gameUI = playerGui:FindFirstChild("GameUI") or playerGui:WaitForChild("GameUI", 60)
    if not gameUI then return false, "GameUI not found" end

    local component = gameUI:FindFirstChild("Component") or gameUI:WaitForChild("Component", 60)
    local menus = gameUI:FindFirstChild("Menus") or gameUI:WaitForChild("Menus", 60)
    if not (component and menus) then
        return false, "Component or Menus missing"
    end

    local buttons = component:FindFirstChild("ButtonsNew")
    local menuKiri = buttons and buttons:FindFirstChild("MenuKiri")
    local frameBtn = menuKiri and menuKiri:FindFirstChild("FrameBtn")
    local toggleBtn = frameBtn and frameBtn:FindFirstChild("SettingButton")
    if toggleBtn and not toggleBtn:IsA("GuiButton") then
        warn("[SettingResolver] Expected Setting toggle as ImageButton/TextButton, got " .. toggleBtn.ClassName)
    end

    local menu = menus:FindFirstChild("Setting")
    local background = menu and menu:FindFirstChild("Background")
    local header = background and background:FindFirstChild("Header")
    local closeBtn = header and header:FindFirstChild("Close")
    local container = background and background:FindFirstChild("Container")
    local list = container and container:FindFirstChild("List")

    local function fetchAdjuster(name)
        local frame = list and list:FindFirstChild(name)
        local bg = frame and frame:FindFirstChild("Background")
        local actions = bg and bg:FindFirstChild("Actions")
        local minBtn = actions and actions:FindFirstChild("Min")
        local plusBtn = actions and actions:FindFirstChild("Plus")
        local valueLbl = actions and actions:FindFirstChild("Value")
        return {
            Frame = frame,
            Min = minBtn,
            Plus = plusBtn,
            Value = valueLbl,
        }
    end

    local function fetchToggle(name)
        local frame = list and list:FindFirstChild(name)
        local bg = frame and frame:FindFirstChild("Background")
        local sliding = bg and bg:FindFirstChild("Slidding")
        local indicator = sliding and sliding:FindFirstChild("Indicator")
        return {
            Frame = frame,
            Sliding = sliding,
            Indicator = indicator,
        }
    end

    local refs = {
        ToggleBtn = toggleBtn,
        Menu = menu,
        Close = closeBtn,
        HiddenPos = menu and menu:GetAttribute("HiddenPos") or (menu and menu.Position),
        ShownPos = menu and (menu:GetAttribute("ShownPos") or UDim2.fromScale(0.5, 0.5)),
        Targets = {
            Jump = component and (component:FindFirstChild("Jump") or component:FindFirstChild("JumpButton") or component:FindFirstChild("JumpUI")),
            Shiftlock = component and (component:FindFirstChild("Shiflock") or component:FindFirstChild("Shiftlock")),
        },
        Toggles = {
            Title = fetchToggle("Title"),
            Players = fetchToggle("Players"),
            Effect = fetchToggle("Effect"),
            Blur = fetchToggle("Blur"),
            Shadow = fetchToggle("Shadow"),
        },
        Adjusters = {
            JumpSize = fetchAdjuster("JumpSize"),
            JumpVertical = fetchAdjuster("JumpVertical"),
            JumpHorizontal = fetchAdjuster("JumpHorizontal"),
            ShiftlockSize = fetchAdjuster("ShiflockSize") or fetchAdjuster("ShiftlockSize"),
            ShiftlockVertical = fetchAdjuster("ShiflcokVertical") or fetchAdjuster("ShiftlockVertical"),
            ShiftlockHorizontal = fetchAdjuster("ShiflockHorizontal") or fetchAdjuster("ShiftlockHorizontal"),
            Reset = list and list:FindFirstChild("Reset"),
        },
    }

    if not refs.Menu or not refs.Close then
        return false, "Setting menu structure incomplete"
    end

    return true, refs
end

return SettingResolver
