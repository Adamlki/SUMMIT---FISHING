-- Server lifecycle: profile load/release, leaderstats mirror, autosave, shutdown.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Profiles = require(script.Parent.Profiles)
local LegacyMigration = require(script.Parent.LegacyMigration)

local Lifecycle = {}

local beforeReleaseCallbacks = {}

function Lifecycle.RegisterBeforeRelease(callback)
	if type(callback) == "function" then
		table.insert(beforeReleaseCallbacks, callback)
	end
end

local function runBeforeRelease(player)
	for _, callback in ipairs(beforeReleaseCallbacks) do
		pcall(callback, player)
	end
end

local function onPlayerAdded(service, player)
	local success, profile = pcall(function()
		return Profiles.Store:LoadProfileAsync("Player_" .. player.UserId)
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

	-- Anti-Race: if the attribute already exists (ExclusiveStoreServer / GamePass), persist it.
	if player:GetAttribute("HasRemoteSell") == true or player:GetAttribute("CanSellAnywhere") == true then
		profile.Data.HasRemoteSell = true
	else
		player:SetAttribute("HasRemoteSell", profile.Data.HasRemoteSell or false)
	end

	-- Gamepass fallback so profile data stays in sync with the store.
	task.spawn(function()
		local MarketplaceService = game:GetService("MarketplaceService")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local StoreConfig = nil
		pcall(function()
			StoreConfig = require(ReplicatedStorage:WaitForChild("FishingSystem"):WaitForChild("ExclusiveStoreConfig"))
		end)
		local sellAnywhereGpId = 0
		if StoreConfig and StoreConfig.Gamepasses then
			for passKey, gp in pairs(StoreConfig.Gamepasses) do
				if passKey == "RemoteSell" and type(gp) == "table" and type(gp.PassId) == "number" then
					sellAnywhereGpId = gp.PassId
					break
				end
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

	-- Every player owns the Basic Rod.
	if not profile.Data.OwnedRods then
		profile.Data.OwnedRods = {}
	end
	if not table.find(profile.Data.OwnedRods, "Basic Rod") then
		table.insert(profile.Data.OwnedRods, "Basic Rod")
	end
	if not profile.Data.LastEquippedRod or profile.Data.LastEquippedRod == "" then
		profile.Data.LastEquippedRod = "Basic Rod"
	end

	LegacyMigration.Migrate(player, profile)

	Profiles.Profiles[player] = profile

	profile:ListenToRelease(function()
		Profiles.Profiles[player] = nil
	end)

	if not player:IsDescendantOf(game.Players) then
		profile:Release()
		Profiles.Profiles[player] = nil
		return
	end

	service.ProfileLoadedSignal:Fire(player)

	-- Merge into an existing leaderstats folder instead of replacing it.
	task.spawn(function()
		local leaderstats = player:FindFirstChild("leaderstats")

		if not leaderstats then
			leaderstats = Instance.new("Folder")
			leaderstats.Name = "leaderstats"
			leaderstats.Parent = player
		end

		local coins = leaderstats:FindFirstChild("Coins")
		if not coins then
			coins = Instance.new("IntValue")
			coins.Name = "Coins"
			coins.Parent = leaderstats
		end
		coins.Value = profile.Data.Coins or 0
		player:SetAttribute("Coins", coins.Value)

		local tangkapan = leaderstats:FindFirstChild("Tangkapan")
		if not tangkapan then
			tangkapan = Instance.new("IntValue")
			tangkapan.Name = "Tangkapan"
			tangkapan.Parent = leaderstats
		end
		tangkapan.Value = profile.Data.TotalFishCaught or 0
	end)
end

local function onPlayerRemoving(player)
	local profile = Profiles.Profiles[player]
	if not profile then return end

	runBeforeRelease(player)

	-- Authoritative coin sync before release.
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
end

function Lifecycle.Start(service)
	Players.PlayerAdded:Connect(function(player)
		onPlayerAdded(service, player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, service, player)
	end
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Auto-sync every 60 seconds.
	task.spawn(function()
		while task.wait(60) do
			for _, player in pairs(Players:GetPlayers()) do
				service:SavePlayerData(player)
			end
		end
	end)

	-- Shutdown: release every profile and wait for the releases to finish.
	if RunService:IsRunning() then
		game:BindToClose(function()
			local startTime = os.clock()
			local MAX_WAIT_TIME = 20

			for player, profile in pairs(Profiles.Profiles) do
				if profile and profile:IsActive() then
					runBeforeRelease(player)
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
				for _, profile in pairs(Profiles.Profiles) do
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
end

return Lifecycle
