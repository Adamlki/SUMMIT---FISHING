local RoleConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Configs"):WaitForChild("RoleConfig"))
local RunService = game:GetService("RunService")
-- FishData - FIXED VERSION (Leaderstats Conflict Solved)
-- Key Changes:
-- 1. Checks for existing leaderstats before creating a new folder to merge with Checkpoint/Summit.
-- 2. Maintained optimizations (caching, throttling).

local SSS = game:GetService("ServerScriptService")
local DataStoreConfig = require(SSS:WaitForChild("Configs"):WaitForChild("DataStoreConfig"))
local Players = game:GetService("Players")
local ProfileService = require(SSS.Data.DataModule:WaitForChild("ProfileService"))
local dataStoreService = game:GetService("DataStoreService")

-- ===================================================================
-- THROTTLE PROTECTION
-- ===================================================================
local LEADERBOARD_UPDATE_COOLDOWN = 60 -- Only update leaderboards every 60 seconds
local lastLeaderboardUpdate = {}

local function updateLeaderboardThrottled(store, userId, statValue)
	local lastUpdate = lastLeaderboardUpdate[userId] or 0
	local now = os.time()

	-- Only update if enough time has passed
	if now - lastUpdate >= LEADERBOARD_UPDATE_COOLDOWN then
		lastLeaderboardUpdate[userId] = now
		task.spawn(function()
			pcall(function()
				store:SetAsync(userId, statValue)
			end)
		end)
	end
end

-- ===================================================================
-- SCRIPT SIGNAL (unchanged)
-- ===================================================================
local function NewScriptSignal()
	local ScriptConnection = {}
	ScriptConnection.__index = ScriptConnection

	function ScriptConnection:Disconnect()
		if self._is_connected == false then return end
		self._is_connected = false
		self._script_signal._listener_count -= 1
		if self._script_signal._head == self then
			self._script_signal._head = self._next
		else
			local prev = self._script_signal._head
			while prev ~= nil and prev._next ~= self do prev = prev._next end
			if prev ~= nil then prev._next = self._next end
		end
	end

	local ScriptSignal = {}
	ScriptSignal.__index = ScriptSignal

	function ScriptSignal:Connect(listener)
		local script_connection = {
			_listener = listener,
			_script_signal = self,
			_next = self._head,
			_is_connected = true,
		}
		setmetatable(script_connection, ScriptConnection)
		self._head = script_connection
		self._listener_count += 1
		return script_connection
	end

	function ScriptSignal:Fire(...)
		local item = self._head
		while item ~= nil do
			if item._is_connected == true then
				task.spawn(item._listener, ...)
			end
			item = item._next
		end
	end

	return setmetatable({_head = nil, _listener_count = 0}, ScriptSignal)
end

local GAME_DATA_STORE_KEY = DataStoreConfig.Stores.PlayerGameData

local PlayerProfileTemplate = {
	Coins = 0,
	OwnedGamepasses = {},
	SavedFish = {},
	TotalFishCaught = 0,
	OwnedRods = {"Basic Rod"},
	LastEquippedRod = "Basic Rod",
	LastPosition = nil,
	LastSessionState = nil,
	FishInventoryLimit = 500,
	HasRemoteSell = false,
	OwnedTrails = {},
	EquippedTrail = "",
}

local PlayerProfileStore = ProfileService.GetProfileStore(
	GAME_DATA_STORE_KEY,
	PlayerProfileTemplate
)

local USE_MOCK_IN_STUDIO = false -- Set false agar data saat testing di Studio tersimpan permanen ke cloud DataStore

if RunService:IsStudio() and USE_MOCK_IN_STUDIO then
	PlayerProfileStore = PlayerProfileStore.Mock
	print("[FishData] ProfileService running in MOCK mode (Studio data will NOT persist to cloud).")
else
	print("[FishData] ProfileService running in REAL DATASTORE mode (Studio and live persist to cloud).")
