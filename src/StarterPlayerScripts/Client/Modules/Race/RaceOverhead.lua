--!nonstrict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local RaceOverhead = {}
RaceOverhead.__index = RaceOverhead

function RaceOverhead.new(template)
    return setmetatable({
        _template = template,
        _billboards = {},
        _finishPart = nil,
    }, RaceOverhead)
end

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

function RaceOverhead:_getBillboard(player)
    local entry = self._billboards[player]
    if entry and entry.Parent then
        return entry
    end

    local character = player.Character
    local head = character and character:FindFirstChild("Head")
    if not head or not self._template then
        return nil
    end

    local billboard = head:FindFirstChild("RaceUI")
    if not billboard then
        billboard = self._template:Clone()
        billboard.Name = "RaceUI"
        billboard.Parent = head
    end

    self._billboards[player] = billboard
    return billboard
end

function RaceOverhead:_destroyBillboard(player)
    local billboard = self._billboards[player]
    if billboard then
        billboard:Destroy()
        self._billboards[player] = nil
    end
end

function RaceOverhead:render(state, canSee)
    if canSee ~= true then
        for player in pairs(self._billboards) do
            self:_destroyBillboard(player)
        end
        return
    end

    -- state = state or {}
    -- self._finishPart = self._finishPart and self._finishPart.Parent and self._finishPart or resolveFinishPart()
    state = state or {}
    if state.status == "Finished" or state.active ~= true then 
        for player in pairs(self._billboards) do
            self:_destroyBillboard(player)
        end
        return
    end

    self._finishPart = self._finishPart and self._finishPart.Parent and self._finishPart or resolveFinishPart()

    local ranking = {}
    local finishPart = self._finishPart
    local visible = {}
    local finishedCount = tonumber(state.finishedCount) or 0
    for _, racer in ipairs(state.joinedPlayers or {}) do
        if racer.finished ~= true and racer.status ~= "Finished" then
            local player = Players:GetPlayerByUserId(racer.userId)
            if player then
                local root = getRootPart(player)
                local distance = math.huge
                if finishPart and root then
                    distance = (finishPart.Position - root.Position).Magnitude
                end
                table.insert(ranking, {
                    player = player,
                    racer = racer,
                    distance = distance,
                    finished = racer.finished == true or racer.status == "Finished",
                })
            end
        end
    end

    table.sort(ranking, function(a, b)
        if a.finished ~= b.finished then
            return a.finished
        end
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

    for index, item in ipairs(ranking) do
        local player = item.player
        local _racer = item.racer
        if player then
            visible[player] = true
            local billboard = self:_getBillboard(player)
            local top = billboard and billboard:FindFirstChild("Top")
            if top and top:IsA("TextLabel") then
                top.Text = string.format("#%d", finishedCount + index)
            end
            if billboard then
                billboard.Enabled = state.active == true
            end
        end
    end

    for player in pairs(self._billboards) do
        if not visible[player] then
            self:_destroyBillboard(player)
        end
    end
end

function RaceOverhead:destroy()
    for player in pairs(self._billboards) do
        self:_destroyBillboard(player)
    end
end

function RaceOverhead:onCharacterAdded(player)
    self._billboards[player] = nil
end

return RaceOverhead
