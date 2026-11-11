--!nonstrict

local SignalManager = {}

local function addToJanitor(janitor, connection)
    if janitor then
        janitor:Add(connection, "Disconnect")
    end
end

local function bindLeaderstats(player, entry, onRefresh)
    local janitor = entry.janitor
    if entry.summitConn then
        entry.summitConn:Disconnect()
    end
    if entry.summitChildConn then
        entry.summitChildConn:Disconnect()
    end
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return
    end

    local summit = leaderstats:FindFirstChild("Summit")
    if summit then
        entry.summitConn = summit:GetPropertyChangedSignal("Value"):Connect(function()
            onRefresh(player)
        end)
        addToJanitor(janitor, entry.summitConn)
    end

    entry.summitChildConn = leaderstats.ChildAdded:Connect(function(child)
        if child.Name == "Summit" then
            bindLeaderstats(player, entry, onRefresh)
            onRefresh(player)
        end
    end)
    addToJanitor(janitor, entry.summitChildConn)
end

function SignalManager.bindPlayerSignals(player, entry, getConfig, onRefresh)
    local conns = entry.conns
    local janitor = entry.janitor

    bindLeaderstats(player, entry, onRefresh)

    local conn = player:GetPropertyChangedSignal("DisplayName"):Connect(function()
        onRefresh(player)
    end)
    table.insert(conns, conn)
    addToJanitor(janitor, conn)

    conn = player.AttributeChanged:Connect(function(attributeName)
        local cfg = getConfig()
        if not cfg then
            return
        end
        local customText = cfg.CustomTitleTextAttribute or "CustomTitleText"
        local customImage = cfg.CustomTitleImageAttribute or "CustomTitleImage"
        local customColor = cfg.CustomTitleTextColorAttribute or "CustomTitleTextColor"
        local customBg = cfg.CustomTitleBgAttribute or "CustomTitleBgColor"
        local customMode = cfg.CustomTitleModeAttribute or "CustomTitleMode"
        local customSlot = cfg.CustomTitleSlotAttribute or "CustomTitleSlot"
        local customTextGrad = cfg.CustomTitleTextGradientAttribute or "CustomTitleTextGradient"
        local customBgGrad = cfg.CustomTitleBgGradientAttribute or "CustomTitleBgGradient"
        local function isCustom(name, base)
            return name == base or string.sub(name, 1, #base + 1) == (base .. "_")
        end
        if attributeName == cfg.VipAttribute
            or attributeName == cfg.DeviceAttribute
            or attributeName == "CountryCode"
            or isCustom(attributeName, customText)
            or isCustom(attributeName, customImage)
            or isCustom(attributeName, customColor)
            or isCustom(attributeName, customBg)
            or isCustom(attributeName, customMode)
            or isCustom(attributeName, customTextGrad)
            or isCustom(attributeName, customBgGrad)
            or attributeName == customSlot then
            onRefresh(player)
        end
    end)
    table.insert(conns, conn)
    addToJanitor(janitor, conn)

    conn = player.ChildAdded:Connect(function(child)
        local cfg = getConfig()
        if not cfg then
            return
        end
        if child.Name == "leaderstats" then
            bindLeaderstats(player, entry, onRefresh)
            onRefresh(player)
        elseif child.Name == cfg.VipAttribute or child.Name == "VIP" then
            onRefresh(player)
        end
    end)
    table.insert(conns, conn)
    addToJanitor(janitor, conn)

    conn = player.ChildRemoved:Connect(function(child)
        local cfg = getConfig()
        if not cfg then
            return
        end
        if child.Name == "leaderstats" then
            bindLeaderstats(player, entry, onRefresh)
            onRefresh(player)
        elseif child.Name == cfg.VipAttribute or child.Name == "VIP" then
            onRefresh(player)
        end
    end)
    table.insert(conns, conn)
    addToJanitor(janitor, conn)
end

function SignalManager.teardownConnections(entry)
    if entry.janitor then
        entry.janitor:Destroy()
    else
        for _, conn in ipairs(entry.conns) do
            conn:Disconnect()
        end
        if entry.summitConn then
            entry.summitConn:Disconnect()
        end
        if entry.summitChildConn then
            entry.summitChildConn:Disconnect()
        end
    end
end

return SignalManager