end

local PlayerProfiles = {}

local GameProfileService = {}
GameProfileService.ProfileLoadedSignal = NewScriptSignal()

local CURRENCY_AMOUNT_PER_INTERVAL = 6
local CURRENCY_INCREASE_INTERVAL_SECONDS = 120

-- ===================================================================
-- CORE PROFILE FUNCTIONS (unchanged)
-- ===================================================================
function GameProfileService:GetProfile(player)
	local profile = PlayerProfiles[player]
	if profile and profile:IsActive() then
		return profile
	end

	local startTime = os.clock()
	local TIMEOUT_SECONDS = 15
	local checkInterval = 0.1

	while not (profile and profile:IsActive()) and (os.clock() - startTime < TIMEOUT_SECONDS) do
		task.wait(checkInterval)
		profile = PlayerProfiles[player]
	end

	if not (profile and profile:IsActive()) then
		warn(string.format("⚠️ Profile for player %s not loaded after %d seconds!", player.Name, TIMEOUT_SECONDS))
		return nil
	end

	return profile
end

-- ===================================================================
-- COIN MANAGEMENT (unchanged)
-- ===================================================================
function GameProfileService:AddCoins(player, amount)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	profile.Data.Coins = math.max(0, (profile.Data.Coins or 0) + amount)

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then coins.Value = profile.Data.Coins end
	end

	player:SetAttribute("Coins", profile.Data.Coins)
	return true
end

function GameProfileService:SetCoins(player, amount)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	profile.Data.Coins = math.max(0, amount)

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then coins.Value = profile.Data.Coins end
	end

	player:SetAttribute("Coins", profile.Data.Coins)
	return true
end

function GameProfileService:TryPurchase(player, cost)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false, 0 end

	local currentCoins = profile.Data.Coins or 0
	if currentCoins < cost then return false, currentCoins end

	profile.Data.Coins = currentCoins - cost

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then coins.Value = profile.Data.Coins end
	end

	player:SetAttribute("Coins", profile.Data.Coins)
	return true, profile.Data.Coins
end

function GameProfileService:GetCoins(player)
	local profile = self:GetProfile(player)
	if not profile then return 0 end
	return profile.Data.Coins or 0
end

function GameProfileService:SavePlayerData(player)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	-- H-01 Fix: profile.Data.Coins is the single source of truth
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins and typeof(coins.Value) == "number" then
			if coins.Value > 0 then
				profile.Data.Coins = coins.Value
			elseif (profile.Data.Coins or 0) > 0 then
				-- Restore view from authoritative profile data if leaderstats was corrupted/zeroed
				coins.Value = profile.Data.Coins
			end
		end
	end

	return true
end

-- ===================================================================
-- FISHING SYSTEM FUNCTIONS (unchanged except RemoveFish)
-- ===================================================================
function GameProfileService:GetFishInventoryLimit(player)
	local profile = self:GetProfile(player)
	if not profile then return 500 end
	return profile.Data.FishInventoryLimit or 500
end

function GameProfileService:AddFish(player, fishData)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false, nil end

	if not profile.Data.SavedFish then profile.Data.SavedFish = {} end

	local limit = profile.Data.FishInventoryLimit or 500
	if #profile.Data.SavedFish >= limit then
		return false, nil
	end

	local uniqueId = game:GetService("HttpService"):GenerateGUID(false)
	local fishEntry = {
		name = fishData.name,
		weight = fishData.weight,
		rarity = fishData.rarity or "Common",
		uniqueId = uniqueId,
		timestamp = tick(),
		isFavorited = false
	}

	table.insert(profile.Data.SavedFish, fishEntry)

	return true, uniqueId
end

