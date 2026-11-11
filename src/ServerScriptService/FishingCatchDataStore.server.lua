local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local FishingCatchSuccess = ReplicatedStorage:WaitForChild("FishingCatchSuccess")
local GetFishIndex = FishingSystem:WaitForChild("GetFishIndex")
local RecordFishCatch = FishingSystem:FindFirstChild("RecordFishCatch")

local catchDataStore = nil
local indexDataStore = nil

pcall(function()
    catchDataStore = DataStoreService:GetDataStore("FishingCatchDataStore")
    indexDataStore = DataStoreService:GetDataStore("PlayerFishIndexDataStore")
end)

-- In-memory cache for player indices & catch count
local playerFishIndices = {}
local isStudio = game:GetService("RunService"):IsStudio()

local function setupLeaderboard(player, savedCatch)
    local stats = player:FindFirstChild("leaderstats")
    if not stats then
        stats = Instance.new("Folder")
        stats.Name = "leaderstats"
        stats.Parent = player
    end

    local catch = stats:FindFirstChild("Tangkapan")
    if not catch then
        catch = Instance.new("IntValue")
        catch.Name = "Tangkapan"
        catch.Parent = stats
    end

    catch.Value = savedCatch or 0
end

local function loadPlayerData(player)
    local savedCatch = 0
    local savedIndex = {}

    if catchDataStore then
        local successCatch, resCatch = pcall(function()
            return catchDataStore:GetAsync("Catch_" .. player.UserId)
        end)
        if successCatch and type(resCatch) == "number" then
            savedCatch = resCatch
        end
    end
    setupLeaderboard(player, savedCatch)

    if indexDataStore then
        local successIndex, resIndex = pcall(function()
            return indexDataStore:GetAsync("Index_" .. player.UserId)
        end)
        if successIndex and type(resIndex) == "table" then
            savedIndex = resIndex
        end
    end
    playerFishIndices[player] = savedIndex
end

Players.PlayerAdded:Connect(loadPlayerData)

for _, p in ipairs(Players:GetPlayers()) do
    task.spawn(loadPlayerData, p)
end

local lastIndexInvoke = {}

local function savePlayerData(player)
    local userId = player.UserId
    local stats = player:FindFirstChild("leaderstats")
    if stats and catchDataStore then
        local catch = stats:FindFirstChild("Tangkapan")
        if catch and typeof(catch.Value) == "number" then
            local targetVal = catch.Value
            local tries = 0
            while tries < 3 do
                tries += 1
                -- H-01 Fix: UpdateAsync prevents race condition and atomic data loss
                local ok, err = pcall(function()
                    catchDataStore:UpdateAsync("Catch_" .. userId, function(oldVal)
                        if oldVal and type(oldVal) == "number" then
                            return math.max(oldVal, targetVal)
                        end
                        return targetVal
                    end)
                end)
                if ok then break end
                if tries < 3 then task.wait(0.5 * tries) end
            end
        end
    end

    local idx = playerFishIndices[player]
    if idx and indexDataStore and type(idx) == "table" then
        local tries = 0
        while tries < 3 do
            tries += 1
            -- H-01 Fix: UpdateAsync merges fish index without dropping discovered species
            local ok, err = pcall(function()
                indexDataStore:UpdateAsync("Index_" .. userId, function(oldIndex)
                    local merged = {}
                    if oldIndex and type(oldIndex) == "table" then
                        for k, v in pairs(oldIndex) do
                            merged[k] = v
                        end
                    end
                    for k, v in pairs(idx) do
                        merged[k] = math.max(merged[k] or 0, v)
                    end
                    return merged
                end)
            end)
            if ok then break end
            if tries < 3 then task.wait(0.5 * tries) end
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    savePlayerData(player)
    playerFishIndices[player] = nil
    lastIndexInvoke[player.UserId] = nil
end)

-- ===================================================================
-- PERIODIC AUTOSAVE (EVERY 60 SECONDS)
-- ===================================================================
task.spawn(function()
    while task.wait(60) do
        for _, player in ipairs(Players:GetPlayers()) do
            task.spawn(savePlayerData, player)
        end
    end
end)

game:BindToClose(function()
    local players = Players:GetPlayers()
    if #players == 0 then return end
    local finished = 0
    for _, player in ipairs(players) do
        task.spawn(function()
            savePlayerData(player)
            finished += 1
        end)
    end
    local startTime = os.clock()
    while finished < #players and (os.clock() - startTime < 10) do
        task.wait(0.1)
    end
end)

-- Return player caught fish table (with 1.0s spam throttle)
GetFishIndex.OnServerInvoke = function(player)
    local now = os.clock()
    if lastIndexInvoke[player.UserId] and (now - lastIndexInvoke[player.UserId]) < 1.0 then
        return playerFishIndices[player] or {}
    end
    lastIndexInvoke[player.UserId] = now
    return playerFishIndices[player] or {}
end

-- Core function to record catch (server-validated fish only)
local function recordCatch(player, fishName)
    if not player or not player:IsDescendantOf(Players) then return end
    if type(fishName) ~= "string" or fishName == "" then return end

    local stats = player:FindFirstChild("leaderstats")
    if stats then
        local catch = stats:FindFirstChild("Tangkapan")
        if catch then
            catch.Value = catch.Value + 1
        end
    end

    local idx = playerFishIndices[player]
    if not idx then
        idx = {}
        playerFishIndices[player] = idx
    end
    idx[fishName] = (idx[fishName] or 0) + 1
    FishingCatchSuccess:FireClient(player, fishName, idx[fishName])
end

-- Record catch via server BindableEvent (fired by FishingServer after validation)
if RecordFishCatch then
    RecordFishCatch.Event:Connect(recordCatch)
end
