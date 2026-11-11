--!nonstrict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local RaceRender = {}
local _finishPart = nil

local function resolveFinishPart()
    local maps = Workspace:FindFirstChild("JaleMaps")
    local raceFolder = maps and maps:FindFirstChild("Race")
    local finishPart = raceFolder and raceFolder:FindFirstChild("Finish", true)
    if finishPart and finishPart:IsA("BasePart") then
        return finishPart
    end
    return nil
end

local function getRootPart(player)
    local character = player and player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function setText(label, value)
    if label and label:IsA("TextLabel") or label and label:IsA("TextBox") then
        label.Text = tostring(value)
    end
end

local function clearList(list, template)
    if not list then
        return
    end
    for _, child in ipairs(list:GetChildren()) do
        if child ~= template and child:IsA("GuiObject") then
            child:Destroy()
        end
    end
end

local function cloneLeaderboardEntries(entries)
    local snapshot = {}
    for index, entry in ipairs(entries or {}) do
        snapshot[index] = {
            userId = entry.userId,
            name = entry.name,
            displayName = entry.displayName,
            lapCount = entry.lapCount,
            finished = entry.finished,
            status = entry.status,
        }
    end
    return snapshot
end

function RaceRender.applyPermission(refs, canUse)
    refs._canUseRaceAdmin = canUse == true
    if refs.Root then
        refs.Root.Visible = true
    end
    if refs.Toggle then
        refs.Toggle.Visible = canUse == true
    end
    if canUse ~= true and refs.Panel then
        refs.Panel.Visible = false
    end
end

function RaceRender.renderState(refs, state)
    state = state or {}
    local isDisplayAlive = state.status ~= "Deactive"
    local shouldKeepDisplay = refs._displayPinnedOpen == true or isDisplayAlive
    local isRaceRunning = state.active == true or state.status == "Preparing" or state.status == "Countdown" or state.status == "Active"
    local entriesByUserId = {}
    local unfinished = {}
    local leaderboard = {}
    _finishPart = _finishPart and _finishPart.Parent and _finishPart or resolveFinishPart()

    if refs._finishOrder == nil then
        refs._finishOrder = {}
    end
    if refs._finishSet == nil then
        refs._finishSet = {}
    end

    if state.status == "Deactive" then
        refs._finishOrder = {}
        refs._finishSet = {}
        if refs._displayPinnedOpen ~= true then
            refs._lastLeaderboardEntries = nil
        end
    end

    setText(refs.ActiveText, state.active == true and "Active" or "Deactive")
    setText(refs.PlayerCount, string.format("%d Players", state.playerCount or 0))
    setText(
        refs.Status,
        string.format(
            "Race Status: %s | Wins: %s | Laps: %s",
            tostring(state.status or "Deactive"),
            tostring(state.maxWins or 1),
            tostring(state.laps or 1)
        )
    )
    setText(refs.Total, string.format("Total Joins: %s", tostring(state.totalJoins or 0)))

    if refs.AccessDisplay then
        refs.AccessDisplay.Visible = (refs._canUseRaceAdmin == true) and shouldKeepDisplay and (refs._displayToggleOn ~= false)
        if refs._applyAccessDisplayPosition then
            refs._applyAccessDisplayPosition(false)
        end
    end

    if refs.Confirm then
        refs.Confirm.Visible = not isRaceRunning
    end
    if refs.Cancel then 
        refs.Cancel.Visible = shouldKeepDisplay
    end

    if refs.Template then
        refs.Template.Visible = false
    end

    if not refs.List or not refs.Template then
        return
    end

    local joinedPlayers = state.joinedPlayers or {}
    local sourcePlayers = joinedPlayers
    if #joinedPlayers == 0 and refs._displayPinnedOpen == true and refs._lastLeaderboardEntries then
        sourcePlayers = refs._lastLeaderboardEntries
    end

    clearList(refs.List, refs.Template)

    for _, racer in ipairs(sourcePlayers) do
        local player = Players:GetPlayerByUserId(racer.userId)
        local root = getRootPart(player)
        local distance = math.huge
        if _finishPart and root then
            distance = (_finishPart.Position - root.Position).Magnitude
        end
        local entry = {
            racer = racer,
            distance = distance,
            finished = racer.finished == true or racer.status == "Finished",
        }
        entriesByUserId[racer.userId] = entry
        if entry.finished then
            if not refs._finishSet[racer.userId] then
                refs._finishSet[racer.userId] = true
                table.insert(refs._finishOrder, racer.userId)
            end
        else
            table.insert(unfinished, entry)
        end
    end

    table.sort(unfinished, function(a, b)
        local aLap = tonumber(a.racer.lapCount or a.racer.lap or 0) or 0
        local bLap = tonumber(b.racer.lapCount or b.racer.lap or 0) or 0
        if aLap ~= bLap then
            return aLap > bLap
        end
        if a.distance ~= b.distance then
            return a.distance < b.distance
        end
        local aName = tostring(a.racer.displayName or a.racer.name or "")
        local bName = tostring(b.racer.displayName or b.racer.name or "")
        return aName < bName
    end)

    local aliveFinishOrder = {}
    local aliveFinishSet = {}
    for _, userId in ipairs(refs._finishOrder) do
        local entry = entriesByUserId[userId]
        if entry and entry.finished then
            table.insert(leaderboard, entry)
            table.insert(aliveFinishOrder, userId)
            aliveFinishSet[userId] = true
        end
    end
    refs._finishOrder = aliveFinishOrder
    refs._finishSet = aliveFinishSet

    for _, entry in ipairs(unfinished) do
        table.insert(leaderboard, entry)
    end

    if #leaderboard > 0 then
        local snapshot = {}
        for index, item in ipairs(leaderboard) do
            snapshot[index] = item.racer
        end
        refs._lastLeaderboardEntries = cloneLeaderboardEntries(snapshot)
    elseif refs._displayPinnedOpen ~= true then
        refs._lastLeaderboardEntries = nil
    end

    for index, item in ipairs(leaderboard) do
        local racer = item.racer
        local row = refs.Template:Clone()
        row.Name = tostring(racer.userId or racer.name or "Racer")
        row.Visible = true
        row.Parent = refs.List

        local nameLabel = row:FindFirstChild("Name")
        if nameLabel and nameLabel:IsA("TextLabel") then
            local displayName = racer.displayName or racer.name or "Unknown"
            nameLabel.Text = string.format("#%d %s", index, displayName)
        end
    end
end

return RaceRender