function GameProfileService:RemoveFish(player, fishUniqueId)
	local profile = self:GetProfile(player)
	if not profile or not profile.Data.SavedFish then return false, nil end

	for i, fish in ipairs(profile.Data.SavedFish) do
		if fish.uniqueId == fishUniqueId then
			-- CEK FAVORIT: Jika ikan favorit, tidak bisa dihapus/terjual!
			if fish.isFavorited == true then
				return false, nil
			end
			local removed = table.remove(profile.Data.SavedFish, i)
			return true, removed
		end
	end

	return false, nil
end

function GameProfileService:RemoveFishBatch(player, idSet)
	local profile = self:GetProfile(player)
	if not profile or not profile.Data.SavedFish then return 0 end

	local kept = {}
	local removedCount = 0
	for _, fish in ipairs(profile.Data.SavedFish) do
		if idSet[fish.uniqueId] and fish.isFavorited ~= true then
			removedCount = removedCount + 1
		else
			table.insert(kept, fish)
		end
	end
	profile.Data.SavedFish = kept
	return removedCount
end

function GameProfileService:GetSavedFish(player)
	local profile = self:GetProfile(player)
	if not profile then return {} end
	return profile.Data.SavedFish or {}
end

function GameProfileService:ToggleFavoriteFish(player, fishUniqueId)
	local profile = self:GetProfile(player)
	if not profile or not profile.Data.SavedFish then return nil end

	for i, fish in ipairs(profile.Data.SavedFish) do
		if fish.uniqueId == fishUniqueId then
			fish.isFavorited = not fish.isFavorited
			return fish.isFavorited
		end
	end

	return nil
end

-- ===================================================================
-- ROD MANAGEMENT (unchanged)
-- ===================================================================
function GameProfileService:AddRod(player, rodName)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	if not profile.Data.OwnedRods then profile.Data.OwnedRods = {} end

	for _, r in ipairs(profile.Data.OwnedRods) do
		if r == rodName then return true end
	end

	table.insert(profile.Data.OwnedRods, rodName)
	return true
end

function GameProfileService:HasRod(player, rodName)
	if rodName == "Basic Rod" then return true end
	local RoleConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Configs"):WaitForChild("RoleConfig"))
	if RoleConfig and RoleConfig.IsOwner(player) then return true end
	local profile = self:GetProfile(player)
	if not profile or not profile.Data.OwnedRods then return false end

	for _, r in ipairs(profile.Data.OwnedRods) do
		if r == rodName then return true end
	end

	return false
end

function GameProfileService:GetOwnedRods(player)
	local RoleConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Configs"):WaitForChild("RoleConfig"))
	if RoleConfig and RoleConfig.IsOwner(player) then
		local rods = {}
		local allRods = game:GetService("ServerStorage"):FindFirstChild("AllRods")
		if allRods then
			for _, r in ipairs(allRods:GetChildren()) do
				table.insert(rods, r.Name)
			end
		end
		if not table.find(rods, "Basic Rod") then table.insert(rods, "Basic Rod") end
		return rods
	end
	local profile = self:GetProfile(player)
	if not profile then return {"Basic Rod"} end
	local list = profile.Data.OwnedRods or {}
	if not table.find(list, "Basic Rod") then
		table.insert(list, "Basic Rod")
	end
	return list
end

function GameProfileService:SetLastEquippedRod(player, rodName)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	profile.Data.LastEquippedRod = rodName
	return true
end

function GameProfileService:GetLastEquippedRod(player)
	local profile = self:GetProfile(player)
	if not profile then return nil end
	return profile.Data.LastEquippedRod
end

function GameProfileService:SetLastSessionState(player, stateData)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end
	profile.Data.LastSessionState = stateData
	return true
end

function GameProfileService:GetLastSessionState(player)
	local profile = self:GetProfile(player)
	if not profile then return nil end
	return profile.Data.LastSessionState
end

