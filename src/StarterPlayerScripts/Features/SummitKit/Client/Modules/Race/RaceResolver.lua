--!nonstrict
local RaceResolver = {}

local function waitForChild(root, childName, timeoutSeconds)
    if not root then
        return nil
    end
    local startedAt = os.clock()
    repeat
        local child = root:FindFirstChild(childName)
        if child then
            return child
        end
        task.wait(0.1)
    until (os.clock() - startedAt) >= (timeoutSeconds or 10)
    return nil
end

local function findPath(root, path)
    local current = root
    for _, name in ipairs(path) do
        current = current and current:FindFirstChild(name) or nil
    end
    return current
end

local function findFirstDescendant(root, childName)
    if not root then
        return nil
    end
    return root:FindFirstChild(childName, true)
end

function RaceResolver.resolve(playerGui)
    local gameUI = playerGui and (playerGui:FindFirstChild("GameUI") or waitForChild(playerGui, "GameUI", 30)) or nil
    local component = gameUI and (gameUI:FindFirstChild("Component") or waitForChild(gameUI, "Component", 10)) or nil
    local menus = gameUI and (gameUI:FindFirstChild("Menus") or waitForChild(gameUI, "Menus", 10)) or nil
    local buttons = component and (component:FindFirstChild("Buttons") or waitForChild(component, "Buttons", 10)) or nil
    local adminRight = buttons and (buttons:FindFirstChild("AdminRight") or waitForChild(buttons, "AdminRight", 10)) or nil
    local root = menus and (menus:FindFirstChild("Race") or waitForChild(menus, "Race", 10)) or nil
    local toggle = adminRight and (adminRight:FindFirstChild("Race") or findFirstDescendant(adminRight, "Race") or waitForChild(adminRight, "Race", 10)) or nil
    local panel = findPath(root, { "Panel" })
    local actions = findPath(panel, { "Container", "Actions" })
    local send = findPath(actions, { "Send" })
    local display = findPath(panel, { "Container", "Display" })
    local accessDisplay = findPath(root, { "Display" })
    local accessDisplayButton = accessDisplay and (accessDisplay:FindFirstChild("toggle") or findFirstDescendant(accessDisplay, "toggle"))
        or display and (display:FindFirstChild("toggle") or findFirstDescendant(display, "toggle"))
        or nil
    local announce = findPath(root, { "Announce" })
    local notifications = findPath(root, { "Notifications" })

    return {
        GameUI = gameUI,
        Toggle = toggle,
        Root = root,
        Panel = panel,
        Close = findPath(panel, { "Header", "Close" }),
        Wins = findPath(actions, { "Frame", "Wins" }),
        Laps = findPath(actions, { "Frame2", "Laps" }),
        Send = send,
        Confirm = send and (send:FindFirstChild("Confirm") or waitForChild(send, "Confirm", 10)) or nil,
        Cancel = send and (send:FindFirstChild("Cancel") or waitForChild(send, "Cancel", 10)) or nil,
        ActiveText = findPath(display, { "Frame", "Text" }),
        PlayerCount = findPath(display, { "Frame2", "Text" }),
        Status = findPath(display, { "Status" }),
        Total = findPath(display, { "Total" }),
        AccessDisplay = accessDisplay,
        AccessDisplayButton = accessDisplayButton,
        List = findPath(accessDisplay, { "Container", "List" }),
        Template = findPath(accessDisplay, { "Container", "List", "Template" }),
        Announce = announce,
        AnnounceHeaderFrame = findPath(announce, { "Header" }),
        AnnounceHeader = findPath(announce, { "Header", "Text" }),
        AnnounceTimerFrame = findPath(announce, { "Timer" }),
        AnnounceTimer = findPath(announce, { "Timer", "Text" }),
        Notifications = notifications,
        NotificationTitle = findPath(notifications, { "Title" }),
    }
end

return RaceResolver