-- ===================================================================
-- TRAIL MANAGEMENT
-- ===================================================================
function GameProfileService:GetOwnedTrails(player)
	local profile = self:GetProfile(player)
	if not profile then return {} end
	if not profile.Data.OwnedTrails then
		profile.Data.OwnedTrails = {}
	end
	return profile.Data.OwnedTrails
end

function GameProfileService:HasTrail(player, trailId)
	local owned = self:GetOwnedTrails(player)
	for _, id in ipairs(owned) do
		if id == trailId then return true end
	end
	return false
end

function GameProfileService:AddTrail(player, trailId)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end
	if not profile.Data.OwnedTrails then
		profile.Data.OwnedTrails = {}
	end
	for _, id in ipairs(profile.Data.OwnedTrails) do
		if id == trailId then return true end
	end
	table.insert(profile.Data.OwnedTrails, trailId)
	return true
end

function GameProfileService:GetEquippedTrail(player)
	local profile = self:GetProfile(player)
	if not profile then return "" end
	return profile.Data.EquippedTrail or ""
end

function GameProfileService:SetEquippedTrail(player, trailId)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end
	profile.Data.EquippedTrail = trailId
	return true
end

-- ===================================================================
-- PLAYER INITIALIZATION
-- ===================================================================
local function onPlayerAdded(player)

	local success, profile = pcall(function()
		return PlayerProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	end)

	if not success then
		player:Kick("Failed to load player data due to an error. Please try rejoining.")
		return
	end

	if not profile then
		player:Kick("Failed to load player data. Please try rejoining.")
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()
	if profile.Data.HasRemoteSell == nil then profile.Data.HasRemoteSell = false end
	
	-- Anti-Race: If player already has the attribute from ExclusiveStoreServer or GamePass, persist to profile
	if player:GetAttribute("HasRemoteSell") == true or player:GetAttribute("CanSellAnywhere") == true then
		profile.Data.HasRemoteSell = true
	else
		player:SetAttribute("HasRemoteSell", profile.Data.HasRemoteSell or false)
	end

	-- Also check gamepass asynchronously as a fallback to ensure profile data is in sync
	task.spawn(function()
		local MarketplaceService = game:GetService("MarketplaceService")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local StoreConfig = nil
		pcall(function()
			StoreConfig = require(ReplicatedStorage:WaitForChild("FishingSystem"):WaitForChild("ExclusiveStoreConfig"))
		end)
		local sellAnywhereGpId = 0
		if StoreConfig and StoreConfig.Gamepasses then
			for _, gp in ipairs(StoreConfig.Gamepasses) do
				if gp.Id == "SellAnywhere" then sellAnywhereGpId = gp.GamePassId break end
			end
		end
		if sellAnywhereGpId > 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, sellAnywhereGpId)
			end)
			if ok and owns then
				profile.Data.HasRemoteSell = true
				player:SetAttribute("HasRemoteSell", true)
				player:SetAttribute("CanSellAnywhere", true)
			end
		end
	end)

	if type(profile.Data.Coins) ~= "number" then
		profile.Data.Coins = 0
	end
	if type(profile.Data.SavedFish) ~= "table" then
		profile.Data.SavedFish = {}
	end
	if type(profile.Data.OwnedRods) ~= "table" then
		profile.Data.OwnedRods = {}
	end
	if type(profile.Data.FishInventoryLimit) ~= "number" then
		profile.Data.FishInventoryLimit = 500
	end

	-- IMPORTANT: Ensure Basic Rod is owned by all players
	if not profile.Data.OwnedRods then
		profile.Data.OwnedRods = {}
	end
	if not table.find(profile.Data.OwnedRods, "Basic Rod") then
		table.insert(profile.Data.OwnedRods, "Basic Rod")
	end
	if not profile.Data.LastEquippedRod or profile.Data.LastEquippedRod == "" then
		profile.Data.LastEquippedRod = "Basic Rod"
	end

	PlayerProfiles[player] = profile

	profile:ListenToRelease(function()
		PlayerProfiles[player] = nil
	end)

	if not player:IsDescendantOf(game.Players) then
		profile:Release()
		PlayerProfiles[player] = nil
		return
	end

	GameProfileService.ProfileLoadedSignal:Fire(player)

	-- ✅ BAGIAN YANG DIPERBAIKI DI SINI:
	task.spawn(function()
		-- Cek dulu apakah Checkpoint/Summit sudah membuat leaderstats?
		local leaderstats = player:FindFirstChild("leaderstats")

		-- Jika belum ada, baru kita buat
		if not leaderstats then
			leaderstats = Instance.new("Folder")
			leaderstats.Name = "leaderstats"
			leaderstats.Parent = player
		end

		-- Cek apakah Coins sudah ada (mencegah duplikasi jika script me-load ulang)
		if not leaderstats:FindFirstChild("Coins") then
			local coins = Instance.new("IntValue")
			coins.Name = "Coins"
			coins.Value = profile.Data.Coins or 0
			coins.Parent = leaderstats
			player:SetAttribute("Coins", coins.Value)
		else
			-- Jika entah kenapa Coins sudah ada, update saja valuenya
			local existingCoins = leaderstats:FindFirstChild("Coins")
			existingCoins.Value = profile.Data.Coins or 0
			player:SetAttribute("Coins", existingCoins.Value)
		end
	end)

	task.spawn(function()
		local backpack = player:WaitForChild("Backpack", 5)
		if not backpack then return end
		task.wait(0.5)

		local wheatInventory = profile.Data.WheatInventory

	end)

end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end
-- ===================================================================
-- PLAYER REMOVING (HARDENED LIFECYCLE)
-- ===================================================================
Players.PlayerRemoving:Connect(function(player)
	local profile = PlayerProfiles[player]
	if not profile then return end

	-- H-01 Fix: Authoritative coin sync before release
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins and typeof(coins.Value) == "number" then
			if coins.Value > 0 then
				profile.Data.Coins = coins.Value
			elseif (profile.Data.Coins or 0) > 0 then
				coins.Value = profile.Data.Coins
			end
		end
	end

	pcall(function()
		profile:Release()
	end)
end)

-- ===================================================================
-- AUTO-SYNC LOOP (EVERY 60 SECONDS)
-- ===================================================================
task.spawn(function()
	while task.wait(60) do 
		for _, player in pairs(Players:GetPlayers()) do
			GameProfileService:SavePlayerData(player)
		end
	end
end)

-- ===================================================================
-- BIND TO CLOSE (AWAIT ALL PROFILES SAVE TO COMPLETION)
-- ===================================================================
if RunService:IsRunning() then
	game:BindToClose(function()
	local startTime = os.clock()
	local MAX_WAIT_TIME = 20

	for player, profile in pairs(PlayerProfiles) do
		if profile and profile:IsActive() then
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local coins = leaderstats:FindFirstChild("Coins")
				if coins and typeof(coins.Value) == "number" then
					if coins.Value > 0 or not profile.Data.Coins or profile.Data.Coins == 0 then
						profile.Data.Coins = coins.Value
					end
				end
			end
			task.spawn(function()
				pcall(function()
					profile:Release()
				end)
			end)
		end
	end

	while os.clock() - startTime < MAX_WAIT_TIME do
		local hasActive = false
		for _, profile in pairs(PlayerProfiles) do
			if profile and profile:IsActive() then
				hasActive = true
				break
			end
		end
		if not hasActive then
			break
		end
		task.wait(0.1)
	end
	end)
end

function GameProfileService:HasRemoteSell(player)
	local profile = self:GetProfile(player)
	if not profile then return false end
	return profile.Data.HasRemoteSell == true
end

function GameProfileService:SetRemoteSell(player, val)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end
	profile.Data.HasRemoteSell = val
	player:SetAttribute("HasRemoteSell", val)
	return true
end

return GameProfileService


