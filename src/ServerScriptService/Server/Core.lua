--!strict
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local serverFolder = ServerScriptService.Server
local DataStoreConfig = require(ServerScriptService:WaitForChild("Configs"):WaitForChild("DataStoreConfig"))

local Core = {
	_armed = false,
	_locked = false,
}

Core.Data = Core.Data or {}
Core.Modules = Core.Modules or {}
Core.Modules.AdminHelpers = Core.Modules.AdminHelpers or {}
Core.Modules.AdminHelpers.ActionHelpers = Core.Modules.AdminHelpers.ActionHelpers or {}
Core.Modules.AdminHelpers.BindHelpers = Core.Modules.AdminHelpers.BindHelpers or {}
Core.Modules.AdminHelpers.BindHelpers.PlayerHelpers = Core.Modules.AdminHelpers.BindHelpers.PlayerHelpers or {}
Core.Modules.AdminHelpers.BootstrapHelpers = Core.Modules.AdminHelpers.BootstrapHelpers or {}
Core.Modules.AdminHelpers.Commands = Core.Modules.AdminHelpers.Commands or {}
Core.Modules.AdminHelpers.JailHelpers = Core.Modules.AdminHelpers.JailHelpers or {}
Core.Modules.AdminHelpers.LogHelpers = Core.Modules.AdminHelpers.LogHelpers or {}
Core.Modules.AdminHelpers.NotificationHelpers = Core.Modules.AdminHelpers.NotificationHelpers or {}
Core.Modules.AdminHelpers.OverheadHelpers = Core.Modules.AdminHelpers.OverheadHelpers or {}
Core.Modules.AdminHelpers.PermissionHelpers = Core.Modules.AdminHelpers.PermissionHelpers or {}
Core.Modules.AdminHelpers.ProfileHelpers = Core.Modules.AdminHelpers.ProfileHelpers or {}
Core.Modules.AdminHelpers.RefreshHelpers = Core.Modules.AdminHelpers.RefreshHelpers or {}
Core.Modules.AdminHelpers.ServerControlHelpers = Core.Modules.AdminHelpers.ServerControlHelpers or {}
Core.Modules.AdminHelpers.UtilityHelpers = Core.Modules.AdminHelpers.UtilityHelpers or {}
Core.Modules.Carry = Core.Modules.Carry or {}
Core.Modules.Carry.FlowHelpers = Core.Modules.Carry.FlowHelpers or {}
Core.Modules.Checkpoint = Core.Modules.Checkpoint or {}
Core.Modules.Checkpoint.Admin = Core.Modules.Checkpoint.Admin or {}
Core.Modules.Donations = Core.Modules.Donations or {}
Core.Modules.Donations.PodiumHelpers = Core.Modules.Donations.PodiumHelpers or {}
Core.Modules.Leaderboard = Core.Modules.Leaderboard or {}
Core.Modules.Physics = Core.Modules.Physics or {}
Core.Modules.PlayerCommands = Core.Modules.PlayerCommands or {}
Core.Modules.Race = Core.Modules.Race or {}
Core.Modules.Shop = Core.Modules.Shop or {}
Core.Modules.Speedrun = Core.Modules.Speedrun or {}
Core.Modules.Speedrun.Admin = Core.Modules.Speedrun.Admin or {}
Core.Modules.Teleport = Core.Modules.Teleport or {}
Core.Modules.Teleport.Util = Core.Modules.Teleport.Util or {}
Core.Components = Core.Components or {}
Core.Services = Core.Services or {}
Core.Services.AvatarHelpers = Core.Services.AvatarHelpers or {}
Core.Services.CustomTitle = Core.Services.CustomTitle or {}
Core.Services.DanceHelpers = Core.Services.DanceHelpers or {}
Core.Services.DonationHelpers = Core.Services.DonationHelpers or {}
Core.Services.LeaderboardHelpers = Core.Services.LeaderboardHelpers or {}
Core.Services.OverheadHelpers = Core.Services.OverheadHelpers or {}
Core.Services.PlayerListHelpers = Core.Services.PlayerListHelpers or {}
Core.Services.SpeedrunHelpers = Core.Services.SpeedrunHelpers or {}
Core.Services.VipHelpers = Core.Services.VipHelpers or {}

Core._stopSystem = function(self, reason)
	warn("[Core] System notice:", tostring(reason))
end
Core._getCreditsOrStop = function(self)
	return serverFolder:FindFirstChild("Credits")
end

---@class CoreDataCheckpointProfile
---@field __source string Path sumber module `Data/CheckpointProfile.luau`.
---@field profiles any Member public `profiles` dari `Data/CheckpointProfile.luau`.
---@field store any Member public `store` dari `Data/CheckpointProfile.luau`.
Core.Data.CheckpointProfile = Core.Data.CheckpointProfile or {}
do
	local __module = nil
	local ServerPackages = game:FindFirstChild("ServerPackages")
	if not ServerPackages then
		local serverRoot = game:GetService("ServerScriptService"):FindFirstChild("Server")
		ServerPackages = serverRoot and serverRoot:FindFirstChild("Package")
	end
	if not ServerPackages then
		error("[CheckpointProfile] ServerPackages not found.")
	end
	local ProfileStore = require(ServerPackages.ProfileStore)

	local CheckpointProfile = {}
	CheckpointProfile.__index = CheckpointProfile

	---Menjalankan fungsi `new`.
	---@return any result Hasil dari fungsi `new`.
	function CheckpointProfile.new()
		local self = setmetatable({}, CheckpointProfile)
		self.store = ProfileStore.New(DataStoreConfig.Stores.CheckpointProgress, {
			bestTime = nil,
			peakIndex = 0,
			summitCount = 0,
			lastIndex = 0,
		})
		self.profiles = {}
		return self
	end

	---Menjalankan fungsi `Load`.
	---@param player any Nilai parameter `player`.
	function CheckpointProfile:Load(player)
		local profile
		for _ = 1, 5 do
			profile = self.store:StartSessionAsync("player_" .. player.UserId)
			if profile then break end
			task.wait(2)
		end
		if not profile then
			return nil
		end

		profile:AddUserId(player.UserId)
		profile:Reconcile()
		self.profiles[player] = profile
		return profile
	end

	---Menjalankan fungsi `GetProfile`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `GetProfile`.
	function CheckpointProfile:GetProfile(player)
		return self.profiles[player]
	end

	---Menjalankan fungsi `SetBestTime`.
	---@param player any Nilai parameter `player`.
	---@param timeSeconds any Nilai parameter `timeSeconds`.
	function CheckpointProfile:SetBestTime(player, timeSeconds)
		local profile = self.profiles[player]
		if profile then
			profile.Data.bestTime = timeSeconds
		end
	end

	---Menjalankan fungsi `GetBestTime`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `GetBestTime`.
	function CheckpointProfile:GetBestTime(player)
		local profile = self.profiles[player]
		if profile then
			return profile.Data.bestTime
		end
		return nil
	end

	---Menjalankan fungsi `SetPeak`.
	---@param player any Nilai parameter `player`.
	---@param peakIndex any Nilai parameter `peakIndex`.
	function CheckpointProfile:SetPeak(player, peakIndex)
		local profile = self.profiles[player]
		if profile then
			profile.Data.peakIndex = peakIndex
		end
	end

	---Menjalankan fungsi `GetPeak`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `GetPeak`.
	function CheckpointProfile:GetPeak(player)
		local profile = self.profiles[player]
		if profile then
			return profile.Data.peakIndex
		end
		return nil
	end

	---Menjalankan fungsi `IncrementSummit`.
	---@param player any Nilai parameter `player`.
	---@param amount any Nilai parameter `amount`.
	function CheckpointProfile:IncrementSummit(player, amount)
		local profile = self.profiles[player]
		if profile then
			amount = amount or 1
			profile.Data.summitCount = (profile.Data.summitCount or 0) + amount
		end
	end

	---Menjalankan fungsi `SetSummit`.
	---@param player any Nilai parameter `player`.
	---@param amount any Nilai parameter `amount`.
	function CheckpointProfile:SetSummit(player, amount)
		local profile = self.profiles[player]
		if profile then
			profile.Data.summitCount = amount or 0
		end
	end

	---Menjalankan fungsi `SetSummitByUserId`.
	---@param userId any Nilai parameter `userId`.
	---@param amount any Nilai parameter `amount`.
	function CheckpointProfile:SetSummitByUserId(userId, amount)
		local profile
		for _ = 1, 5 do
			profile = self.store:StartSessionAsync("player_" .. userId)
			if profile then break end
			task.wait(2)
		end
		if not profile then
			return nil
		end
		profile:Reconcile()
		profile.Data.summitCount = amount or 0
		profile:EndSession()
		return profile.Data.summitCount
	end

	---Menjalankan fungsi `AddSummitByUserId`.
	---@param userId any Nilai parameter `userId`.
	---@param amount any Nilai parameter `amount`.
	function CheckpointProfile:AddSummitByUserId(userId, amount)
		local profile
		for _ = 1, 5 do
			profile = self.store:StartSessionAsync("player_" .. userId)
			if profile then break end
			task.wait(2)
		end
		if not profile then
			return nil
		end
		profile:Reconcile()
		local current = profile.Data.summitCount or 0
		profile.Data.summitCount = current + (amount or 0)
		profile:EndSession()
		return profile.Data.summitCount
	end

	---Menjalankan fungsi `GetSummit`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `GetSummit`.
	function CheckpointProfile:GetSummit(player)
		local profile = self.profiles[player]
		if profile then
			return profile.Data.summitCount or 0
		end
		return 0
	end

	---Menjalankan fungsi `SetLastIndex`.
	---@param player any Nilai parameter `player`.
	---@param index any Nilai parameter `index`.
	function CheckpointProfile:SetLastIndex(player, index)
		local profile = self.profiles[player]
		if profile then
			profile.Data.lastIndex = index
		end
	end

	---Menjalankan fungsi `GetLastIndex`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `GetLastIndex`.
	function CheckpointProfile:GetLastIndex(player)
		local profile = self.profiles[player]
		if profile then
			return profile.Data.lastIndex or 0
		end
		return 0
	end

	---Menjalankan fungsi `Release`.
	---@param player any Nilai parameter `player`.
	function CheckpointProfile:Release(player)
		local profile = self.profiles[player]
		if profile then
			profile:EndSession()
			self.profiles[player] = nil
		end
	end

	__module = CheckpointProfile

	if type(__module) == "table" then
		__module.__source = "Data/CheckpointProfile.luau"
	end
	Core.Data.CheckpointProfile = __module
end

---@class CoreDataLeaderstats
---@field __source string Path sumber module `Data/Leaderstats.luau`.
---@field bestTime any Member public `bestTime` dari `Data/Leaderstats.luau`.
---@field folder any Member public `folder` dari `Data/Leaderstats.luau`.
---@field posisi any Member public `posisi` dari `Data/Leaderstats.luau`.
---@field summit any Member public `summit` dari `Data/Leaderstats.luau`.
Core.Data.Leaderstats = Core.Data.Leaderstats or {}
do
	local __module = nil
	local Leaderstats = {}
	Leaderstats.__index = Leaderstats

	---Menjalankan fungsi `new`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `new`.
	function Leaderstats.new(player)
		local self = setmetatable({}, Leaderstats)
		local folder = player:FindFirstChild("leaderstats")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "leaderstats"
			folder.Parent = player
		end

		local posisi = folder:FindFirstChild("Posisi")
		if not posisi then
			posisi = Instance.new("StringValue")
			posisi.Name = "Posisi"
			posisi.Value = "0"
			posisi.Parent = folder
		end

		local summit = folder:FindFirstChild("Summit")
		if not summit then
			summit = Instance.new("IntValue")
			summit.Name = "Summit"
			summit.Value = 0
			summit.Parent = folder
		end

		local bestTime = folder:FindFirstChild("BestTime")
		if not bestTime then
			bestTime = Instance.new("StringValue")
			bestTime.Name = "BestTime"
			bestTime.Value = "00:00"
			bestTime.Parent = folder
		end

		self.folder = folder
		self.posisi = posisi
		self.summit = summit
		self.bestTime = bestTime
		return self
	end

	---Menjalankan fungsi `SetPosisi`.
	---@param value any Nilai parameter `value`.
	---@param startIndex any Nilai parameter `startIndex`.
	---@param finishIndex any Nilai parameter `finishIndex`.
	---@param finishStartIndex any Nilai parameter `finishStartIndex`.
	function Leaderstats:SetPosisi(value, startIndex, finishIndex, finishStartIndex)
		local index = tonumber(value) or 0
		if startIndex ~= nil and index == tonumber(startIndex) then
			self.posisi.Value = "Basecamp"
			return
		end
		local finishStart = tonumber(finishStartIndex)
		local finishEnd = tonumber(finishIndex)
		if finishStart ~= nil and finishEnd ~= nil and index >= finishStart and index <= finishEnd then
			self.posisi.Value = "Summit"
			return
		end
		if finishEnd ~= nil and index == finishEnd then
			self.posisi.Value = "Summit"
			return
		end
		self.posisi.Value = tostring(index)
	end

	---Menjalankan fungsi `SetSummit`.
	---@param value any Nilai parameter `value`.
	function Leaderstats:SetSummit(value)
		self.summit.Value = value or 0
	end

	---Menjalankan fungsi `IncrementSummit`.
	function Leaderstats:IncrementSummit()
		self.summit.Value += 1
	end

	---Menjalankan fungsi `SetBestTime`.
	---@param value any Nilai parameter `value`.
	function Leaderstats:SetBestTime(value)
		if self.bestTime then
			self.bestTime.Value = value or "00:00"
		end
	end

	---Menjalankan fungsi `Destroy`.
	function Leaderstats:Destroy()
		-- Do not destroy self.folder directly so other systems (like Fishing leaderboard/DataStore) don't lose data on PlayerRemoving!
		if self.posisi then self.posisi:Destroy() self.posisi = nil end
		if self.summit then self.summit:Destroy() self.summit = nil end
		if self.bestTime then self.bestTime:Destroy() self.bestTime = nil end
		self.folder = nil
	end

	__module = Leaderstats

	if type(__module) == "table" then
		__module.__source = "Data/Leaderstats.luau"
	end
	Core.Data.Leaderstats = __module
end

---@class CoreDataPlaytimeProfile
---@field __source string Path sumber module `Data/PlaytimeProfile.luau`.
---@field profiles any Member public `profiles` dari `Data/PlaytimeProfile.luau`.
---@field store any Member public `store` dari `Data/PlaytimeProfile.luau`.
Core.Data.PlaytimeProfile = Core.Data.PlaytimeProfile or {}
do
	local __module = nil
	local ServerPackages = game:FindFirstChild("ServerPackages")
	if not ServerPackages then
		local serverRoot = game:GetService("ServerScriptService"):FindFirstChild("Server")
		ServerPackages = serverRoot and serverRoot:FindFirstChild("Package")
	end
	if not ServerPackages then
		error("[PlaytimeProfile] ServerPackages not found.")
	end
	local ProfileStore = require(ServerPackages.ProfileStore)

	local PlaytimeProfile = {}
	PlaytimeProfile.__index = PlaytimeProfile

	---Menjalankan fungsi `new`.
	---@param storeKey any Nilai parameter `storeKey`.
	---@return any result Hasil dari fungsi `new`.
	function PlaytimeProfile.new(storeKey)
		local self = setmetatable({}, PlaytimeProfile)
		self.store = ProfileStore.New(storeKey or DataStoreConfig.Stores.PlaytimeData, {
			totalSeconds = 0,
		})
		self.profiles = {}
		return self
	end

	---Menjalankan fungsi `Load`.
	---@param player any Nilai parameter `player`.
	function PlaytimeProfile:Load(player)
		local profile
		for _ = 1, 5 do
			profile = self.store:StartSessionAsync("player_" .. player.UserId)
			if profile then break end
			task.wait(2)
		end
		if not profile then
			return nil
		end
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		self.profiles[player] = profile
		return profile
	end

	---Menjalankan fungsi `GetProfile`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `GetProfile`.
	function PlaytimeProfile:GetProfile(player)
		return self.profiles[player]
	end

	---Menjalankan fungsi `GetTotal`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `GetTotal`.
	function PlaytimeProfile:GetTotal(player)
		local profile = self.profiles[player]
		if profile then
			return profile.Data.totalSeconds or 0
		end
		return 0
	end

	---Menjalankan fungsi `AddSeconds`.
	---@param player any Nilai parameter `player`.
	---@param seconds any Nilai parameter `seconds`.
	function PlaytimeProfile:AddSeconds(player, seconds)
		local profile = self.profiles[player]
		if profile then
			local add = math.max(0, math.floor(tonumber(seconds) or 0))
			profile.Data.totalSeconds = (profile.Data.totalSeconds or 0) + add
			return profile.Data.totalSeconds
		end
		return nil
	end

	---Menjalankan fungsi `Release`.
	---@param player any Nilai parameter `player`.
	function PlaytimeProfile:Release(player)
		local profile = self.profiles[player]
		if profile then
			profile:EndSession()
			self.profiles[player] = nil
		end
	end

	__module = PlaytimeProfile

	if type(__module) == "table" then
		__module.__source = "Data/PlaytimeProfile.luau"
	end
	Core.Data.PlaytimeProfile = __module
end

---@class CoreDataShopProfile
---@field __source string Path sumber module `Data/ShopProfile.luau`.
---@field profiles any Member public `profiles` dari `Data/ShopProfile.luau`.
---@field store any Member public `store` dari `Data/ShopProfile.luau`.
Core.Data.ShopProfile = Core.Data.ShopProfile or {}
do
	local __module = nil
	local ServerPackages = game:FindFirstChild("ServerPackages")
	if not ServerPackages then
		local serverRoot = game:GetService("ServerScriptService"):FindFirstChild("Server")
		ServerPackages = serverRoot and serverRoot:FindFirstChild("Package")
	end
	if not ServerPackages then
		error("[ShopProfile] ServerPackages not found.")
	end

	local ProfileStore = require(ServerPackages.ProfileStore)

	local ShopProfile = {}
	ShopProfile.__index = ShopProfile

	---Menjalankan fungsi `new`.
	---@param storeKey any Nilai parameter `storeKey`.
	---@return any result Hasil dari fungsi `new`.
	function ShopProfile.new(storeKey)
		local self = setmetatable({}, ShopProfile)
		self.store = ProfileStore.New(storeKey or DataStoreConfig.Stores.ShopToolsData, {
			ownedTools = {},
		})
		self.profiles = {}
		return self
	end

	---Menjalankan fungsi `Load`.
	---@param player any Nilai parameter `player`.
	function ShopProfile:Load(player)
		local profile
		for _ = 1, 5 do
			profile = self.store:StartSessionAsync("player_" .. player.UserId)
			if profile then
				break
			end
			task.wait(2)
		end
		if not profile then
			return nil
		end

		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile.Data.ownedTools = profile.Data.ownedTools or {}
		self.profiles[player] = profile
		return profile
	end

	---Menjalankan fungsi `GetProfile`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `GetProfile`.
	function ShopProfile:GetProfile(player)
		return self.profiles[player]
	end

	---Menjalankan fungsi `GetOwnedTools`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `GetOwnedTools`.
	function ShopProfile:GetOwnedTools(player)
		local profile = self.profiles[player]
		if not profile then
			return {}
		end
		profile.Data.ownedTools = profile.Data.ownedTools or {}
		return profile.Data.ownedTools
	end

	---Menjalankan fungsi `HasTool`.
	---@param player any Nilai parameter `player`.
	---@param toolId any Nilai parameter `toolId`.
	---@return any result Hasil dari fungsi `HasTool`.
	function ShopProfile:HasTool(player, toolId)
		local owned = self:GetOwnedTools(player)
		return owned[toolId] == true
	end

	---Menjalankan fungsi `AddTool`.
	---@param player any Nilai parameter `player`.
	---@param toolId any Nilai parameter `toolId`.
	function ShopProfile:AddTool(player, toolId)
		if not toolId then
			return false
		end

		local profile = self.profiles[player]
		if not profile then
			return false
		end

		profile.Data.ownedTools = profile.Data.ownedTools or {}
		profile.Data.ownedTools[toolId] = true
		return true
	end

	---Menjalankan fungsi `AddToolByUserId`.
	---@param userId any Nilai parameter `userId`.
	---@param toolId any Nilai parameter `toolId`.
	function ShopProfile:AddToolByUserId(userId, toolId)
		if not userId or not toolId then
			return false
		end

		local profile
		for _ = 1, 5 do
			profile = self.store:StartSessionAsync("player_" .. userId)
			if profile then
				break
			end
			task.wait(2)
		end
		if not profile then
			return false
		end

		profile:Reconcile()
		profile.Data.ownedTools = profile.Data.ownedTools or {}
		profile.Data.ownedTools[toolId] = true
		profile:EndSession()
		return true
	end

	---Menjalankan fungsi `Release`.
	---@param player any Nilai parameter `player`.
	function ShopProfile:Release(player)
		local profile = self.profiles[player]
		if profile then
			profile:EndSession()
			self.profiles[player] = nil
		end
	end

	__module = ShopProfile

	if type(__module) == "table" then
		__module.__source = "Data/ShopProfile.luau"
	end
	Core.Data.ShopProfile = __module
end

---@class CoreDataSpeedrunProfile
---@field __source string Path sumber module `Data/SpeedrunProfile.luau`.
---@field profiles any Member public `profiles` dari `Data/SpeedrunProfile.luau`.
---@field store any Member public `store` dari `Data/SpeedrunProfile.luau`.
Core.Data.SpeedrunProfile = Core.Data.SpeedrunProfile or {}
do
	local __module = nil
	local ServerPackages = game:FindFirstChild("ServerPackages")
	if not ServerPackages then
		local serverRoot = game:GetService("ServerScriptService"):FindFirstChild("Server")
		ServerPackages = serverRoot and serverRoot:FindFirstChild("Package")
	end
	if not ServerPackages then
		error("[SpeedrunProfile] ServerPackages not found.")
	end
	local ProfileStore = require(ServerPackages.ProfileStore)

	local SpeedrunProfile = {}
	SpeedrunProfile.__index = SpeedrunProfile

	---Menjalankan fungsi `new`.
	---@param storeKey any Nilai parameter `storeKey`.
	---@return any result Hasil dari fungsi `new`.
	function SpeedrunProfile.new(storeKey)
		local self = setmetatable({}, SpeedrunProfile)
		self.store = ProfileStore.New(storeKey or DataStoreConfig.Stores.SpeedrunData, {
			bestTime = nil,
		})
		self.profiles = {}
		return self
	end

	---Menjalankan fungsi `Load`.
	---@param player any Nilai parameter `player`.
	function SpeedrunProfile:Load(player)
		local profile
		for _ = 1, 5 do
			profile = self.store:StartSessionAsync("player_" .. player.UserId)
			if profile then break end
			task.wait(2)
		end
		if not profile then
			return nil
		end
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		self.profiles[player] = profile
		return profile
	end

	---Menjalankan fungsi `GetProfile`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `GetProfile`.
	function SpeedrunProfile:GetProfile(player)
		return self.profiles[player]
	end

	---Menjalankan fungsi `GetBestTime`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `GetBestTime`.
	function SpeedrunProfile:GetBestTime(player)
		local profile = self.profiles[player]
		if profile then
			return profile.Data.bestTime
		end
		return nil
	end

	---Menjalankan fungsi `SetBestTime`.
	---@param player any Nilai parameter `player`.
	---@param seconds any Nilai parameter `seconds`.
	function SpeedrunProfile:SetBestTime(player, seconds)
		local profile = self.profiles[player]
		if profile then
			profile.Data.bestTime = seconds
		end
	end

	---Menjalankan fungsi `SetBestTimeByUserId`.
	---@param userId any Nilai parameter `userId`.
	---@param seconds any Nilai parameter `seconds`.
	function SpeedrunProfile:SetBestTimeByUserId(userId, seconds)
		local profile
		for _ = 1, 5 do
			profile = self.store:StartSessionAsync("player_" .. userId)
			if profile then break end
			task.wait(2)
		end
		if not profile then
			return false
		end
		profile:Reconcile()
		profile.Data.bestTime = seconds
		profile:EndSession()
		return true
	end

	---Menjalankan fungsi `Release`.
	---@param player any Nilai parameter `player`.
	function SpeedrunProfile:Release(player)
		local profile = self.profiles[player]
		if profile then
			profile:EndSession()
			self.profiles[player] = nil
		end
	end

	__module = SpeedrunProfile

	if type(__module) == "table" then
		__module.__source = "Data/SpeedrunProfile.luau"
	end
	Core.Data.SpeedrunProfile = __module
end

---@class CoreDataVipProfile
---@field __source string Path sumber module `Data/VipProfile.luau`.
---@field profiles any Member public `profiles` dari `Data/VipProfile.luau`.
---@field store any Member public `store` dari `Data/VipProfile.luau`.
Core.Data.VipProfile = Core.Data.VipProfile or {}
do
	local __module = nil
	local ServerPackages = game:FindFirstChild("ServerPackages")
	if not ServerPackages then
		local serverRoot = game:GetService("ServerScriptService"):FindFirstChild("Server")
		ServerPackages = serverRoot and serverRoot:FindFirstChild("Package")
	end
	if not ServerPackages then
		error("[VipProfile] ServerPackages not found.")
	end
	local ProfileStore = require(ServerPackages.ProfileStore)

	local VipProfile = {}
	VipProfile.__index = VipProfile

	---Menjalankan fungsi `new`.
	---@return any result Hasil dari fungsi `new`.
	function VipProfile.new()
		local self = setmetatable({}, VipProfile)
		self.store = ProfileStore.New(DataStoreConfig.Stores.VipData, {
			vip = false,
		})
		self.profiles = {}
		return self
	end

	---Menjalankan fungsi `Load`.
	---@param player any Nilai parameter `player`.
	function VipProfile:Load(player)
		local profile
		for _ = 1, 5 do
			profile = self.store:StartSessionAsync("player_" .. player.UserId)
			if profile then break end
			task.wait(2)
		end
		if not profile then
			return nil
		end
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		self.profiles[player] = profile
		return profile
	end

	---Menjalankan fungsi `GetProfile`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `GetProfile`.
	function VipProfile:GetProfile(player)
		return self.profiles[player]
	end

	---Menjalankan fungsi `IsVip`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `IsVip`.
	function VipProfile:IsVip(player)
		local profile = self.profiles[player]
		if profile then
			return profile.Data.vip == true
		end
		return false
	end

	---Menjalankan fungsi `IsVipByUserId`.
	---@param userId any Nilai parameter `userId`.
	---@return any result Hasil dari fungsi `IsVipByUserId`.
	function VipProfile:IsVipByUserId(userId)
		local profile
		for _ = 1, 5 do
			profile = self.store:StartSessionAsync("player_" .. userId)
			if profile then break end
			task.wait(2)
		end
		if not profile then
			return nil
		end
		profile:Reconcile()
		local isVip = profile.Data.vip == true
		profile:EndSession()
		return isVip
	end

	---Menjalankan fungsi `SetVip`.
	---@param player any Nilai parameter `player`.
	---@param enabled any Nilai parameter `enabled`.
	function VipProfile:SetVip(player, enabled)
		local profile = self.profiles[player]
		if profile then
			profile.Data.vip = enabled == true
		end
	end

	---Menjalankan fungsi `SetVipByUserId`.
	---@param userId any Nilai parameter `userId`.
	---@param enabled any Nilai parameter `enabled`.
	function VipProfile:SetVipByUserId(userId, enabled)
		local profile
		for _ = 1, 5 do
			profile = self.store:StartSessionAsync("player_" .. userId)
			if profile then break end
			task.wait(2)
		end
		if not profile then
			return nil
		end
		profile:Reconcile()
		profile.Data.vip = enabled == true
		profile:EndSession()
		return profile.Data.vip
	end

	---Menjalankan fungsi `Release`.
	---@param player any Nilai parameter `player`.
	function VipProfile:Release(player)
		local profile = self.profiles[player]
		if profile then
			profile:EndSession()
			self.profiles[player] = nil
		end
	end

	__module = VipProfile

	if type(__module) == "table" then
		__module.__source = "Data/VipProfile.luau"
	end
	Core.Data.VipProfile = __module
end

---@class CoreModulesAdminHelpersBindHelpersPlayerHelpersBanRole
---@field __source string Path sumber module `Modules/AdminHelpers/BindHelpers/PlayerHelpers/BanRole.luau`.
Core.Modules.AdminHelpers.BindHelpers.PlayerHelpers.BanRole = Core.Modules.AdminHelpers.BindHelpers.PlayerHelpers.BanRole or {}
do
	local __module = nil
	local BanRole = {}

	---Menjalankan fungsi `checkBan`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	function BanRole.checkBan(service, player)
		local profile = service:_loadBanProfile(player)
		if profile and profile.Data.banned == true then
			player:Kick("You are banned.")
		end
	end

	---Menjalankan fungsi `loadRole`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	function BanRole.loadRole(service, player)
		local profile = service:_loadRoleProfile(player)
		if not profile then return end
		local role = profile.Data.role
		if role and role ~= "Member" then
			service._extraRoles[player.UserId] = role
			service:_setRoleForPlayer(player, role)
		else
			service:_setRoleTitlePreserveVip(player)
		end
		service:_pushOverheadConfig()
	end

	---Menjalankan fungsi `cleanup`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	function BanRole.cleanup(service, player)
		service:_releaseBanProfile(player)
		service:_releaseRoleProfile(player)
	end

	__module = BanRole

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/BindHelpers/PlayerHelpers/BanRole.luau"
	end
	Core.Modules.AdminHelpers.BindHelpers.PlayerHelpers.BanRole = __module
end

---@class CoreModulesAdminHelpersBindHelpersPlayerHelpersJail
---@field __source string Path sumber module `Modules/AdminHelpers/BindHelpers/PlayerHelpers/Jail.luau`.
Core.Modules.AdminHelpers.BindHelpers.PlayerHelpers.Jail = Core.Modules.AdminHelpers.BindHelpers.PlayerHelpers.Jail or {}
do
	local __module = nil
	local Jail = {}

	---Menjalankan fungsi `loadJail`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	function Jail.loadJail(service, player)
		local profile = service:_loadJailProfile(player)
		if not profile then return end
		if profile.Data.isJailed == true then
			player:SetAttribute("Jail", true)
			local cf = service:_tableToCFrame(profile.Data.pos)
			if player.Character then
				if cf then
					local root = service._utils.getHumanoidRootPart(player.Character)
					if root then
						root.CFrame = cf
						service._jailLastPos[player.UserId] = cf
					end
					service:_applyJailAtCFrame(player, cf)
				end
			end
			service:_stopJailRejoinHook(player)
			service._jailRejoinConns[player] = player.CharacterAdded:Connect(function(char)
				if player:GetAttribute("Jail") ~= true then
					return
				end
				local root = service._utils.getHumanoidRootPart(char)
				if not root then return end
				local use = cf or root.CFrame
				root.CFrame = use
				service._jailLastPos[player.UserId] = use
				service:_applyJailAtCFrame(player, use)
			end)
		else
			player:SetAttribute("Jail", false)
			service:_applyJailCollision(player, false)
			service:_stopJailRejoinHook(player)
		end
	end

	---Menjalankan fungsi `cleanup`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	function Jail.cleanup(service, player)
		service:_saveJailState(player, player:GetAttribute("Jail") == true)
		service:_releaseJailProfile(player)
		local jail = service._jailModels[player.UserId]
		if jail and jail.Parent then
			jail:Destroy()
		end
		service._jailModels[player.UserId] = nil
		service:_stopJailGuard(player.UserId)
		service:_stopJailRejoinHook(player)
		service._jailLastPos[player.UserId] = nil
		service:_applyJailCollision(player, false)
	end

	__module = Jail

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/BindHelpers/PlayerHelpers/Jail.luau"
	end
	Core.Modules.AdminHelpers.BindHelpers.PlayerHelpers.Jail = __module
end

---@class CoreModulesAdminHelpersActionHelpersManage
---@field __source string Path sumber module `Modules/AdminHelpers/ActionHelpers/Manage.luau`.
Core.Modules.AdminHelpers.ActionHelpers.Manage = Core.Modules.AdminHelpers.ActionHelpers.Manage or {}
do
	local __module = nil
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Shared = ReplicatedStorage.Shared
	local Packages = Shared.Packages
	local Knit = require(Packages.Knit)

	local Manage = {}

	---Menjalankan fungsi `run`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param action any Nilai parameter `action`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	---@param amount any Nilai parameter `amount`.
	function Manage.run(service, player, action, targetUserId, amount)
		if not service:_canUsePanel(player) then
			return false, "NoPermission"
		end
		local knit = service._knit or Knit
		local checkpointService = knit.GetService("CheckpointService")
		local speedrunService = knit.GetService("SpeedrunService")
		local targetId = tonumber(targetUserId)
		if not targetId then
			return false, "InvalidTarget"
		end
		local targetPlayer = service:_findPlayerByUserId(targetId)
		if targetPlayer and not service:_canActOn(player, targetPlayer) then
			return false, "TargetHigherRole"
		end
		local targetName = service:_describeTarget(targetPlayer, targetId)
		local amt = tonumber(amount) or 0

		if action == "ResetBesttime" then
			if targetPlayer then
				speedrunService:_resetBestTime(targetPlayer)
			else
				speedrunService:_resetBestTimeByUserId(targetId)
			end
			service:_emitLog(player, string.format("Reset best time for %s", targetName))
			return true
		end

		if action == "ResetSummit" then
			if targetPlayer then
				checkpointService:_resetSummit(targetPlayer)
			else
				checkpointService:_resetSummitByUserId(targetId)
			end
			service:_emitLog(player, string.format("Reset summit for %s", targetName))
			return true
		end

		if action == "Add" or action == "Gift" then
			if amt == 0 then
				amt = 1
			end
			if targetPlayer then
				checkpointService:_addSummit(targetPlayer, amt)
			else
				checkpointService:_addSummitByUserId(targetId, amt)
			end
			service:_emitLog(player, string.format("Add %d summit to %s", amt, targetName))
			return true
		end

		if action == "Sub" then
			if amt == 0 then
				amt = 1
			end
			if targetPlayer then
				checkpointService:_addSummit(targetPlayer, -amt)
			else
				checkpointService:_addSummitByUserId(targetId, -amt)
			end
			service:_emitLog(player, string.format("Sub %d summit from %s", amt, targetName))
			return true
		end

		if action == "Set" then
			if targetPlayer then
				checkpointService:_setSummit(targetPlayer, amt)
			else
				checkpointService:_setSummitByUserId(targetId, amt)
			end
			service:_emitLog(player, string.format("Set summit to %d for %s", amt, targetName))
			return true
		end

		return false, "UnknownAction"
	end

	__module = Manage

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/ActionHelpers/Manage.luau"
	end
	Core.Modules.AdminHelpers.ActionHelpers.Manage = __module
end

---@class CoreModulesAdminHelpersActionHelpersPlayerActions
---@field __source string Path sumber module `Modules/AdminHelpers/ActionHelpers/PlayerActions.luau`.
Core.Modules.AdminHelpers.ActionHelpers.PlayerActions = Core.Modules.AdminHelpers.ActionHelpers.PlayerActions or {}
do
	local __module = nil
	local PlayerActions = {}

	---Menjalankan fungsi `run`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param action any Nilai parameter `action`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	function PlayerActions.run(service, player, action, targetUserId)
		if not service:_canUsePanel(player) then
			return false, "NoPermission"
		end
		local target = service:_findPlayerByUserId(targetUserId)
		if not target then
			return false, "TargetOffline"
		end
		if not service:_canActOn(player, target) then
			return false, "TargetHigherRole"
		end
		local targetName = service:_describeTarget(target, target.UserId)

		if action == "Kick" then
			target:Kick("Kicked by admin.")
			service:_emitLog(player, string.format("Kick %s", targetName))
			return true
		end
		if action == "Ban" then
			local ok = service:_setBan(target.UserId, true)
			if not ok then
				return false, "StoreError"
			end
			target:Kick("Banned by admin.")
			service:_emitLog(player, string.format("Ban %s", targetName))
			return true
		end
		if action == "Freeze" then
			service._utils.applyFreeze(target, true)
			service:_emitLog(player, string.format("Freeze %s", targetName))
			return true
		end
		if action == "Unfreeze" then
			service._utils.applyFreeze(target, false)
			service:_emitLog(player, string.format("Unfreeze %s", targetName))
			return true
		end
		if action == "Visible" then
			service._utils.applyInvisible(target, false)
			service:_emitLog(player, string.format("Visible %s", targetName))
			return true
		end
		if action == "Invis" then
			service._utils.applyInvisible(target, true)
			service:_emitLog(player, string.format("Invis %s", targetName))
			return true
		end
		if action == "Bring" then
			local adminChar = player.Character
			local targetChar = target.Character
			local adminRoot = service._utils.getHumanoidRootPart(adminChar)
			local targetRoot = service._utils.getHumanoidRootPart(targetChar)
			if adminRoot and targetRoot then
				targetRoot.CFrame = adminRoot.CFrame * CFrame.new(2, 0, 0)
				service:_emitLog(player, string.format("Bring %s", targetName))
				return true
			end
			return false, "NoCharacter"
		end
		if action == "Teleport" then
			local adminChar = player.Character
			local targetChar = target.Character
			local adminRoot = service._utils.getHumanoidRootPart(adminChar)
			local targetRoot = service._utils.getHumanoidRootPart(targetChar)
			if adminRoot and targetRoot then
				adminRoot.CFrame = targetRoot.CFrame * CFrame.new(2, 0, 0)
				service:_emitLog(player, string.format("Teleport to %s", targetName))
				return true
			end
			return false, "NoCharacter"
		end
		if action == "Jail" then
			service:_ensureJailProfile(target)
			local model = service:_ensureJailModel(target)
			if not model then
				return false, "NoJailTemplate"
			end
			local pos = service:_findJailPos(model)
			local targetChar = target.Character
			local targetRoot = service._utils.getHumanoidRootPart(targetChar)
			if pos and targetRoot then
				local pivot = model:GetPivot()
				local rel = pivot:ToObjectSpace(pos.CFrame)
				local newPivot = targetRoot.CFrame * rel:Inverse()
				model:PivotTo(newPivot)
				target:SetAttribute("Jail", true)
				service._utils.applyFreeze(target, true)
				local freezeSeconds = tonumber(service._adminConfig.JailFreezeSeconds) or 3
				task.delay(freezeSeconds, function()
					if target.Parent and target:GetAttribute("Jail") == true then
						service._utils.applyFreeze(target, false)
					end
				end)
				service:_startJailGuard(target, model, pos)
				service._jailLastPos[target.UserId] = targetRoot.CFrame
				service:_saveJailState(target, true)
				service:_emitLog(player, string.format("Jail %s", targetName))
				return true
			end
			return false, "NoJailPos"
		end
		if action == "Unjail" then
			service:_ensureJailProfile(target)
			service._utils.applyFreeze(target, false)
			local jail = service._jailModels[target.UserId]
			if jail and jail.Parent then
				jail:Destroy()
			end
			service._jailModels[target.UserId] = nil
			service:_stopJailGuard(target.UserId)
			service:_stopJailRejoinHook(target)
			target:SetAttribute("Jail", false)
			service:_applyJailCollision(target, false)
			service._jailLastPos[target.UserId] = nil
			service:_saveJailState(target, false)
			service:_emitLog(player, string.format("Unjail %s", targetName))
			return true
		end
		return false, "UnknownAction"
	end

	__module = PlayerActions

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/ActionHelpers/PlayerActions.luau"
	end
	Core.Modules.AdminHelpers.ActionHelpers.PlayerActions = __module
end

---@class CoreModulesAdminHelpersActionHelpersRoles
---@field __source string Path sumber module `Modules/AdminHelpers/ActionHelpers/Roles.luau`.
Core.Modules.AdminHelpers.ActionHelpers.Roles = Core.Modules.AdminHelpers.ActionHelpers.Roles or {}
do
	local __module = nil
	local Roles = {}

	---Menjalankan fungsi `assign`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	---@param role any Nilai parameter `role`.
	function Roles.assign(service, player, targetUserId, role)
		if not service:_canUsePanel(player) then
			return false, "NoPermission"
		end
		local targetId = tonumber(targetUserId)
		if not targetId then
			return false, "InvalidTarget"
		end
		local newRole = tostring(role or "Member")
		local allowed = false
		for _, r in ipairs(service._adminConfig.AssignableRoles or {}) do
			if r == newRole then
				allowed = true
				break
			end
		end
		if not allowed then
			return false, "InvalidRole"
		end
		if not service:_canAssignRole(player, newRole) then
			return false, "RoleTooHigh"
		end

		local targetPlayer = service:_findPlayerByUserId(targetId)
		if targetPlayer and not service:_canActOn(player, targetPlayer) then
			return false, "TargetHigherRole"
		end
		local ok = service:_setRoleData(targetId, newRole)
		if not ok then
			return false, "StoreError"
		end
		local targetName = service:_describeTarget(targetPlayer, targetId)
		service:_emitLog(player, string.format("Assign role %s to %s", newRole, targetName))
		return true
	end

	---Menjalankan fungsi `remove`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	function Roles.remove(service, player, targetUserId)
		if not service:_canUsePanel(player) then
			return false, "NoPermission"
		end
		local targetId = tonumber(targetUserId)
		if not targetId then
			return false, "InvalidTarget"
		end
		local targetPlayer = service:_findPlayerByUserId(targetId)
		if targetPlayer and not service:_canActOn(player, targetPlayer) then
			return false, "TargetHigherRole"
		end

		local ok = service:_setRoleData(targetId, "Member")
		if not ok then
			return false, "StoreError"
		end
		local targetName = service:_describeTarget(targetPlayer, targetId)
		service:_emitLog(player, string.format("Remove role from %s", targetName))
		return true
	end

	__module = Roles

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/ActionHelpers/Roles.luau"
	end
	Core.Modules.AdminHelpers.ActionHelpers.Roles = __module
end

---@class CoreModulesAdminHelpersActionHelpersTeleport
---@field __source string Path sumber module `Modules/AdminHelpers/ActionHelpers/Teleport.luau`.
Core.Modules.AdminHelpers.ActionHelpers.Teleport = Core.Modules.AdminHelpers.ActionHelpers.Teleport or {}
do
	local __module = nil
	local Teleport = {}

	---Menjalankan fungsi `run`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param destinationName any Nilai parameter `destinationName`.
	function Teleport.run(service, player, destinationName)
		if not service:_canUsePanel(player) then
			return false, "NoPermission"
		end
		local dest = service._teleports[destinationName]
		if not dest then
			return false, "UnknownDestination"
		end
		local root = service._utils.getHumanoidRootPart(player.Character)
		if root then
			root.CFrame = dest
			service:_emitLog(player, string.format("Teleport to %s", tostring(destinationName)))
			return true
		end
		return false, "NoCharacter"
	end

	__module = Teleport

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/ActionHelpers/Teleport.luau"
	end
	Core.Modules.AdminHelpers.ActionHelpers.Teleport = __module
end

---@class CoreModulesAdminHelpersActionHelpersTools
---@field __source string Path sumber module `Modules/AdminHelpers/ActionHelpers/Tools.luau`.
Core.Modules.AdminHelpers.ActionHelpers.Tools = Core.Modules.AdminHelpers.ActionHelpers.Tools or {}
do
	local __module = nil
	local Tools = {}

	---@private
	---Menjalankan fungsi `isVipGrant`.
	---@param toolName any Nilai parameter `toolName`.
	---@return any result Hasil dari fungsi `isVipGrant`.
	local function isVipGrant(toolName)
		return string.lower(tostring(toolName)) == "vip"
	end

	---Menjalankan fungsi `run`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param toolName any Nilai parameter `toolName`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	function Tools.run(service, player, toolName, targetUserId)
		if not service:_canUsePanel(player) then
			return false, "NoPermission"
		end

		local target = targetUserId and service:_findPlayerByUserId(targetUserId) or player 
		if not target then 
			return false, "TargetOffiline"
		end

		if target ~= player and not service:_canActOn(player, target) then 
			return false, "TargetHigherRole"
		end 

		if isVipGrant(toolName) then 
			local knit = service._knit 
			local vipService = knit and knit.GetService("VipService") or nil 
			if not vipService or not vipService._grantVip then 
				return false, "VipServiceUnvailable"
			end 

			vipService:_grantVip(target)
			local targetName = service:_describeTarget(target, target.UserId)
			service._emitLog(player, string.format("Grant VIP to %s", targetName))
			return true 
		end

		local tool = service._tools[toolName]
		if not tool then
			return false, "UnknownTool"
		end

		local backpack = target:FindFirstChild("Backpack")
		if not backpack then
			return false, "NoBackpack"
		end

		local existing = backpack:FindFirstChild(tool.Name)
		if existing then 
			existing:Destroy()
		end

		local clone = tool:Clone()
		clone.Parent = backpack

		local starterGear = target:FindFirstChild("StarterGear")
		if starterGear then
			local existingStarter = starterGear:FindFirstChild(tool.Name)
			if existingStarter then 
				existingStarter:Destroy()
			end
			local clone2 = tool:Clone()
			clone2.Parent = starterGear
		end
		local targetName = service:_describeTarget(target, target and target.UserId or targetUserId)
		service:_emitLog(player, string.format("Give tool %s to %s", tostring(toolName), targetName))
		return true
	end

	__module = Tools

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/ActionHelpers/Tools.luau"
	end
	Core.Modules.AdminHelpers.ActionHelpers.Tools = __module
end

---@class CoreModulesAdminHelpersBindHelpersMessaging
---@field __source string Path sumber module `Modules/AdminHelpers/BindHelpers/Messaging.luau`.
---@field bind any Member public `bind` dari `Modules/AdminHelpers/BindHelpers/Messaging.luau`.
Core.Modules.AdminHelpers.BindHelpers.Messaging = Core.Modules.AdminHelpers.BindHelpers.Messaging or {}
do
	local __module = nil
	local Messaging = {}

	---Menjalankan fungsi `bind`.
	---@param service any Nilai parameter `service`.
	function Messaging.bind(service)
		local ok, conn = pcall(function()
			return service._messaging:SubscribeAsync("AdminAnnounce", function(message)
				if message and message.Data then
					service.Client.Announcement:FireAll(message.Data)
				end
			end)
		end)
		if ok and conn then
			service._janitor:Add(conn, "Disconnect")
		end
	end

	__module = Messaging

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/BindHelpers/Messaging.luau"
	end
	Core.Modules.AdminHelpers.BindHelpers.Messaging = __module
end

---@class CoreModulesAdminHelpersBindHelpersPlayers
---@field __source string Path sumber module `Modules/AdminHelpers/BindHelpers/Players.luau`.
Core.Modules.AdminHelpers.BindHelpers.Players = Core.Modules.AdminHelpers.BindHelpers.Players or {}
do
	local __module = nil
	local BanRole = Core.Modules.AdminHelpers.BindHelpers.PlayerHelpers.BanRole
	local Jail = Core.Modules.AdminHelpers.BindHelpers.PlayerHelpers.Jail

	local PlayersBind = {}

	---Menjalankan fungsi `bind`.
	---@param service any Nilai parameter `service`.
	function PlayersBind.bind(service)
		service._janitor:Add(service._players.PlayerAdded:Connect(function(player)
			if service._serverLocked and not service:_isPrivileged(player) then
				player:Kick("Server is private.")
				return
			end
			BanRole.checkBan(service, player)
			BanRole.loadRole(service, player)
			Jail.loadJail(service, player)
		end), "Disconnect")

		service._janitor:Add(service._players.PlayerRemoving:Connect(function(player)
			Jail.cleanup(service, player)
			BanRole.cleanup(service, player)
		end), "Disconnect")

		for _, player in ipairs(service._players:GetPlayers()) do
			BanRole.checkBan(service, player)
			BanRole.loadRole(service, player)
			Jail.loadJail(service, player)
		end
	end

	__module = PlayersBind

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/BindHelpers/Players.luau"
	end
	Core.Modules.AdminHelpers.BindHelpers.Players = __module
end

---@class CoreModulesAdminHelpersBindHelpersUptime
---@field __source string Path sumber module `Modules/AdminHelpers/BindHelpers/Uptime.luau`.
---@field bind any Member public `bind` dari `Modules/AdminHelpers/BindHelpers/Uptime.luau`.
Core.Modules.AdminHelpers.BindHelpers.Uptime = Core.Modules.AdminHelpers.BindHelpers.Uptime or {}
do
	local __module = nil
	local Uptime = {}

	---Menjalankan fungsi `bind`.
	---@param service any Nilai parameter `service`.
	function Uptime.bind(service)
		local timer = service._timer.new(1)
		service._janitor:Add(timer, "Destroy")
		timer.Tick:Connect(function()
			local elapsed = os.time() - service._startTime
			service.Client.Uptime:FireAll(elapsed)
		end)
		timer:Start()
	end

	__module = Uptime

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/BindHelpers/Uptime.luau"
	end
	Core.Modules.AdminHelpers.BindHelpers.Uptime = __module
end

---@class CoreModulesAdminHelpersBootstrapHelpersAnnounce
---@field __source string Path sumber module `Modules/AdminHelpers/BootstrapHelpers/Announce.luau`.
Core.Modules.AdminHelpers.BootstrapHelpers.Announce = Core.Modules.AdminHelpers.BootstrapHelpers.Announce or {}
do
	local __module = nil
	local Announce = {}

	---Menjalankan fungsi `broadcast`.
	---@param service any Nilai parameter `service`.
	---@param payload any Nilai parameter `payload`.
	---@param scope any Nilai parameter `scope`.
	function Announce.broadcast(service, payload, scope)
		local resolvedScope = scope or payload.scope or "Server"

		if resolvedScope == "Global" then
			local ok = pcall(function()
				service._messaging:PublishAsync("AdminAnnounce", payload)
			end)
			if not ok then
				service.Client.Announcement:FireAll(payload)
			end
			return
		end
		service.Client.Announcement:FireAll(payload)
	end

	---Menjalankan fungsi `run`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param message any Nilai parameter `message`.
	---@param scope any Nilai parameter `scope`.
	---@param duration any Nilai parameter `duration`.
	function Announce.run(service, player, message, scope, duration)
		if not service:_canUsePanel(player) then
			return false, "NoPermission"
		end
		local text = tostring(message or "")
		text = string.gsub(text, "%s+$", "")
		if text == "" then
			return false, "Empty"
		end
		local maxLen = service._adminConfig.MaxAnnounceLength or 100
		if #text > maxLen then
			text = string.sub(text, 1, maxLen)
		end
		local dur = tonumber(duration) or service._adminConfig.DefaultAnnounceDuration or 6
		local maxDur = service._adminConfig.MaxAnnounceDuration or 60
		if dur < 1 then
			dur = 1
		end
		if dur > maxDur then
			dur = maxDur
		end
		local resolvedScope = (scope == "Global" and "Global") or "Server"
		local payload = {
			header = "Admin",
			message = text,
			duration = dur,
			scope = resolvedScope,
			from = player and player.Name or "",
			fromDisplayName = player and (player.DisplayName or player.Name) or "",
			fromUserId = player and player.UserId or 0,
			fromRole = service:_getRoleDisplay(service:_getRoleLabel(player)),
		}
		Announce.broadcast(service, payload, scope or "Server")
		service:_emitLog(player, string.format("Announce (%s): %s", payload.scope or "Server", text))
		return true
	end

	__module = Announce

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/BootstrapHelpers/Announce.luau"
	end
	Core.Modules.AdminHelpers.BootstrapHelpers.Announce = __module
end

---@class CoreModulesAdminHelpersBootstrapHelpersGet
---@field __source string Path sumber module `Modules/AdminHelpers/BootstrapHelpers/Get.luau`.
---@field run any Member public `run` dari `Modules/AdminHelpers/BootstrapHelpers/Get.luau`.
Core.Modules.AdminHelpers.BootstrapHelpers.Get = Core.Modules.AdminHelpers.BootstrapHelpers.Get or {}
do
	local __module = nil
	local Get = {}

	---Menjalankan fungsi `run`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	function Get.run(service, player)
		local canUse = service:_canUsePanel(player)
		local summitEvent = service._getSummitEvent and service:_getSummitEvent() or {
			active = false,
			value = 0,
			durationHours = 0,
			startedAt = 0,
			endsAt = 0,
		}

		return {
			canUse = canUse,
			roles = service._adminConfig.AssignableRoles or {"Member"},
			teleports = service._teleportNames or {},
			tools = service._toolNames or {},
			maxAnnounce = service._adminConfig.MaxAnnounceLength or 100,
			defaultDuration = service._adminConfig.DefaultAnnounceDuration or 6,
			logMax = service._logMax,
			logs = canUse and service._logs or {},
			summitEvent = summitEvent,
		}
	end

	__module = Get

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/BootstrapHelpers/Get.luau"
	end
	Core.Modules.AdminHelpers.BootstrapHelpers.Get = __module
end

---@class CoreModulesAdminHelpersCommandsUnbanCommandBinder
---@field __source string Path sumber module `Modules/AdminHelpers/Commands/UnbanCommandBinder.luau`.
Core.Modules.AdminHelpers.Commands.UnbanCommandBinder = Core.Modules.AdminHelpers.Commands.UnbanCommandBinder or {}
do
	local __module = nil
	local Players = game:GetService("Players")
	local TextChatService = game:FindService("TextChatService")

	local UnbanCommandBinder = {}

	---@private
	---Menjalankan fungsi `parseTarget`.
	---@param raw any Nilai parameter `raw`.
	local function parseTarget(raw)
		local text = tostring(raw or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if text == "" then
			return nil
		end
		local first = text:match("^(%S+)")
		return first
	end

	---@private
	---Menjalankan fungsi `resolveUserId`.
	---@param target any Nilai parameter `target`.
	local function resolveUserId(target)
		local id = tonumber(target)
		if id then
			return id
		end
		local ok, res = pcall(function()
			return Players:GetUserIdFromNameAsync(target)
		end)
		if ok then
			return res
		end
		return nil
	end

	---@private
	---Menjalankan fungsi `handle`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param targetRaw any Nilai parameter `targetRaw`.
	local function handle(service, player, targetRaw)
		local target = parseTarget(targetRaw)
		if not target then
			return
		end
		local userId = resolveUserId(target)
		if not userId then
			return
		end
		service:_unbanUserId(player, userId)
	end

	---@private
	---Menjalankan fungsi `bindPlayer`.
	---@param service any Nilai parameter `service`.
	---@param janitor any Nilai parameter `janitor`.
	---@param player any Nilai parameter `player`.
	local function bindPlayer(service, janitor, player)
		janitor:Add(player.Chatted:Connect(function(message)
			local msg = tostring(message or ""):lower()
			if msg:sub(1, 6) == "/unban" or msg:sub(1, 5) == "unban" then
				local arg = tostring(message):gsub("^%s*[/]?[Uu][Nn][Bb][Aa][Nn]%s*", "")
				handle(service, player, arg)
			end
		end), "Disconnect")
	end

	---Menjalankan fungsi `bind`.
	---@param service any Nilai parameter `service`.
	---@param janitor any Nilai parameter `janitor`.
	function UnbanCommandBinder.bind(service, janitor)
		local j = janitor or {
			Add = function(_, c)
				return c
			end,
		}

		---@private
		---Menjalankan fungsi `bindTextChatCommands`.
		---@param commandParent any Nilai parameter `commandParent`.
		local function bindTextChatCommands(commandParent)
			if not commandParent then return end
			---@private
			---Menjalankan fungsi `ensureCommand`.
			---@param name any Nilai parameter `name`.
			---@param primary any Nilai parameter `primary`.
			---@param secondary any Nilai parameter `secondary`.
			---@param description any Nilai parameter `description`.
			local function ensureCommand(name, primary, secondary, description)
				local cmd = commandParent:FindFirstChild(name)
				if not cmd then
					cmd = Instance.new("TextChatCommand")
					cmd.Name = name
					cmd.PrimaryAlias = primary
					cmd.Enabled = true
					if secondary then
						pcall(function()
							cmd.SecondaryAlias = {secondary}
						end)
					end
					pcall(function()
						cmd.Description = description
					end)
					cmd.Parent = commandParent
				elseif cmd.Parent ~= commandParent then
					cmd.Parent = commandParent
				end
				return cmd
			end

			local unbanCmd = ensureCommand("UnbanCommand", "/unban", "unban", "Unban player: /unban <userId|username>")
			j:Add(unbanCmd.Triggered:Connect(function(textSource, message)
				local player = textSource and Players:GetPlayerByUserId(textSource.UserId)
				if not player then
					return
				end
				handle(service, player, message)
			end), "Disconnect")
		end

		if TextChatService then
			local existing = TextChatService:FindFirstChild("TextChatCommands")
			if existing then
				bindTextChatCommands(existing)
			else
				j:Add(TextChatService.ChildAdded:Connect(function(child)
					if child.Name == "TextChatCommands" then
						bindTextChatCommands(child)
					end
				end), "Disconnect")
			end
		end

		j:Add(Players.PlayerAdded:Connect(function(player)
			bindPlayer(service, j, player)
		end), "Disconnect")
		for _, player in ipairs(Players:GetPlayers()) do
			bindPlayer(service, j, player)
		end
	end

	__module = UnbanCommandBinder

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/Commands/UnbanCommandBinder.luau"
	end
	Core.Modules.AdminHelpers.Commands.UnbanCommandBinder = __module
end

---@class CoreModulesAdminHelpersJailHelpersGuard
---@field __source string Path sumber module `Modules/AdminHelpers/JailHelpers/Guard.luau`.
Core.Modules.AdminHelpers.JailHelpers.Guard = Core.Modules.AdminHelpers.JailHelpers.Guard or {}
do
	local __module = nil
	local RunService = game:GetService("RunService")
	local PhysicsService = game:GetService("PhysicsService")

	local Guard = {}

	local PLAYERS_GROUP = "PlayersNoCollide"
	local JAILED_GROUP = "JailedPlayers"
	local JAIL_GROUP = "AdminJailBarrier"
	local CARRY_GROUP = "CarryNoCollide"

	---@private
	---Menjalankan fungsi `ensureCollisionGroups`.
	local function ensureCollisionGroups()
		pcall(function()
			PhysicsService:RegisterCollisionGroup(JAILED_GROUP)
		end)
		pcall(function()
			PhysicsService:RegisterCollisionGroup(JAIL_GROUP)
		end)

		pcall(function()
			PhysicsService:CollisionGroupSetCollidable(JAIL_GROUP, JAIL_GROUP, false)
			PhysicsService:CollisionGroupSetCollidable(JAIL_GROUP, PLAYERS_GROUP, false)
			PhysicsService:CollisionGroupSetCollidable(JAIL_GROUP, CARRY_GROUP, false)
			PhysicsService:CollisionGroupSetCollidable(JAIL_GROUP, "Default", false)
			PhysicsService:CollisionGroupSetCollidable(JAIL_GROUP, JAILED_GROUP, true)
			PhysicsService:CollisionGroupSetCollidable(JAILED_GROUP, JAILED_GROUP, false)
			PhysicsService:CollisionGroupSetCollidable(JAILED_GROUP, PLAYERS_GROUP, false)
			PhysicsService:CollisionGroupSetCollidable(JAILED_GROUP, CARRY_GROUP, false)
			PhysicsService:CollisionGroupSetCollidable(JAILED_GROUP, "Default", true)
			PhysicsService:CollisionGroupSetCollidable(JAILED_GROUP, JAIL_GROUP, true)
		end)
	end

	---@private
	---Menjalankan fungsi `setCollisionGroupRecursive`.
	---@param root any Nilai parameter `root`.
	---@param groupName any Nilai parameter `groupName`.
	local function setCollisionGroupRecursive(root, groupName)
		if not root then return end
		for _, desc in ipairs(root:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.CollisionGroup = groupName
			end
		end
	end

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	---@param deps any Nilai parameter `deps`.
	function Guard.install(service, deps)
		local AdminConfig = deps.AdminConfig
		local AdminUtils = deps.AdminUtils

		ensureCollisionGroups()

		---@private
		---Menjalankan fungsi `_applyJailCollision`.
		---@param player any Nilai parameter `player`.
		---@param enabled any Nilai parameter `enabled`.
		function service:_applyJailCollision(player, enabled)
			local character = player and player.Character
			if not character then
				return
			end
			setCollisionGroupRecursive(character, enabled and JAILED_GROUP or PLAYERS_GROUP)
		end

		---@private
		---Menjalankan fungsi `_applyJailBarrierCollision`.
		---@param model any Nilai parameter `model`.
		function service:_applyJailBarrierCollision(model)
			setCollisionGroupRecursive(model, JAIL_GROUP)
		end

		---@private
		---Menjalankan fungsi `_applyJailAtCFrame`.
		---@param player any Nilai parameter `player`.
		---@param cf any Nilai parameter `cf`.
		function service:_applyJailAtCFrame(player, cf)
			if not player or not cf then return end
			local model = self:_ensureJailModel(player)
			if not model then return end
			local pos = self:_findJailPos(model)
			if not pos then return end
			local pivot = model:GetPivot()
			local rel = pivot:ToObjectSpace(pos.CFrame)
			local newPivot = cf * rel:Inverse()
			model:PivotTo(newPivot)
			player:SetAttribute("Jail", true)
			self:_applyJailCollision(player, true)
			self:_applyJailBarrierCollision(model)
			AdminUtils.applyFreeze(player, true)
			local freezeSeconds = tonumber(AdminConfig.JailFreezeSeconds) or 3
			task.delay(freezeSeconds, function()
				if player.Parent and player:GetAttribute("Jail") == true then
					AdminUtils.applyFreeze(player, false)
				end
			end)
			self:_startJailGuard(player, model, pos)
		end

		---@private
		---Menjalankan fungsi `_startJailGuard`.
		---@param player any Nilai parameter `player`.
		---@param model any Nilai parameter `model`.
		---@param posPart any Nilai parameter `posPart`.
		function service:_startJailGuard(player, model, posPart)
			if not player or not model or not posPart then return end
			local userId = player.UserId
			self:_stopJailGuard(userId)
			local jan = self._jailGuards
			local conn
			conn = RunService.Heartbeat:Connect(function()
				if not player.Parent or player:GetAttribute("Jail") ~= true then
					self:_stopJailGuard(userId)
					return
				end
				local char = player.Character
				local root = AdminUtils.getHumanoidRootPart(char)
				if not root then return end
				self._jailLastPos[userId] = root.CFrame

				local cf, size = model:GetBoundingBox()
				local padding = tonumber(AdminConfig.JailRadiusPadding) or 2
				local half = (size / 2) + Vector3.new(padding, padding, padding)
				local localPos = cf:PointToObjectSpace(root.Position)
				if math.abs(localPos.X) > half.X
					or math.abs(localPos.Y) > half.Y
					or math.abs(localPos.Z) > half.Z then
					local targetCf = posPart.CFrame + Vector3.new(0, 2, 0)
					root.CFrame = targetCf
					self._jailLastPos[userId] = root.CFrame
				end
			end)
			jan[userId] = conn
		end

		---@private
		---Menjalankan fungsi `_stopJailGuard`.
		---@param userId any Nilai parameter `userId`.
		function service:_stopJailGuard(userId)
			local conn = self._jailGuards[userId]
			if conn then
				conn:Disconnect()
				self._jailGuards[userId] = nil
			end
		end

		---@private
		---Menjalankan fungsi `_stopJailRejoinHook`.
		---@param player any Nilai parameter `player`.
		function service:_stopJailRejoinHook(player)
			if not player then return end
			local conn = self._jailRejoinConns[player]
			if conn then
				conn:Disconnect()
				self._jailRejoinConns[player] = nil
			end
		end
	end

	__module = Guard

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/JailHelpers/Guard.luau"
	end
	Core.Modules.AdminHelpers.JailHelpers.Guard = __module
end

---@class CoreModulesAdminHelpersJailHelpersProfile
---@field __source string Path sumber module `Modules/AdminHelpers/JailHelpers/Profile.luau`.
Core.Modules.AdminHelpers.JailHelpers.Profile = Core.Modules.AdminHelpers.JailHelpers.Profile or {}
do
	local __module = nil
	local Profile = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	---@param _deps any Nilai parameter `_deps`.
	function Profile.install(service, _deps)

		---@private
		---Menjalankan fungsi `_cframeToTable`.
		---@param cf any Nilai parameter `cf`.
		function service:_cframeToTable(cf)
			if not cf then
				return nil
			end
			return {cf.X, cf.Y, cf.Z}
		end

		---@private
		---Menjalankan fungsi `_tableToCFrame`.
		---@param t any Nilai parameter `t`.
		function service:_tableToCFrame(t)
			if type(t) ~= "table" then
				return nil
			end
			local x, y, z = t[1], t[2], t[3]
			if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
				return nil
			end
			return CFrame.new(x, y, z)
		end

		---@private
		---Menjalankan fungsi `_loadJailProfile`.
		---@param player any Nilai parameter `player`.
		function service:_loadJailProfile(player)
			if self._jailProfiles[player] then
				return self._jailProfiles[player]
			end
			local key = "jail_" .. tostring(player.UserId)
			local profile
			for _ = 1, 5 do
				profile = self._jailStore:StartSessionAsync(key)
				if profile then
					break
				end
				task.wait(2)
			end
			if not profile then
				warn("[AdminService] Failed to load jail profile for " .. player.Name)
				return nil
			end
			profile:AddUserId(player.UserId)
			profile:Reconcile()
			self._jailProfiles[player] = profile
			return profile
		end

		---@private
		---Menjalankan fungsi `_ensureJailProfile`.
		---@param player any Nilai parameter `player`.
		function service:_ensureJailProfile(player)
			if not player then
				return nil
			end
			return self:_loadJailProfile(player)
		end

		---@private
		---Menjalankan fungsi `_releaseJailProfile`.
		---@param player any Nilai parameter `player`.
		function service:_releaseJailProfile(player)
			local profile = self._jailProfiles[player]
			if profile then
				profile:EndSession()
				self._jailProfiles[player] = nil
			end
		end

		---@private
		---Menjalankan fungsi `_saveJailState`.
		---@param player any Nilai parameter `player`.
		---@param isJailed any Nilai parameter `isJailed`.
		function service:_saveJailState(player, isJailed)
			if not player then
				return
			end
			local profile = self._jailProfiles[player]
			if not profile then
				return
			end
			profile.Data.isJailed = isJailed == true
			if isJailed then
				local cf = self._jailLastPos[player.UserId]
				profile.Data.pos = self:_cframeToTable(cf)
			else
				profile.Data.pos = nil
			end
			profile:Save()
		end
	end

	__module = Profile

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/JailHelpers/Profile.luau"
	end
	Core.Modules.AdminHelpers.JailHelpers.Profile = __module
end

---@class CoreModulesAdminHelpersJailHelpersTemplate
---@field __source string Path sumber module `Modules/AdminHelpers/JailHelpers/Template.luau`.
Core.Modules.AdminHelpers.JailHelpers.Template = Core.Modules.AdminHelpers.JailHelpers.Template or {}
do
	local __module = nil
	local Template = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	---@param deps any Nilai parameter `deps`.
	function Template.install(service, deps)
		local AdminConfig = deps.AdminConfig
		local AdminUtils = deps.AdminUtils
		local ServerStorage = deps.ServerStorage

		---@private
		---Menjalankan fungsi `_getJailTemplate`.
		function service:_getJailTemplate()
			local root = ServerStorage:FindFirstChild("AdminJail")
			local model = root and root:FindFirstChild("Jail")
			if model and model:IsA("Model") then
				return model
			end
			return nil
		end

		---@private
		---Menjalankan fungsi `_findJailPos`.
		---@param model any Nilai parameter `model`.
		function service:_findJailPos(model)
			if not model then return nil end
			local pos = model:FindFirstChild("Posisi", true)
			if pos and pos:IsA("BasePart") then
				return pos
			end
			if model.PrimaryPart then
				return model.PrimaryPart
			end
			for _, child in ipairs(model:GetDescendants()) do
				if child:IsA("BasePart") then
					return child
				end
			end
			return nil
		end

		---@private
		---Menjalankan fungsi `_ensureJailModel`.
		---@param player any Nilai parameter `player`.
		function service:_ensureJailModel(player)
			if not player then return nil end
			local userId = player.UserId
			local existing = self._jailModels[userId]
			if existing and existing.Parent then
				return existing
			end
			local template = self:_getJailTemplate()
			if not template then
				return nil
			end
			local clone = template:Clone()
			clone.Name = "AdminJail_" .. tostring(userId)
			clone.Parent = workspace
			self._jailModels[userId] = clone
			return clone
		end

		---@private
		---Menjalankan fungsi `_getJailCFrame`.
		function service:_getJailCFrame()
			local path = AdminConfig.JailPartPath
			local inst = AdminUtils.resolvePath(path)
			if inst and inst:IsA("BasePart") then
				return inst.CFrame
			end
			local byName = workspace:FindFirstChild("AdminJail") or workspace:FindFirstChild("Jail")
			if byName and byName:IsA("BasePart") then
				return byName.CFrame
			end
			return nil
		end
	end

	__module = Template

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/JailHelpers/Template.luau"
	end
	Core.Modules.AdminHelpers.JailHelpers.Template = __module
end

---@class CoreModulesAdminHelpersLogHelpersDescribe
---@field __source string Path sumber module `Modules/AdminHelpers/LogHelpers/Describe.luau`.
---@field install any Member public `install` dari `Modules/AdminHelpers/LogHelpers/Describe.luau`.
Core.Modules.AdminHelpers.LogHelpers.Describe = Core.Modules.AdminHelpers.LogHelpers.Describe or {}
do
	local __module = nil
	local Describe = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	function Describe.install(service)
		---@private
		---Menjalankan fungsi `_describeTarget`.
		---@param targetPlayer any Nilai parameter `targetPlayer`.
		---@param targetId any Nilai parameter `targetId`.
		function service:_describeTarget(targetPlayer, targetId)
			if targetPlayer then
				return targetPlayer.DisplayName or targetPlayer.Name, targetPlayer.UserId
			end
			if targetId then
				return "UserId " .. tostring(targetId), targetId
			end
			return "Unknown", nil
		end
	end

	__module = Describe

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/LogHelpers/Describe.luau"
	end
	Core.Modules.AdminHelpers.LogHelpers.Describe = __module
end

---@class CoreModulesAdminHelpersLogHelpersEmit
---@field __source string Path sumber module `Modules/AdminHelpers/LogHelpers/Emit.luau`.
Core.Modules.AdminHelpers.LogHelpers.Emit = Core.Modules.AdminHelpers.LogHelpers.Emit or {}
do
	local __module = nil
	local Emit = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	function Emit.install(service)
		---@private
		---Menjalankan fungsi `_emitLog`.
		---@param player any Nilai parameter `player`.
		---@param message any Nilai parameter `message`.
		function service:_emitLog(player, message)
			if not message or message == "" then return end
			local userId = player and player.UserId or 0
			local displayName = player and (player.DisplayName or player.Name) or "System"
			self._logCounter += 1
			local entry = {
				id = self._logCounter,
				userId = userId,
				displayName = displayName,
				message = message,
				time = os.time(),
			}
			table.insert(self._logs, entry)
			if #self._logs > self._logMax then
				table.remove(self._logs, 1)
			end
			self.Client.Log:FireAll(entry)
		end
	end

	__module = Emit

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/LogHelpers/Emit.luau"
	end
	Core.Modules.AdminHelpers.LogHelpers.Emit = __module
end

---@class CoreModulesAdminHelpersNotificationHelpersNotice
---@field __source string Path sumber module `Modules/AdminHelpers/NotificationHelpers/Notice.luau`.
Core.Modules.AdminHelpers.NotificationHelpers.Notice = Core.Modules.AdminHelpers.NotificationHelpers.Notice or {}
do
	local __module = nil
	local Notice = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	function Notice.install(service)
		---@private
		---Menjalankan fungsi `_notifyAdmin`.
		---@param player any Nilai parameter `player`.
		---@param ok any Nilai parameter `ok`.
		---@param message any Nilai parameter `message`.
		function service:_notifyAdmin(player, ok, message)
			if not player then return end
			if not self.Client or not self.Client.Notice then return end
			self.Client.Notice:Fire(player, {
				ok = ok == true,
				message = tostring(message or ""),
			})
		end
	end

	__module = Notice

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/NotificationHelpers/Notice.luau"
	end
	Core.Modules.AdminHelpers.NotificationHelpers.Notice = __module
end

---@class CoreModulesAdminHelpersOverheadHelpersApplyRole
---@field __source string Path sumber module `Modules/AdminHelpers/OverheadHelpers/ApplyRole.luau`.
Core.Modules.AdminHelpers.OverheadHelpers.ApplyRole = Core.Modules.AdminHelpers.OverheadHelpers.ApplyRole or {}
do
	local __module = nil
	local ApplyRole = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	---@param _deps any Nilai parameter `_deps`.
	function ApplyRole.install(service, _deps)
		---@private
		---Menjalankan fungsi `_applyRole`.
		---@param userId any Nilai parameter `userId`.
		---@param role any Nilai parameter `role`.
		function service:_applyRole(userId, role)
			if not userId then
				return
			end
			if role == "Member" then
				self._extraRoles[userId] = nil
			else
				self._extraRoles[userId] = role
			end
			local player = self._players:GetPlayerByUserId(userId)
			if player then
				self:_setRoleForPlayer(player, role)
			end
			self:_pushOverheadConfig()
		end
	end

	__module = ApplyRole

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/OverheadHelpers/ApplyRole.luau"
	end
	Core.Modules.AdminHelpers.OverheadHelpers.ApplyRole = __module
end

---@class CoreModulesAdminHelpersOverheadHelpersPushConfig
---@field __source string Path sumber module `Modules/AdminHelpers/OverheadHelpers/PushConfig.luau`.
Core.Modules.AdminHelpers.OverheadHelpers.PushConfig = Core.Modules.AdminHelpers.OverheadHelpers.PushConfig or {}
do
	local __module = nil
	local PushConfig = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	---@param deps any Nilai parameter `deps`.
	function PushConfig.install(service, deps)
		local OverheadConfig = deps.OverheadConfig

		---@private
		---Menjalankan fungsi `_pushOverheadConfig`.
		function service:_pushOverheadConfig()
			local overheadService = self._knit.GetService("OverheadService")
			if not overheadService or not overheadService.Client or not overheadService.Client.Config then
				return
			end
			---@private
			---Menjalankan fungsi `copyArray`.
			---@param arr any Nilai parameter `arr`.
			local function copyArray(arr)
				return table.clone(arr or {})
			end

			---@private
			---Menjalankan fungsi `copyMap`.
			---@param map any Nilai parameter `map`.
			local function copyMap(map)
				return table.clone(map or {})
			end

			---@private
			---Menjalankan fungsi `copySpecialRoles`.
			---@param src any Nilai parameter `src`.
			local function copySpecialRoles(src)
				local out = {}
				for roleName, spec in pairs(src or {}) do
					out[roleName] = {
						UserIds = copyArray(spec and spec.UserIds),
						Usernames = copyArray(spec and spec.Usernames),
					}
				end
				return out
			end

			local cfg = {}
			for k, v in pairs(OverheadConfig) do
				if k ~= "TitleConfig" then
					cfg[k] = v
				end
			end
			cfg.TitleConfig = copyMap(OverheadConfig.TitleConfig or {})
			cfg.TitleConfig.SpecialRoles = copySpecialRoles(OverheadConfig.TitleConfig and OverheadConfig.TitleConfig.SpecialRoles)
			cfg.TitleConfig.DisplayRole = copyMap(OverheadConfig.TitleConfig and OverheadConfig.TitleConfig.DisplayRole)
			cfg.TitleConfig.ChatTag = copyMap(OverheadConfig.TitleConfig and OverheadConfig.TitleConfig.ChatTag)
			cfg.TitleConfig.ExemptRoles = copyMap(OverheadConfig.TitleConfig and OverheadConfig.TitleConfig.ExemptRoles)
			cfg.TitleConfig.SummitLevels = OverheadConfig.TitleConfig and OverheadConfig.TitleConfig.SummitLevels or cfg.TitleConfig.SummitLevels

			---@private
			---Menjalankan fungsi `ensureRole`.
			---@param roleName any Nilai parameter `roleName`.
			local function ensureRole(roleName)
				local role = cfg.TitleConfig.SpecialRoles[roleName]
				if not role then
					role = {UserIds = {}, Usernames = {}}
					cfg.TitleConfig.SpecialRoles[roleName] = role
				end
				role.UserIds = role.UserIds or {}
				return role
			end

			local adminRole = ensureRole("Admin")
			local modRole = ensureRole("Moderator")
			local devRole = ensureRole("Developer")

			---@private
			---Menjalankan fungsi `addUserId`.
			---@param list any Nilai parameter `list`.
			---@param userId any Nilai parameter `userId`.
			local function addUserId(list, userId)
				for _, id in ipairs(list) do
					if id == userId then
						return
					end
				end
				table.insert(list, userId)
			end

			for userId, role in pairs(self._extraRoles) do
				if role == "Admin" then
					addUserId(adminRole.UserIds, userId)
				elseif role == "Moderator" then
					addUserId(modRole.UserIds, userId)
				elseif role == "Developer" then
					addUserId(devRole.UserIds, userId)
				end
			end

			overheadService.Client.Config:Set(cfg)
		end
	end

	__module = PushConfig

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/OverheadHelpers/PushConfig.luau"
	end
	Core.Modules.AdminHelpers.OverheadHelpers.PushConfig = __module
end

---@class CoreModulesAdminHelpersPermissionHelpersChecks
---@field __source string Path sumber module `Modules/AdminHelpers/PermissionHelpers/Checks.luau`.
Core.Modules.AdminHelpers.PermissionHelpers.Checks = Core.Modules.AdminHelpers.PermissionHelpers.Checks or {}
do
	local __module = nil
	local Checks = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	---@param deps any Nilai parameter `deps`.
	function Checks.install(service, deps)
		local OverheadConfig = deps.OverheadConfig
		local Utils = deps.Utils

		---@private
		---Menjalankan fungsi `_isOwner`.
		---@param player any Nilai parameter `player`.
		function service:_isOwner(player)
			if not player then return false end
			if OverheadConfig.PlaceOwnerId and player.UserId == OverheadConfig.PlaceOwnerId then
				return true
			end
			if Utils.isOwnerByGame(player) then
				return true
			end
			local special = OverheadConfig.TitleConfig and OverheadConfig.TitleConfig.SpecialRoles
			local ownerSpec = special and special.Owner
			if ownerSpec and Utils.matches(ownerSpec.UserIds, ownerSpec.Usernames, player) then
				return true
			end
			return false
		end

		---@private
		---Menjalankan fungsi `_hasRoleFromConfig`.
		---@param player any Nilai parameter `player`.
		---@param roleName any Nilai parameter `roleName`.
		function service:_hasRoleFromConfig(player, roleName)
			local special = OverheadConfig.TitleConfig and OverheadConfig.TitleConfig.SpecialRoles
			local spec = special and special[roleName]
			return spec and Utils.matches(spec.UserIds, spec.Usernames, player) or false
		end

		---@private
		---Menjalankan fungsi `_hasDynamicRole`.
		---@param player any Nilai parameter `player`.
		---@param roleName any Nilai parameter `roleName`.
		function service:_hasDynamicRole(player, roleName)
			local role = self._extraRoles[player.UserId]
			return role == roleName
		end

		---@private
		---Menjalankan fungsi `_isPrivileged`.
		---@param player any Nilai parameter `player`.
		function service:_isPrivileged(player)
			if not player then return false end
			if self:_isOwner(player) then return true end
			if self:_hasRoleFromConfig(player, "Developer") or self:_hasDynamicRole(player, "Developer") then return true end
			if self:_hasRoleFromConfig(player, "Admin") or self:_hasDynamicRole(player, "Admin") then return true end
			if self:_hasRoleFromConfig(player, "Moderator") or self:_hasDynamicRole(player, "Moderator") then return true end
			return false
		end

		---@private
		---Menjalankan fungsi `_getRoleLabel`.
		---@param player any Nilai parameter `player`.
		function service:_getRoleLabel(player)
			if self:_isOwner(player) then
				return "Owner"
			end
			if self:_hasRoleFromConfig(player, "Developer") or self:_hasDynamicRole(player, "Developer") then
				return "Developer"
			end
			if self:_hasRoleFromConfig(player, "Admin") or self:_hasDynamicRole(player, "Admin") then
				return "Admin"
			end
			if self:_hasRoleFromConfig(player, "Moderator") or self:_hasDynamicRole(player, "Moderator") then
				return "Moderator"
			end
			local vipAttr = OverheadConfig.VipAttribute or "VIP"
			if player:GetAttribute(vipAttr) == true then
				return "VIP"
			end
			return "Member"
		end

		---@private
		---Menjalankan fungsi `_getRoleDisplay`.
		---@param roleName any Nilai parameter `roleName`.
		function service:_getRoleDisplay(roleName)
			local display = OverheadConfig.TitleConfig and OverheadConfig.TitleConfig.DisplayRole
			if display and display[roleName] then
				return display[roleName]
			end
			return roleName
		end

		---@private
		---Menjalankan fungsi `_getRoleRank`.
		---@param roleName any Nilai parameter `roleName`.
		function service:_getRoleRank(roleName)
			local rank = {
				Owner = 5,
				Developer = 4,
				Admin = 3,
				Moderator = 2,
				VIP = 1,
				Member = 0,
			}
			return rank[roleName] or 0
		end

		---@private
		---Menjalankan fungsi `_canActOn`.
		---@param actor any Nilai parameter `actor`.
		---@param target any Nilai parameter `target`.
		function service:_canActOn(actor, target)
			if not actor or not target then return false end
			if actor == target then return true end
			local actorRole = self:_getRoleLabel(actor)
			local targetRole = self:_getRoleLabel(target)
			return self:_getRoleRank(actorRole) >= self:_getRoleRank(targetRole)
		end

		---@private
		---Menjalankan fungsi `_canAssignRole`.
		---@param actor any Nilai parameter `actor`.
		---@param roleName any Nilai parameter `roleName`.
		function service:_canAssignRole(actor, roleName)
			if not actor then return false end
			local actorRole = self:_getRoleLabel(actor)
			return self:_getRoleRank(actorRole) >= self:_getRoleRank(roleName)
		end

		---@private
		---Menjalankan fungsi `_canUsePanel`.
		---@param player any Nilai parameter `player`.
		function service:_canUsePanel(player)
			return self:_isPrivileged(player)
		end

		---@private
		---Menjalankan fungsi `_isAdminOnly`.
		---@param player any Nilai parameter `player`.
		function service:_isAdminOnly(player)
			if not player then return false end
			local role = self:_getRoleLabel(player)
			return self:_getRoleRank(role) >= self:_getRoleRank("Admin")
		end
	end

	__module = Checks

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/PermissionHelpers/Checks.luau"
	end
	Core.Modules.AdminHelpers.PermissionHelpers.Checks = __module
end

---@class CoreModulesAdminHelpersPermissionHelpersMutate
---@field __source string Path sumber module `Modules/AdminHelpers/PermissionHelpers/Mutate.luau`.
Core.Modules.AdminHelpers.PermissionHelpers.Mutate = Core.Modules.AdminHelpers.PermissionHelpers.Mutate or {}
do
	local __module = nil
	local Mutate = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	---@param deps any Nilai parameter `deps`.
	function Mutate.install(service, deps)
		local OverheadConfig = deps.OverheadConfig

		---@private
		---Menjalankan fungsi `_setRoleForPlayer`.
		---@param player any Nilai parameter `player`.
		---@param role any Nilai parameter `role`.
		function service:_setRoleForPlayer(player, role)
			if not player then return end
			local normalized = role or "Member"
			player:SetAttribute("RoleTitle", normalized)

			local vipAttr = OverheadConfig.VipAttribute or "VIP"
			if normalized == "VIP" then
				player:SetAttribute(vipAttr, true)
			end
		end

		---@private
		---Menjalankan fungsi `_setRoleTitlePreserveVip`.
		---@param player any Nilai parameter `player`.
		function service:_setRoleTitlePreserveVip(player)
			if not player then return end
			local vipAttr = OverheadConfig.VipAttribute or "VIP"
			if player:GetAttribute(vipAttr) == true then
				player:SetAttribute("RoleTitle", "VIP")
			else
				player:SetAttribute("RoleTitle", "Member")
			end
		end
	end

	__module = Mutate

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/PermissionHelpers/Mutate.luau"
	end
	Core.Modules.AdminHelpers.PermissionHelpers.Mutate = __module
end

---@class CoreModulesAdminHelpersProfileHelpersBan
---@field __source string Path sumber module `Modules/AdminHelpers/ProfileHelpers/Ban.luau`.
Core.Modules.AdminHelpers.ProfileHelpers.Ban = Core.Modules.AdminHelpers.ProfileHelpers.Ban or {}
do
	local __module = nil
	local Ban = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	---@param _deps any Nilai parameter `_deps`.
	function Ban.install(service, _deps)
		---@private
		---Menjalankan fungsi `startSession`.
		---@param store any Nilai parameter `store`.
		---@param key any Nilai parameter `key`.
		local function startSession(store, key)
			local profile
			for _ = 1, 5 do
				profile = store:StartSessionAsync(key)
				if profile then break end
				task.wait(2)
			end
			return profile
		end

		---@private
		---Menjalankan fungsi `_loadBanProfile`.
		---@param player any Nilai parameter `player`.
		function service:_loadBanProfile(player)
			if not player then
				return nil
			end
			local userId = player.UserId
			if self._banProfiles[userId] then
				return self._banProfiles[userId]
			end
			local profile = startSession(self._banStore, "ban_" .. tostring(userId))
			if not profile then
				warn("[AdminService] Failed to load ban profile for " .. player.Name)
				return nil
			end
			profile:AddUserId(userId)
			profile:Reconcile()
			self._banProfiles[userId] = profile
			return profile
		end

		---@private
		---Menjalankan fungsi `_releaseBanProfile`.
		---@param player any Nilai parameter `player`.
		function service:_releaseBanProfile(player)
			if not player then
				return
			end
			local profile = self._banProfiles[player.UserId]
			if profile then
				profile:EndSession()
				self._banProfiles[player.UserId] = nil
			end
		end

		---@private
		---Menjalankan fungsi `_isBanned`.
		---@param userId any Nilai parameter `userId`.
		function service:_isBanned(userId)
			local profile = self._banProfiles[userId]
			if profile then
				return profile.Data.banned == true
			end
			return false
		end

		---@private
		---Menjalankan fungsi `_setBan`.
		---@param userId any Nilai parameter `userId`.
		---@param banned any Nilai parameter `banned`.
		function service:_setBan(userId, banned)
			local id = tonumber(userId)
			if not id then
				return false
			end
			local profile = self._banProfiles[id]
			if profile then
				profile.Data.banned = banned == true
				pcall(function()
					profile:Save()
				end)
				return true
			end
			local temp = startSession(self._banStore, "ban_" .. tostring(id))
			if not temp then
				return false
			end
			temp:Reconcile()
			temp.Data.banned = banned == true
			temp:EndSession()
			return true
		end
	end

	__module = Ban

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/ProfileHelpers/Ban.luau"
	end
	Core.Modules.AdminHelpers.ProfileHelpers.Ban = __module
end

---@class CoreModulesAdminHelpersProfileHelpersRoles
---@field __source string Path sumber module `Modules/AdminHelpers/ProfileHelpers/Roles.luau`.
Core.Modules.AdminHelpers.ProfileHelpers.Roles = Core.Modules.AdminHelpers.ProfileHelpers.Roles or {}
do
	local __module = nil
	local Roles = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	---@param _deps any Nilai parameter `_deps`.
	function Roles.install(service, _deps)
		---@private
		---Menjalankan fungsi `startSession`.
		---@param store any Nilai parameter `store`.
		---@param key any Nilai parameter `key`.
		local function startSession(store, key)
			local profile
			for _ = 1, 5 do
				profile = store:StartSessionAsync(key)
				if profile then break end
				task.wait(2)
			end
			return profile
		end

		---@private
		---Menjalankan fungsi `_loadRoleProfile`.
		---@param player any Nilai parameter `player`.
		function service:_loadRoleProfile(player)
			if not player then
				return nil
			end
			local userId = player.UserId
			if self._roleProfiles[userId] then
				return self._roleProfiles[userId]
			end
			local profile = startSession(self._roleStore, "role_" .. tostring(userId))
			if not profile then
				warn("[AdminService] Failed to load role profile for " .. player.Name)
				return nil
			end
			profile:AddUserId(userId)
			profile:Reconcile()
			self._roleProfiles[userId] = profile
			return profile
		end

		---@private
		---Menjalankan fungsi `_releaseRoleProfile`.
		---@param player any Nilai parameter `player`.
		function service:_releaseRoleProfile(player)
			if not player then
				return
			end
			local profile = self._roleProfiles[player.UserId]
			if profile then
				profile:EndSession()
				self._roleProfiles[player.UserId] = nil
			end
		end

		---@private
		---Menjalankan fungsi `_getRoleData`.
		---@param userId any Nilai parameter `userId`.
		function service:_getRoleData(userId)
			local profile = self._roleProfiles[userId]
			if profile then
				return profile.Data.role
			end
			return nil
		end

		---@private
		---Menjalankan fungsi `_setRoleData`.
		---@param userId any Nilai parameter `userId`.
		---@param role any Nilai parameter `role`.
		function service:_setRoleData(userId, role)
			local id = tonumber(userId)
			if not id then
				return false
			end
			local newRole = role or "Member"
			local profile = self._roleProfiles[id]
			if profile then
				profile.Data.role = newRole
				pcall(function()
					profile:Save()
				end)
			else
				local temp = startSession(self._roleStore, "role_" .. tostring(id))
				if not temp then
					return false
				end
				temp:Reconcile()
				temp.Data.role = newRole
				temp:EndSession()
			end

			if newRole == "Member" then
				self._extraRoles[id] = nil
			else
				self._extraRoles[id] = newRole
			end

			local targetPlayer = self._players:GetPlayerByUserId(id)
			if targetPlayer then
				if newRole == "Member" then
					self:_setRoleTitlePreserveVip(targetPlayer)
				else
					self:_setRoleForPlayer(targetPlayer, newRole)
				end
			end
			self:_pushOverheadConfig()
			return true
		end
	end

	__module = Roles

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/ProfileHelpers/Roles.luau"
	end
	Core.Modules.AdminHelpers.ProfileHelpers.Roles = __module
end

---@class CoreModulesAdminHelpersRefreshHelpersTeleports
---@field __source string Path sumber module `Modules/AdminHelpers/RefreshHelpers/Teleports.luau`.
Core.Modules.AdminHelpers.RefreshHelpers.Teleports = Core.Modules.AdminHelpers.RefreshHelpers.Teleports or {}
do
	local __module = nil
	local Teleports = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	---@param deps any Nilai parameter `deps`.
	function Teleports.install(service, deps)
		local CheckpointIndex = deps.CheckpointIndex

		---@private
		---Menjalankan fungsi `buildTeleportName`.
		---@param info any Nilai parameter `info`.
		---@param summitOrder any Nilai parameter `summitOrder`.
		local function buildTeleportName(info, summitOrder)
			if not info or info.index == nil then
				return nil
			end

			if info.isStart then
				return "Basecamp"
			end

			if info.isFinish then
				if summitOrder <= 1 then
					return "Summit"
				end
				return string.format("Summit %d", summitOrder)
			end

			return string.format("Checkpoint %d", info.index)
		end

		---@private
		---Menjalankan fungsi `_refreshTeleports`.
		function service:_refreshTeleports()
			self._teleports = {}
			self._teleportNames = {}

			local ordered = CheckpointIndex:GetOrdered()
			local summitOrder = 0
			for _, part in ipairs(ordered) do
				local info = CheckpointIndex:GetInfoForInstance(part)
				if info and info.index then
					if info.isFinish then
						summitOrder += 1
					end

					local name = buildTeleportName(info, summitOrder)
					if not name then
						continue
					end

					self._teleports[name] = part.CFrame
					table.insert(self._teleportNames, name)
				end
			end
		end
	end

	__module = Teleports

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/RefreshHelpers/Teleports.luau"
	end
	Core.Modules.AdminHelpers.RefreshHelpers.Teleports = __module
end

---@class CoreModulesAdminHelpersRefreshHelpersTools
---@field __source string Path sumber module `Modules/AdminHelpers/RefreshHelpers/Tools.luau`.
Core.Modules.AdminHelpers.RefreshHelpers.Tools = Core.Modules.AdminHelpers.RefreshHelpers.Tools or {}
do
	local __module = nil
	local Tools = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	---@param deps any Nilai parameter `deps`.
	function Tools.install(service, deps)
		local ServerStorage = deps.ServerStorage

		---@private
		---Menjalankan fungsi `_refreshTools`.
		function service:_refreshTools()
			self._tools = {}
			self._toolNames = {}
			local folder = ServerStorage:FindFirstChild("AdminTools")
			if not folder then
				return
			end
			for _, tool in ipairs(folder:GetChildren()) do
				if tool:IsA("Tool") then
					self._tools[tool.Name] = tool
					table.insert(self._toolNames, tool.Name)
				end
			end
			table.sort(self._toolNames, function(a, b)
				return a:lower() < b:lower()
			end)
		end
	end

	__module = Tools

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/RefreshHelpers/Tools.luau"
	end
	Core.Modules.AdminHelpers.RefreshHelpers.Tools = __module
end

---@class CoreModulesAdminHelpersServerControlHelpersLock
---@field __source string Path sumber module `Modules/AdminHelpers/ServerControlHelpers/Lock.luau`.
Core.Modules.AdminHelpers.ServerControlHelpers.Lock = Core.Modules.AdminHelpers.ServerControlHelpers.Lock or {}
do
	local __module = nil
	local Lock = {}

	---Menjalankan fungsi `run`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param action any Nilai parameter `action`.
	function Lock.run(service, player, action)
		if not service:_canUsePanel(player) then
			return false, "NoPermission"
		end
		if action == "Lock" then
			service._serverLocked = true
			service:_emitLog(player, "Server locked")
			return true
		end
		if action == "Unlock" then
			service._serverLocked = false
			service:_emitLog(player, "Server unlocked")
			return true
		end
		return false, "UnknownAction"
	end

	__module = Lock

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/ServerControlHelpers/Lock.luau"
	end
	Core.Modules.AdminHelpers.ServerControlHelpers.Lock = __module
end

---@class CoreModulesAdminHelpersServerControlHelpersRestart
---@field __source string Path sumber module `Modules/AdminHelpers/ServerControlHelpers/Restart.luau`.
Core.Modules.AdminHelpers.ServerControlHelpers.Restart = Core.Modules.AdminHelpers.ServerControlHelpers.Restart or {}
do
	local __module = nil
	local Restart = {}

	---Menjalankan fungsi `run`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	function Restart.run(service, player)
		if not service:_canUsePanel(player) then
			return false, "NoPermission"
		end
		if service._runService:IsStudio() then
			return false, "RestartNotAvailableInStudio"
		end
		service:_emitLog(player, "Server restarting.")
		local allPlayers = service._players:GetPlayers()
		if #allPlayers == 0 then
			return true
		end
		local reservedOk, reservedCode = pcall(function()
			return service._teleportService:ReserveServer(game.PlaceId)
		end)
		if not reservedOk then
			service:_emitLog(player, "Reserve server failed: " .. tostring(reservedCode))
		end
		local ok, err = pcall(function()
			if reservedOk and reservedCode then
				local options = Instance.new("TeleportOptions")
				options.ReservedServerAccessCode = reservedCode
				service._teleportService:TeleportAsync(game.PlaceId, allPlayers, options)
			else
				service._teleportService:TeleportAsync(game.PlaceId, allPlayers)
			end
		end)
		if not ok then
			service:_emitLog(player, "Restart teleport failed: " .. tostring(err))
			return false, tostring(err)
		end
		return true
	end

	__module = Restart

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/ServerControlHelpers/Restart.luau"
	end
	Core.Modules.AdminHelpers.ServerControlHelpers.Restart = __module
end

---@class CoreModulesAdminHelpersServerControlHelpersShutdown
---@field __source string Path sumber module `Modules/AdminHelpers/ServerControlHelpers/Shutdown.luau`.
Core.Modules.AdminHelpers.ServerControlHelpers.Shutdown = Core.Modules.AdminHelpers.ServerControlHelpers.Shutdown or {}
do
	local __module = nil
	local Shutdown = {}

	---Menjalankan fungsi `run`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	function Shutdown.run(service, player)
		if not service:_canUsePanel(player) then
			return false, "NoPermission"
		end
		local message = "Server shutting down."
		service:_emitLog(player, message)
		for _, plr in ipairs(service._players:GetPlayers()) do
			plr:Kick(message)
		end
		if service._runService:IsStudio() then
			return false, "ShutdownNotAvailableInStudio"
		end
		task.delay(0.5, function()
			game:Shutdown()
		end)
		return true
	end

	__module = Shutdown

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/ServerControlHelpers/Shutdown.luau"
	end
	Core.Modules.AdminHelpers.ServerControlHelpers.Shutdown = __module
end

---@class CoreModulesAdminHelpersUtilityHelpersCharacter
---@field __source string Path sumber module `Modules/AdminHelpers/UtilityHelpers/Character.luau`.
---@field getHumanoidRootPart any Member public `getHumanoidRootPart` dari `Modules/AdminHelpers/UtilityHelpers/Character.luau`.
Core.Modules.AdminHelpers.UtilityHelpers.Character = Core.Modules.AdminHelpers.UtilityHelpers.Character or {}
do
	local __module = nil
	local Character = {}

	---Menjalankan fungsi `getHumanoidRootPart`.
	---@param character any Nilai parameter `character`.
	---@return any result Hasil dari fungsi `getHumanoidRootPart`.
	function Character.getHumanoidRootPart(character)
		if not character then return nil end
		return character:FindFirstChild("HumanoidRootPart")
	end

	__module = Character

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/UtilityHelpers/Character.luau"
	end
	Core.Modules.AdminHelpers.UtilityHelpers.Character = __module
end

---@class CoreModulesAdminHelpersUtilityHelpersEffects
---@field __source string Path sumber module `Modules/AdminHelpers/UtilityHelpers/Effects.luau`.
Core.Modules.AdminHelpers.UtilityHelpers.Effects = Core.Modules.AdminHelpers.UtilityHelpers.Effects or {}
do
	local __module = nil
	local Character = Core.Modules.AdminHelpers.UtilityHelpers.Character
	local Players = game:GetService("Players")

	local Effects = {}

	---@private
	---Menjalankan fungsi `applyTransparency`.
	---@param instance any Nilai parameter `instance`.
	---@param enabled any Nilai parameter `enabled`.
	local function applyTransparency(instance, enabled)
		if enabled then
			if instance:GetAttribute("AdminOrigTransparency") == nil then
				instance:SetAttribute("AdminOrigTransparency", instance.Transparency)
			end
			instance.Transparency = 1
			return
		end

		local orig = instance:GetAttribute("AdminOrigTransparency")
		if orig ~= nil then
			instance.Transparency = orig
			instance:SetAttribute("AdminOrigTransparency", nil)
		end
	end

	---@private
	---Menjalankan fungsi `refreshCharacterAppearance`.
	---@param character any Nilai parameter `character`.
	local function refreshCharacterAppearance(character)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end

		task.defer(function()
			local okDesc, description = pcall(function()
				return humanoid:GetAppliedDescription()
			end)
			if okDesc and description then
				pcall(function()
					humanoid:ApplyDescriptionReset(description)
				end)
				return
			end

			local player = Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end

			local okUserDesc, userDescription = pcall(function()
				return Players:GetHumanoidDescriptionFromUserId(player.UserId)
			end)
			if okUserDesc and userDescription then
				pcall(function()
					humanoid:ApplyDescription(userDescription)
				end)
			end
		end)
	end

	---Menjalankan fungsi `applyFreeze`.
	---@param player any Nilai parameter `player`.
	---@param enabled any Nilai parameter `enabled`.
	function Effects.applyFreeze(player, enabled)
		local char = player.Character
		if not char then return end
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		local hrp = Character.getHumanoidRootPart(char)
		if humanoid then
			humanoid.PlatformStand = enabled
		end
		if hrp then
			hrp.Anchored = enabled
		end
		player:SetAttribute("AdminFrozen", enabled)
	end

	---Menjalankan fungsi `applyInvisible`.
	---@param player any Nilai parameter `player`.
	---@param enabled any Nilai parameter `enabled`.
	function Effects.applyInvisible(player, enabled)
		local char = player.Character
		if not char then return end
		for _, desc in ipairs(char:GetDescendants()) do
			if desc:IsA("BasePart") or desc:IsA("Decal") then
				applyTransparency(desc, enabled)
			end
		end
		player:SetAttribute("AdminInvisible", enabled)
		if not enabled then
			refreshCharacterAppearance(char)
		end
	end

	__module = Effects

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/UtilityHelpers/Effects.luau"
	end
	Core.Modules.AdminHelpers.UtilityHelpers.Effects = __module
end

---@class CoreModulesAdminHelpersUtilityHelpersMatch
---@field __source string Path sumber module `Modules/AdminHelpers/UtilityHelpers/Match.luau`.
Core.Modules.AdminHelpers.UtilityHelpers.Match = Core.Modules.AdminHelpers.UtilityHelpers.Match or {}
do
	local __module = nil
	local Match = {}

	---Menjalankan fungsi `matches`.
	---@param listIds any Nilai parameter `listIds`.
	---@param listNames any Nilai parameter `listNames`.
	---@param player any Nilai parameter `player`.
	function Match.matches(listIds, listNames, player)
		for _, id in ipairs(listIds or {}) do
			if id == player.UserId then
				return true
			end
		end
		local uname = string.lower(player.Name)
		for _, name in ipairs(listNames or {}) do
			if uname == string.lower(name) then
				return true
			end
		end
		return false
	end

	---Menjalankan fungsi `isOwnerByGame`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `isOwnerByGame`.
	function Match.isOwnerByGame(player)
		if game.CreatorType == Enum.CreatorType.User then
			return player.UserId == game.CreatorId
		end
		if game.CreatorType == Enum.CreatorType.Group then
			local ok, rank = pcall(function()
				return player:GetRankInGroup(game.CreatorId)
			end)
			return ok and rank == 255
		end
		return false
	end

	---Menjalankan fungsi `resolvePath`.
	---@param path any Nilai parameter `path`.
	function Match.resolvePath(path)
		if typeof(path) ~= "string" or path == "" then
			return nil
		end
		local current = game
		for token in string.gmatch(path, "[^%.]+") do
			current = current:FindFirstChild(token)
			if not current then
				return nil
			end
		end
		return current
	end

	__module = Match

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/UtilityHelpers/Match.luau"
	end
	Core.Modules.AdminHelpers.UtilityHelpers.Match = __module
end

---@class CoreModulesCarryFlowHelpersCharacterCleanup
---@field __source string Path sumber module `Modules/Carry/FlowHelpers/CharacterCleanup.luau`.
---@field bind any Member public `bind` dari `Modules/Carry/FlowHelpers/CharacterCleanup.luau`.
Core.Modules.Carry.FlowHelpers.CharacterCleanup = Core.Modules.Carry.FlowHelpers.CharacterCleanup or {}
do
	local __module = nil
	local CharacterCleanup = {}

	---Menjalankan fungsi `bind`.
	---@param flow any Nilai parameter `flow`.
	---@param character any Nilai parameter `character`.
	---@param player any Nilai parameter `player`.
	function CharacterCleanup.bind(flow, character, player)
		local hum = character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Died:Connect(function()
				flow:safeDetachIfAny(player, "death")
			end)
		end

		character.AncestryChanged:Connect(function(_, parent)
			if not parent then
				flow:safeDetachIfAny(player, "character removed")
			end
		end)
	end

	__module = CharacterCleanup

	if type(__module) == "table" then
		__module.__source = "Modules/Carry/FlowHelpers/CharacterCleanup.luau"
	end
	Core.Modules.Carry.FlowHelpers.CharacterCleanup = __module
end

---@class CoreModulesCarryFlowHelpersHumanoidState
---@field __source string Path sumber module `Modules/Carry/FlowHelpers/HumanoidState.luau`.
Core.Modules.Carry.FlowHelpers.HumanoidState = Core.Modules.Carry.FlowHelpers.HumanoidState or {}
do
	local __module = nil
	local HumanoidState = {}

	---Menjalankan fungsi `applyCarried`.
	---@param flow any Nilai parameter `flow`.
	---@param hum any Nilai parameter `hum`.
	---@param uid any Nilai parameter `uid`.
	function HumanoidState.applyCarried(flow, hum, uid)
		if not hum then
			return
		end

		if uid then
			flow:_saveHumState(uid, hum)
		end

		hum.AutoRotate = false
		hum.WalkSpeed = 0
		if hum.UseJumpPower then
			hum.JumpPower = 0
		else
			hum.JumpHeight = 0
		end
		hum.Sit = true
		hum.PlatformStand = true
		hum.Jump = false

		pcall(function()
			hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Running, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
		end)
	end

	---Menjalankan fungsi `restore`.
	---@param flow any Nilai parameter `flow`.
	---@param hum any Nilai parameter `hum`.
	---@param uid any Nilai parameter `uid`.
	function HumanoidState.restore(flow, hum, uid)
		if not hum then
			return
		end

		hum.PlatformStand = false
		hum.Sit = false
		hum.Jump = false
		flow:_restoreHumState(uid, hum)

		pcall(function()
			hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
			hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
		end)
	end

	__module = HumanoidState

	if type(__module) == "table" then
		__module.__source = "Modules/Carry/FlowHelpers/HumanoidState.luau"
	end
	Core.Modules.Carry.FlowHelpers.HumanoidState = __module
end

---@class CoreModulesCarryFlowHelpersSlotPlanner
---@field __source string Path sumber module `Modules/Carry/FlowHelpers/SlotPlanner.luau`.
Core.Modules.Carry.FlowHelpers.SlotPlanner = Core.Modules.Carry.FlowHelpers.SlotPlanner or {}
do
	local __module = nil
	local SlotPlanner = {}

	---Menjalankan fungsi `collectOrderedTargets`.
	---@param flow any Nilai parameter `flow`.
	---@param carrier any Nilai parameter `carrier`.
	function SlotPlanner.collectOrderedTargets(flow, carrier)
		local slotMap = flow.state.slotByCarrier[carrier.UserId]
		if not slotMap then
			return nil
		end

		local temp = {}
		for targetUserId, slotIndex in pairs(slotMap) do
			local target = flow.Players:GetPlayerByUserId(targetUserId)
			if target then
				table.insert(temp, {
					player = target,
					slot = slotIndex,
				})
			end
		end

		table.sort(temp, function(a, b)
			return a.slot < b.slot
		end)

		return temp
	end

	---Menjalankan fungsi `findNextOpenSlot`.
	---@param flow any Nilai parameter `flow`.
	---@param carrier any Nilai parameter `carrier`.
	function SlotPlanner.findNextOpenSlot(flow, carrier)
		local used = {}
		local slotMap = flow:_getSlotMap(carrier)
		for _, index in pairs(slotMap) do
			used[index] = true
		end

		for index = 1, flow.config.MAX_CARRY do
			if not used[index] then
				return index
			end
		end

		return nil
	end

	__module = SlotPlanner

	if type(__module) == "table" then
		__module.__source = "Modules/Carry/FlowHelpers/SlotPlanner.luau"
	end
	Core.Modules.Carry.FlowHelpers.SlotPlanner = __module
end

---@class CoreModulesCheckpointAdminSummitCommandHandler
---@field __source string Path sumber module `Modules/Checkpoint/Admin/SummitCommandHandler.luau`.
Core.Modules.Checkpoint.Admin.SummitCommandHandler = Core.Modules.Checkpoint.Admin.SummitCommandHandler or {}
do
	local __module = nil
	local Players = game:GetService("Players")

	local SummitCommandHandler = {}

	---@private
	---Menjalankan fungsi `isOwner`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `isOwner`.
	local function isOwner(player)
		if game.CreatorType == Enum.CreatorType.User then
			return player.UserId == game.CreatorId
		end
		if game.CreatorType == Enum.CreatorType.Group then
			local ok, rank = pcall(function()
				return player:GetRankInGroup(game.CreatorId)
			end)
			return ok and rank == 255
		end
		return false
	end

	---@private
	---Menjalankan fungsi `findPlayerByNameOrDisplay`.
	---@param name any Nilai parameter `name`.
	local function findPlayerByNameOrDisplay(name)
		if not name then return nil end
		local lowered = name:lower()
		local best = nil
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Name:lower() == lowered or p.DisplayName:lower() == lowered then
				return p
			end
			if not best then
				if p.Name:lower():sub(1, #lowered) == lowered or p.DisplayName:lower():sub(1, #lowered) == lowered then
					best = p
				end
			end
		end
		return best
	end

	---@private
	---Menjalankan fungsi `resolveTarget`.
	---@param sender any Nilai parameter `sender`.
	---@param token any Nilai parameter `token`.
	local function resolveTarget(sender, token)
		if not token or token:lower() == "me" then
			return sender, nil
		end
		local online = findPlayerByNameOrDisplay(token)
		if online then
			return online, nil
		end
		local userId
		local ok = pcall(function()
			userId = Players:GetUserIdFromNameAsync(token)
		end)
		if ok and userId then
			return nil, userId
		end
		return nil, nil
	end

	---Menjalankan fungsi `handle`.
	---@param service any Nilai parameter `service`.
	---@param sender any Nilai parameter `sender`.
	---@param cmd any Nilai parameter `cmd`.
	function SummitCommandHandler.handle(service, sender, cmd)
		if not cmd or not sender then return end
		if not isOwner(sender) then
			return
		end

		local targetPlayer, targetUserId = resolveTarget(sender, cmd.target)
		if not targetPlayer and not targetUserId then return end

		if cmd.action == "reset" then
			if targetPlayer then
				service:_resetSummit(targetPlayer)
			else
				service:_resetSummitByUserId(targetUserId)
			end
			return
		end
		if cmd.action == "add" then
			local amount = tonumber(cmd.amount)
			if not amount then return end
			if targetPlayer then
				service:_addSummit(targetPlayer, amount)
			else
				service:_addSummitByUserId(targetUserId, amount)
			end
			return
		end
		if cmd.action == "set" then
			local amount = tonumber(cmd.amount)
			if not amount then return end
			if targetPlayer then
				service:_setSummit(targetPlayer, amount)
			else
				service:_setSummitByUserId(targetUserId, amount)
			end
			return
		end
	end

	__module = SummitCommandHandler

	if type(__module) == "table" then
		__module.__source = "Modules/Checkpoint/Admin/SummitCommandHandler.luau"
	end
	Core.Modules.Checkpoint.Admin.SummitCommandHandler = __module
end

---@class CoreModulesCheckpointAdminSummitCommandParser
---@field __source string Path sumber module `Modules/Checkpoint/Admin/SummitCommandParser.luau`.
Core.Modules.Checkpoint.Admin.SummitCommandParser = Core.Modules.Checkpoint.Admin.SummitCommandParser or {}
do
	local __module = nil
	local SummitCommandParser = {}

	---@private
	---Menjalankan fungsi `trim`.
	---@param s any Nilai parameter `s`.
	local function trim(s)
		return (s:gsub("^%s+", ""):gsub("%s+$", ""))
	end

	---Menjalankan fungsi `parse`.
	---@param message any Nilai parameter `message`.
	function SummitCommandParser.parse(message)
		if typeof(message) ~= "string" then
			return nil
		end
		local text = trim(message)
		if text == "" then
			return nil
		end
		if text:sub(1, 1) == "!" or text:sub(1, 1) == "/" then
			text = text:sub(2)
		end
		local parts = {}
		for token in text:gmatch("%S+") do
			table.insert(parts, token)
		end
		if #parts < 1 then
			return nil
		end

		local head = parts[1]:lower()
		local action
		local startIndex = 2

		if head == "summit" then
			if #parts < 2 then
				return nil
			end
			action = parts[2]:lower()
			startIndex = 3
		elseif head == "summitadd" then
			action = "add"
			startIndex = 2
		elseif head == "summitset" then
			action = "set"
			startIndex = 2
		elseif head == "summitreset" then
			action = "reset"
			startIndex = 2
		else
			return nil
		end

		if action ~= "reset" and action ~= "add" and action ~= "set" then
			return nil
		end
		local amount = nil
		local target = nil
		if action == "add" or action == "set" then
			amount = tonumber(parts[startIndex])
			target = parts[startIndex + 1]
		else
			target = parts[startIndex]
		end
		return {
			action = action,
			amount = amount,
			target = target,
		}
	end

	__module = SummitCommandParser

	if type(__module) == "table" then
		__module.__source = "Modules/Checkpoint/Admin/SummitCommandParser.luau"
	end
	Core.Modules.Checkpoint.Admin.SummitCommandParser = __module
end

---@class CoreModulesCheckpointAdminSummitCommandBinder
---@field __source string Path sumber module `Modules/Checkpoint/Admin/SummitCommandBinder.luau`.
Core.Modules.Checkpoint.Admin.SummitCommandBinder = Core.Modules.Checkpoint.Admin.SummitCommandBinder or {}
do
	local __module = nil
	local Players = game:GetService("Players")
	local TextChatService = game:FindService("TextChatService")

	local SummitCommandParser = Core.Modules.Checkpoint.Admin.SummitCommandParser
	local SummitCommandHandler = Core.Modules.Checkpoint.Admin.SummitCommandHandler

	local SummitCommandBinder = {}

	---@private
	---Menjalankan fungsi `bindPlayer`.
	---@param service any Nilai parameter `service`.
	---@param janitor any Nilai parameter `janitor`.
	---@param player any Nilai parameter `player`.
	local function bindPlayer(service, janitor, player)
		janitor:Add(player.Chatted:Connect(function(message)
			local cmd = SummitCommandParser.parse(message)
			if cmd then
				SummitCommandHandler.handle(service, player, cmd)
			end
		end), "Disconnect")
	end

	---Menjalankan fungsi `bind`.
	---@param service any Nilai parameter `service`.
	---@param janitor any Nilai parameter `janitor`.
	function SummitCommandBinder.bind(service, janitor)
		local j = janitor or {
			Add = function(_, c)
				return c
			end,
		}
		---@private
		---Menjalankan fungsi `bindTextChatCommands`.
		---@param commandParent any Nilai parameter `commandParent`.
		local function bindTextChatCommands(commandParent)
			if not commandParent then return end
			---@private
			---Menjalankan fungsi `ensureCommand`.
			---@param name any Nilai parameter `name`.
			---@param primary any Nilai parameter `primary`.
			---@param secondary any Nilai parameter `secondary`.
			---@param description any Nilai parameter `description`.
			local function ensureCommand(name, primary, secondary, description)
				local cmd = commandParent:FindFirstChild(name)
				if not cmd then
					cmd = Instance.new("TextChatCommand")
					cmd.Name = name
					cmd.PrimaryAlias = primary
					cmd.Enabled = true
					if secondary then
						pcall(function()
							cmd.SecondaryAlias = {secondary}
						end)
					end
					pcall(function()
						cmd.Description = description
					end)
					cmd.Parent = commandParent
				elseif cmd.Parent ~= commandParent then
					cmd.Parent = commandParent
				end
				return cmd
			end

			local addCmd = ensureCommand("SummitAddCommand", "/summitadd", "summitadd", "Add summit: /summitadd <amount> [player]")
			local setCmd = ensureCommand("SummitSetCommand", "/summitset", "summitset", "Set summit: /summitset <amount> [player]")
			local resetCmd = ensureCommand("SummitResetCommand", "/summitreset", "summitreset", "Reset summit: /summitreset [player]")

			j:Add(addCmd.Triggered:Connect(function(textSource, message)
				local player = textSource and Players:GetPlayerByUserId(textSource.UserId)
				if not player then
					return
				end
				local raw = typeof(message) == "string" and message or ""
				local parts = {}
				for token in raw:gmatch("%S+") do
					table.insert(parts, token)
				end
				local amount = tonumber(parts[1])
				local target = parts[2]
				SummitCommandHandler.handle(service, player, {
					action = "add",
					amount = amount,
					target = target,
				})
			end), "Disconnect")

			j:Add(setCmd.Triggered:Connect(function(textSource, message)
				local player = textSource and Players:GetPlayerByUserId(textSource.UserId)
				if not player then
					return
				end
				local raw = typeof(message) == "string" and message or ""
				local parts = {}
				for token in raw:gmatch("%S+") do
					table.insert(parts, token)
				end
				local amount = tonumber(parts[1])
				local target = parts[2]
				SummitCommandHandler.handle(service, player, {
					action = "set",
					amount = amount,
					target = target,
				})
			end), "Disconnect")

			j:Add(resetCmd.Triggered:Connect(function(textSource, message)
				local player = textSource and Players:GetPlayerByUserId(textSource.UserId)
				if not player then
					return
				end
				local raw = typeof(message) == "string" and message or ""
				local target = raw ~= "" and raw or nil
				SummitCommandHandler.handle(service, player, {
					action = "reset",
					target = target,
				})
			end), "Disconnect")
		end

		if TextChatService then
			local existing = TextChatService:FindFirstChild("TextChatCommands")
			if existing then
				bindTextChatCommands(existing)
			else
				j:Add(TextChatService.ChildAdded:Connect(function(child)
					if child.Name == "TextChatCommands" then
						bindTextChatCommands(child)
					end
				end), "Disconnect")
			end
		end
		j:Add(Players.PlayerAdded:Connect(function(player)
			bindPlayer(service, j, player)
		end), "Disconnect")
		for _, player in ipairs(Players:GetPlayers()) do
			bindPlayer(service, j, player)
		end
	end

	__module = SummitCommandBinder

	if type(__module) == "table" then
		__module.__source = "Modules/Checkpoint/Admin/SummitCommandBinder.luau"
	end
	Core.Modules.Checkpoint.Admin.SummitCommandBinder = __module
end

---@class CoreModulesDonationsPodiumHelpersPodiumBuilder
---@field __source string Path sumber module `Modules/Donations/PodiumHelpers/PodiumBuilder.luau`.
Core.Modules.Donations.PodiumHelpers.PodiumBuilder = Core.Modules.Donations.PodiumHelpers.PodiumBuilder or {}
do
	local __module = nil
	local PodiumBuilder = {}

	---Menjalankan fungsi `find`.
	---@param parent any Nilai parameter `parent`.
	---@param name any Nilai parameter `name`.
	---@param timeout any Nilai parameter `timeout`.
	function PodiumBuilder.find(parent, name, timeout)
		if not parent then
			return nil
		end
		local ok, obj = pcall(function()
			return parent:WaitForChild(name, timeout or 60)
		end)
		return ok and obj or nil
	end

	---Menjalankan fungsi `captureModelState`.
	---@param model any Nilai parameter `model`.
	function PodiumBuilder.captureModelState(model)
		local state = {}
		for _, desc in ipairs(model:GetDescendants()) do
			if desc:IsA("BasePart") then
				state[desc] = {
					Transparency = desc.Transparency,
					CanCollide = desc.CanCollide,
					CanTouch = desc.CanTouch,
					CanQuery = desc.CanQuery,
				}
			end
		end
		return state
	end

	---Menjalankan fungsi `getPivotOf`.
	---@param instance any Nilai parameter `instance`.
	---@return any result Hasil dari fungsi `getPivotOf`.
	function PodiumBuilder.getPivotOf(instance)
		if not instance then
			return nil
		end
		local humanoid = instance:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local rootPart = humanoid.RootPart or instance:FindFirstChild("HumanoidRootPart")
			if rootPart and rootPart:IsA("BasePart") then
				return rootPart.CFrame
			end
		end
		if instance:IsA("Model") then
			return instance:GetPivot()
		end
		if instance:IsA("BasePart") then
			return instance.CFrame
		end
		return nil
	end

	---Menjalankan fungsi `getRootCFrameOf`.
	---@param instance any Nilai parameter `instance`.
	---@return any result Hasil dari fungsi `getRootCFrameOf`.
	function PodiumBuilder.getRootCFrameOf(instance)
		if not instance then
			return nil
		end
		local humanoid = instance:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local rootPart = humanoid.RootPart or instance:FindFirstChild("HumanoidRootPart")
			if rootPart and rootPart:IsA("BasePart") then
				return rootPart.CFrame
			end
		end
		return nil
	end

	---Menjalankan fungsi `getBottomYOf`.
	---@param instance any Nilai parameter `instance`.
	---@return any result Hasil dari fungsi `getBottomYOf`.
	function PodiumBuilder.getBottomYOf(instance)
		if not instance then
			return nil
		end
		if instance:IsA("Model") then
			local cf, size = instance:GetBoundingBox()
			return cf.Position.Y - (size.Y * 0.5)
		end
		if instance:IsA("BasePart") then
			return instance.Position.Y - (instance.Size.Y * 0.5)
		end
		return nil
	end

	---Menjalankan fungsi `findFrameFromTags`.
	---@param tags any Nilai parameter `tags`.
	function PodiumBuilder.findFrameFromTags(tags)
		if not tags then
			return nil
		end
		if tags:IsA("BillboardGui") then
			return tags:FindFirstChild("Frame")
		end
		return tags:FindFirstChild("Frame", true)
	end

	---Menjalankan fungsi `cloneTagsGui`.
	---@param tagsTemplate any Nilai parameter `tagsTemplate`.
	function PodiumBuilder.cloneTagsGui(tagsTemplate)
		if not tagsTemplate then
			return nil
		end
		local tagsClone = tagsTemplate:Clone()
		if tagsClone:IsA("BillboardGui") then
			return tagsClone
		end
		return tagsClone:FindFirstChildWhichIsA("BillboardGui", true)
	end

	---Menjalankan fungsi `resolveSlotObjects`.
	---@param podiumRoot any Nilai parameter `podiumRoot`.
	---@param index any Nilai parameter `index`.
	function PodiumBuilder.resolveSlotObjects(podiumRoot, index)
		local slotRoot = PodiumBuilder.find(podiumRoot, "Podium" .. tostring(index), 10)
		if slotRoot then
			local rig = PodiumBuilder.find(slotRoot, "rig", 10)
			local config = PodiumBuilder.find(slotRoot, "Config", 10)
			local grid = PodiumBuilder.find(slotRoot, "Grid", 10)
			local tags = PodiumBuilder.find(slotRoot, "Tags", 10)
			return slotRoot, rig, config, grid, tags
		end

		local statue = PodiumBuilder.find(podiumRoot, "Statue" .. tostring(index), 10)
		local tags = statue and PodiumBuilder.find(statue, "Tags", 10)
		return statue, statue, nil, nil, tags
	end

	---Menjalankan fungsi `getRankColor`.
	---@param config any Nilai parameter `config`.
	---@param rank any Nilai parameter `rank`.
	---@return any result Hasil dari fungsi `getRankColor`.
	function PodiumBuilder.getRankColor(config, rank)
		if rank == 1 then
			return config.RankColor1
		end
		if rank == 2 then
			return config.RankColor2
		end
		if rank == 3 then
			return config.RankColor3
		end
		return nil
	end

	---Menjalankan fungsi `getAnimId`.
	---@param config any Nilai parameter `config`.
	---@param rank any Nilai parameter `rank`.
	---@param rigType any Nilai parameter `rigType`.
	---@return any result Hasil dari fungsi `getAnimId`.
	function PodiumBuilder.getAnimId(config, rank, rigType)
		local animCfg = config.Animations and config.Animations[rank]
		if not animCfg then
			return nil
		end
		if rigType == Enum.HumanoidRigType.R15 then
			return animCfg.R15
		end
		return animCfg.R6
	end

	__module = PodiumBuilder

	if type(__module) == "table" then
		__module.__source = "Modules/Donations/PodiumHelpers/PodiumBuilder.luau"
	end
	Core.Modules.Donations.PodiumHelpers.PodiumBuilder = __module
end

---@class CoreModulesDonationsPodiumHelpersRigBuilder
---@field __source string Path sumber module `Modules/Donations/PodiumHelpers/RigBuilder.luau`.
Core.Modules.Donations.PodiumHelpers.RigBuilder = Core.Modules.Donations.PodiumHelpers.RigBuilder or {}
do
	local __module = nil
	local Players = game:GetService("Players")

	local RigBuilder = {}

	---Menjalankan fungsi `createForUser`.
	---@param userId any Nilai parameter `userId`.
	---@return any result Hasil dari fungsi `createForUser`.
	function RigBuilder.createForUser(userId)
		local ok, rig = pcall(function()
			return Players:CreateHumanoidModelFromUserId(userId)
		end)
		if ok and rig then
			return rig
		end

		local okDescription, description = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(userId)
		end)
		if okDescription and description then
			local okR15, r15Rig = pcall(function()
				return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
			end)
			if okR15 and r15Rig then
				return r15Rig
			end

			local okR6, r6Rig = pcall(function()
				return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R6)
			end)
			if okR6 and r6Rig then
				return r6Rig
			end
		end

		return nil
	end

	__module = RigBuilder

	if type(__module) == "table" then
		__module.__source = "Modules/Donations/PodiumHelpers/RigBuilder.luau"
	end
	Core.Modules.Donations.PodiumHelpers.RigBuilder = __module
end

---@class CoreModulesSpeedrunAdminSpeedrunCommandHandler
---@field __source string Path sumber module `Modules/Speedrun/Admin/SpeedrunCommandHandler.luau`.
Core.Modules.Speedrun.Admin.SpeedrunCommandHandler = Core.Modules.Speedrun.Admin.SpeedrunCommandHandler or {}
do
	local __module = nil
	local Players = game:GetService("Players")

	local SpeedrunCommandHandler = {}

	---@private
	---Menjalankan fungsi `isOwner`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `isOwner`.
	local function isOwner(player)
		if game.CreatorType == Enum.CreatorType.User then
			return player.UserId == game.CreatorId
		end
		if game.CreatorType == Enum.CreatorType.Group then
			local ok, rank = pcall(function()
				return player:GetRankInGroup(game.CreatorId)
			end)
			return ok and rank == 255
		end
		return false
	end

	---@private
	---Menjalankan fungsi `findPlayerByNameOrDisplay`.
	---@param name any Nilai parameter `name`.
	local function findPlayerByNameOrDisplay(name)
		if not name then return nil end
		local lowered = name:lower()
		local best = nil
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Name:lower() == lowered or p.DisplayName:lower() == lowered then
				return p
			end
			if not best then
				if p.Name:lower():sub(1, #lowered) == lowered or p.DisplayName:lower():sub(1, #lowered) == lowered then
					best = p
				end
			end
		end
		return best
	end

	---@private
	---Menjalankan fungsi `resolveTarget`.
	---@param sender any Nilai parameter `sender`.
	---@param token any Nilai parameter `token`.
	local function resolveTarget(sender, token)
		if not token or token:lower() == "me" then
			return sender, nil
		end
		local online = findPlayerByNameOrDisplay(token)
		if online then
			return online, nil
		end
		local userId
		local ok = pcall(function()
			userId = Players:GetUserIdFromNameAsync(token)
		end)
		if ok and userId then
			return nil, userId
		end
		return nil, nil
	end

	---Menjalankan fungsi `handle`.
	---@param service any Nilai parameter `service`.
	---@param sender any Nilai parameter `sender`.
	---@param cmd any Nilai parameter `cmd`.
	function SpeedrunCommandHandler.handle(service, sender, cmd)
		if not cmd or not sender then return end
		if not isOwner(sender) then
			return
		end

		if cmd.action == "resetall" then
			service:_resetAllBestTimes()
			return
		end

		if cmd.action == "reset" then
			local targetPlayer, targetUserId = resolveTarget(sender, cmd.target)
			if not targetPlayer and not targetUserId then return end
			if targetPlayer then
				service:_resetBestTime(targetPlayer)
			else
				service:_resetBestTimeByUserId(targetUserId)
			end
			return
		end
	end

	__module = SpeedrunCommandHandler

	if type(__module) == "table" then
		__module.__source = "Modules/Speedrun/Admin/SpeedrunCommandHandler.luau"
	end
	Core.Modules.Speedrun.Admin.SpeedrunCommandHandler = __module
end

---@class CoreModulesSpeedrunAdminSpeedrunCommandParser
---@field __source string Path sumber module `Modules/Speedrun/Admin/SpeedrunCommandParser.luau`.
Core.Modules.Speedrun.Admin.SpeedrunCommandParser = Core.Modules.Speedrun.Admin.SpeedrunCommandParser or {}
do
	local __module = nil
	local SpeedrunCommandParser = {}

	---@private
	---Menjalankan fungsi `trim`.
	---@param s any Nilai parameter `s`.
	local function trim(s)
		return (s:gsub("^%s+", ""):gsub("%s+$", ""))
	end

	---Menjalankan fungsi `parse`.
	---@param message any Nilai parameter `message`.
	function SpeedrunCommandParser.parse(message)
		if typeof(message) ~= "string" then
			return nil
		end
		local text = trim(message)
		if text == "" then
			return nil
		end
		if text:sub(1, 1) == "!" or text:sub(1, 1) == "/" then
			text = text:sub(2)
		end
		local parts = {}
		for token in text:gmatch("%S+") do
			table.insert(parts, token)
		end
		if #parts < 1 then
			return nil
		end

		local head = parts[1]:lower()
		if head == "timeresetall" then
			return {action = "resetall"}
		end
		if head == "timereset" then
			return {action = "reset", target = parts[2]}
		end
		return nil
	end

	__module = SpeedrunCommandParser

	if type(__module) == "table" then
		__module.__source = "Modules/Speedrun/Admin/SpeedrunCommandParser.luau"
	end
	Core.Modules.Speedrun.Admin.SpeedrunCommandParser = __module
end

---@class CoreModulesSpeedrunAdminSpeedrunCommandBinder
---@field __source string Path sumber module `Modules/Speedrun/Admin/SpeedrunCommandBinder.luau`.
Core.Modules.Speedrun.Admin.SpeedrunCommandBinder = Core.Modules.Speedrun.Admin.SpeedrunCommandBinder or {}
do
	local __module = nil
	local Players = game:GetService("Players")
	local TextChatService = game:FindService("TextChatService")

	local SpeedrunCommandParser = Core.Modules.Speedrun.Admin.SpeedrunCommandParser
	local SpeedrunCommandHandler = Core.Modules.Speedrun.Admin.SpeedrunCommandHandler

	local SpeedrunCommandBinder = {}

	---@private
	---Menjalankan fungsi `bindPlayer`.
	---@param service any Nilai parameter `service`.
	---@param janitor any Nilai parameter `janitor`.
	---@param player any Nilai parameter `player`.
	local function bindPlayer(service, janitor, player)
		janitor:Add(player.Chatted:Connect(function(message)
			local cmd = SpeedrunCommandParser.parse(message)
			if cmd then
				SpeedrunCommandHandler.handle(service, player, cmd)
			end
		end), "Disconnect")
	end

	---Menjalankan fungsi `bind`.
	---@param service any Nilai parameter `service`.
	---@param janitor any Nilai parameter `janitor`.
	function SpeedrunCommandBinder.bind(service, janitor)
		local j = janitor or {
			Add = function(_, c)
				return c
			end,
		}
		---@private
		---Menjalankan fungsi `bindTextChatCommands`.
		---@param commandParent any Nilai parameter `commandParent`.
		local function bindTextChatCommands(commandParent)
			if not commandParent then return end
			---@private
			---Menjalankan fungsi `ensureCommand`.
			---@param name any Nilai parameter `name`.
			---@param primary any Nilai parameter `primary`.
			---@param secondary any Nilai parameter `secondary`.
			---@param description any Nilai parameter `description`.
			local function ensureCommand(name, primary, secondary, description)
				local cmd = commandParent:FindFirstChild(name)
				if not cmd then
					cmd = Instance.new("TextChatCommand")
					cmd.Name = name
					cmd.PrimaryAlias = primary
					cmd.Enabled = true
					if secondary then
						pcall(function()
							cmd.SecondaryAlias = {secondary}
						end)
					end
					pcall(function()
						cmd.Description = description
					end)
					cmd.Parent = commandParent
				elseif cmd.Parent ~= commandParent then
					cmd.Parent = commandParent
				end
				return cmd
			end

			local resetCmd = ensureCommand("SpeedrunResetCommand", "/timereset", "timereset", "Reset best time: /timereset [player]")
			local resetAllCmd = ensureCommand("SpeedrunResetAllCommand", "/timeresetall", "timeresetall", "Reset all best times")

			j:Add(resetCmd.Triggered:Connect(function(textSource, message)
				local player = textSource and Players:GetPlayerByUserId(textSource.UserId)
				if not player then
					return
				end
				local raw = typeof(message) == "string" and message or ""
				local target = raw ~= "" and raw or nil
				SpeedrunCommandHandler.handle(service, player, {
					action = "reset",
					target = target,
				})
			end), "Disconnect")

			j:Add(resetAllCmd.Triggered:Connect(function(textSource)
				local player = textSource and Players:GetPlayerByUserId(textSource.UserId)
				if not player then
					return
				end
				SpeedrunCommandHandler.handle(service, player, {
					action = "resetall",
				})
			end), "Disconnect")
		end

		if TextChatService then
			local existing = TextChatService:FindFirstChild("TextChatCommands")
			if existing then
				bindTextChatCommands(existing)
			else
				j:Add(TextChatService.ChildAdded:Connect(function(child)
					if child.Name == "TextChatCommands" then
						bindTextChatCommands(child)
					end
				end), "Disconnect")
			end
		end
		j:Add(Players.PlayerAdded:Connect(function(player)
			bindPlayer(service, j, player)
		end), "Disconnect")
		for _, player in ipairs(Players:GetPlayers()) do
			bindPlayer(service, j, player)
		end
	end

	__module = SpeedrunCommandBinder

	if type(__module) == "table" then
		__module.__source = "Modules/Speedrun/Admin/SpeedrunCommandBinder.luau"
	end
	Core.Modules.Speedrun.Admin.SpeedrunCommandBinder = __module
end

---@class CoreModulesTeleportUtilTargetFinder
---@field __source string Path sumber module `Modules/Teleport/Util/TargetFinder.luau`.
Core.Modules.Teleport.Util.TargetFinder = Core.Modules.Teleport.Util.TargetFinder or {}
do
	local __module = nil
	local TargetFinder = {}

	---@private
	---Menjalankan fungsi `findInFolder`.
	---@param folder any Nilai parameter `folder`.
	---@param index any Nilai parameter `index`.
	---@param pattern any Nilai parameter `pattern`.
	local function findInFolder(folder, index, pattern)
		if not folder then
			return nil
		end

		for _, inst in ipairs(folder:GetChildren()) do
			if inst:IsA("BasePart") then
				local num = tonumber(string.match(inst.Name, pattern) or string.match(inst.Name, "(%d+)$"))
				if num == index then
					return inst
				end
			end
		end
		return nil
	end

	---@private
	---Menjalankan fungsi `getJaleMaps`.
	---@return any result Hasil dari fungsi `getJaleMaps`.
	local function getJaleMaps()
		return workspace:FindFirstChild("JaleMaps")
	end

	---Menjalankan fungsi `findTeleporterParts`.
	function TargetFinder.findTeleporterParts()
		local jaleMaps = getJaleMaps()
		if not jaleMaps then
			return {}
		end

		local folder = jaleMaps:FindFirstChild("Teleports")
		if not folder then
			return {}
		end

		local parts = {}
		for _, inst in ipairs(folder:GetChildren()) do
			if inst:IsA("BasePart") and string.lower(inst.Name) == "teleport" then
				table.insert(parts, inst)
			end
		end
		return parts
	end

	---Menjalankan fungsi `findTeleportSpawnPart`.
	---@param index any Nilai parameter `index`.
	function TargetFinder.findTeleportSpawnPart(index)
		local jaleMaps = getJaleMaps()
		local candidates = {}
		if jaleMaps then
			local jmSpawns = jaleMaps:FindFirstChild("Spawns")
			if jmSpawns then
				table.insert(candidates, jmSpawns)
			end
		end
		local rootSpawns = workspace:FindFirstChild("Spawns")
		if rootSpawns then
			table.insert(candidates, rootSpawns)
		end

		for _, spawns in ipairs(candidates) do
			local found = findInFolder(spawns, index, "TP(%d+)")
			if found then
				return found
			end
		end

		return nil
	end

	---Menjalankan fungsi `findCheckpointPart`.
	---@param index any Nilai parameter `index`.
	function TargetFinder.findCheckpointPart(index)
		local jaleMaps = getJaleMaps()
		local checkpointCandidates = {}
		if jaleMaps then
			local jmCheckpoints = jaleMaps:FindFirstChild("Checkpoints")
			if jmCheckpoints then
				table.insert(checkpointCandidates, jmCheckpoints)
			end
		end
		local rootCheckpoints = workspace:FindFirstChild("Checkpoints")
		if rootCheckpoints then
			table.insert(checkpointCandidates, rootCheckpoints)
		end

		for _, checkpoints in ipairs(checkpointCandidates) do
			local found = findInFolder(checkpoints, index, "CP(%d+)")
			if found then
				return found
			end
		end

		return nil
	end

	---Menjalankan fungsi `findSpawnPart`.
	---@param index any Nilai parameter `index`.
	function TargetFinder.findSpawnPart(index)
		return TargetFinder.findCheckpointPart(index)
	end

	---Menjalankan fungsi `parseIndexFromName`.
	---@param name any Nilai parameter `name`.
	function TargetFinder.parseIndexFromName(name)
		return tonumber(string.match(name, "CP(%d+)") or string.match(name, "TP(%d+)") or string.match(name, "(%d+)$"))
	end

	__module = TargetFinder

	if type(__module) == "table" then
		__module.__source = "Modules/Teleport/Util/TargetFinder.luau"
	end
	Core.Modules.Teleport.Util.TargetFinder = __module
end

---@class CoreModulesTeleportUtilTeleportUtil
---@field __source string Path sumber module `Modules/Teleport/Util/TeleportUtil.luau`.
Core.Modules.Teleport.Util.TeleportUtil = Core.Modules.Teleport.Util.TeleportUtil or {}
do
	local __module = nil
	local TeleportUtil = {}

	---Menjalankan fungsi `teleport`.
	---@param character any Nilai parameter `character`.
	---@param targetPart any Nilai parameter `targetPart`.
	function TeleportUtil.teleport(character, targetPart)
		if not character or not targetPart then
			return
		end
		local hrp = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
		if not hrp then
			return
		end
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		character:PivotTo(targetPart.CFrame + Vector3.new(0, 3, 0))
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Sit = false
		end
	end

	__module = TeleportUtil

	if type(__module) == "table" then
		__module.__source = "Modules/Teleport/Util/TeleportUtil.luau"
	end
	Core.Modules.Teleport.Util.TeleportUtil = __module
end

---@class CoreModulesAdminHelpersActions
---@field __source string Path sumber module `Modules/AdminHelpers/Actions.luau`.
---@field assignRole any Member public `assignRole` dari `Modules/AdminHelpers/Actions.luau`.
---@field giveTool any Member public `giveTool` dari `Modules/AdminHelpers/Actions.luau`.
---@field manage any Member public `manage` dari `Modules/AdminHelpers/Actions.luau`.
---@field playerAction any Member public `playerAction` dari `Modules/AdminHelpers/Actions.luau`.
---@field removeRole any Member public `removeRole` dari `Modules/AdminHelpers/Actions.luau`.
---@field teleport any Member public `teleport` dari `Modules/AdminHelpers/Actions.luau`.
Core.Modules.AdminHelpers.Actions = Core.Modules.AdminHelpers.Actions or {}
do
	local __module = nil
	local Manage = Core.Modules.AdminHelpers.ActionHelpers.Manage
	local PlayerActions = Core.Modules.AdminHelpers.ActionHelpers.PlayerActions
	local Roles = Core.Modules.AdminHelpers.ActionHelpers.Roles
	local Teleport = Core.Modules.AdminHelpers.ActionHelpers.Teleport
	local Tools = Core.Modules.AdminHelpers.ActionHelpers.Tools

	local Actions = {}

	---Menjalankan fungsi `manage`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param action any Nilai parameter `action`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	---@param amount any Nilai parameter `amount`.
	function Actions.manage(service, player, action, targetUserId, amount)
		return Manage.run(service, player, action, targetUserId, amount)
	end

	---Menjalankan fungsi `playerAction`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param action any Nilai parameter `action`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	function Actions.playerAction(service, player, action, targetUserId)
		return PlayerActions.run(service, player, action, targetUserId)
	end

	---Menjalankan fungsi `assignRole`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	---@param role any Nilai parameter `role`.
	function Actions.assignRole(service, player, targetUserId, role)
		return Roles.assign(service, player, targetUserId, role)
	end

	---Menjalankan fungsi `removeRole`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	function Actions.removeRole(service, player, targetUserId)
		return Roles.remove(service, player, targetUserId)
	end

	---Menjalankan fungsi `teleport`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param destinationName any Nilai parameter `destinationName`.
	function Actions.teleport(service, player, destinationName)
		return Teleport.run(service, player, destinationName)
	end

	---Menjalankan fungsi `giveTool`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param toolName any Nilai parameter `toolName`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	function Actions.giveTool(service, player, toolName, targetUserId)
		return Tools.run(service, player, toolName, targetUserId)
	end

	__module = Actions

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/Actions.luau"
	end
	Core.Modules.AdminHelpers.Actions = __module
end

---@class CoreModulesAdminHelpersBinds
---@field __source string Path sumber module `Modules/AdminHelpers/Binds.luau`.
---@field bindMessaging any Member public `bindMessaging` dari `Modules/AdminHelpers/Binds.luau`.
---@field bindPlayers any Member public `bindPlayers` dari `Modules/AdminHelpers/Binds.luau`.
---@field bindUptime any Member public `bindUptime` dari `Modules/AdminHelpers/Binds.luau`.
Core.Modules.AdminHelpers.Binds = Core.Modules.AdminHelpers.Binds or {}
do
	local __module = nil
	local folder = Core.Modules.AdminHelpers.BindHelpers
	if not folder then
		error("[AdminBinds] Folder 'BindHelpers' not found.")
	end
	local Uptime = Core.Modules.AdminHelpers.BindHelpers.Uptime
	local Messaging = Core.Modules.AdminHelpers.BindHelpers.Messaging
	local Players = Core.Modules.AdminHelpers.BindHelpers.Players

	local Binds = {}

	---Menjalankan fungsi `bindUptime`.
	---@param service any Nilai parameter `service`.
	function Binds.bindUptime(service)
		return Uptime.bind(service)
	end

	---Menjalankan fungsi `bindMessaging`.
	---@param service any Nilai parameter `service`.
	function Binds.bindMessaging(service)
		return Messaging.bind(service)
	end

	---Menjalankan fungsi `bindPlayers`.
	---@param service any Nilai parameter `service`.
	function Binds.bindPlayers(service)
		return Players.bind(service)
	end

	__module = Binds

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/Binds.luau"
	end
	Core.Modules.AdminHelpers.Binds = __module
end

---@class CoreModulesAdminHelpersBootstrap
---@field __source string Path sumber module `Modules/AdminHelpers/Bootstrap.luau`.
---@field announce any Member public `announce` dari `Modules/AdminHelpers/Bootstrap.luau`.
---@field broadcastAnnouncement any Member public `broadcastAnnouncement` dari `Modules/AdminHelpers/Bootstrap.luau`.
---@field get any Member public `get` dari `Modules/AdminHelpers/Bootstrap.luau`.
Core.Modules.AdminHelpers.Bootstrap = Core.Modules.AdminHelpers.Bootstrap or {}
do
	local __module = nil
	local Get = Core.Modules.AdminHelpers.BootstrapHelpers.Get
	local Announce = Core.Modules.AdminHelpers.BootstrapHelpers.Announce

	local Bootstrap = {}

	---Menjalankan fungsi `get`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `get`.
	function Bootstrap.get(service, player)
		return Get.run(service, player)
	end

	---Menjalankan fungsi `broadcastAnnouncement`.
	---@param service any Nilai parameter `service`.
	---@param payload any Nilai parameter `payload`.
	---@param scope any Nilai parameter `scope`.
	function Bootstrap.broadcastAnnouncement(service, payload, scope)
		return Announce.broadcast(service, payload, scope)
	end

	---Menjalankan fungsi `announce`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param message any Nilai parameter `message`.
	---@param scope any Nilai parameter `scope`.
	---@param duration any Nilai parameter `duration`.
	function Bootstrap.announce(service, player, message, scope, duration)
		return Announce.run(service, player, message, scope, duration)
	end

	__module = Bootstrap

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/Bootstrap.luau"
	end
	Core.Modules.AdminHelpers.Bootstrap = __module
end

---@class CoreModulesAdminHelpersJail
---@field __source string Path sumber module `Modules/AdminHelpers/Jail.luau`.
---@field install any Member public `install` dari `Modules/AdminHelpers/Jail.luau`.
Core.Modules.AdminHelpers.Jail = Core.Modules.AdminHelpers.Jail or {}
do
	local __module = nil
	local Template = Core.Modules.AdminHelpers.JailHelpers.Template
	local Profile = Core.Modules.AdminHelpers.JailHelpers.Profile
	local Guard = Core.Modules.AdminHelpers.JailHelpers.Guard

	local Jail = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	---@param deps any Nilai parameter `deps`.
	function Jail.install(service, deps)
		Template.install(service, deps)
		Profile.install(service, deps)
		Guard.install(service, deps)
	end

	__module = Jail

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/Jail.luau"
	end
	Core.Modules.AdminHelpers.Jail = __module
end

---@class CoreModulesAdminHelpersLogs
---@field __source string Path sumber module `Modules/AdminHelpers/Logs.luau`.
---@field install any Member public `install` dari `Modules/AdminHelpers/Logs.luau`.
Core.Modules.AdminHelpers.Logs = Core.Modules.AdminHelpers.Logs or {}
do
	local __module = nil
	local Describe = Core.Modules.AdminHelpers.LogHelpers.Describe
	local Emit = Core.Modules.AdminHelpers.LogHelpers.Emit

	local Logs = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	function Logs.install(service)
		Describe.install(service)
		Emit.install(service)
	end

	__module = Logs

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/Logs.luau"
	end
	Core.Modules.AdminHelpers.Logs = __module
end

---@class CoreModulesAdminHelpersNotifications
---@field __source string Path sumber module `Modules/AdminHelpers/Notifications.luau`.
---@field install any Member public `install` dari `Modules/AdminHelpers/Notifications.luau`.
Core.Modules.AdminHelpers.Notifications = Core.Modules.AdminHelpers.Notifications or {}
do
	local __module = nil
	local Notice = Core.Modules.AdminHelpers.NotificationHelpers.Notice

	local Notifications = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	function Notifications.install(service)
		Notice.install(service)
	end

	__module = Notifications

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/Notifications.luau"
	end
	Core.Modules.AdminHelpers.Notifications = __module
end

---@class CoreModulesAdminHelpersOverhead
---@field __source string Path sumber module `Modules/AdminHelpers/Overhead.luau`.
---@field install any Member public `install` dari `Modules/AdminHelpers/Overhead.luau`.
Core.Modules.AdminHelpers.Overhead = Core.Modules.AdminHelpers.Overhead or {}
do
	local __module = nil
	local ApplyRole = Core.Modules.AdminHelpers.OverheadHelpers.ApplyRole
	local PushConfig = Core.Modules.AdminHelpers.OverheadHelpers.PushConfig

	local Overhead = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	---@param deps any Nilai parameter `deps`.
	function Overhead.install(service, deps)
		ApplyRole.install(service, deps)
		PushConfig.install(service, deps)
	end

	__module = Overhead

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/Overhead.luau"
	end
	Core.Modules.AdminHelpers.Overhead = __module
end

---@class CoreModulesAdminHelpersPermissions
---@field __source string Path sumber module `Modules/AdminHelpers/Permissions.luau`.
---@field install any Member public `install` dari `Modules/AdminHelpers/Permissions.luau`.
Core.Modules.AdminHelpers.Permissions = Core.Modules.AdminHelpers.Permissions or {}
do
	local __module = nil
	local Checks = Core.Modules.AdminHelpers.PermissionHelpers.Checks
	local Mutate = Core.Modules.AdminHelpers.PermissionHelpers.Mutate

	local Permissions = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	---@param deps any Nilai parameter `deps`.
	function Permissions.install(service, deps)
		Checks.install(service, deps)
		Mutate.install(service, deps)
	end

	__module = Permissions

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/Permissions.luau"
	end
	Core.Modules.AdminHelpers.Permissions = __module
end

---@class CoreModulesAdminHelpersProfiles
---@field __source string Path sumber module `Modules/AdminHelpers/Profiles.luau`.
---@field install any Member public `install` dari `Modules/AdminHelpers/Profiles.luau`.
Core.Modules.AdminHelpers.Profiles = Core.Modules.AdminHelpers.Profiles or {}
do
	local __module = nil
	local Ban = Core.Modules.AdminHelpers.ProfileHelpers.Ban
	local Roles = Core.Modules.AdminHelpers.ProfileHelpers.Roles

	local Profiles = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	---@param deps any Nilai parameter `deps`.
	function Profiles.install(service, deps)
		Ban.install(service, deps)
		Roles.install(service, deps)
	end

	__module = Profiles

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/Profiles.luau"
	end
	Core.Modules.AdminHelpers.Profiles = __module
end

---@class CoreModulesAdminHelpersRefresh
---@field __source string Path sumber module `Modules/AdminHelpers/Refresh.luau`.
---@field install any Member public `install` dari `Modules/AdminHelpers/Refresh.luau`.
Core.Modules.AdminHelpers.Refresh = Core.Modules.AdminHelpers.Refresh or {}
do
	local __module = nil
	local Tools = Core.Modules.AdminHelpers.RefreshHelpers.Tools
	local Teleports = Core.Modules.AdminHelpers.RefreshHelpers.Teleports

	local Refresh = {}

	---Menjalankan fungsi `install`.
	---@param service any Nilai parameter `service`.
	---@param deps any Nilai parameter `deps`.
	function Refresh.install(service, deps)
		Tools.install(service, deps)
		Teleports.install(service, deps)
	end

	__module = Refresh

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/Refresh.luau"
	end
	Core.Modules.AdminHelpers.Refresh = __module
end

---@class CoreModulesAdminHelpersServerControl
---@field __source string Path sumber module `Modules/AdminHelpers/ServerControl.luau`.
---@field run any Member public `run` dari `Modules/AdminHelpers/ServerControl.luau`.
Core.Modules.AdminHelpers.ServerControl = Core.Modules.AdminHelpers.ServerControl or {}
do
	local __module = nil
	local Lock = Core.Modules.AdminHelpers.ServerControlHelpers.Lock
	local Restart = Core.Modules.AdminHelpers.ServerControlHelpers.Restart
	local Shutdown = Core.Modules.AdminHelpers.ServerControlHelpers.Shutdown

	local ServerControl = {}

	---Menjalankan fungsi `run`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param action any Nilai parameter `action`.
	function ServerControl.run(service, player, action)
		local act = tostring(action or "")
		if act == "Lock" or act == "Unlock" then
			return Lock.run(service, player, act)
		end
		if act == "Restart" then
			return Restart.run(service, player)
		end
		if act == "Shutdown" then
			return Shutdown.run(service, player)
		end
		return false, "UnknownAction"
	end

	__module = ServerControl

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/ServerControl.luau"
	end
	Core.Modules.AdminHelpers.ServerControl = __module
end

---@class CoreModulesAdminHelpersUtils
---@field __source string Path sumber module `Modules/AdminHelpers/Utils.luau`.
---@field applyFreeze any Member public `applyFreeze` dari `Modules/AdminHelpers/Utils.luau`.
---@field applyInvisible any Member public `applyInvisible` dari `Modules/AdminHelpers/Utils.luau`.
---@field getHumanoidRootPart any Member public `getHumanoidRootPart` dari `Modules/AdminHelpers/Utils.luau`.
---@field isOwnerByGame any Member public `isOwnerByGame` dari `Modules/AdminHelpers/Utils.luau`.
---@field matches any Member public `matches` dari `Modules/AdminHelpers/Utils.luau`.
---@field resolvePath any Member public `resolvePath` dari `Modules/AdminHelpers/Utils.luau`.
Core.Modules.AdminHelpers.Utils = Core.Modules.AdminHelpers.Utils or {}
do
	local __module = nil
	local Match = Core.Modules.AdminHelpers.UtilityHelpers.Match
	local Character = Core.Modules.AdminHelpers.UtilityHelpers.Character
	local Effects = Core.Modules.AdminHelpers.UtilityHelpers.Effects

	local Utils = {}

	---Menjalankan fungsi `matches`.
	---@param listIds any Nilai parameter `listIds`.
	---@param listNames any Nilai parameter `listNames`.
	---@param player any Nilai parameter `player`.
	function Utils.matches(listIds, listNames, player)
		return Match.matches(listIds, listNames, player)
	end

	---Menjalankan fungsi `isOwnerByGame`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `isOwnerByGame`.
	function Utils.isOwnerByGame(player)
		return Match.isOwnerByGame(player)
	end

	---Menjalankan fungsi `resolvePath`.
	---@param path any Nilai parameter `path`.
	function Utils.resolvePath(path)
		return Match.resolvePath(path)
	end

	---Menjalankan fungsi `getHumanoidRootPart`.
	---@param character any Nilai parameter `character`.
	---@return any result Hasil dari fungsi `getHumanoidRootPart`.
	function Utils.getHumanoidRootPart(character)
		return Character.getHumanoidRootPart(character)
	end

	---Menjalankan fungsi `applyFreeze`.
	---@param player any Nilai parameter `player`.
	---@param enabled any Nilai parameter `enabled`.
	function Utils.applyFreeze(player, enabled)
		return Effects.applyFreeze(player, enabled)
	end

	---Menjalankan fungsi `applyInvisible`.
	---@param player any Nilai parameter `player`.
	---@param enabled any Nilai parameter `enabled`.
	function Utils.applyInvisible(player, enabled)
		return Effects.applyInvisible(player, enabled)
	end

	__module = Utils

	if type(__module) == "table" then
		__module.__source = "Modules/AdminHelpers/Utils.luau"
	end
	Core.Modules.AdminHelpers.Utils = __module
end

---@class CoreModulesCarryCharacter
---@field __source string Path sumber module `Modules/Carry/Character.luau`.
Core.Modules.Carry.Character = Core.Modules.Carry.Character or {}
do
	local __module = nil
	local Character = {}

	---Menjalankan fungsi `getCharHRP`.
	---@param p any Nilai parameter `p`.
	---@return any result Hasil dari fungsi `getCharHRP`.
	function Character.getCharHRP(p)
		local char = p.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not (hrp and hum) then return end
		return char, hrp, hum
	end

	---Menjalankan fungsi `clearCarryWeldsForChar`.
	---@param char any Nilai parameter `char`.
	function Character.clearCarryWeldsForChar(char)
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			for _, w in ipairs(hrp:GetChildren()) do
				if w:IsA("WeldConstraint") and w.Name == "CarryWeld" then
					w:Destroy()
				end
			end
		end
	end

	__module = Character

	if type(__module) == "table" then
		__module.__source = "Modules/Carry/Character.luau"
	end
	Core.Modules.Carry.Character = __module
end

---@class CoreModulesCarryConfig
---@field __source string Path sumber module `Modules/Carry/Config.luau`.
Core.Modules.Carry.Config = Core.Modules.Carry.Config or {}
do
	local __module = nil
	__module = {
		PENDING_TIMEOUT = 8,
		MAX_DISTANCE = 20,
		MAX_CARRY = 8,

		BASE_Z = 1.6,
		SPACING_Z = 1.1,
		Y_OFFSET = 0.9,
		SLOT1_ADJ_Z = -0.2,
		SLOT2_ADJ_Z = 0.2,
		STEP_Y_FIRST = 0.55,
		STEP_Y_NEXT = 0.30,
		MAX_EXTRA_Y = 6.0,
	}

	if type(__module) == "table" then
		__module.__source = "Modules/Carry/Config.luau"
	end
	Core.Modules.Carry.Config = __module
end

---@class CoreModulesCarryFlowLifecycle
---@field __source string Path sumber module `Modules/Carry/FlowLifecycle.luau`.
---@field cleanupPending any Member public `cleanupPending` dari `Modules/Carry/FlowLifecycle.luau`.
---@field onCharacterAdded any Member public `onCharacterAdded` dari `Modules/Carry/FlowLifecycle.luau`.
Core.Modules.Carry.FlowLifecycle = Core.Modules.Carry.FlowLifecycle or {}
do
	local __module = nil
	local FlowLifecycle = {}

	---Menjalankan fungsi `onCharacterAdded`.
	---@param flow any Nilai parameter `flow`.
	---@param p any Nilai parameter `p`.
	---@param char any Nilai parameter `char`.
	function FlowLifecycle.onCharacterAdded(flow, p, char)
		flow:safeDetachIfAny(p, "respawn")
		task.defer(function()
			task.wait(0.5)
			flow.Character.clearCarryWeldsForChar(char)
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.Sit = false
				hum.AutoRotate = true
				hum.WalkSpeed = 16
				hum.PlatformStand = false
				hum.Jump = false
				if hum.UseJumpPower then
					hum.JumpPower = 50
				else
					hum.JumpHeight = 7.2
				end
				hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
				task.spawn(function()
					for phase = 1, 3 do
						task.wait(0.1 * phase)
						if not hum or not hum.Parent then
							break
						end
						hum.Sit = false
						hum.PlatformStand = false
						hum.AutoRotate = true
						hum.WalkSpeed = math.max(hum.WalkSpeed, 16)
						for _ = 1, 6 do
							hum.Sit = false
							hum:ChangeState(Enum.HumanoidStateType.Running)
							task.wait(0.02)
						end
					end
				end)
			end
			flow.state.savedProps[p.UserId] = nil
			flow.state.savedHum[p.UserId] = nil
			flow:_giveSelfOwnership(p)
		end)
	end

	---Menjalankan fungsi `cleanupPending`.
	---@param flow any Nilai parameter `flow`.
	---@param now any Nilai parameter `now`.
	function FlowLifecycle.cleanupPending(flow, now)
		for targetId, info in pairs(flow.state.pending) do
			if now - info.time > flow.config.PENDING_TIMEOUT then
				local target = flow.Players:GetPlayerByUserId(targetId)
				if info.requester and info.requester.Parent == flow.Players then
					flow.remote:Fire(info.requester, "RequestExpired", {targetId = targetId})
					if target then
						flow.remote:Fire(target, "PromptExpire", {})
					end
				end
				flow.state.pending[targetId] = nil
			end
		end
	end

	__module = FlowLifecycle

	if type(__module) == "table" then
		__module.__source = "Modules/Carry/FlowLifecycle.luau"
	end
	Core.Modules.Carry.FlowLifecycle = __module
end

---@class CoreModulesCarryFlowOps
---@field __source string Path sumber module `Modules/Carry/FlowOps.luau`.
Core.Modules.Carry.FlowOps = Core.Modules.Carry.FlowOps or {}
do
	local __module = nil
	local CharacterCleanup = Core.Modules.Carry.FlowHelpers.CharacterCleanup
	local HumanoidState = Core.Modules.Carry.FlowHelpers.HumanoidState
	local SlotPlanner = Core.Modules.Carry.FlowHelpers.SlotPlanner

	local FlowOps = {}

	---Menjalankan fungsi `reindexSlots`.
	---@param flow any Nilai parameter `flow`.
	---@param carrier any Nilai parameter `carrier`.
	function FlowOps.reindexSlots(flow, carrier)
		flow:_acquire(carrier.UserId)
		local ok = pcall(function()
			local _, cHRP = flow:_getCharHRP(carrier)
			if not cHRP then
				return
			end

			local orderedTargets = SlotPlanner.collectOrderedTargets(flow, carrier)
			if not orderedTargets then
				return
			end

			for index, entry in ipairs(orderedTargets) do
				local _, tHRP = flow:_getCharHRP(entry.player)
				if tHRP then
					if entry.slot ~= index then
						flow.Weld.removeCarryWeldBetween(cHRP, tHRP)
						tHRP.CFrame = cHRP.CFrame * flow:_slotOffset(index)
						flow.Weld.ensureCarryWeldBetween(cHRP, tHRP)
						flow.state.slotByCarrier[carrier.UserId][entry.player.UserId] = index
					else
						flow.Weld.ensureCarryWeldBetween(cHRP, tHRP)
					end
				end
			end
		end)
		flow:_release(carrier.UserId)
		return ok
	end

	---Menjalankan fungsi `transferPassengersToAtomic`.
	---@param flow any Nilai parameter `flow`.
	---@param newCarrier any Nilai parameter `newCarrier`.
	---@param oldCarrier any Nilai parameter `oldCarrier`.
	function FlowOps.transferPassengersToAtomic(flow, newCarrier, oldCarrier)
		local oldMap = flow.state.carryingByCarrier[oldCarrier.UserId]
		if not oldMap then
			return
		end

		local smapOld = flow.state.slotByCarrier[oldCarrier.UserId] or {}
		local arr = {}
		for tid, target in pairs(oldMap) do
			table.insert(arr, { t = target, s = smapOld[tid] or 999 })
		end
		table.sort(arr, function(a, b)
			return a.s < b.s
		end)

		local _, newHRP = flow:_getCharHRP(newCarrier)
		local _, oldHRP = flow:_getCharHRP(oldCarrier)
		if not newHRP or not oldHRP then
			return
		end

		flow:_acquirePair(newCarrier.UserId, oldCarrier.UserId)

		for _, entry in ipairs(arr) do
			local t = entry.t
			local tChar, tHRP, tHum = flow:_getCharHRP(t)
			if tChar and tHRP and tHum then
				local slotIdx = SlotPlanner.findNextOpenSlot(flow, newCarrier)
				if slotIdx then
					flow.Weld.removeCarryWeldBetween(oldHRP, tHRP)
					tHRP.CFrame = newHRP.CFrame * flow:_slotOffset(slotIdx)
					flow.Weld.ensureCarryWeldBetween(newHRP, tHRP)

					HumanoidState.applyCarried(flow, tHum, t.UserId)

					flow:_giveCarrierOwnership(t, newCarrier)

					local oldMap2 = flow.state.carryingByCarrier[oldCarrier.UserId]
					if oldMap2 then
						oldMap2[t.UserId] = nil
						if not next(oldMap2) then
							flow.state.carryingByCarrier[oldCarrier.UserId] = nil
						end
					end
					if flow.state.slotByCarrier[oldCarrier.UserId] then
						flow.state.slotByCarrier[oldCarrier.UserId][t.UserId] = nil
					end
					flow:_getCarryMap(newCarrier)[t.UserId] = t
					flow:_getSlotMap(newCarrier)[t.UserId] = slotIdx
					flow.state.carriedByTarget[t.UserId] = newCarrier

					flow.Notifier.sendEndForCarrierOnly(flow.remote, oldCarrier, t, "transfer", flow:countCarried(oldCarrier))
					flow:_fireStarted(newCarrier, t)
				end
			end
		end

		flow:_releasePair(newCarrier.UserId, oldCarrier.UserId)

		if flow.state.carryingByCarrier[oldCarrier.UserId] then
			flow:reindexSlots(oldCarrier)
		end
		flow:_sendCarrierList(newCarrier)
		flow:_sendCarrierList(oldCarrier)
	end

	---Menjalankan fungsi `startCarry`.
	---@param flow any Nilai parameter `flow`.
	---@param carrier any Nilai parameter `carrier`.
	---@param target any Nilai parameter `target`.
	function FlowOps.startCarry(flow, carrier, target)
		local cChar, cHRP = flow:_getCharHRP(carrier)
		local tChar, tHRP, tHum = flow:_getCharHRP(target)
		if not (cChar and cHRP and tChar and tHRP and tHum) then
			return false, "character missing"
		end

		flow:_acquire(carrier.UserId)
		local ok, err = pcall(function()
			if (cHRP.Position - tHRP.Position).Magnitude > flow.config.MAX_DISTANCE then
				error("too far")
			end
			if not flow:canCarrierRequest(carrier) then
				error("busy")
			end
			if not flow:targetAvailable(target) then
				error("busy")
			end

			local extra = flow:countCarried(target)
			if (flow:countCarried(carrier) + 1 + extra) > flow.config.MAX_CARRY then
				error("limit_transfer")
			end

			local slotIdx = SlotPlanner.findNextOpenSlot(flow, carrier)
			if not slotIdx then
				error("limit")
			end

			tHRP.CFrame = cHRP.CFrame * flow:_slotOffset(slotIdx)
			flow.Weld.ensureCarryWeldBetween(cHRP, tHRP)

			HumanoidState.applyCarried(flow, tHum, target.UserId)

			flow:_makeCarriedLight(tChar, target.UserId)
			flow:_giveCarrierOwnership(target, carrier)

			flow:_getCarryMap(carrier)[target.UserId] = target
			flow:_getSlotMap(carrier)[target.UserId] = slotIdx
			flow.state.carriedByTarget[target.UserId] = carrier

			CharacterCleanup.bind(flow, cChar, carrier)
			CharacterCleanup.bind(flow, tChar, target)

			flow:_fireStarted(carrier, target)
		end)
		flow:_release(carrier.UserId)

		if not ok then
			return false, tostring(err)
		end

		if flow:countCarried(target) > 0 then
			flow:transferPassengersToAtomic(carrier, target)
		end
		flow:_sendCarrierList(carrier)
		return true
	end

	---Menjalankan fungsi `detachPair`.
	---@param flow any Nilai parameter `flow`.
	---@param carrier any Nilai parameter `carrier`.
	---@param target any Nilai parameter `target`.
	---@param reason any Nilai parameter `reason`.
	function FlowOps.detachPair(flow, carrier, target, reason)
		local cUID = carrier.UserId
		local tUID = target.UserId

		flow:_acquire(cUID)
		local _, cHRP = flow:_getCharHRP(carrier)
		local _, tHRP, tHum = flow:_getCharHRP(target)

		if cHRP and tHRP then
			flow.Weld.removeCarryWeldBetween(cHRP, tHRP)
		end

		HumanoidState.restore(flow, tHum, tUID)

		if tHRP then
			pcall(function()
				tHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				tHRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
				tHRP.Anchored = false
			end)
			flow:_giveSelfOwnership(target)
		end

		flow:_restoreCarriedLight(tUID)

		local cmap = flow.state.carryingByCarrier[cUID]
		if cmap then
			cmap[tUID] = nil
			if not next(cmap) then
				flow.state.carryingByCarrier[cUID] = nil
			end
		end
		if flow.state.slotByCarrier[cUID] then
			flow.state.slotByCarrier[cUID][tUID] = nil
		end
		flow.state.carriedByTarget[tUID] = nil

		flow:_release(cUID)

		flow:_fireEnded(carrier, target, reason)

		task.defer(function()
			if flow.state.carryingByCarrier[cUID] then
				flow:reindexSlots(carrier)
			end
			flow:_sendCarrierList(carrier)
		end)
	end

	---Menjalankan fungsi `detachAllForCarrier`.
	---@param flow any Nilai parameter `flow`.
	---@param carrier any Nilai parameter `carrier`.
	---@param reason any Nilai parameter `reason`.
	function FlowOps.detachAllForCarrier(flow, carrier, reason)
		local cmap = flow.state.carryingByCarrier[carrier.UserId]
		if not cmap then
			return
		end

		local list = {}
		for _, target in pairs(cmap) do
			table.insert(list, target)
		end
		for _, target in ipairs(list) do
			flow:detachPair(carrier, target, reason)
		end
	end

	---Menjalankan fungsi `detachIfAny`.
	---@param flow any Nilai parameter `flow`.
	---@param p any Nilai parameter `p`.
	---@param reason any Nilai parameter `reason`.
	function FlowOps.detachIfAny(flow, p, reason)
		if flow.state.carriedByTarget[p.UserId] then
			flow:detachPair(flow.state.carriedByTarget[p.UserId], p, reason)
		elseif flow.state.carryingByCarrier[p.UserId] then
			flow:detachAllForCarrier(p, reason)
		end
	end

	---Menjalankan fungsi `safeDetachIfAny`.
	---@param flow any Nilai parameter `flow`.
	---@param p any Nilai parameter `p`.
	---@param reason any Nilai parameter `reason`.
	function FlowOps.safeDetachIfAny(flow, p, reason)
		if flow.state.detachGuard[p.UserId] then
			return
		end
		flow.state.detachGuard[p.UserId] = true
		task.defer(function()
			flow:detachIfAny(p, reason)
			flow.state.detachGuard[p.UserId] = nil
		end)
	end

	__module = FlowOps

	if type(__module) == "table" then
		__module.__source = "Modules/Carry/FlowOps.luau"
	end
	Core.Modules.Carry.FlowOps = __module
end

---@class CoreModulesCarryFlowRequests
---@field __source string Path sumber module `Modules/Carry/FlowRequests.luau`.
Core.Modules.Carry.FlowRequests = Core.Modules.Carry.FlowRequests or {}
do
	local __module = nil
	local FlowRequests = {}

	---Menjalankan fungsi `handleRequest`.
	---@param flow any Nilai parameter `flow`.
	---@param player any Nilai parameter `player`.
	---@param data any Nilai parameter `data`.
	function FlowRequests.handleRequest(flow, player, data)
		local targetId = data and data.targetId
		if type(targetId) ~= "number" then
			return
		end
		local target = flow.Players:GetPlayerByUserId(targetId)
		if not target or target == player then
			return
		end

		local _, cHRP = flow:_getCharHRP(player)
		local _, tHRP = flow:_getCharHRP(target)
		if not (cHRP and tHRP) then
			return
		end

		local distance = (cHRP.Position - tHRP.Position).Magnitude
		if distance > flow.config.MAX_DISTANCE then
			flow.remote:Fire(player, "TooFar", {targetId = targetId})
			return
		end

		local extra = flow:countCarried(target)
		if (flow:countCarried(player) + 1 + extra) > flow.config.MAX_CARRY then
			flow.remote:Fire(player, "Limit", {max = flow.config.MAX_CARRY, reason = "transfer"})
			return
		end

		if not flow:canCarrierRequest(player) or not flow:targetAvailable(target) then
			flow.remote:Fire(player, "Busy", {})
			return
		end

		if flow.state:hasPendingIncoming(player) or flow.state:hasPendingOutgoing(player) or flow.state.pending[target.UserId] then
			flow.remote:Fire(player, "Busy", {})
			return
		end

		if flow.state:isTrusted(target, player) then
			if flow.Promise then
				flow.Promise.try(function()
					local ok2, err2 = flow:startCarry(player, target)
					if not ok2 then
						error(err2 or "failed")
					end
				end):catch(function(err2)
					if tostring(err2) == "limit_transfer" then
						flow.remote:Fire(player, "Limit", {max = flow.config.MAX_CARRY, reason = "transfer"})
						flow.remote:Fire(target, "Failed", {reason = "limit_transfer"})
					else
						flow.remote:Fire(player, "Failed", {reason = err2})
						flow.remote:Fire(target, "Failed", {reason = err2})
					end
				end)
			else
				local ok2, err2 = flow:startCarry(player, target)
				if not ok2 then
					if tostring(err2) == "limit_transfer" then
						flow.remote:Fire(player, "Limit", {max = flow.config.MAX_CARRY, reason = "transfer"})
						flow.remote:Fire(target, "Failed", {reason = "limit_transfer"})
					else
						flow.remote:Fire(player, "Failed", {reason = err2})
						flow.remote:Fire(target, "Failed", {reason = err2})
					end
				end
			end
			return
		end

		flow.state.pending[target.UserId] = {requester = player, time = os.clock()}
		flow.remote:Fire(target, "Prompt", {fromId = player.UserId, fromName = player.DisplayName})
	end

	---Menjalankan fungsi `handleResponse`.
	---@param flow any Nilai parameter `flow`.
	---@param player any Nilai parameter `player`.
	---@param data any Nilai parameter `data`.
	function FlowRequests.handleResponse(flow, player, data)
		local accept = data and data.accept == true
		local requesterId = data and data.requesterId
		if type(requesterId) ~= "number" then
			return
		end

		local requester = flow.Players:GetPlayerByUserId(requesterId)
		if not requester then
			return
		end

		local pend = flow.state.pending[player.UserId]
		if not pend or pend.requester ~= requester then
			return
		end
		flow.state.pending[player.UserId] = nil

		if not accept then
			flow.remote:Fire(requester, "Declined", {targetId = player.UserId})
			flow.remote:Fire(player, "PromptClose", {})
			return
		end

		if flow.Promise then
			flow.Promise.try(function()
				local ok2, err2 = flow:startCarry(requester, player)
				if not ok2 then
					error(err2 or "failed")
				end
			end):catch(function(err2)
				if tostring(err2) == "limit_transfer" then
					flow.remote:Fire(requester, "Limit", {max = flow.config.MAX_CARRY, reason = "transfer"})
					flow.remote:Fire(player, "Failed", {reason = "limit_transfer"})
				else
					flow.remote:Fire(requester, "Failed", {reason = err2})
					flow.remote:Fire(player, "Failed", {reason = err2})
				end
			end)
		else
			local ok2, err2 = flow:startCarry(requester, player)
			if not ok2 then
				if tostring(err2) == "limit_transfer" then
					flow.remote:Fire(requester, "Limit", {max = flow.config.MAX_CARRY, reason = "transfer"})
					flow.remote:Fire(player, "Failed", {reason = "limit_transfer"})
				else
					flow.remote:Fire(requester, "Failed", {reason = err2})
					flow.remote:Fire(player, "Failed", {reason = err2})
				end
			end
		end
	end

	---Menjalankan fungsi `handleStop`.
	---@param flow any Nilai parameter `flow`.
	---@param player any Nilai parameter `player`.
	---@param data any Nilai parameter `data`.
	function FlowRequests.handleStop(flow, player, data)
		local targetId = data and data.targetId
		if type(targetId) == "number" then
			local t = flow.Players:GetPlayerByUserId(targetId)
			if t and flow.state.carryingByCarrier[player.UserId] and flow.state.carryingByCarrier[player.UserId][targetId] then
				flow:detachPair(player, t, "stop")
				return
			end
		end
		flow:detachIfAny(player, "stop")
	end

	---Menjalankan fungsi `handleTrust`.
	---@param flow any Nilai parameter `flow`.
	---@param player any Nilai parameter `player`.
	---@param data any Nilai parameter `data`.
	function FlowRequests.handleTrust(flow, player, data)
		local carrierId = data and data.carrierId
		local trust = data and data.trust == true
		if type(carrierId) ~= "number" then
			return
		end
		local carrier = flow.Players:GetPlayerByUserId(carrierId)
		if not carrier or carrier == player then
			return
		end
		flow.state:setTrusted(player, carrier, trust)
	end

	---Menjalankan fungsi `handleRemote`.
	---@param flow any Nilai parameter `flow`.
	---@param player any Nilai parameter `player`.
	---@param action any Nilai parameter `action`.
	---@param data any Nilai parameter `data`.
	function FlowRequests.handleRemote(flow, player, action, data)
		if action == "Request" then
			FlowRequests.handleRequest(flow, player, data)
		elseif action == "Response" then
			FlowRequests.handleResponse(flow, player, data)
		elseif action == "Stop" then
			FlowRequests.handleStop(flow, player, data)
		elseif action == "Trust" then
			FlowRequests.handleTrust(flow, player, data)
		end
	end

	__module = FlowRequests

	if type(__module) == "table" then
		__module.__source = "Modules/Carry/FlowRequests.luau"
	end
	Core.Modules.Carry.FlowRequests = __module
end

---@class CoreModulesCarryFlow
---@field __source string Path sumber module `Modules/Carry/Flow.luau`.
---@field Character any Member public `Character` dari `Modules/Carry/Flow.luau`.
---@field config any Member public `config` dari `Modules/Carry/Flow.luau`.
---@field Locks any Member public `Locks` dari `Modules/Carry/Flow.luau`.
---@field Notifier any Member public `Notifier` dari `Modules/Carry/Flow.luau`.
---@field Physics any Member public `Physics` dari `Modules/Carry/Flow.luau`.
---@field Players any Member public `Players` dari `Modules/Carry/Flow.luau`.
---@field Promise any Member public `Promise` dari `Modules/Carry/Flow.luau`.
---@field remote any Member public `remote` dari `Modules/Carry/Flow.luau`.
---@field Signal any Member public `Signal` dari `Modules/Carry/Flow.luau`.
---@field signals any Member public `signals` dari `Modules/Carry/Flow.luau`.
---@field state any Member public `state` dari `Modules/Carry/Flow.luau`.
---@field TableUtil any Member public `TableUtil` dari `Modules/Carry/Flow.luau`.
---@field Weld any Member public `Weld` dari `Modules/Carry/Flow.luau`.
Core.Modules.Carry.Flow = Core.Modules.Carry.Flow or {}
do
	local __module = nil
	local CarryFlow = {}
	CarryFlow.__index = CarryFlow

	local FlowOps = Core.Modules.Carry.FlowOps
	local FlowRequests = Core.Modules.Carry.FlowRequests
	local FlowLifecycle = Core.Modules.Carry.FlowLifecycle

	---Menjalankan fungsi `new`.
	---@param deps any Nilai parameter `deps`.
	---@return any result Hasil dari fungsi `new`.
	function CarryFlow.new(deps)
		local self = setmetatable({}, CarryFlow)
		self.Players = deps.Players
		self.Promise = deps.Promise
		self.TableUtil = deps.TableUtil
		self.Signal = deps.Signal
		self.remote = deps.Remote
		self.config = deps.Config
		self.state = deps.State
		self.Locks = deps.Locks
		self.Character = deps.Character
		self.Weld = deps.Weld
		self.Physics = deps.Physics
		self.Notifier = deps.Notifier

		self.signals = {
			Started = self.Signal and self.Signal.new() or nil,
			Ended = self.Signal and self.Signal.new() or nil,
		}

		return self
	end

	---@private
	---Menjalankan fungsi `_slotOffset`.
	---@param i any Nilai parameter `i`.
	function CarryFlow:_slotOffset(i)
		local z = self.config.BASE_Z + (i - 1) * self.config.SPACING_Z
		if i == 1 then
			z += self.config.SLOT1_ADJ_Z
		elseif i == 2 then
			z += self.config.SLOT2_ADJ_Z
		end

		local elevIndex = math.max(0, i - 1)
		local extraY = 0
		if elevIndex > 0 then
			extraY = self.config.STEP_Y_FIRST + (elevIndex - 1) * self.config.STEP_Y_NEXT
		end
		extraY = math.min(extraY, self.config.MAX_EXTRA_Y)

		return CFrame.new(0, self.config.Y_OFFSET + extraY, z)
	end

	---@private
	---Menjalankan fungsi `_acquire`.
	---@param uid any Nilai parameter `uid`.
	function CarryFlow:_acquire(uid)
		self.Locks.acquire(self.state.lockMap, uid)
	end

	---@private
	---Menjalankan fungsi `_release`.
	---@param uid any Nilai parameter `uid`.
	function CarryFlow:_release(uid)
		self.Locks.release(self.state.lockMap, uid)
	end

	---@private
	---Menjalankan fungsi `_acquirePair`.
	---@param a any Nilai parameter `a`.
	---@param b any Nilai parameter `b`.
	function CarryFlow:_acquirePair(a, b)
		self.Locks.acquirePair(self.state.lockMap, a, b)
	end

	---@private
	---Menjalankan fungsi `_releasePair`.
	---@param a any Nilai parameter `a`.
	---@param b any Nilai parameter `b`.
	function CarryFlow:_releasePair(a, b)
		self.Locks.releasePair(self.state.lockMap, a, b)
	end

	---@private
	---Menjalankan fungsi `_getCharHRP`.
	---@param player any Nilai parameter `player`.
	function CarryFlow:_getCharHRP(player)
		return self.Character.getCharHRP(player)
	end

	---@private
	---Menjalankan fungsi `_getCarryMap`.
	---@param carrier any Nilai parameter `carrier`.
	function CarryFlow:_getCarryMap(carrier)
		return self.state:getCarryMap(carrier)
	end

	---@private
	---Menjalankan fungsi `_getSlotMap`.
	---@param carrier any Nilai parameter `carrier`.
	function CarryFlow:_getSlotMap(carrier)
		return self.state:getSlotMap(carrier)
	end

	---Menjalankan fungsi `countCarried`.
	---@param carrier any Nilai parameter `carrier`.
	function CarryFlow:countCarried(carrier)
		return self.state:countCarried(carrier)
	end

	---Menjalankan fungsi `isBeingCarried`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `isBeingCarried`.
	function CarryFlow:isBeingCarried(player)
		return self.state:isBeingCarried(player)
	end

	---Menjalankan fungsi `canCarrierRequest`.
	---@param player any Nilai parameter `player`.
	function CarryFlow:canCarrierRequest(player)
		return self.state:canCarrierRequest(player)
	end

	---Menjalankan fungsi `targetAvailable`.
	---@param player any Nilai parameter `player`.
	function CarryFlow:targetAvailable(player)
		return self.state:targetAvailable(player)
	end

	---@private
	---Menjalankan fungsi `_saveHumState`.
	---@param uid any Nilai parameter `uid`.
	---@param hum any Nilai parameter `hum`.
	function CarryFlow:_saveHumState(uid, hum)
		self.Physics.saveHumState(self.state.savedHum, uid, hum)
	end

	---@private
	---Menjalankan fungsi `_restoreHumState`.
	---@param uid any Nilai parameter `uid`.
	---@param hum any Nilai parameter `hum`.
	function CarryFlow:_restoreHumState(uid, hum)
		self.Physics.restoreHumState(self.state.savedHum, uid, hum)
	end

	---@private
	---Menjalankan fungsi `_makeCarriedLight`.
	---@param char any Nilai parameter `char`.
	---@param uid any Nilai parameter `uid`.
	function CarryFlow:_makeCarriedLight(char, uid)
		self.Physics.makeCarriedLight(self.state.savedProps, char, uid)
	end

	---@private
	---Menjalankan fungsi `_restoreCarriedLight`.
	---@param uid any Nilai parameter `uid`.
	function CarryFlow:_restoreCarriedLight(uid)
		self.Physics.restoreCarriedLight(self.state.savedProps, uid)
	end

	---@private
	---Menjalankan fungsi `_setHRPOwnerTo`.
	---@param player any Nilai parameter `player`.
	---@param owner any Nilai parameter `owner`.
	function CarryFlow:_setHRPOwnerTo(player, owner)
		self.Physics.setHRPOwnerTo(self.Character.getCharHRP, player, owner)
	end

	---@private
	---Menjalankan fungsi `_giveSelfOwnership`.
	---@param player any Nilai parameter `player`.
	function CarryFlow:_giveSelfOwnership(player)
		self:_setHRPOwnerTo(player, player)
	end

	---@private
	---Menjalankan fungsi `_giveCarrierOwnership`.
	---@param target any Nilai parameter `target`.
	---@param carrier any Nilai parameter `carrier`.
	function CarryFlow:_giveCarrierOwnership(target, carrier)
		-- M-02 Fix: Set ownership to server (nil) so carrier client cannot manipulate target physics
		self:_setHRPOwnerTo(target, nil)
	end

	---@private
	---Menjalankan fungsi `_sendCarrierList`.
	---@param carrier any Nilai parameter `carrier`.
	function CarryFlow:_sendCarrierList(carrier)
		self.Notifier.sendCarrierList(self.remote, self.TableUtil, self.state.carryingByCarrier, carrier)
	end

	---@private
	---Menjalankan fungsi `_fireStarted`.
	---@param carrier any Nilai parameter `carrier`.
	---@param target any Nilai parameter `target`.
	function CarryFlow:_fireStarted(carrier, target)
		if self.signals.Started then
			self.signals.Started:Fire(carrier, target)
		end
	end

	---@private
	---Menjalankan fungsi `_fireEnded`.
	---@param carrier any Nilai parameter `carrier`.
	---@param target any Nilai parameter `target`.
	---@param reason any Nilai parameter `reason`.
	function CarryFlow:_fireEnded(carrier, target, reason)
		if self.signals.Ended then
			self.signals.Ended:Fire(carrier, target, reason)
		end
	end

	---Menjalankan fungsi `reindexSlots`.
	---@param carrier any Nilai parameter `carrier`.
	function CarryFlow:reindexSlots(carrier)
		return FlowOps.reindexSlots(self, carrier)
	end

	---Menjalankan fungsi `transferPassengersToAtomic`.
	---@param newCarrier any Nilai parameter `newCarrier`.
	---@param oldCarrier any Nilai parameter `oldCarrier`.
	function CarryFlow:transferPassengersToAtomic(newCarrier, oldCarrier)
		return FlowOps.transferPassengersToAtomic(self, newCarrier, oldCarrier)
	end

	---Menjalankan fungsi `startCarry`.
	---@param carrier any Nilai parameter `carrier`.
	---@param target any Nilai parameter `target`.
	function CarryFlow:startCarry(carrier, target)
		return FlowOps.startCarry(self, carrier, target)
	end

	---Menjalankan fungsi `detachPair`.
	---@param carrier any Nilai parameter `carrier`.
	---@param target any Nilai parameter `target`.
	---@param reason any Nilai parameter `reason`.
	function CarryFlow:detachPair(carrier, target, reason)
		return FlowOps.detachPair(self, carrier, target, reason)
	end

	---Menjalankan fungsi `detachAllForCarrier`.
	---@param carrier any Nilai parameter `carrier`.
	---@param reason any Nilai parameter `reason`.
	function CarryFlow:detachAllForCarrier(carrier, reason)
		return FlowOps.detachAllForCarrier(self, carrier, reason)
	end

	---Menjalankan fungsi `detachIfAny`.
	---@param p any Nilai parameter `p`.
	---@param reason any Nilai parameter `reason`.
	function CarryFlow:detachIfAny(p, reason)
		return FlowOps.detachIfAny(self, p, reason)
	end

	---Menjalankan fungsi `safeDetachIfAny`.
	---@param p any Nilai parameter `p`.
	---@param reason any Nilai parameter `reason`.
	function CarryFlow:safeDetachIfAny(p, reason)
		return FlowOps.safeDetachIfAny(self, p, reason)
	end

	---Menjalankan fungsi `onCharacterAdded`.
	---@param p any Nilai parameter `p`.
	---@param char any Nilai parameter `char`.
	function CarryFlow:onCharacterAdded(p, char)
		return FlowLifecycle.onCharacterAdded(self, p, char)
	end

	---Menjalankan fungsi `cleanupPending`.
	---@param now any Nilai parameter `now`.
	function CarryFlow:cleanupPending(now)
		return FlowLifecycle.cleanupPending(self, now)
	end

	---Menjalankan fungsi `handleRequest`.
	---@param player any Nilai parameter `player`.
	---@param data any Nilai parameter `data`.
	function CarryFlow:handleRequest(player, data)
		return FlowRequests.handleRequest(self, player, data)
	end

	---Menjalankan fungsi `handleResponse`.
	---@param player any Nilai parameter `player`.
	---@param data any Nilai parameter `data`.
	function CarryFlow:handleResponse(player, data)
		return FlowRequests.handleResponse(self, player, data)
	end

	---Menjalankan fungsi `handleStop`.
	---@param player any Nilai parameter `player`.
	---@param data any Nilai parameter `data`.
	function CarryFlow:handleStop(player, data)
		return FlowRequests.handleStop(self, player, data)
	end

	---Menjalankan fungsi `handleTrust`.
	---@param player any Nilai parameter `player`.
	---@param data any Nilai parameter `data`.
	function CarryFlow:handleTrust(player, data)
		return FlowRequests.handleTrust(self, player, data)
	end

	---Menjalankan fungsi `handleRemote`.
	---@param player any Nilai parameter `player`.
	---@param action any Nilai parameter `action`.
	---@param data any Nilai parameter `data`.
	function CarryFlow:handleRemote(player, action, data)
		return FlowRequests.handleRemote(self, player, action, data)
	end

	__module = CarryFlow

	if type(__module) == "table" then
		__module.__source = "Modules/Carry/Flow.luau"
	end
	Core.Modules.Carry.Flow = __module
end

---@class CoreModulesCarryLocks
---@field __source string Path sumber module `Modules/Carry/Locks.luau`.
Core.Modules.Carry.Locks = Core.Modules.Carry.Locks or {}
do
	local __module = nil
	local Locks = {}

	---Menjalankan fungsi `acquire`.
	---@param lockMap any Nilai parameter `lockMap`.
	---@param uid any Nilai parameter `uid`.
	function Locks.acquire(lockMap, uid)
		while lockMap[uid] do
			task.wait()
		end
		lockMap[uid] = true
	end

	---Menjalankan fungsi `release`.
	---@param lockMap any Nilai parameter `lockMap`.
	---@param uid any Nilai parameter `uid`.
	function Locks.release(lockMap, uid)
		lockMap[uid] = false
	end

	---Menjalankan fungsi `acquirePair`.
	---@param lockMap any Nilai parameter `lockMap`.
	---@param a any Nilai parameter `a`.
	---@param b any Nilai parameter `b`.
	function Locks.acquirePair(lockMap, a, b)
		if a == b then
			Locks.acquire(lockMap, a)
			return
		end
		if a < b then
			Locks.acquire(lockMap, a)
			Locks.acquire(lockMap, b)
		else
			Locks.acquire(lockMap, b)
			Locks.acquire(lockMap, a)
		end
	end

	---Menjalankan fungsi `releasePair`.
	---@param lockMap any Nilai parameter `lockMap`.
	---@param a any Nilai parameter `a`.
	---@param b any Nilai parameter `b`.
	function Locks.releasePair(lockMap, a, b)
		Locks.release(lockMap, a)
		if b ~= a then
			Locks.release(lockMap, b)
		end
	end

	__module = Locks

	if type(__module) == "table" then
		__module.__source = "Modules/Carry/Locks.luau"
	end
	Core.Modules.Carry.Locks = __module
end

---@class CoreModulesCarryNotifier
---@field __source string Path sumber module `Modules/Carry/Notifier.luau`.
Core.Modules.Carry.Notifier = Core.Modules.Carry.Notifier or {}
do
	local __module = nil
	local Notifier = {}

	---@private
	---Menjalankan fungsi `buildCarriedList`.
	---@param carryingByCarrier any Nilai parameter `carryingByCarrier`.
	---@param carrier any Nilai parameter `carrier`.
	local function buildCarriedList(carryingByCarrier, carrier)
		local list = {}
		local cmap = carryingByCarrier[carrier.UserId]
		if cmap then
			for tid, t in pairs(cmap) do
				table.insert(list, {id = tid, name = t.DisplayName})
			end
			table.sort(list, function(a, b)
				return a.name < b.name
			end)
		end
		return list
	end

	---Menjalankan fungsi `sendCarrierList`.
	---@param CarrySignal any Nilai parameter `CarrySignal`.
	---@param TableUtil any Nilai parameter `TableUtil`.
	---@param carryingByCarrier any Nilai parameter `carryingByCarrier`.
	---@param carrier any Nilai parameter `carrier`.
	function Notifier.sendCarrierList(CarrySignal, TableUtil, carryingByCarrier, carrier)
		local list = buildCarriedList(carryingByCarrier, carrier)
		if TableUtil and TableUtil.Copy then
			list = TableUtil.Copy(list)
		end
		CarrySignal:Fire(carrier, "CarrierList", {list = list})
	end

	---Menjalankan fungsi `sendStart`.
	---@param CarrySignal any Nilai parameter `CarrySignal`.
	---@param carrier any Nilai parameter `carrier`.
	---@param target any Nilai parameter `target`.
	---@param total any Nilai parameter `total`.
	function Notifier.sendStart(CarrySignal, carrier, target, total)
		CarrySignal:Fire(carrier, "Start", {
			carrierId = carrier.UserId, carrierName = carrier.DisplayName,
			targetId = target.UserId, targetName = target.DisplayName,
			youAreCarrier = true, carrierActiveCount = total or 0
		})
		CarrySignal:Fire(target, "Start", {
			carrierId = carrier.UserId, carrierName = carrier.DisplayName,
			targetId = target.UserId, targetName = target.DisplayName,
			youAreCarrier = false
		})
	end

	---Menjalankan fungsi `sendEndPair`.
	---@param CarrySignal any Nilai parameter `CarrySignal`.
	---@param carrier any Nilai parameter `carrier`.
	---@param target any Nilai parameter `target`.
	---@param reason any Nilai parameter `reason`.
	---@param carrierCount any Nilai parameter `carrierCount`.
	---@param targetCount any Nilai parameter `targetCount`.
	function Notifier.sendEndPair(CarrySignal, carrier, target, reason, carrierCount, targetCount)
		CarrySignal:Fire(carrier, "End", {
			reason = reason or "end",
			youAreCarrier = true,
			carrierActiveCount = carrierCount or 0,
			removedId = target.UserId,
			removedName = target.DisplayName,
		})
		CarrySignal:Fire(target, "End", {
			reason = reason or "end",
			youAreCarrier = false,
			yourCarryCount = targetCount or 0,
		})
	end

	---Menjalankan fungsi `sendEndForCarrierOnly`.
	---@param CarrySignal any Nilai parameter `CarrySignal`.
	---@param carrier any Nilai parameter `carrier`.
	---@param removedTarget any Nilai parameter `removedTarget`.
	---@param reason any Nilai parameter `reason`.
	---@param carrierCount any Nilai parameter `carrierCount`.
	function Notifier.sendEndForCarrierOnly(CarrySignal, carrier, removedTarget, reason, carrierCount)
		CarrySignal:Fire(carrier, "End", {
			reason = reason or "end",
			youAreCarrier = true,
			carrierActiveCount = carrierCount or 0,
			removedId = removedTarget.UserId,
			removedName = removedTarget.DisplayName,
		})
	end

	__module = Notifier

	if type(__module) == "table" then
		__module.__source = "Modules/Carry/Notifier.luau"
	end
	Core.Modules.Carry.Notifier = __module
end

---@class CoreModulesCarryPhysics
---@field __source string Path sumber module `Modules/Carry/Physics.luau`.
Core.Modules.Carry.Physics = Core.Modules.Carry.Physics or {}
do
	local __module = nil
	local _Physics = {}
	local PhysicsService = game:GetService("PhysicsService")

	local CARRY_GROUP = "CarryNoCollide"
	local PLAYERS_GROUP = "PlayersNoCollide"

	---@private
	---Menjalankan fungsi `ensureCarryGroup`.
	local function ensureCarryGroup()
		local ok = pcall(function()
			PhysicsService:RegisterCollisionGroup(CARRY_GROUP)
		end)
		local _ok = ok
		pcall(function()
			PhysicsService:CollisionGroupSetCollidable(CARRY_GROUP, "Default", false)
			PhysicsService:CollisionGroupSetCollidable(CARRY_GROUP, CARRY_GROUP, false)
			PhysicsService:CollisionGroupSetCollidable(CARRY_GROUP, PLAYERS_GROUP, false)
		end)
	end

	---@private
	---Menjalankan fungsi `getGroupNameFromId`.
	---@param id any Nilai parameter `id`.
	---@return any result Hasil dari fungsi `getGroupNameFromId`.
	local function getGroupNameFromId(id)
		local ok, name = pcall(function()
			return PhysicsService:GetCollisionGroupName(id)
		end)
		if ok and type(name) == "string" then
			return name
		end
		return "Default"
	end

	---@private
	---Menjalankan fungsi `saveHumState`.
	---@param savedHum any Nilai parameter `savedHum`.
	---@param uid any Nilai parameter `uid`.
	---@param hum any Nilai parameter `hum`.
	local function saveHumState(savedHum, uid, hum)
		if savedHum[uid] then
			return
		end

		savedHum[uid] = {
			ws = hum.WalkSpeed,
			useJP = hum.UseJumpPower,
			jp = hum.JumpPower,
			jh = hum.JumpHeight,
			autoRotate = hum.AutoRotate,
			jumpEnabled = hum:GetStateEnabled(Enum.HumanoidStateType.Jumping),
			platformStand = hum.PlatformStand,
		}
	end

	---@private
	---Menjalankan fungsi `forceHumanoidMovement`.
	---@param hum any Nilai parameter `hum`.
	local function forceHumanoidMovement(hum)
		if not hum or not hum.Parent then
			return
		end
		hum.Sit = false
		hum.PlatformStand = false
		hum.Jump = false
		for _ = 1, 10 do
			if not hum.Parent then
				break
			end
			hum.Sit = false
			hum.PlatformStand = false
			hum.Jump = false
			hum:ChangeState(Enum.HumanoidStateType.Running)
			hum:ChangeState(Enum.HumanoidStateType.Freefall)
			hum:ChangeState(Enum.HumanoidStateType.Running)
			task.wait(0.05)
			if hum.WalkSpeed > 0 and not hum.Sit and not hum.PlatformStand then
				break
			end
		end
	end

	---@private
	---Menjalankan fungsi `restoreHumState`.
	---@param savedHum any Nilai parameter `savedHum`.
	---@param uid any Nilai parameter `uid`.
	---@param hum any Nilai parameter `hum`.
	local function restoreHumState(savedHum, uid, hum)
		local st = savedHum[uid]
		if st then
			hum.WalkSpeed = math.max(st.ws, 16)
			hum.AutoRotate = st.autoRotate
			hum.PlatformStand = false
			if st.useJP then
				hum.JumpPower = st.jp
			else
				hum.JumpHeight = st.jh
			end
			hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, st.jumpEnabled)
			savedHum[uid] = nil
		else
			hum.WalkSpeed = 16
			hum.AutoRotate = true
			hum.PlatformStand = false
			if hum.UseJumpPower then
				hum.JumpPower = 50
			else
				hum.JumpHeight = 7.2
			end
			hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		end
		task.spawn(function()
			forceHumanoidMovement(hum)
		end)
	end

	---@private
	---Menjalankan fungsi `makeCarriedLight`.
	---@param savedProps any Nilai parameter `savedProps`.
	---@param char any Nilai parameter `char`.
	---@param userId any Nilai parameter `userId`.
	local function makeCarriedLight(savedProps, char, userId)
		ensureCarryGroup()
		if savedProps[userId] then
			for part in pairs(savedProps[userId]) do
				if part and part.Parent then
					if not part:IsDescendantOf(char) then
						savedProps[userId] = nil
						break
					end
				end
			end
		end
		if savedProps[userId] then
			return
		end

		local map = {}
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") then
				map[d] = { cc = d.CanCollide, ml = d.Massless, cg = getGroupNameFromId(d.CollisionGroupId) }
				d.CanCollide = false
				d.Massless = true
				d.CollisionGroup = CARRY_GROUP
			end
		end
		savedProps[userId] = map
	end

	---@private
	---Menjalankan fungsi `restoreCarriedLight`.
	---@param savedProps any Nilai parameter `savedProps`.
	---@param userId any Nilai parameter `userId`.
	local function restoreCarriedLight(savedProps, userId)
		local map = savedProps[userId]
		if not map then
			return
		end
		for part, st in pairs(map) do
			if part and part.Parent then
				part.CanCollide = st.cc
				part.Massless = st.ml
				if st.cg then
					part.CollisionGroup = st.cg
				end
			end
		end
		savedProps[userId] = nil
	end

	---@private
	---Menjalankan fungsi `setHRPOwnerTo`.
	---@param getCharHRP any Nilai parameter `getCharHRP`.
	---@param p any Nilai parameter `p`.
	---@param owner any Nilai parameter `owner`.
	local function setHRPOwnerTo(getCharHRP, p, owner)
		local _, hrp = getCharHRP(p)
		if not hrp then
			return
		end
		pcall(function()
			if owner then
				hrp:SetNetworkOwner(owner)
			else
				hrp:SetNetworkOwnershipAuto()
			end
		end)
	end

	__module = {
		saveHumState = saveHumState,
		restoreHumState = restoreHumState,
		makeCarriedLight = makeCarriedLight,
		restoreCarriedLight = restoreCarriedLight,
		setHRPOwnerTo = setHRPOwnerTo,
	}

	if type(__module) == "table" then
		__module.__source = "Modules/Carry/Physics.luau"
	end
	Core.Modules.Carry.Physics = __module
end

---@class CoreModulesCarryRemoteHandler
---@field __source string Path sumber module `Modules/Carry/RemoteHandler.luau`.
Core.Modules.Carry.RemoteHandler = Core.Modules.Carry.RemoteHandler or {}
do
	local __module = nil
	local RemoteHandler = {}

	---Menjalankan fungsi `bind`.
	---@param remote any Nilai parameter `remote`.
	---@param flow any Nilai parameter `flow`.
	---@param janitor any Nilai parameter `janitor`.
	function RemoteHandler.bind(remote, flow, janitor)
		local conn = remote.OnServerEvent:Connect(function(player, action, data)
			flow:handleRemote(player, action, data)
		end)
		if janitor then
			janitor:Add(conn, "Disconnect")
		end
		return conn
	end

	__module = RemoteHandler

	if type(__module) == "table" then
		__module.__source = "Modules/Carry/RemoteHandler.luau"
	end
	Core.Modules.Carry.RemoteHandler = __module
end

---@class CoreModulesCarryState
---@field __source string Path sumber module `Modules/Carry/State.luau`.
---@field carriedByTarget any Member public `carriedByTarget` dari `Modules/Carry/State.luau`.
---@field carryingByCarrier any Member public `carryingByCarrier` dari `Modules/Carry/State.luau`.
---@field detachGuard any Member public `detachGuard` dari `Modules/Carry/State.luau`.
---@field lockMap any Member public `lockMap` dari `Modules/Carry/State.luau`.
---@field pending any Member public `pending` dari `Modules/Carry/State.luau`.
---@field savedHum any Member public `savedHum` dari `Modules/Carry/State.luau`.
---@field savedProps any Member public `savedProps` dari `Modules/Carry/State.luau`.
---@field slotByCarrier any Member public `slotByCarrier` dari `Modules/Carry/State.luau`.
---@field trustByTarget any Member public `trustByTarget` dari `Modules/Carry/State.luau`.
Core.Modules.Carry.State = Core.Modules.Carry.State or {}
do
	local __module = nil
	local State = {}
	State.__index = State

	---Menjalankan fungsi `new`.
	---@return any result Hasil dari fungsi `new`.
	function State.new()
		local self = setmetatable({}, State)
		self.pending = {}
		self.carryingByCarrier = {}
		self.carriedByTarget = {}
		self.slotByCarrier = {}
		self.lockMap = {}
		self.detachGuard = {}
		self.savedProps = {}
		self.savedHum = {}
		self.trustByTarget = {}
		return self
	end

	---Menjalankan fungsi `getCarryMap`.
	---@param carrier any Nilai parameter `carrier`.
	---@return any result Hasil dari fungsi `getCarryMap`.
	function State:getCarryMap(carrier)
		local m = self.carryingByCarrier[carrier.UserId]
		if not m then
			m = {}
			self.carryingByCarrier[carrier.UserId] = m
		end
		return m
	end

	---Menjalankan fungsi `getSlotMap`.
	---@param carrier any Nilai parameter `carrier`.
	---@return any result Hasil dari fungsi `getSlotMap`.
	function State:getSlotMap(carrier)
		local m = self.slotByCarrier[carrier.UserId]
		if not m then
			m = {}
			self.slotByCarrier[carrier.UserId] = m
		end
		return m
	end

	---Menjalankan fungsi `countCarried`.
	---@param carrier any Nilai parameter `carrier`.
	function State:countCarried(carrier)
		local m = self.carryingByCarrier[carrier.UserId]
		if not m then
			return 0
		end
		local n = 0
		for _ in pairs(m) do
			n += 1
		end
		return n
	end

	---Menjalankan fungsi `isBeingCarried`.
	---@param p any Nilai parameter `p`.
	---@return any result Hasil dari fungsi `isBeingCarried`.
	function State:isBeingCarried(p)
		return self.carriedByTarget[p.UserId] ~= nil
	end

	---Menjalankan fungsi `canCarrierRequest`.
	---@param p any Nilai parameter `p`.
	function State:canCarrierRequest(p)
		return not self:isBeingCarried(p)
	end

	---Menjalankan fungsi `targetAvailable`.
	---@param p any Nilai parameter `p`.
	function State:targetAvailable(p)
		return not self:isBeingCarried(p)
	end

	---Menjalankan fungsi `hasPendingIncoming`.
	---@param p any Nilai parameter `p`.
	---@return any result Hasil dari fungsi `hasPendingIncoming`.
	function State:hasPendingIncoming(p)
		return self.pending[p.UserId] ~= nil
	end

	---Menjalankan fungsi `hasPendingOutgoing`.
	---@param p any Nilai parameter `p`.
	---@return any result Hasil dari fungsi `hasPendingOutgoing`.
	function State:hasPendingOutgoing(p)
		for _, info in pairs(self.pending) do
			if info.requester == p then
				return true
			end
		end
		return false
	end

	---Menjalankan fungsi `isTrusted`.
	---@param target any Nilai parameter `target`.
	---@param carrier any Nilai parameter `carrier`.
	---@return any result Hasil dari fungsi `isTrusted`.
	function State:isTrusted(target, carrier)
		local map = self.trustByTarget[target.UserId]
		return map ~= nil and map[carrier.UserId] == true
	end

	---Menjalankan fungsi `setTrusted`.
	---@param target any Nilai parameter `target`.
	---@param carrier any Nilai parameter `carrier`.
	---@param value any Nilai parameter `value`.
	function State:setTrusted(target, carrier, value)
		local tId = target.UserId
		local cId = carrier.UserId
		if value then
			local map = self.trustByTarget[tId]
			if not map then
				map = {}
				self.trustByTarget[tId] = map
			end
			map[cId] = true
		else
			local map = self.trustByTarget[tId]
			if map then
				map[cId] = nil
				if not next(map) then
					self.trustByTarget[tId] = nil
				end
			end
		end
	end

	---Menjalankan fungsi `clearTrustForUserId`.
	---@param userId any Nilai parameter `userId`.
	function State:clearTrustForUserId(userId)
		self.trustByTarget[userId] = nil
		for targetId, map in pairs(self.trustByTarget) do
			map[userId] = nil
			if not next(map) then
				self.trustByTarget[targetId] = nil
			end
		end
	end

	__module = State

	if type(__module) == "table" then
		__module.__source = "Modules/Carry/State.luau"
	end
	Core.Modules.Carry.State = __module
end

---@class CoreModulesCarryWeld
---@field __source string Path sumber module `Modules/Carry/Weld.luau`.
---@field Name any Member public `Name` dari `Modules/Carry/Weld.luau`.
---@field Parent any Member public `Parent` dari `Modules/Carry/Weld.luau`.
---@field Part0 any Member public `Part0` dari `Modules/Carry/Weld.luau`.
---@field Part1 any Member public `Part1` dari `Modules/Carry/Weld.luau`.
Core.Modules.Carry.Weld = Core.Modules.Carry.Weld or {}
do
	local __module = nil
	local Weld = {}

	---Menjalankan fungsi `findCarryWeldBetween`.
	---@param targetHRP any Nilai parameter `targetHRP`.
	---@param carrierHRP any Nilai parameter `carrierHRP`.
	function Weld.findCarryWeldBetween(targetHRP, carrierHRP)
		for _, w in ipairs(targetHRP:GetChildren()) do
			if w:IsA("WeldConstraint") and w.Name == "CarryWeld" and w.Part0 == carrierHRP and w.Part1 == targetHRP then
				return w
			end
		end
		return nil
	end

	---Menjalankan fungsi `ensureCarryWeldBetween`.
	---@param carrierHRP any Nilai parameter `carrierHRP`.
	---@param targetHRP any Nilai parameter `targetHRP`.
	function Weld.ensureCarryWeldBetween(carrierHRP, targetHRP)
		local w = Weld.findCarryWeldBetween(targetHRP, carrierHRP)
		if not w then
			w = Instance.new("WeldConstraint")
			w.Name = "CarryWeld"
			w.Part0 = carrierHRP
			w.Part1 = targetHRP
			w.Parent = targetHRP
		end
		return w
	end

	---Menjalankan fungsi `removeCarryWeldBetween`.
	---@param carrierHRP any Nilai parameter `carrierHRP`.
	---@param targetHRP any Nilai parameter `targetHRP`.
	function Weld.removeCarryWeldBetween(carrierHRP, targetHRP)
		local w = Weld.findCarryWeldBetween(targetHRP, carrierHRP)
		if w then
			w:Destroy()
		end
	end

	__module = Weld

	if type(__module) == "table" then
		__module.__source = "Modules/Carry/Weld.luau"
	end
	Core.Modules.Carry.Weld = __module
end

---@class CoreModulesCheckpointBindings
---@field __source string Path sumber module `Modules/Checkpoint/Bindings.luau`.
---@field janitor any Member public `janitor` dari `Modules/Checkpoint/Bindings.luau`.
---@field service any Member public `service` dari `Modules/Checkpoint/Bindings.luau`.
Core.Modules.Checkpoint.Bindings = Core.Modules.Checkpoint.Bindings or {}
do
	local __module = nil
	local Bindings = {}
	Bindings.__index = Bindings

	---Menjalankan fungsi `new`.
	---@param service any Nilai parameter `service`.
	---@return any result Hasil dari fungsi `new`.
	function Bindings.new(service)
		local self = setmetatable({}, Bindings)
		self.service = service
		self.janitor = service._janitor or service.janitor or nil
		return self
	end

	---Menjalankan fungsi `setupPlayers`.
	---@param includeExistingPlayers any Nilai parameter `includeExistingPlayers`.
	function Bindings:setupPlayers(includeExistingPlayers)
		local Players = game:GetService("Players")
		local j = self.janitor or {
			Add = function(_, c)
				return c
			end,
		}
		j:Add(Players.PlayerAdded:Connect(function(player)
			self.service:_onPlayerAdded(player)
		end), "Disconnect")
		j:Add(Players.PlayerRemoving:Connect(function(player)
			self.service:_onPlayerRemoving(player)
		end), "Disconnect")
		if includeExistingPlayers ~= false then
			for _, player in ipairs(Players:GetPlayers()) do
				self.service:_onPlayerAdded(player)
			end
		end
	end

	__module = Bindings

	if type(__module) == "table" then
		__module.__source = "Modules/Checkpoint/Bindings.luau"
	end
	Core.Modules.Checkpoint.Bindings = __module
end

---@class CoreModulesCheckpointCheckpointBackbasecamp
---@field __source string Path sumber module `Modules/Checkpoint/CheckpointBackbasecamp.luau`.
Core.Modules.Checkpoint.CheckpointBackbasecamp = Core.Modules.Checkpoint.CheckpointBackbasecamp or {}
do
	local __module = nil
	local Backbasecamp = {}

	---Menjalankan fungsi `bind`.
	---@param janitor any Nilai parameter `janitor`.
	---@param deps any Nilai parameter `deps`.
	function Backbasecamp.bind(janitor, deps)
		local BackBasecampHandler = deps.BackBasecampHandler
		if not BackBasecampHandler then return end

		BackBasecampHandler.setup(
			deps.CheckpointIndex,
			deps.CheckpointConfig,
			janitor,
			function(player)
				local state = deps.playerState[player]
				if not state then return end
				local startIndex = (deps.CheckpointIndex and deps.CheckpointIndex.StartIndex) or deps.CheckpointConfig.DefaultStartIndex or 0
				state.index = startIndex
				state.startTime = os.clock()
				state.lapActive = true
				deps.profiles:SetLastIndex(player, state.index)
				deps.setClientState(player, deps.serialize(state))
				deps.syncLeaderstats(player, state)
				local target = (deps.CheckpointIndex and deps.CheckpointIndex.GetCheckpointByIndex and deps.CheckpointIndex:GetCheckpointByIndex(startIndex))
					or deps.TargetFinder.findCheckpointPart(startIndex)
				local carryService = deps.getCarryService and deps.getCarryService() or nil
				if carryService and target then
					carryService:TeleportCarryGroup(player, target)
				else
					deps.TeleportHelper.teleportToIndex(player, startIndex, deps.CheckpointIndex, deps.CheckpointConfig.DefaultStartIndex)
				end
			end
		)
	end

	__module = Backbasecamp

	if type(__module) == "table" then
		__module.__source = "Modules/Checkpoint/CheckpointBackbasecamp.luau"
	end
	Core.Modules.Checkpoint.CheckpointBackbasecamp = __module
end

---@class CoreModulesCheckpointCheckpointLeaderboard
---@field __source string Path sumber module `Modules/Checkpoint/CheckpointLeaderboard.luau`.
---@field _board any Member private `_board` dari `Modules/Checkpoint/CheckpointLeaderboard.luau`.
---@field _filterUtil any Member private `_filterUtil` dari `Modules/Checkpoint/CheckpointLeaderboard.luau`.
---@field _overheadConfig any Member private `_overheadConfig` dari `Modules/Checkpoint/CheckpointLeaderboard.luau`.
Core.Modules.Checkpoint.CheckpointLeaderboard = Core.Modules.Checkpoint.CheckpointLeaderboard or {}
do
	local __module = nil
	local CheckpointLeaderboard = {}
	CheckpointLeaderboard.__index = CheckpointLeaderboard

	---Menjalankan fungsi `new`.
	---@param board any Nilai parameter `board`.
	---@param filterUtil any Nilai parameter `filterUtil`.
	---@param overheadConfig any Nilai parameter `overheadConfig`.
	---@return any result Hasil dari fungsi `new`.
	function CheckpointLeaderboard.new(board, filterUtil, overheadConfig)
		local self = setmetatable({}, CheckpointLeaderboard)
		self._board = board
		self._filterUtil = filterUtil
		self._overheadConfig = overheadConfig
		return self
	end

	---Menjalankan fungsi `updateSummit`.
	---@param userId any Nilai parameter `userId`.
	---@param summitCount any Nilai parameter `summitCount`.
	---@param username any Nilai parameter `username`.
	function CheckpointLeaderboard:updateSummit(userId, summitCount, username)
		if not self._board or not userId then
			return
		end
		if not self._lastSummitCache then
			self._lastSummitCache = {}
			self._lastSummitTime = {}
		end
		local now = os.clock()
		local lastVal = self._lastSummitCache[userId]
		local lastTime = self._lastSummitTime[userId] or 0
		if lastVal == summitCount or (now - lastTime < 15 and lastVal and summitCount <= lastVal) then
			return
		end
		self._lastSummitCache[userId] = summitCount
		self._lastSummitTime[userId] = now

		if self._filterUtil and self._filterUtil.isExemptFromLeaderboard then
			if self._filterUtil.isExemptFromLeaderboard(userId, nil, self._overheadConfig) then
				DataStoreConfig.RetryCall(function()
					self._board:RemoveAsync(tostring(userId))
				end, "Leaderboard:RemoveAsync")
				return
			end
		elseif self._filterUtil and self._filterUtil.isPrivileged then 
			if self._filterUtil.isPrivileged(userId, username, self._overheadConfig)  then
				DataStoreConfig.RetryCall(function()
					self._board:RemoveAsync(tostring(userId))
				end, "Leaderboard:RemoveAsync")
				return
			end
		end
		task.spawn(function()
			DataStoreConfig.RetryCall(function()
				self._board:SetAsync(tostring(userId), summitCount or 0)
			end, "CheckpointLeaderboard:SetAsync")
		end)
	end

	---Menjalankan fungsi `remove`.
	---@param userId any Nilai parameter `userId`.
	function CheckpointLeaderboard:remove(userId)
		if not self._board or not userId then 
			return
		end
		pcall(function()
			self._board:RemoveAsync(tostring(userId))
		end)
	end

	__module = CheckpointLeaderboard

	if type(__module) == "table" then
		__module.__source = "Modules/Checkpoint/CheckpointLeaderboard.luau"
	end
	Core.Modules.Checkpoint.CheckpointLeaderboard = __module
end

---@class CoreModulesCheckpointCheckpointSummitActions
---@field __source string Path sumber module `Modules/Checkpoint/CheckpointSummitActions.luau`.
---@field _leaderboard any Member private `_leaderboard` dari `Modules/Checkpoint/CheckpointSummitActions.luau`.
---@field _playerState any Member private `_playerState` dari `Modules/Checkpoint/CheckpointSummitActions.luau`.
---@field _profiles any Member private `_profiles` dari `Modules/Checkpoint/CheckpointSummitActions.luau`.
---@field _serialize any Member private `_serialize` dari `Modules/Checkpoint/CheckpointSummitActions.luau`.
---@field _setClientState any Member private `_setClientState` dari `Modules/Checkpoint/CheckpointSummitActions.luau`.
---@field _syncLeaderstats any Member private `_syncLeaderstats` dari `Modules/Checkpoint/CheckpointSummitActions.luau`.
Core.Modules.Checkpoint.CheckpointSummitActions = Core.Modules.Checkpoint.CheckpointSummitActions or {}
do
	local __module = nil
	local SummitActions = {}
	SummitActions.__index = SummitActions

	---Menjalankan fungsi `new`.
	---@param deps any Nilai parameter `deps`.
	---@return any result Hasil dari fungsi `new`.
	function SummitActions.new(deps)
		local self = setmetatable({}, SummitActions)
		self._playerState = deps.playerState
		self._profiles = deps.profiles
		self._leaderboard = deps.leaderboard
		self._serialize = deps.serialize
		self._setClientState = deps.setClientState
		self._syncLeaderstats = deps.syncLeaderstats
		return self
	end

	---Menjalankan fungsi `set`.
	---@param player any Nilai parameter `player`.
	---@param amount any Nilai parameter `amount`.
	function SummitActions:set(player, amount)
		local state = self._playerState[player]
		if not state then return end
		local value = math.max(0, math.floor(tonumber(amount) or 0))
		state.summitCount = value
		self._profiles:SetSummit(player, value)
		if self._leaderboard then
			self._leaderboard:updateSummit(player.UserId, value)
		end
		if self._setClientState and self._serialize then
			self._setClientState(player, self._serialize(state))
		end
		if self._syncLeaderstats then
			self._syncLeaderstats(player, state)
		end
	end

	---Menjalankan fungsi `add`.
	---@param player any Nilai parameter `player`.
	---@param amount any Nilai parameter `amount`.
	function SummitActions:add(player, amount)
		local state = self._playerState[player]
		if not state then return end
		local delta = math.floor(tonumber(amount) or 0)
		if delta == 0 then return end
		state.summitCount = math.max(0, (state.summitCount or 0) + delta)
		self._profiles:SetSummit(player, state.summitCount)
		if self._leaderboard then
			self._leaderboard:updateSummit(player.UserId, state.summitCount)
		end
		if self._setClientState and self._serialize then
			self._setClientState(player, self._serialize(state))
		end
		if self._syncLeaderstats then
			self._syncLeaderstats(player, state)
		end
	end

	---Menjalankan fungsi `reset`.
	---@param player any Nilai parameter `player`.
	function SummitActions:reset(player)
		self:set(player, 0)
	end

	---Menjalankan fungsi `addByUserId`.
	---@param userId any Nilai parameter `userId`.
	---@param amount any Nilai parameter `amount`.
	function SummitActions:addByUserId(userId, amount)
		if not userId then return end
		local delta = math.floor(tonumber(amount) or 0)
		if delta == 0 then return end
		local newTotal = self._profiles:AddSummitByUserId(userId, delta)
		if newTotal then
			if self._leaderboard then
				self._leaderboard:updateSummit(userId, newTotal)
			end
		end
	end

	---Menjalankan fungsi `resetByUserId`.
	---@param userId any Nilai parameter `userId`.
	function SummitActions:resetByUserId(userId)
		self:setByUserId(userId, 0)
	end

	---Menjalankan fungsi `setByUserId`.
	---@param userId any Nilai parameter `userId`.
	---@param amount any Nilai parameter `amount`.
	function SummitActions:setByUserId(userId, amount)
		if not userId then return end
		local value = math.max(0, math.floor(tonumber(amount) or 0))
		self._profiles:SetSummitByUserId(userId, value)
		if self._leaderboard then
			self._leaderboard:updateSummit(userId, value)
		end
	end

	__module = SummitActions

	if type(__module) == "table" then
		__module.__source = "Modules/Checkpoint/CheckpointSummitActions.luau"
	end
	Core.Modules.Checkpoint.CheckpointSummitActions = __module
end

---@class CoreModulesCheckpointFlow
---@field __source string Path sumber module `Modules/Checkpoint/Flow.luau`.
---@field cfg any Member public `cfg` dari `Modules/Checkpoint/Flow.luau`.
---@field idx any Member public `idx` dari `Modules/Checkpoint/Flow.luau`.
---@field profiles any Member public `profiles` dari `Modules/Checkpoint/Flow.luau`.
---@field rewards any Member public `rewards` dari `Modules/Checkpoint/Flow.luau`.
Core.Modules.Checkpoint.Flow = Core.Modules.Checkpoint.Flow or {}
do
	local __module = nil
	local Server = serverFolder
	local Config = Server.Config

	local Flow = {}
	Flow.__index = Flow

	---Menjalankan fungsi `new`.
	---@param idxModule any Nilai parameter `idxModule`.
	---@param profiles any Nilai parameter `profiles`.
	---@return any result Hasil dari fungsi `new`.
	function Flow.new(idxModule, profiles)
		local self = setmetatable({}, Flow)
		self.idx = idxModule
		self.profiles = profiles
		self.rewards = require(Config.RewandConfig)
		self.cfg = require(Config.CheckpointConfig)
		return self
	end

	---Menjalankan fungsi `handle`.
	---@param state any Nilai parameter `state`.
	---@param player any Nilai parameter `player`.
	---@param checkpointIndex any Nilai parameter `checkpointIndex`.
	---@param isFinish any Nilai parameter `isFinish`.
	---@param summitReward any Nilai parameter `summitReward`.
	function Flow:handle(state, player, checkpointIndex, isFinish, summitReward)
		local startIndex = self.idx.StartIndex or 0
		local finishStartIndex = self.idx.FinishStartIndex
		local finishIndex = self.idx.FinishIndex
		local expectedIndex = state.index + 1
		local accepted = false
		local rejectReason = nil
		local isAlternativeFinish = isFinish
			and finishStartIndex ~= nil
			and finishIndex ~= nil
			and checkpointIndex >= finishStartIndex
			and checkpointIndex <= finishIndex

		if checkpointIndex == state.index then
			return state, false, accepted
		end

		if checkpointIndex == startIndex and state.lapActive then
			return state, false, accepted
		end

		if not state.lapActive and checkpointIndex == startIndex then
			state.index = startIndex
			state.startTime = os.clock()
			state.lapActive = true
			self.profiles:SetLastIndex(player, state.index)
			accepted = true
			return state, false, accepted
		end

		if finishIndex and state.index == finishIndex and checkpointIndex == startIndex then
			expectedIndex = startIndex
		end

		if (not isAlternativeFinish) and checkpointIndex < expectedIndex then
			return state, false, accepted
		end
		local allowFinishChoice = isAlternativeFinish and finishStartIndex ~= nil and expectedIndex == finishStartIndex
		if self.cfg and self.cfg.EnableSkip == false and checkpointIndex ~= expectedIndex and not allowFinishChoice then
			rejectReason = "SkipDisabled"
			return state, false, accepted, rejectReason, expectedIndex
		end

		state.index = checkpointIndex
		accepted = true
		self.profiles:SetLastIndex(player, checkpointIndex)
		if checkpointIndex > (state.peakIndex or 0) then
			state.peakIndex = checkpointIndex
			self.profiles:SetPeak(player, state.peakIndex)
		end

		local summitReached = false
		if isFinish or (finishIndex and checkpointIndex == finishIndex) then
			if not state.lapActive then
				return state, false
			end
			state.lapActive = false
			local runTime = os.clock() - state.startTime
			state.lastRun = runTime
			if not state.bestTime or runTime < state.bestTime then
				state.bestTime = runTime
				self.profiles:SetBestTime(player, runTime)
			end
			local reward = tonumber(summitReward) or (self.rewards and self.rewards.SummitReward) or 1
			state.summitCount += reward
			self.profiles:IncrementSummit(player, reward)
			summitReached = true
		end

		return state, summitReached, accepted, rejectReason, expectedIndex, tonumber(summitReward) or nil
	end

	__module = Flow

	if type(__module) == "table" then
		__module.__source = "Modules/Checkpoint/Flow.luau"
	end
	Core.Modules.Checkpoint.Flow = __module
end

---@class CoreModulesCheckpointIndex
---@field __source string Path sumber module `Modules/Checkpoint/Index.luau`.
---@field _ordered any Member private `_ordered` dari `Modules/Checkpoint/Index.luau`.
---@field FinishIndex any Member public `FinishIndex` dari `Modules/Checkpoint/Index.luau`.
---@field FinishStartIndex any Member public `FinishStartIndex` dari `Modules/Checkpoint/Index.luau`.
---@field InfoByInstance any Member public `InfoByInstance` dari `Modules/Checkpoint/Index.luau`.
---@field StartIndex any Member public `StartIndex` dari `Modules/Checkpoint/Index.luau`.
Core.Modules.Checkpoint.Index = Core.Modules.Checkpoint.Index or {}
do
	local __module = nil
	local serverRoot = serverFolder
	local CheckpointConfig = require(serverRoot.Config.CheckpointConfig)
	local RewardConfig = require(serverRoot.Config.RewandConfig)
	local CollectionService = game:GetService("CollectionService")

	local CheckpointIndex = {}
	CheckpointIndex.__index = CheckpointIndex

	---Menjalankan fungsi `new`.
	---@return any result Hasil dari fungsi `new`.
	function CheckpointIndex.new()
		local self = setmetatable({}, CheckpointIndex)
		self._ordered = nil
		self.InfoByInstance = {}
		self.StartIndex = CheckpointConfig.DefaultStartIndex or 0
		self.FinishStartIndex = nil
		self.FinishIndex = nil
		return self
	end

	---@private
	---Menjalankan fungsi `resolveFolder`.
	---@param path any Nilai parameter `path`.
	local function resolveFolder(path)
		local current = workspace
		for _, name in ipairs(path) do
			current = current:WaitForChild(name)
		end
		return current
	end

	---@private
	---Menjalankan fungsi `_build`.
	function CheckpointIndex:_build()
		local folder = resolveFolder(CheckpointConfig.FolderPath)
		local list = {}
		local summitParts = {}
		self.InfoByInstance = {}
		local extraSummitEnabled = RewardConfig.SummitPlusEnabled
		local extraSummitReward = tonumber(RewardConfig.SummitPlusReward)
			or tonumber(RewardConfig.SummitReward)
			or 1
		local extraSummitName = string.lower(RewardConfig.SummitPlusPartName or "SummitPlus")

		for _, inst in ipairs(folder:GetChildren()) do
			if inst:IsA("BasePart") then
				local lowerName = string.lower(inst.Name)
				if lowerName == "summit" then
					table.insert(summitParts, {
						part = inst,
						reward = tonumber(RewardConfig.SummitReward) or 1,
					})
				elseif extraSummitEnabled == true and lowerName == extraSummitName then
					table.insert(summitParts, {
						part = inst,
						reward = extraSummitReward,
					})
				else
					local number = tonumber(string.match(inst.Name, "CP(%d+)") or string.match(inst.Name, "(%d+)$")) or 0
					table.insert(list, {part = inst, index = number})
				end
			end
		end

		table.sort(list, function(a, b)
			return a.index < b.index
		end)

		self.StartIndex = list[1] and list[1].index or (CheckpointConfig.DefaultStartIndex or 0)
		local maxIndex = list[#list] and list[#list].index or self.StartIndex
		local finishStartIndex = nil
		if #summitParts > 0 then
			for i, summitData in ipairs(summitParts) do
				local idx = maxIndex + i
				if not finishStartIndex then
					finishStartIndex = idx
				end
				table.insert(list, {
					part = summitData.part,
					index = idx,
					summitReward = summitData.reward,
				})
			end
			table.sort(list, function(a, b)
				return a.index < b.index
			end)
		end
		self.FinishStartIndex = finishStartIndex
		self.FinishIndex = list[#list] and list[#list].index or self.StartIndex

		for _, entry in ipairs(list) do
			local info = {
				index = entry.index,
				isStart = entry.index == self.StartIndex,
				isFinish = entry.summitReward ~= nil or entry.index == self.FinishIndex,
				summitReward = entry.summitReward,
			}
			self.InfoByInstance[entry.part] = info
		end

		self._ordered = {}
		for _, entry in ipairs(list) do
			table.insert(self._ordered, entry.part)
			if not CollectionService:HasTag(entry.part, CheckpointConfig.Tag) then
				CollectionService:AddTag(entry.part, CheckpointConfig.Tag)
			end
		end
	end

	---@private
	---Menjalankan fungsi `_ensure`.
	function CheckpointIndex:_ensure()
		if not self._ordered then
			self:_build()
		end
	end

	---Menjalankan fungsi `GetOrdered`.
	---@return any result Hasil dari fungsi `GetOrdered`.
	function CheckpointIndex:GetOrdered()
		self:_ensure()
		return self._ordered
	end

	---Menjalankan fungsi `GetCheckpointByIndex`.
	---@param index any Nilai parameter `index`.
	---@return any result Hasil dari fungsi `GetCheckpointByIndex`.
	function CheckpointIndex:GetCheckpointByIndex(index)
		self:_ensure()
		for _, part in ipairs(self._ordered) do
			local info = self.InfoByInstance[part]
			if info and info.index == index then
				return part
			end
		end
		return nil
	end

	---Menjalankan fungsi `GetInfoForInstance`.
	---@param inst any Nilai parameter `inst`.
	---@return any result Hasil dari fungsi `GetInfoForInstance`.
	function CheckpointIndex:GetInfoForInstance(inst)
		self:_ensure()
		return self.InfoByInstance[inst]
	end

	__module = CheckpointIndex.new()

	if type(__module) == "table" then
		__module.__source = "Modules/Checkpoint/Index.luau"
	end
	Core.Modules.Checkpoint.Index = __module
end

---@class CoreModulesCheckpointLifecycle
---@field __source string Path sumber module `Modules/Checkpoint/Lifecycle.luau`.
Core.Modules.Checkpoint.Lifecycle = Core.Modules.Checkpoint.Lifecycle or {}
do
	local __module = nil
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Shared = ReplicatedStorage.Shared
	local Packages = Shared.Packages
	local Janitor = require(Packages.Janitor)

	local Lifecycle = {}

	---Menjalankan fungsi `onCharacterAdded`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param character any Nilai parameter `character`.
	function Lifecycle.onCharacterAdded(service, player, character)
		if not character then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
		if humanoid then
			service._playerConns[player]:Add(humanoid.Died:Connect(function()
				player:LoadCharacter()
			end), "Disconnect")
		end
		local state = service._playerState[player]
		local idx = state and state.index or service._respawn.idx.StartIndex
		local profileIdx = service._profiles and service._profiles.GetLastIndex and service._profiles:GetLastIndex(player) or nil
		if profileIdx and profileIdx > 0 then
			idx = profileIdx
		end
		service._respawn:teleport(player, idx)
	end

	---Menjalankan fungsi `addPlayer`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	function Lifecycle.addPlayer(service, player)
		local profile = service._profiles:Load(player)
		service._leaderstats[player] = service._leaderstatsClass.new(player)
		service._playerConns[player] = service._playerConns[player] or Janitor.new()

		local state = service._stateMgr:create(player)
		service._stateMgr:applyProfile(state, profile)
		service._playerState[player] = state

		service._playerConns[player]:Add(player.CharacterAdded:Connect(function(character)
			Lifecycle.onCharacterAdded(service, player, character)
		end), "Disconnect")
		Lifecycle.onCharacterAdded(service, player, player.Character)

		service.Client.State:SetFor(player, service._serialize(state))
		service:_syncLeaderstats(player, state)
	end

	---Menjalankan fungsi `removePlayer`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	function Lifecycle.removePlayer(service, player)
		service._profiles:Release(player)
		service._playerState[player] = nil
		if service._leaderstats[player] then
			service._leaderstats[player]:Destroy()
			service._leaderstats[player] = nil
		end
		if service._playerConns[player] then
			service._playerConns[player]:Destroy()
			service._playerConns[player] = nil
		end
		service.Client.State:SetFor(player, nil)
	end

	__module = Lifecycle

	if type(__module) == "table" then
		__module.__source = "Modules/Checkpoint/Lifecycle.luau"
	end
	Core.Modules.Checkpoint.Lifecycle = __module
end

---@class CoreModulesCheckpointPlayerState
---@field __source string Path sumber module `Modules/Checkpoint/PlayerState.luau`.
---@field bestTime any Member public `bestTime` dari `Modules/Checkpoint/PlayerState.luau`.
---@field finishIndex any Member public `finishIndex` dari `Modules/Checkpoint/PlayerState.luau`.
---@field index any Member public `index` dari `Modules/Checkpoint/PlayerState.luau`.
---@field lapActive any Member public `lapActive` dari `Modules/Checkpoint/PlayerState.luau`.
---@field lastRun any Member public `lastRun` dari `Modules/Checkpoint/PlayerState.luau`.
---@field peakIndex any Member public `peakIndex` dari `Modules/Checkpoint/PlayerState.luau`.
---@field startTime any Member public `startTime` dari `Modules/Checkpoint/PlayerState.luau`.
---@field summitCount any Member public `summitCount` dari `Modules/Checkpoint/PlayerState.luau`.
Core.Modules.Checkpoint.PlayerState = Core.Modules.Checkpoint.PlayerState or {}
do
	local __module = nil
	local PlayerState = {}
	PlayerState.__index = PlayerState

	---Menjalankan fungsi `new`.
	---@param startIndex any Nilai parameter `startIndex`.
	---@param finishIndex any Nilai parameter `finishIndex`.
	---@return any result Hasil dari fungsi `new`.
	function PlayerState.new(startIndex, finishIndex)
		local self = setmetatable({}, PlayerState)
		self.index = startIndex
		self.startTime = os.clock()
		self.lastRun = nil
		self.bestTime = nil
		self.peakIndex = 0
		self.summitCount = 0
		self.lapActive = true
		self.finishIndex = finishIndex
		return self
	end

	__module = PlayerState

	if type(__module) == "table" then
		__module.__source = "Modules/Checkpoint/PlayerState.luau"
	end
	Core.Modules.Checkpoint.PlayerState = __module
end

---@class CoreModulesTeleportTeleportHelper
---@field __source string Path sumber module `Modules/Teleport/TeleportHelper.luau`.
Core.Modules.Teleport.TeleportHelper = Core.Modules.Teleport.TeleportHelper or {}
do
	local __module = nil
	local TargetFinder = Core.Modules.Teleport.Util.TargetFinder
	local TeleportUtil = Core.Modules.Teleport.Util.TeleportUtil
	local Players = game:GetService("Players")

	local TeleportHelper = {}

	---@private
	---Menjalankan fungsi `resolveTarget`.
	---@param index any Nilai parameter `index`.
	---@param checkpointIndex any Nilai parameter `checkpointIndex`.
	---@param defaultStartIndex any Nilai parameter `defaultStartIndex`.
	local function resolveTarget(index, checkpointIndex, defaultStartIndex)
		local target = (checkpointIndex and checkpointIndex.GetCheckpointByIndex and checkpointIndex:GetCheckpointByIndex(index))
		if target and target:IsDescendantOf(workspace) then
			return target
		end
		target = TargetFinder.findCheckpointPart(index)
		if target then
			return target
		end
		if checkpointIndex and checkpointIndex.FinishIndex then
			local finishTarget = checkpointIndex:GetCheckpointByIndex(checkpointIndex.FinishIndex)
			if finishTarget and finishTarget:IsDescendantOf(workspace) then
				return finishTarget
			end
		end
		target = (checkpointIndex and checkpointIndex.GetCheckpointByIndex and checkpointIndex:GetCheckpointByIndex(defaultStartIndex))
		if target and target:IsDescendantOf(workspace) then
			return target
		end
		return TargetFinder.findCheckpointPart(defaultStartIndex)
	end

	---Menjalankan fungsi `teleportToIndex`.
	---@param player any Nilai parameter `player`.
	---@param index any Nilai parameter `index`.
	---@param checkpointIndex any Nilai parameter `checkpointIndex`.
	---@param defaultStartIndex any Nilai parameter `defaultStartIndex`.
	function TeleportHelper.teleportToIndex(player, index, checkpointIndex, defaultStartIndex)
		local target = resolveTarget(index, checkpointIndex, defaultStartIndex)
		if not target then
			return
		end
		local character = player.Character or player.CharacterAdded:Wait()
		TeleportUtil.teleport(character, target)
	end

	---Menjalankan fungsi `teleportToIndexWithRetry`.
	---@param player any Nilai parameter `player`.
	---@param index any Nilai parameter `index`.
	---@param checkpointIndex any Nilai parameter `checkpointIndex`.
	---@param defaultStartIndex any Nilai parameter `defaultStartIndex`.
	---@param attempts any Nilai parameter `attempts`.
	---@param delaySeconds any Nilai parameter `delaySeconds`.
	function TeleportHelper.teleportToIndexWithRetry(player, index, checkpointIndex, defaultStartIndex, attempts, delaySeconds)
		attempts = attempts or 10
		delaySeconds = delaySeconds or 0.15

		---@private
		---Menjalankan fungsi `attempt`.
		---@param try any Nilai parameter `try`.
		local function attempt(try)
			if not player.Parent then
				return
			end
			local target = resolveTarget(index, checkpointIndex, defaultStartIndex)
			if target then
				local character = player.Character or player.CharacterAdded:Wait()
				TeleportUtil.teleport(character, target)
				return
			end
			if try < attempts then
				task.delay(delaySeconds, function()
					attempt(try + 1)
				end)
			else
				local fallback = resolveTarget(defaultStartIndex, checkpointIndex, defaultStartIndex)
				if fallback then
					local character = player.Character or player.CharacterAdded:Wait()
					TeleportUtil.teleport(character, fallback)
				end
			end
		end

		attempt(1)
	end

	---Menjalankan fungsi `teleportToSpawn`.
	---@param player any Nilai parameter `player`.
	---@param index any Nilai parameter `index`.
	---@param checkpointIndex any Nilai parameter `checkpointIndex`.
	---@param defaultStartIndex any Nilai parameter `defaultStartIndex`.
	function TeleportHelper.teleportToSpawn(player, index, checkpointIndex, defaultStartIndex)
		local target = TargetFinder.findTeleportSpawnPart(index)
		if not target then
			target = resolveTarget(index, checkpointIndex, defaultStartIndex)
		end
		if not target then
			target = TargetFinder.findTeleportSpawnPart(defaultStartIndex)
		end
		if not target then
			target = resolveTarget(defaultStartIndex, checkpointIndex, defaultStartIndex)
		end
		if not target then
			return
		end
		local character = player.Character or player.CharacterAdded:Wait()
		TeleportUtil.teleport(character, target)
	end

	---Menjalankan fungsi `bindTeleportParts`.
	---@param janitor any Nilai parameter `janitor`.
	---@param checkpointIndex any Nilai parameter `checkpointIndex`.
	---@param defaultStartIndex any Nilai parameter `defaultStartIndex`.
	---@param getPlayerState any Nilai parameter `getPlayerState`.
	function TeleportHelper.bindTeleportParts(janitor, checkpointIndex, defaultStartIndex, getPlayerState)
		for _, part in ipairs(TargetFinder.findTeleporterParts()) do
			local conn = part.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if not player then
					return
				end
				local state = getPlayerState and getPlayerState(player) or nil
				local target = (state and state.index) or defaultStartIndex
				TeleportHelper.teleportToSpawn(player, target, checkpointIndex, defaultStartIndex)
			end)
			if janitor then
				janitor:Add(conn, "Disconnect")
			end
		end
	end

	__module = TeleportHelper

	if type(__module) == "table" then
		__module.__source = "Modules/Teleport/TeleportHelper.luau"
	end
	Core.Modules.Teleport.TeleportHelper = __module
end

---@class CoreModulesCheckpointRespawn
---@field __source string Path sumber module `Modules/Checkpoint/Respawn.luau`.
---@field defaultStartIndex any Member public `defaultStartIndex` dari `Modules/Checkpoint/Respawn.luau`.
---@field idx any Member public `idx` dari `Modules/Checkpoint/Respawn.luau`.
Core.Modules.Checkpoint.Respawn = Core.Modules.Checkpoint.Respawn or {}
do
	local __module = nil
	local TeleportHelper = Core.Modules.Teleport.TeleportHelper

	local Respawn = {}
	Respawn.__index = Respawn

	---Menjalankan fungsi `new`.
	---@param checkpointIndex any Nilai parameter `checkpointIndex`.
	---@param defaultStartIndex any Nilai parameter `defaultStartIndex`.
	---@return any result Hasil dari fungsi `new`.
	function Respawn.new(checkpointIndex, defaultStartIndex)
		local self = setmetatable({}, Respawn)
		self.idx = checkpointIndex
		self.defaultStartIndex = defaultStartIndex or 0
		return self
	end

	---Menjalankan fungsi `teleport`.
	---@param player any Nilai parameter `player`.
	---@param index any Nilai parameter `index`.
	function Respawn:teleport(player, index)
		TeleportHelper.teleportToIndexWithRetry(player, index, self.idx, self.defaultStartIndex)
	end

	---Menjalankan fungsi `bindCharacter`.
	---@param player any Nilai parameter `player`.
	---@param connTable any Nilai parameter `connTable`.
	---@param getState any Nilai parameter `getState`.
	function Respawn:bindCharacter(player, connTable, getState)
		connTable:Add(player.CharacterAdded:Connect(function(character)
			local state = getState()
			local target = state and state.index or (self.idx.StartIndex or self.defaultStartIndex)
			self:teleport(player, target)
			local hum = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
			if hum then
				connTable:Add(hum.Died:Connect(function()
					player:LoadCharacter()
				end), "Disconnect")
			end
		end), "Disconnect")
	end

	__module = Respawn

	if type(__module) == "table" then
		__module.__source = "Modules/Checkpoint/Respawn.luau"
	end
	Core.Modules.Checkpoint.Respawn = __module
end

---@class CoreModulesCheckpointServiceReset
---@field __source string Path sumber module `Modules/Checkpoint/ServiceReset.luau`.
Core.Modules.Checkpoint.ServiceReset = Core.Modules.Checkpoint.ServiceReset or {}
do
	local __module = nil
	local ServiceReset = {}

	---Menjalankan fungsi `resetToStart`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param checkpointIndex any Nilai parameter `checkpointIndex`.
	---@param checkpointConfig any Nilai parameter `checkpointConfig`.
	function ServiceReset.resetToStart(service, player, checkpointIndex, checkpointConfig)
		local state = service._playerState[player]
		if not state then return end
		state.index = checkpointIndex.StartIndex or (checkpointConfig.DefaultStartIndex or 0)
		state.startTime = os.clock()
		state.lapActive = true
		service._profiles:SetLastIndex(player, state.index)
		service.Client.State:SetFor(player, service._serialize(state))
		service:_syncLeaderstats(player, state)
		local targetPart = checkpointIndex.GetCheckpointByIndex and checkpointIndex:GetCheckpointByIndex(state.index) or nil
		local carryService = service._getCarryService and service:_getCarryService() or nil
		if carryService and targetPart then
			local ok = carryService:TeleportCarryGroup(player, targetPart)
			if ok == true then
				return
			end
		end
		service._respawn:teleport(player, state.index)
	end

	__module = ServiceReset

	if type(__module) == "table" then
		__module.__source = "Modules/Checkpoint/ServiceReset.luau"
	end
	Core.Modules.Checkpoint.ServiceReset = __module
end

---@class CoreModulesCheckpointServiceSerializer
---@field __source string Path sumber module `Modules/Checkpoint/ServiceSerializer.luau`.
---@field serialize any Member public `serialize` dari `Modules/Checkpoint/ServiceSerializer.luau`.
Core.Modules.Checkpoint.ServiceSerializer = Core.Modules.Checkpoint.ServiceSerializer or {}
do
	local __module = nil
	local ServiceSerializer = {}

	---Menjalankan fungsi `serialize`.
	---@param state any Nilai parameter `state`.
	function ServiceSerializer.serialize(state)
		if not state then return {} end
		return {
			index = state.index,
			startTime = state.startTime,
			lastRun = state.lastRun,
			bestTime = state.bestTime,
			peakIndex = state.peakIndex,
			summitCount = state.summitCount,
			lapActive = state.lapActive,
		}
	end

	__module = ServiceSerializer

	if type(__module) == "table" then
		__module.__source = "Modules/Checkpoint/ServiceSerializer.luau"
	end
	Core.Modules.Checkpoint.ServiceSerializer = __module
end

---@class CoreModulesCheckpointStateFactory
---@field __source string Path sumber module `Modules/Checkpoint/StateFactory.luau`.
---@field bestTime any Member public `bestTime` dari `Modules/Checkpoint/StateFactory.luau`.
---@field index any Member public `index` dari `Modules/Checkpoint/StateFactory.luau`.
---@field lapActive any Member public `lapActive` dari `Modules/Checkpoint/StateFactory.luau`.
---@field peakIndex any Member public `peakIndex` dari `Modules/Checkpoint/StateFactory.luau`.
---@field startTime any Member public `startTime` dari `Modules/Checkpoint/StateFactory.luau`.
---@field summitCount any Member public `summitCount` dari `Modules/Checkpoint/StateFactory.luau`.
Core.Modules.Checkpoint.StateFactory = Core.Modules.Checkpoint.StateFactory or {}
do
	local __module = nil
	local StateFactory = {}

	---Menjalankan fungsi `make`.
	---@param startIndex any Nilai parameter `startIndex`.
	---@param finishIndex any Nilai parameter `finishIndex`.
	function StateFactory.make(startIndex: number, finishIndex: number?)
		return {
			index = startIndex,
			startTime = os.clock(),
			lastRun = nil,
			bestTime = nil,
			peakIndex = 0,
			summitCount = 0,
			lapActive = true,
			finishIndex = finishIndex,
		}
	end

	---Menjalankan fungsi `hydrate`.
	---@param profile any Nilai parameter `profile`.
	---@param startIndex any Nilai parameter `startIndex`.
	---@param finishIndex any Nilai parameter `finishIndex`.
	function StateFactory.hydrate(profile, startIndex: number, finishIndex: number?)
		local state = StateFactory.make(startIndex, finishIndex)
		if profile then
			state.bestTime = profile.Data.bestTime or state.bestTime
			state.peakIndex = profile.Data.peakIndex or state.peakIndex
			state.summitCount = profile.Data.summitCount or state.summitCount
			state.index = profile.Data.lastIndex or state.index
		end
		if finishIndex and state.index == finishIndex then
			state.lapActive = false
		end
		return state
	end

	---Menjalankan fungsi `resetToStart`.
	---@param state any Nilai parameter `state`.
	---@param startIndex any Nilai parameter `startIndex`.
	function StateFactory.resetToStart(state, startIndex: number)
		state.index = startIndex
		state.startTime = os.clock()
		state.lapActive = true
		return state
	end

	__module = StateFactory

	if type(__module) == "table" then
		__module.__source = "Modules/Checkpoint/StateFactory.luau"
	end
	Core.Modules.Checkpoint.StateFactory = __module
end

---@class CoreModulesCheckpointStateManager
---@field __source string Path sumber module `Modules/Checkpoint/StateManager.luau`.
---@field _states any Member private `_states` dari `Modules/Checkpoint/StateManager.luau`.
---@field finishIndex any Member public `finishIndex` dari `Modules/Checkpoint/StateManager.luau`.
---@field startIndex any Member public `startIndex` dari `Modules/Checkpoint/StateManager.luau`.
Core.Modules.Checkpoint.StateManager = Core.Modules.Checkpoint.StateManager or {}
do
	local __module = nil
	local PlayerState = Core.Modules.Checkpoint.PlayerState

	local StateManager = {}
	StateManager.__index = StateManager

	---Menjalankan fungsi `new`.
	---@param startIndex any Nilai parameter `startIndex`.
	---@param finishIndex any Nilai parameter `finishIndex`.
	---@return any result Hasil dari fungsi `new`.
	function StateManager.new(startIndex, finishIndex)
		local self = setmetatable({}, StateManager)
		self.startIndex = startIndex
		self.finishIndex = finishIndex
		self._states = {}
		return self
	end

	---Menjalankan fungsi `create`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `create`.
	function StateManager:create(player)
		local state = PlayerState.new(self.startIndex, self.finishIndex)
		self._states[player] = state
		return state
	end

	---Menjalankan fungsi `get`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `get`.
	function StateManager:get(player)
		return self._states[player]
	end

	---Menjalankan fungsi `remove`.
	---@param player any Nilai parameter `player`.
	function StateManager:remove(player)
		self._states[player] = nil
	end

	---Menjalankan fungsi `applyProfile`.
	---@param state any Nilai parameter `state`.
	---@param profile any Nilai parameter `profile`.
	function StateManager:applyProfile(state, profile)
		if not profile then return end
		state.bestTime = profile.Data.bestTime or state.bestTime
		state.peakIndex = profile.Data.peakIndex or state.peakIndex
		state.summitCount = profile.Data.summitCount or state.summitCount
		state.index = profile.Data.lastIndex or state.index
		if state.finishIndex and state.index == state.finishIndex then
			state.lapActive = false
		end
	end

	__module = StateManager

	if type(__module) == "table" then
		__module.__source = "Modules/Checkpoint/StateManager.luau"
	end
	Core.Modules.Checkpoint.StateManager = __module
end

---@class CoreModulesDonationsDonationsFormatter
---@field __source string Path sumber module `Modules/Donations/DonationsFormatter.luau`.
---@field formatAmountPlain any Member public `formatAmountPlain` dari `Modules/Donations/DonationsFormatter.luau`.
---@field formatNumber any Member public `formatNumber` dari `Modules/Donations/DonationsFormatter.luau`.
---@field formatRobux any Member public `formatRobux` dari `Modules/Donations/DonationsFormatter.luau`.
Core.Modules.Donations.DonationsFormatter = Core.Modules.Donations.DonationsFormatter or {}
do
	local __module = nil
	local Formatter = {}

	---Menjalankan fungsi `formatNumber`.
	---@param n any Nilai parameter `n`.
	function Formatter.formatNumber(n)
		local str = tostring(math.floor(n or 0))
		local rev = string.reverse(str)
		local grouped = string.gsub(rev, "(%d%d%d)", "%1,")
		grouped = string.gsub(grouped, ",$", "")
		return string.reverse(grouped)
	end

	---Menjalankan fungsi `formatRobux`.
	---@param n any Nilai parameter `n`.
	function Formatter.formatRobux(n)
		return "? " .. Formatter.formatNumber(n)
	end

	---Menjalankan fungsi `formatAmountPlain`.
	---@param n any Nilai parameter `n`.
	function Formatter.formatAmountPlain(n)
		return Formatter.formatNumber(n)
	end

	__module = Formatter

	if type(__module) == "table" then
		__module.__source = "Modules/Donations/DonationsFormatter.luau"
	end
	Core.Modules.Donations.DonationsFormatter = __module
end

---@class CoreModulesDonationsDonationsListRenderer
---@field __source string Path sumber module `Modules/Donations/DonationsListRenderer.luau`.
Core.Modules.Donations.DonationsListRenderer = Core.Modules.Donations.DonationsListRenderer or {}
do
	local __module = nil
	local ListRenderer = {}

	---@private
	---Menjalankan fungsi `clearList`.
	---@param listFrame any Nilai parameter `listFrame`.
	local function clearList(listFrame)
		for _, child in ipairs(listFrame:GetChildren()) do
			if child:IsA("Frame") and child.Name == "DonationEntry" then
				child:Destroy()
			end
		end
	end

	---Menjalankan fungsi `render`.
	---@param listFrame any Nilai parameter `listFrame`.
	---@param template any Nilai parameter `template`.
	---@param entries any Nilai parameter `entries`.
	---@param formatter any Nilai parameter `formatter`.
	function ListRenderer.render(listFrame, template, entries, formatter)
		if not (listFrame and template) then return end
		clearList(listFrame)

		local emptyState = listFrame.Parent and listFrame.Parent:FindFirstChild("EmptyState")
		if emptyState then
			emptyState.Visible = (#entries == 0)
		end

		for rank, entry in ipairs(entries) do
			local item = template:Clone()
			item.Name = "DonationEntry"
			item.Visible = true
			item.LayoutOrder = rank
			item.Parent = listFrame

			local rankLabel = item:FindFirstChild("Rank")
			if rankLabel and rankLabel:IsA("TextLabel") then
				rankLabel.Text = "#" .. tostring(rank)
			end

			local nameLabel = item:FindFirstChild("Name")
			if nameLabel and nameLabel:IsA("TextLabel") then
				if entry.DisplayName and entry.DisplayName ~= "" then
					nameLabel.Text = entry.DisplayName
				else
					nameLabel.Text = entry.Username or "Unknown"
				end
			end

			local avatar = item:FindFirstChild("Avatar")
			if avatar and avatar:IsA("ImageLabel") and entry.Thumbnail then
				avatar.Image = entry.Thumbnail
				avatar.Visible = true
			end

			local right = item:FindFirstChild("Right")
			local amountLabel = right and right:FindFirstChild("Amount")
			if amountLabel and amountLabel:IsA("TextLabel") then
				amountLabel.Text = formatter.formatAmountPlain(entry.Amount or 0)
			end
		end
	end

	__module = ListRenderer

	if type(__module) == "table" then
		__module.__source = "Modules/Donations/DonationsListRenderer.luau"
	end
	Core.Modules.Donations.DonationsListRenderer = __module
end

---@class CoreModulesDonationsDonationsPodium
---@field __source string Path sumber module `Modules/Donations/DonationsPodium.luau`.
---@field _config any Member private `_config` dari `Modules/Donations/DonationsPodium.luau`.
---@field _formatter any Member private `_formatter` dari `Modules/Donations/DonationsPodium.luau`.
---@field _slots any Member private `_slots` dari `Modules/Donations/DonationsPodium.luau`.
Core.Modules.Donations.DonationsPodium = Core.Modules.Donations.DonationsPodium or {}
do
	local __module = nil
	local Workspace = game:GetService("Workspace")

	local PodiumHelpers = Core.Modules.Donations.PodiumHelpers
	local PodiumBuilder = Core.Modules.Donations.PodiumHelpers.PodiumBuilder
	local RigBuilder = Core.Modules.Donations.PodiumHelpers.RigBuilder

	local Podium = {}
	Podium.__index = Podium

	---Menjalankan fungsi `new`.
	---@param podiumRoot any Nilai parameter `podiumRoot`.
	---@param config any Nilai parameter `config`.
	---@param formatter any Nilai parameter `formatter`.
	---@return any result Hasil dari fungsi `new`.
	function Podium.new(podiumRoot, config, formatter)
		local self = setmetatable({}, Podium)
		self._config = config or {}
		self._formatter = formatter
		self._slots = {}

		if podiumRoot then
			for i = 1, 3 do
				local slotRoot, rigTemplate, configPart, gridPart, tags = PodiumBuilder.resolveSlotObjects(podiumRoot, i)
				local frame = PodiumBuilder.findFrameFromTags(tags)
				local rank = frame and frame:FindFirstChild("Rank")
				local robux = frame and frame:FindFirstChild("Robux")
				local username = frame and frame:FindFirstChild("Username")
				self._slots[i] = {
					Rank = rank,
					Robux = robux,
					Username = username,
					SlotRoot = slotRoot,
					RigTemplate = rigTemplate,
					ConfigPart = configPart,
					GridPart = gridPart,
					OriginalParent = rigTemplate and rigTemplate.Parent or slotRoot or nil,
					OriginalPivot = PodiumBuilder.getPivotOf(rigTemplate),
					OriginalRootCFrame = PodiumBuilder.getRootCFrameOf(rigTemplate),
					OriginalBottomY = PodiumBuilder.getBottomYOf(rigTemplate),
					PartState = rigTemplate and PodiumBuilder.captureModelState(rigTemplate) or nil,
					CurrentUserId = nil,
					TagsTemplate = tags and tags:Clone() or nil,
					CurrentRig = nil,
					CurrentTrack = nil,
				}
			end
		end
		return self
	end

	---@private
	---Menjalankan fungsi `_cleanupSlotTemplates`.
	---@param slot any Nilai parameter `slot`.
	function Podium:_cleanupSlotTemplates(slot)
		if not slot then
			return
		end

		if slot.RigTemplate and slot.RigTemplate.Parent then
			slot.RigTemplate:Destroy()
		end
		slot.RigTemplate = nil

		if slot.ConfigPart and slot.ConfigPart.Parent then
			slot.ConfigPart:Destroy()
		end
		slot.ConfigPart = nil

		if slot.GridPart and slot.GridPart.Parent then
			slot.GridPart:Destroy()
		end
		slot.GridPart = nil
	end

	---@private
	---Menjalankan fungsi `_clearExistingRig`.
	---@param slot any Nilai parameter `slot`.
	function Podium:_clearExistingRig(slot)
		if not slot then return end
		if slot.CurrentTrack then
			slot.CurrentTrack:Stop()
			slot.CurrentTrack:Destroy()
			slot.CurrentTrack = nil
		end
		if slot.CurrentRig and slot.CurrentRig.Parent then
			slot.CurrentRig:Destroy()
		end
		slot.CurrentRig = nil
	end

	---@private
	---Menjalankan fungsi `_attachTagsToRig`.
	---@param slot any Nilai parameter `slot`.
	---@param rig any Nilai parameter `rig`.
	function Podium:_attachTagsToRig(slot, rig)
		if not slot or not rig then return end
		if not slot.TagsTemplate then return end
		local head = rig:FindFirstChild("Head")
		if not head then return end
		for _, child in ipairs(head:GetChildren()) do
			if child:IsA("BillboardGui") and child.Name == slot.TagsTemplate.Name then
				child:Destroy()
			end
		end
		local tags = PodiumBuilder.cloneTagsGui(slot.TagsTemplate)
		if not tags then
			return
		end
		tags.Enabled = true
		tags.Parent = head
		local frame = tags:FindFirstChild("Frame")
		slot.Rank = frame and frame:FindFirstChild("Rank") or slot.Rank
		slot.Robux = frame and frame:FindFirstChild("Robux") or slot.Robux
		slot.Username = frame and frame:FindFirstChild("Username") or slot.Username
	end

	---@private
	---Menjalankan fungsi `_ensureRigForUser`.
	---@param slot any Nilai parameter `slot`.
	---@param userId any Nilai parameter `userId`.
	---@param rank any Nilai parameter `rank`.
	function Podium:_ensureRigForUser(slot, userId, rank)
		if not slot then return end
		if slot.CurrentUserId == userId then
			return
		end
		slot.CurrentUserId = userId
		self:_clearExistingRig(slot)
		local rig = RigBuilder.createForUser(userId)
		if rig then
			rig.Name = "PlayerRig"
			rig.Parent = slot.OriginalParent or Workspace
			if slot.OriginalPivot then
				rig:PivotTo(slot.OriginalPivot)
			end
			for _, desc in ipairs(rig:GetDescendants()) do
				if desc:IsA("BasePart") then
					desc.AssemblyLinearVelocity = Vector3.zero
					desc.AssemblyAngularVelocity = Vector3.zero
					desc.Anchored = false
					desc.CanCollide = false
				end
			end
			local hrp = rig:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				if slot.OriginalRootCFrame then
					hrp.CFrame = slot.OriginalRootCFrame
				end
				hrp.Anchored = true
			end
			if slot.OriginalBottomY then
				local currentBottomY = PodiumBuilder.getBottomYOf(rig)
				if currentBottomY then
					local deltaY = slot.OriginalBottomY - currentBottomY
					if math.abs(deltaY) > 0.001 then
						rig:PivotTo(rig:GetPivot() + Vector3.new(0, deltaY, 0))
					end
				end
			end
			self:_attachTagsToRig(slot, rig)
			local humanoid = rig:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local animator = humanoid:FindFirstChildOfClass("Animator")
				if not animator then
					animator = Instance.new("Animator")
					animator.Parent = humanoid
				end
				local animId = PodiumBuilder.getAnimId(self._config, rank, humanoid.RigType)
				if animId and animId ~= "" then
					local anim = Instance.new("Animation")
					anim.AnimationId = animId
					local track = animator:LoadAnimation(anim)
					track.Looped = true
					track.Priority = Enum.AnimationPriority.Action
					track:Play()
					slot.CurrentTrack = track
					anim:Destroy()
				end
			end
			slot.CurrentRig = rig
			self:_cleanupSlotTemplates(slot)
		end
	end

	---Menjalankan fungsi `update`.
	---@param entries any Nilai parameter `entries`.
	function Podium:update(entries)
		for i = 1, 3 do
			local slot = self._slots[i]
			if slot then
				if slot.Rank and slot.Rank:IsA("TextLabel") then
					slot.Rank.Text = "#" .. tostring(i)
					local rankColor = PodiumBuilder.getRankColor(self._config, i)
					if rankColor then
						slot.Rank.TextColor3 = rankColor
					end
				end
				local entry = entries[i]
				if entry then
					self:_ensureRigForUser(slot, entry.UserId, i)
					if slot.Username and slot.Username:IsA("TextLabel") then
						local username = entry.Username or "Unknown"
						local display = entry.DisplayName
						if display and display ~= "" and display ~= username then
							slot.Username.Text = display .. " (@" .. username .. ")"
						else
							slot.Username.Text = "@" .. username
						end
					end
					if slot.Robux and slot.Robux:IsA("TextLabel") then
						slot.Robux.Text = self._formatter.formatRobux(entry.Amount or 0)
					end
				else
					slot.CurrentUserId = nil
					self:_clearExistingRig(slot)
					self:_cleanupSlotTemplates(slot)
					if slot.Username and slot.Username:IsA("TextLabel") then
						slot.Username.Text = "-"
					end
					if slot.Robux and slot.Robux:IsA("TextLabel") then
						slot.Robux.Text = "0"
					end
				end
			end
		end
	end

	__module = Podium

	if type(__module) == "table" then
		__module.__source = "Modules/Donations/DonationsPodium.luau"
	end
	Core.Modules.Donations.DonationsPodium = __module
end

---@class CoreModulesDonationsDonationsProfileCache
---@field __source string Path sumber module `Modules/Donations/DonationsProfileCache.luau`.
---@field _displayNameCache any Member private `_displayNameCache` dari `Modules/Donations/DonationsProfileCache.luau`.
---@field _nameCache any Member private `_nameCache` dari `Modules/Donations/DonationsProfileCache.luau`.
---@field _thumbCache any Member private `_thumbCache` dari `Modules/Donations/DonationsProfileCache.luau`.
Core.Modules.Donations.DonationsProfileCache = Core.Modules.Donations.DonationsProfileCache or {}
do
	local __module = nil
	local Players = game:GetService("Players")

	local ProfileCache = {}
	ProfileCache.__index = ProfileCache

	---Menjalankan fungsi `new`.
	---@return any result Hasil dari fungsi `new`.
	function ProfileCache.new()
		local self = setmetatable({}, ProfileCache)
		self._nameCache = {}
		self._displayNameCache = {}
		self._thumbCache = {}
		return self
	end

	---Menjalankan fungsi `getName`.
	---@param userId any Nilai parameter `userId`.
	---@return any result Hasil dari fungsi `getName`.
	function ProfileCache:getName(userId)
		if self._nameCache[userId] then
			return self._nameCache[userId]
		end
		local ok, name = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		if ok and name then
			self._nameCache[userId] = name
			return name
		end
		return "Unknown"
	end

	---Menjalankan fungsi `getDisplayName`.
	---@param userId any Nilai parameter `userId`.
	---@return any result Hasil dari fungsi `getDisplayName`.
	function ProfileCache:getDisplayName(userId)
		if self._displayNameCache[userId] then
			return self._displayNameCache[userId]
		end
		local plr = Players:GetPlayerByUserId(userId)
		if plr and plr.DisplayName and plr.DisplayName ~= "" then
			self._displayNameCache[userId] = plr.DisplayName
			return plr.DisplayName
		end
		local ok, name = pcall(function()
			return Players:GetDisplayNameFromUserIdAsync(userId)
		end)
		if ok and name then
			self._displayNameCache[userId] = name
			return name
		end
		return nil
	end

	---Menjalankan fungsi `getThumbnail`.
	---@param userId any Nilai parameter `userId`.
	---@return any result Hasil dari fungsi `getThumbnail`.
	function ProfileCache:getThumbnail(userId)
		if self._thumbCache[userId] then
			return self._thumbCache[userId]
		end
		local ok, content = pcall(function()
			local thumb, _ = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			return thumb
		end)
		if ok and content then
			self._thumbCache[userId] = content
			return content
		end
		return nil
	end

	__module = ProfileCache

	if type(__module) == "table" then
		__module.__source = "Modules/Donations/DonationsProfileCache.luau"
	end
	Core.Modules.Donations.DonationsProfileCache = __module
end

---@class CoreModulesDonationsDonationsUiResolver
---@field __source string Path sumber module `Modules/Donations/DonationsUiResolver.luau`.
---@field resolve any Member public `resolve` dari `Modules/Donations/DonationsUiResolver.luau`.
Core.Modules.Donations.DonationsUiResolver = Core.Modules.Donations.DonationsUiResolver or {}
do
	local __module = nil
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Workspace = game:GetService("Workspace")

	local Resolver = {}

	---@private
	---Menjalankan fungsi `find`.
	---@param parent any Nilai parameter `parent`.
	---@param name any Nilai parameter `name`.
	---@param timeout any Nilai parameter `timeout`.
	local function find(parent, name, timeout)
		if not parent then return nil end
		local ok, obj = pcall(function()
			return parent:WaitForChild(name, timeout or 60)
		end)
		return ok and obj or nil
	end

	---Menjalankan fungsi `resolve`.
	function Resolver.resolve()
		local maps = find(Workspace, "JaleMaps", 10)
		local leaderboard = maps and find(maps, "Leaderboard", 10)
		local global = leaderboard and find(leaderboard, "GlobalDonations", 10)
		local surfaceGui = global and find(global, "SurfaceGui", 10)
		local list = surfaceGui and find(surfaceGui, "ScrollingFrame", 10)

		local assets = ReplicatedStorage.Shared:FindFirstChild("Assets")
		local donations = assets and assets:FindFirstChild("Donations")
		local template = donations and donations:FindFirstChild("Leaderboard")

		local podium = global and find(global, "Podium", 10)

		if list and template and template:IsA("Frame") then
			return true, {
				listFrame = list,
				template = template,
				podium = podium,
			}
		end
		return false, "Leaderboard UI not found"
	end

	__module = Resolver

	if type(__module) == "table" then
		__module.__source = "Modules/Donations/DonationsUiResolver.luau"
	end
	Core.Modules.Donations.DonationsUiResolver = __module
end

---@class CoreModulesLeaderboardFilterUtil
---@field __source string Path sumber module `Modules/Leaderboard/FilterUtil.luau`.
Core.Modules.Leaderboard.FilterUtil = Core.Modules.Leaderboard.FilterUtil or {}
do
	local __module = nil
	local FilterUtil = {}

	---@private
	---Menjalankan fungsi `matches`.
	---@param listIds any Nilai parameter `listIds`.
	---@param listNames any Nilai parameter `listNames`.
	---@param userId any Nilai parameter `userId`.
	---@param username any Nilai parameter `username`.
	local function matches(listIds, listNames, userId, username)
		for _, id in ipairs(listIds or {}) do
			if id == userId then
				return true
			end
		end
		if username and username ~= "" then
			local uname = string.lower(username)
			for _, name in ipairs(listNames or {}) do
				if name and name ~= "" and uname == string.lower(name) then
					return true
				end
			end
		end
		return false
	end

	---@private
	---Menjalankan fungsi `getExemptRoles`.
	---@param cfg any Nilai parameter `cfg`.
	---@return any result Hasil dari fungsi `getExemptRoles`.
	local function getExemptRoles(cfg)
		return (cfg and cfg.TitleConfig and cfg.TitleConfig.ExemptRoles)
	end

	---@private
	---Menjalankan fungsi `getSpecialRoles`.
	---@param cfg any Nilai parameter `cfg`.
	---@return any result Hasil dari fungsi `getSpecialRoles`.
	local function getSpecialRoles(cfg)
		return cfg and cfg.TitleConfig and cfg.TitleConfig.SpecialRoles or nil
	end

	---Menjalankan fungsi `isExemptFromLeaderboard`.
	---@param userId any Nilai parameter `userId`.
	---@param username any Nilai parameter `username`.
	---@param cfg any Nilai parameter `cfg`.
	---@return any result Hasil dari fungsi `isExemptFromLeaderboard`.
	function FilterUtil.isExemptFromLeaderboard(userId, username, cfg)
		if not userId then
			return false
		end
		local exempt = getExemptRoles(cfg)
		if exempt.Owner == true then
			if cfg.PlaceOwnerId and userId == cfg.PlaceOwnerId then
				return true
			end
			if game.CreatorType == Enum.CreatorType.User and userId == game.CreatorId then
				return true
			end
		end
		local special = getSpecialRoles(cfg)
		if not special then
			return false
		end
		for _, role in ipairs({"Owner", "Developer", "Admin", "Moderator"}) do
			if exempt[role] ~= true then
				continue
			end
			local spec = special[role]
			if spec and matches(spec.UserIds, spec.Usernames, userId, username) then
				return true
			end
		end
		return false
	end

	---Menjalankan fungsi `isPrivileged`.
	---@param userId any Nilai parameter `userId`.
	---@param username any Nilai parameter `username`.
	---@param cfg any Nilai parameter `cfg`.
	---@return any result Hasil dari fungsi `isPrivileged`.
	function FilterUtil.isPrivileged(userId, username, cfg)
		return FilterUtil.isExemptFromLeaderboard(userId, username, cfg)
	end

	__module = FilterUtil

	if type(__module) == "table" then
		__module.__source = "Modules/Leaderboard/FilterUtil.luau"
	end
	Core.Modules.Leaderboard.FilterUtil = __module
end

---@class CoreModulesLeaderboardLeaderboardFormatter
---@field __source string Path sumber module `Modules/Leaderboard/LeaderboardFormatter.luau`.
---@field formatTime any Member public `formatTime` dari `Modules/Leaderboard/LeaderboardFormatter.luau`.
Core.Modules.Leaderboard.LeaderboardFormatter = Core.Modules.Leaderboard.LeaderboardFormatter or {}
do
	local __module = nil
	local Formatter = {}

	---Menjalankan fungsi `formatTime`.
	---@param seconds any Nilai parameter `seconds`.
	function Formatter.formatTime(seconds)
		if not seconds or seconds <= 0 then
			return "00:00"
		end
		local mins = math.floor(seconds / 60)
		local secs = seconds % 60
		return string.format("%02d:%02d", mins, secs)
	end

	__module = Formatter

	if type(__module) == "table" then
		__module.__source = "Modules/Leaderboard/LeaderboardFormatter.luau"
	end
	Core.Modules.Leaderboard.LeaderboardFormatter = __module
end

---@class CoreModulesLeaderboardLeaderboardListRenderer
---@field __source string Path sumber module `Modules/Leaderboard/LeaderboardListRenderer.luau`.
Core.Modules.Leaderboard.LeaderboardListRenderer = Core.Modules.Leaderboard.LeaderboardListRenderer or {}
do
	local __module = nil
	local Renderer = {}

	---@private
	---Menjalankan fungsi `clearList`.
	---@param list any Nilai parameter `list`.
	local function clearList(list)
		if not list then return end
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
	end

	---Menjalankan fungsi `render`.
	---@param list any Nilai parameter `list`.
	---@param template any Nilai parameter `template`.
	---@param entries any Nilai parameter `entries`.
	---@param profileCache any Nilai parameter `profileCache`.
	function Renderer.render(list, template, entries, profileCache)
		if not (list and template) then return end
		clearList(list)

		local emptyState = list.Parent and list.Parent:FindFirstChild("EmptyState")
		if emptyState then
			emptyState.Visible = (#entries == 0)
		end

		for _, entry in ipairs(entries) do
			local item = template:Clone()
			item.Name = "Item"
			item.Visible = true
			item.Parent = list

			local icon = item:FindFirstChild("Avatar")
			if icon and icon:IsA("ImageLabel") then
				local thumb = profileCache:getThumbnail(entry.UserId)
				if thumb then
					icon.Image = thumb
				end
			end

			local nameLabel = item:FindFirstChild("Name")
			if nameLabel and nameLabel:IsA("TextLabel") then
				nameLabel.Text = profileCache:getDisplayName(entry.UserId)
			end

			local rankLabel = item:FindFirstChild("Rank")
			if rankLabel and rankLabel:IsA("TextLabel") then
				rankLabel.Text = "#" .. tostring(entry.Rank)
			end

			local statsLabel = item:FindFirstChild("Stats")
			if statsLabel and statsLabel:IsA("TextLabel") then
				statsLabel.Text = entry.StatsText
			end
		end
	end

	__module = Renderer

	if type(__module) == "table" then
		__module.__source = "Modules/Leaderboard/LeaderboardListRenderer.luau"
	end
	Core.Modules.Leaderboard.LeaderboardListRenderer = __module
end

---@class CoreModulesLeaderboardLeaderboardProfileCache
---@field __source string Path sumber module `Modules/Leaderboard/LeaderboardProfileCache.luau`.
---@field _nameCache any Member private `_nameCache` dari `Modules/Leaderboard/LeaderboardProfileCache.luau`.
---@field _thumbCache any Member private `_thumbCache` dari `Modules/Leaderboard/LeaderboardProfileCache.luau`.
Core.Modules.Leaderboard.LeaderboardProfileCache = Core.Modules.Leaderboard.LeaderboardProfileCache or {}
do
	local __module = nil
	local Players = game:GetService("Players")

	local ProfileCache = {}
	ProfileCache.__index = ProfileCache

	---Menjalankan fungsi `new`.
	---@return any result Hasil dari fungsi `new`.
	function ProfileCache.new()
		local self = setmetatable({}, ProfileCache)
		self._nameCache = {}
		self._thumbCache = {}
		return self
	end

	---Menjalankan fungsi `getDisplayName`.
	---@param userId any Nilai parameter `userId`.
	---@return any result Hasil dari fungsi `getDisplayName`.
	function ProfileCache:getDisplayName(userId)
		if self._nameCache[userId] then
			return self._nameCache[userId]
		end
		local online = userId and Players:GetPlayerByUserId(userId)
		if online then
			self._nameCache[userId] = online.DisplayName
			return online.DisplayName
		end
		local ok, name = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		if ok and name then
			self._nameCache[userId] = name
			return name
		end
		return "Unknown"
	end

	---Menjalankan fungsi `getThumbnail`.
	---@param userId any Nilai parameter `userId`.
	---@return any result Hasil dari fungsi `getThumbnail`.
	function ProfileCache:getThumbnail(userId)
		if self._thumbCache[userId] then
			return self._thumbCache[userId]
		end
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok and content then
			self._thumbCache[userId] = content
			return content
		end
		return nil
	end

	__module = ProfileCache

	if type(__module) == "table" then
		__module.__source = "Modules/Leaderboard/LeaderboardProfileCache.luau"
	end
	Core.Modules.Leaderboard.LeaderboardProfileCache = __module
end

---@class CoreModulesLeaderboardLeaderboardUiResolver
---@field __source string Path sumber module `Modules/Leaderboard/LeaderboardUiResolver.luau`.
Core.Modules.Leaderboard.LeaderboardUiResolver = Core.Modules.Leaderboard.LeaderboardUiResolver or {}
do
	local __module = nil
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Workspace = game:GetService("Workspace")

	local Resolver = {}

	---@private
	---Menjalankan fungsi `resolveBoard`.
	---@param folder any Nilai parameter `folder`.
	---@param name any Nilai parameter `name`.
	local function resolveBoard(folder, name)
		local part = folder and folder:FindFirstChild(name)
		local surface = part and part:FindFirstChildOfClass("SurfaceGui")
		local list = surface and surface:FindFirstChild("ScrollingFrame")
		if list and list:IsA("ScrollingFrame") then
			return list
		end
		return nil
	end

	---Menjalankan fungsi `resolve`.
	function Resolver.resolve()
		local maps = Workspace:FindFirstChild("JaleMaps")
		local lbFolder = maps and maps:FindFirstChild("Leaderboard")
		local summitList = resolveBoard(lbFolder, "GlobalSummit")
		local speedrunList = resolveBoard(lbFolder, "GlobalSpeedrun")
		local playtimeList = resolveBoard(lbFolder, "GlobalPlaytime")
		local assets = ReplicatedStorage.Shared:FindFirstChild("Assets")
		local templateFolder = assets and assets:FindFirstChild("Leaderboard")
		local template = templateFolder and templateFolder:FindFirstChild("Template")

		if not template then
			return false, "Template not found"
		end

		return true, {
			summitList = summitList,
			speedrunList = speedrunList,
			playtimeList = playtimeList,
			template = template,
		}
	end

	__module = Resolver

	if type(__module) == "table" then
		__module.__source = "Modules/Leaderboard/LeaderboardUiResolver.luau"
	end
	Core.Modules.Leaderboard.LeaderboardUiResolver = __module
end

---@class CoreModulesPhysicsNoPlayerCollision
---@field __source string Path sumber module `Modules/Physics/NoPlayerCollision.luau`.
Core.Modules.Physics.NoPlayerCollision = Core.Modules.Physics.NoPlayerCollision or {}
do
	local __module = nil
	local Players = game:GetService("Players")
	local PhysicsService = game:GetService("PhysicsService")

	local NoPlayerCollision = {}

	local GROUP_NAME = "PlayersNoCollide"
	local CARRY_GROUP = "CarryNoCollide"

	---@private
	---Menjalankan fungsi `ensureGroup`.
	local function ensureGroup()
		pcall(function()
			PhysicsService:RegisterCollisionGroup(GROUP_NAME)
		end)
		pcall(function()
			PhysicsService:CollisionGroupSetCollidable(GROUP_NAME, GROUP_NAME, false)
			PhysicsService:CollisionGroupSetCollidable(GROUP_NAME, "Default", true)
			PhysicsService:CollisionGroupSetCollidable(GROUP_NAME, CARRY_GROUP, false)
		end)
	end

	---@private
	---Menjalankan fungsi `setCharacterGroup`.
	---@param character any Nilai parameter `character`.
	local function setCharacterGroup(character)
		if not character then
			return
		end
		for _, inst in ipairs(character:GetDescendants()) do
			if inst:IsA("BasePart") then
				inst.CollisionGroup = GROUP_NAME
			end
		end
	end

	---@private
	---Menjalankan fungsi `bindCharacter`.
	---@param janitor any Nilai parameter `janitor`.
	---@param character any Nilai parameter `character`.
	local function bindCharacter(janitor, character)
		if not character then
			return
		end
		setCharacterGroup(character)
		janitor:Add(character.DescendantAdded:Connect(function(inst)
			if inst:IsA("BasePart") then
				inst.CollisionGroup = GROUP_NAME
			end
		end), "Disconnect")
	end

	---Menjalankan fungsi `enable`.
	---@param janitor any Nilai parameter `janitor`.
	function NoPlayerCollision.enable(janitor)
		ensureGroup()

		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				bindCharacter(janitor, player.Character)
			end
		end

		if janitor then
			janitor:Add(Players.PlayerAdded:Connect(function(player)
				janitor:Add(player.CharacterAdded:Connect(function(character)
					bindCharacter(janitor, character)
				end), "Disconnect")
			end), "Disconnect")
			janitor:Add(Players.PlayerRemoving:Connect(function(_player)
			end), "Disconnect")
		end
	end

	__module = NoPlayerCollision

	if type(__module) == "table" then
		__module.__source = "Modules/Physics/NoPlayerCollision.luau"
	end
	Core.Modules.Physics.NoPlayerCollision = __module
end

---@class CoreModulesPlayerCommandsPlayerCommandBinder
---@field __source string Path sumber module `Modules/PlayerCommands/PlayerCommandBinder.luau`.
Core.Modules.PlayerCommands.PlayerCommandBinder = Core.Modules.PlayerCommands.PlayerCommandBinder or {}
do
	local __module = nil
	local Players = game:GetService("Players")
	local TextChatService = game:FindService("TextChatService")

	local PlayerCommandBinder = {}

	---@private
	---Menjalankan fungsi `normalize`.
	---@param msg any Nilai parameter `msg`.
	local function normalize(msg)
		if type(msg) ~= "string" then
			return ""
		end
		msg = msg:lower()
		msg = msg:gsub("^%s+", ""):gsub("%s+$", "")
		return msg
	end

	---@private
	---Menjalankan fungsi `parse`.
	---@param message any Nilai parameter `message`.
	local function parse(message)
		local msg = normalize(message)
		if msg == "" then
			return nil
		end
		local first = msg:match("^(%S+)")
		if not first then
			return nil
		end
		if first == "/rejoin" or first == "rejoin" then
			return {action = "rejoin"}
		end
		if first == "/fps" or first == "fps" then
			return {action = "fps"}
		end
		return nil
	end

	---@private
	---Menjalankan fungsi `bindPlayer`.
	---@param service any Nilai parameter `service`.
	---@param janitor any Nilai parameter `janitor`.
	---@param player any Nilai parameter `player`.
	local function bindPlayer(service, janitor, player)
		janitor:Add(player.Chatted:Connect(function(message)
			local cmd = parse(message)
			if cmd then
				service:_handleCommand(player, cmd.action)
			end
		end), "Disconnect")
	end

	---Menjalankan fungsi `bind`.
	---@param service any Nilai parameter `service`.
	---@param janitor any Nilai parameter `janitor`.
	function PlayerCommandBinder.bind(service, janitor)
		local j = janitor or {
			Add = function(_, c)
				return c
			end,
		}

		---@private
		---Menjalankan fungsi `bindTextChatCommands`.
		---@param commandParent any Nilai parameter `commandParent`.
		local function bindTextChatCommands(commandParent)
			if not commandParent then return end
			---@private
			---Menjalankan fungsi `ensureCommand`.
			---@param name any Nilai parameter `name`.
			---@param primary any Nilai parameter `primary`.
			---@param secondary any Nilai parameter `secondary`.
			---@param description any Nilai parameter `description`.
			local function ensureCommand(name, primary, secondary, description)
				local cmd = commandParent:FindFirstChild(name)
				if not cmd then
					cmd = Instance.new("TextChatCommand")
					cmd.Name = name
					cmd.PrimaryAlias = primary
					cmd.Enabled = true
					if secondary then
						pcall(function()
							cmd.SecondaryAlias = {secondary}
						end)
					end
					pcall(function()
						cmd.Description = description
					end)
					cmd.Parent = commandParent
				elseif cmd.Parent ~= commandParent then
					cmd.Parent = commandParent
				end
				return cmd
			end

			local rejoinCmd = ensureCommand("RejoinCommand", "/rejoin", "rejoin", "Rejoin server: /rejoin")
			local fpsCmd = ensureCommand("FpsCommand", "/fps", "fps", "Toggle FPS panel: /fps")

			j:Add(rejoinCmd.Triggered:Connect(function(textSource, _message)
				local player = textSource and Players:GetPlayerByUserId(textSource.UserId)
				if player then
					service:_handleCommand(player, "rejoin")
				end
			end), "Disconnect")

			j:Add(fpsCmd.Triggered:Connect(function(textSource, _message)
				local player = textSource and Players:GetPlayerByUserId(textSource.UserId)
				if player then
					service:_handleCommand(player, "fps")
				end
			end), "Disconnect")
		end

		if TextChatService then
			local existing = TextChatService:FindFirstChild("TextChatCommands")
			if existing then
				bindTextChatCommands(existing)
			else
				j:Add(TextChatService.ChildAdded:Connect(function(child)
					if child.Name == "TextChatCommands" then
						bindTextChatCommands(child)
					end
				end), "Disconnect")
			end
		end

		j:Add(Players.PlayerAdded:Connect(function(player)
			bindPlayer(service, j, player)
		end), "Disconnect")
		for _, player in ipairs(Players:GetPlayers()) do
			bindPlayer(service, j, player)
		end
	end

	__module = PlayerCommandBinder

	if type(__module) == "table" then
		__module.__source = "Modules/PlayerCommands/PlayerCommandBinder.luau"
	end
	Core.Modules.PlayerCommands.PlayerCommandBinder = __module
end

---@class CoreModulesRaceAnnouncer
---@field __source string Path sumber module `Modules/Race/Announcer.luau`.
---@field announceAll any Member public `announceAll` dari `Modules/Race/Announcer.luau`.
---@field new any Member public `new` dari `Modules/Race/Announcer.luau`.
---@field notifyAll any Member public `notifyAll` dari `Modules/Race/Announcer.luau`.
---@field promptJoinAll any Member public `promptJoinAll` dari `Modules/Race/Announcer.luau`.
Core.Modules.Race.Announcer = Core.Modules.Race.Announcer or {}
do
	local __module = nil
	local Players = game:GetService("Players")

	local Announcer = {}
	Announcer.__index = Announcer

	---Menjalankan fungsi `new`.
	---@param service any Nilai parameter `service`.
	---@return any result Hasil dari fungsi `new`.
	function Announcer.new(service)
		return setmetatable({
			_service = service,
		}, Announcer)
	end

	---Menjalankan fungsi `announceAll`.
	---@param text any Nilai parameter `text`.
	---@param secondsLeft any Nilai parameter `secondsLeft`.
	function Announcer:announceAll(text, secondsLeft)
		for _, player in ipairs(Players:GetPlayers()) do
			self._service.Client.Announcement:Fire(player, {
				text = text,
				secondsLeft = secondsLeft,
			})
		end
	end

	---Menjalankan fungsi `notifyAll`.
	---@param title any Nilai parameter `title`.
	---@param message any Nilai parameter `message`.
	---@param kind any Nilai parameter `kind`.
	---@param extra any Nilai parameter `extra`.
	function Announcer:notifyAll(title, message, kind, extra)
		for _, player in ipairs(Players:GetPlayers()) do
			local payload = {
				title = title,
				message = message,
				kind = kind,
			}
			if type(extra) == "table" then
				for key, value in pairs(extra) do
					payload[key] = value
				end
			end
			self._service.Client.Notification:Fire(player, payload)
		end
	end

	---Menjalankan fungsi `promptJoinAll`.
	---@param payload any Nilai parameter `payload`.
	function Announcer:promptJoinAll(payload)
		for _, player in ipairs(Players:GetPlayers()) do
			self._service.Client.JoinPrompt:Fire(player, payload or {})
		end
	end

	__module = Announcer

	if type(__module) == "table" then
		__module.__source = "Modules/Race/Announcer.luau"
	end
	Core.Modules.Race.Announcer = __module
end

---@class CoreModulesRaceBarrierController
---@field __source string Path sumber module `Modules/Race/BarrierController.luau`.
Core.Modules.Race.BarrierController = Core.Modules.Race.BarrierController or {}
do
	local __module = nil
	local BarrierController = {}
	BarrierController.__index = BarrierController

	---Menjalankan fungsi `new`.
	---@param runtimeFolder any Nilai parameter `runtimeFolder`.
	---@return any result Hasil dari fungsi `new`.
	function BarrierController.new(runtimeFolder)
		local self = setmetatable({
			_parts = {},
		}, BarrierController)

		if runtimeFolder then
			for _, descendant in ipairs(runtimeFolder:GetDescendants()) do
				if descendant:IsA("BasePart") and descendant.Name == "Barrier" then
					table.insert(self._parts, descendant)
				end
			end
		end

		return self
	end

	---Menjalankan fungsi `setClosed`.
	---@param closed any Nilai parameter `closed`.
	function BarrierController:setClosed(closed)
		for _, part in ipairs(self._parts) do
			part.CanCollide = closed == true
			part.Transparency = closed == true and 0 or 1
		end
	end

	__module = BarrierController

	if type(__module) == "table" then
		__module.__source = "Modules/Race/BarrierController.luau"
	end
	Core.Modules.Race.BarrierController = __module
end

---@class CoreModulesRaceFlow
---@field __source string Path sumber module `Modules/Race/Flow.luau`.
Core.Modules.Race.Flow = Core.Modules.Race.Flow or {}
do
	local __module = nil
	local Flow = {}
	Flow.__index = Flow
	local INTRO_DELAY_SECONDS = 3

	---Menjalankan fungsi `new`.
	---@param deps any Nilai parameter `deps`.
	---@return any result Hasil dari fungsi `new`.
	function Flow.new(deps)
		return setmetatable({
			_config = deps.config,
			_stateManager = deps.stateManager,
			_runtimeLoader = deps.runtimeLoader,
			_buildRuntimeControllers = deps.buildRuntimeControllers,
			_clearRuntimeControllers = deps.clearRuntimeControllers,
			_getBarriers = deps.getBarriers,
			_announcer = deps.announcer,
			_pushState = deps.pushState,
			_runId = 0,
		}, Flow)
	end

	---@private
	---Menjalankan fungsi `_nextRunId`.
	function Flow:_nextRunId()
		self._runId += 1
		return self._runId
	end

	---@private
	---Menjalankan fungsi `_isCurrent`.
	---@param runId any Nilai parameter `runId`.
	function Flow:_isCurrent(runId)
		return self._runId == runId
	end

	---Menjalankan fungsi `createRace`.
	---@param wins any Nilai parameter `wins`.
	---@param laps any Nilai parameter `laps`.
	---@return any result Hasil dari fungsi `createRace`.
	function Flow:createRace(wins, laps)
		local runId = self:_nextRunId()
		local stateManager = self._stateManager
		local config = self._config

		stateManager:resetSession()
		stateManager:setConfig(wins, laps)
		stateManager:setActive(true)
		stateManager:setStatus(config.Statuses.Preparing)
		stateManager:setJoinWindow(config.JoinWindowSeconds)
		stateManager:setCountdown(0)

		local runtime = self._runtimeLoader:createRuntime()
		if self._buildRuntimeControllers then
			self._buildRuntimeControllers(runtime)
		end

		local barriers = self._getBarriers and self._getBarriers() or nil
		if barriers then
			barriers:setClosed(true)
		end

		self._announcer:notifyAll("Race", "Race join dibuka", "info")
		self._announcer:promptJoinAll({
			title = "Race",
			message = "Accept untuk ikut race sekarang",
		})
		self._pushState()

		task.spawn(function()
			-- Beri waktu intro header client 3 detik sebelum joinWindow mulai berkurang.
			for _ = 1, INTRO_DELAY_SECONDS do
				if not self:_isCurrent(runId) then
					return
				end
				task.wait(1)
			end

			for secondsLeft = config.JoinWindowSeconds, 1, -1 do
				if not self:_isCurrent(runId) then
					return
				end
				stateManager:setJoinWindow(secondsLeft)
				self._pushState()
				task.wait(1)
			end

			if not self:_isCurrent(runId) then
				return
			end

			stateManager:setJoinWindow(0)
			stateManager:setCountdown(0)
			stateManager:setStatus(config.Statuses.Active)
			self._pushState()
			if barriers then
				barriers:setClosed(false)
			end
			self._announcer:notifyAll("Race", "Race dimulai", "success")
		end)

		return true
	end

	---Menjalankan fungsi `cancelRace`.
	function Flow:cancelRace()
		self:_nextRunId()
		local stateManager = self._stateManager
		local barriers = self._getBarriers and self._getBarriers() or nil
		if barriers then
			barriers:setClosed(true)
		end

		self._runtimeLoader:destroyRuntime()
		if self._clearRuntimeControllers then
			self._clearRuntimeControllers()
		end

		stateManager:resetSession()
		stateManager:setStatus(self._config.Statuses.Inactive)
		self._pushState()
		return true
	end

	---Menjalankan fungsi `finishRace`.
	function Flow:finishRace()
		local cleanupRunId = self:_nextRunId()
		local stateManager = self._stateManager
		local barriers = self._getBarriers and self._getBarriers() or nil
		local currentState = stateManager:get()
		local winner = stateManager.getWinner and stateManager:getWinner() or nil

		stateManager:setActive(false)
		stateManager:setStatus(self._config.Statuses.Finished)
		if barriers then
			barriers:setClosed(true)
		end
		self._pushState()
		self._announcer:notifyAll("Race", "Race selesai", "success", {
			topDisplayName = winner and (winner.displayName or winner.name) or nil,
			maxWins = currentState and currentState.maxWins or 0,
		})

		task.delay(self._config.CleanupDelaySeconds, function()
			if not self:_isCurrent(cleanupRunId) then
				return
			end
			self._runtimeLoader:destroyRuntime()
			if self._clearRuntimeControllers then
				self._clearRuntimeControllers()
			end
			stateManager:resetSession()
			stateManager:setStatus(self._config.Statuses.Inactive)
			self._pushState()
		end)

		return true
	end

	---Menjalankan fungsi `tryAutoFinish`.
	function Flow:tryAutoFinish()
		if self._stateManager:allFinished() then
			self:finishRace()
			return true
		end
		return false
	end

	__module = Flow

	if type(__module) == "table" then
		__module.__source = "Modules/Race/Flow.luau"
	end
	Core.Modules.Race.Flow = __module
end

---@class CoreModulesRaceJoinRequestHandler
---@field __source string Path sumber module `Modules/Race/JoinRequestHandler.luau`.
Core.Modules.Race.JoinRequestHandler = Core.Modules.Race.JoinRequestHandler or {}
do
	local __module = nil
	local ServerScriptService = game:GetService("ServerScriptService")

	local RaceConfig = require(ServerScriptService.Server.Config.RaceConfig)

	local JoinRequestHandler = {}
	JoinRequestHandler.__index = JoinRequestHandler

	---Menjalankan fungsi `new`.
	---@param deps any Nilai parameter `deps`.
	---@return any result Hasil dari fungsi `new`.
	function JoinRequestHandler.new(deps)
		return setmetatable({
			_stateManager = deps.stateManager,
			_runtimeLoader = deps.runtimeLoader,
			_spawnResolver = deps.spawnResolver,
			_pushState = deps.pushState,
			_resetProgress = deps.resetProgress,
		}, JoinRequestHandler)
	end

	---Menjalankan fungsi `setSpawnResolver`.
	---@param spawnResolver any Nilai parameter `spawnResolver`.
	function JoinRequestHandler:setSpawnResolver(spawnResolver)
		self._spawnResolver = spawnResolver
	end

	---Menjalankan fungsi `accept`.
	---@param player any Nilai parameter `player`.
	function JoinRequestHandler:accept(player)
		local state = self._stateManager:get()
		if not state.active or state.status ~= RaceConfig.Statuses.Preparing then
			return false, "RaceClosed"
		end
		if not self._runtimeLoader:getRuntime() then
			return false, "RuntimeMissing"
		end
		if not self._spawnResolver then
			return false, "SpawnResolverMissing"
		end

		local resetOk = true
		if self._resetProgress then
			resetOk = self._resetProgress(player)
		end
		if resetOk == false then
			return false, "ResetFailed"
		end

		local ok, reason = self._stateManager:addPlayer(player)
		if ok ~= true then
			return false, reason
		end

		local teleported, teleportReason = self._spawnResolver:teleport(player)
		if teleported ~= true then
			self._stateManager:removePlayer(player.UserId)
			return false, teleportReason
		end

		self._pushState()
		return true
	end

	__module = JoinRequestHandler

	if type(__module) == "table" then
		__module.__source = "Modules/Race/JoinRequestHandler.luau"
	end
	Core.Modules.Race.JoinRequestHandler = __module
end

---@class CoreModulesRacePlayerBinder
---@field __source string Path sumber module `Modules/Race/PlayerBinder.luau`.
---@field bind any Member public `bind` dari `Modules/Race/PlayerBinder.luau`.
Core.Modules.Race.PlayerBinder = Core.Modules.Race.PlayerBinder or {}
do
	local __module = nil
	local PlayerBinder = {}

	---Menjalankan fungsi `bind`.
	---@param service any Nilai parameter `service`.
	---@param players any Nilai parameter `players`.
	---@param janitor any Nilai parameter `janitor`.
	function PlayerBinder.bind(service, players, janitor)
		for _, player in ipairs(players:GetPlayers()) do
			service:_onPlayerAdded(player)
		end

		janitor:Add(players.PlayerAdded:Connect(function(player)
			service:_onPlayerAdded(player)
		end), "Disconnect")

		janitor:Add(players.PlayerRemoving:Connect(function(player)
			service:_onPlayerRemoving(player)
		end), "Disconnect")
	end

	__module = PlayerBinder

	if type(__module) == "table" then
		__module.__source = "Modules/Race/PlayerBinder.luau"
	end
	Core.Modules.Race.PlayerBinder = __module
end

---@class CoreModulesRaceRuntimeLoader
---@field __source string Path sumber module `Modules/Race/RuntimeLoader.luau`.
Core.Modules.Race.RuntimeLoader = Core.Modules.Race.RuntimeLoader or {}
do
	local __module = nil
	local Workspace = game:GetService("Workspace")
	local ServerScriptService = game:GetService("ServerScriptService")

	local RaceConfig = require(ServerScriptService.Server.Config.RaceConfig)

	local RuntimeLoader = {}
	RuntimeLoader.__index = RuntimeLoader

	---Menjalankan fungsi `new`.
	---@param templateFolder any Nilai parameter `templateFolder`.
	---@return any result Hasil dari fungsi `new`.
	function RuntimeLoader.new(templateFolder)
		return setmetatable({
			_template = templateFolder,
			_runtime = nil,
		}, RuntimeLoader)
	end

	---Menjalankan fungsi `createRuntime`.
	---@return any result Hasil dari fungsi `createRuntime`.
	function RuntimeLoader:createRuntime()
		self:destroyRuntime()
		if not self._template then
			return nil
		end

		local runtime = self._template:Clone()
		runtime.Name = RaceConfig.RuntimeName or "RaceRuntime"
		runtime.Parent = Workspace
		self._runtime = runtime
		return runtime
	end

	---Menjalankan fungsi `getRuntime`.
	---@return any result Hasil dari fungsi `getRuntime`.
	function RuntimeLoader:getRuntime()
		return self._runtime
	end

	---Menjalankan fungsi `destroyRuntime`.
	function RuntimeLoader:destroyRuntime()
		if self._runtime then
			self._runtime:Destroy()
			self._runtime = nil
		end
	end

	__module = RuntimeLoader

	if type(__module) == "table" then
		__module.__source = "Modules/Race/RuntimeLoader.luau"
	end
	Core.Modules.Race.RuntimeLoader = __module
end

---@class CoreModulesRaceSerializer
---@field __source string Path sumber module `Modules/Race/Serializer.luau`.
---@field serialize any Member public `serialize` dari `Modules/Race/Serializer.luau`.
Core.Modules.Race.Serializer = Core.Modules.Race.Serializer or {}
do
	local __module = nil
	local Serializer = {}

	---Menjalankan fungsi `serialize`.
	---@param state any Nilai parameter `state`.
	function Serializer.serialize(state)
		local racers = {}
		local byUserId = {}
		local finishedCount = 0
		for _, racer in ipairs(state.joinedPlayers or {}) do
			local item = {
				userId = racer.userId,
				name = racer.name,
				displayName = racer.displayName,
				lapCount = racer.lapCount or 0,
				finished = racer.finished == true,
				status = racer.status or "Joined",
			}
			if item.finished then
				finishedCount += 1
			end
			table.insert(racers, item)
			byUserId[item.userId] = item
		end

		table.sort(racers, function(a, b)
			local aName = a.displayName or a.name or ""
			local bName = b.displayName or b.name or ""
			return aName < bName
		end)

		local winnerUserId = (state.finishedPlayers and state.finishedPlayers[1]) or nil
		local winner = winnerUserId and byUserId[winnerUserId] or nil
		local latestFinishedUserId = state.finishedPlayers and state.finishedPlayers[#state.finishedPlayers] or nil
		local latestFinished = latestFinishedUserId and byUserId[latestFinishedUserId] or nil

		return {
			active = state.active == true,
			status = state.status,
			totalJoins = state.totalJoins or 0,
			maxWins = state.maxWins or 0,
			laps = state.laps or 0,
			countdown = state.countdown or 0,
			joinWindow = state.joinWindow or 0,
			playerCount = #racers,
			finishedCount = finishedCount,
			joinedPlayers = racers,
			winnerUserId = winnerUserId,
			winnerDisplayName = winner and (winner.displayName or winner.name) or nil,
			latestFinishedUserId = latestFinishedUserId,
			latestFinishedDisplayName = latestFinished and (latestFinished.displayName or latestFinished.name) or nil,
			latestFinishedPlace = finishedCount,
		}
	end

	__module = Serializer

	if type(__module) == "table" then
		__module.__source = "Modules/Race/Serializer.luau"
	end
	Core.Modules.Race.Serializer = __module
end

---@class CoreModulesRaceSpawnResolver
---@field __source string Path sumber module `Modules/Race/SpawnResolver.luau`.
---@field _spawns any Member private `_spawns` dari `Modules/Race/SpawnResolver.luau`.
Core.Modules.Race.SpawnResolver = Core.Modules.Race.SpawnResolver or {}
do
	local __module = nil
	local SpawnResolver = {}
	SpawnResolver.__index = SpawnResolver

	---Menjalankan fungsi `new`.
	---@param runtimeFolder any Nilai parameter `runtimeFolder`.
	---@return any result Hasil dari fungsi `new`.
	function SpawnResolver.new(runtimeFolder)
		local self = setmetatable({
			_spawns = {},
		}, SpawnResolver)

		if runtimeFolder then
			for _, descendant in ipairs(runtimeFolder:GetDescendants()) do
				if descendant:IsA("BasePart") and descendant.Name == "Spawns" then
					table.insert(self._spawns, descendant)
				end
			end
		end

		return self
	end

	---Menjalankan fungsi `getRandom`.
	---@return any result Hasil dari fungsi `getRandom`.
	function SpawnResolver:getRandom()
		if #self._spawns == 0 then
			return nil
		end
		return self._spawns[math.random(1, #self._spawns)]
	end

	---Menjalankan fungsi `teleport`.
	---@param player any Nilai parameter `player`.
	function SpawnResolver:teleport(player)
		if not player then
			return false, "InvalidPlayer"
		end

		local spawnPart = self:getRandom()
		if not spawnPart then
			return false, "SpawnNotFound"
		end

		local character = player.Character
		if not character then
			return false, "CharacterNotFound"
		end

		character:PivotTo(spawnPart.CFrame + Vector3.new(0, 3, 0))
		return true
	end

	__module = SpawnResolver

	if type(__module) == "table" then
		__module.__source = "Modules/Race/SpawnResolver.luau"
	end
	Core.Modules.Race.SpawnResolver = __module
end

---@class CoreModulesRaceStateFactory
---@field __source string Path sumber module `Modules/Race/StateFactory.luau`.
---@field create any Member public `create` dari `Modules/Race/StateFactory.luau`.
Core.Modules.Race.StateFactory = Core.Modules.Race.StateFactory or {}
do
	local __module = nil
	local ServerScriptService = game:GetService("ServerScriptService")

	local RaceConfig = require(ServerScriptService.Server.Config.RaceConfig)

	local StateFactory = {}

	---Menjalankan fungsi `create`.
	---@return any result Hasil dari fungsi `create`.
	function StateFactory.create()
		return {
			active = false,
			status = RaceConfig.Statuses.Inactive,
			totalJoins = 0,
			maxWins = RaceConfig.MinWins,
			laps = RaceConfig.MinLaps,
			countdown = 0,
			joinWindow = 0,
			joinedPlayers = {},
			finishedPlayers = {},
		}
	end

	__module = StateFactory

	if type(__module) == "table" then
		__module.__source = "Modules/Race/StateFactory.luau"
	end
	Core.Modules.Race.StateFactory = __module
end

---@class CoreModulesRaceStateManager
---@field __source string Path sumber module `Modules/Race/StateManager.luau`.
Core.Modules.Race.StateManager = Core.Modules.Race.StateManager or {}
do
	local __module = nil
	local ServerScriptService = game:GetService("ServerScriptService")

	local RaceConfig = require(ServerScriptService.Server.Config.RaceConfig)
	local StateFactory = Core.Modules.Race.StateFactory

	local StateManager = {}
	StateManager.__index = StateManager

	---@private
	---Menjalankan fungsi `parsePositiveInteger`.
	---@param value any Nilai parameter `value`.
	---@param minimum any Nilai parameter `minimum`.
	local function parsePositiveInteger(value, minimum)
		local numeric = tonumber(value)
		if not numeric and type(value) == "string" then
			local extracted = string.match(value, "%d+")
			numeric = extracted and tonumber(extracted) or nil
		end
		local result = math.floor(numeric or minimum or 1)
		if result < (minimum or 1) then
			result = minimum or 1
		end
		return result
	end

	---Menjalankan fungsi `new`.
	---@param initialState any Nilai parameter `initialState`.
	---@return any result Hasil dari fungsi `new`.
	function StateManager.new(initialState)
		return setmetatable({
			_state = initialState or StateFactory.create(),
		}, StateManager)
	end

	---Menjalankan fungsi `get`.
	---@return any result Hasil dari fungsi `get`.
	function StateManager:get()
		return self._state
	end

	---Menjalankan fungsi `getPlayer`.
	---@param userId any Nilai parameter `userId`.
	---@return any result Hasil dari fungsi `getPlayer`.
	function StateManager:getPlayer(userId)
		for _, racer in ipairs(self._state.joinedPlayers) do
			if racer.userId == userId then
				return racer
			end
		end
		return nil
	end

	---Menjalankan fungsi `setConfig`.
	---@param wins any Nilai parameter `wins`.
	---@param laps any Nilai parameter `laps`.
	function StateManager:setConfig(wins, laps)
		self._state.maxWins = parsePositiveInteger(wins, RaceConfig.MinWins)
		self._state.laps = parsePositiveInteger(laps, RaceConfig.MinLaps)
	end

	---Menjalankan fungsi `setStatus`.
	---@param status any Nilai parameter `status`.
	function StateManager:setStatus(status)
		self._state.status = status
	end

	---Menjalankan fungsi `setActive`.
	---@param isActive any Nilai parameter `isActive`.
	function StateManager:setActive(isActive)
		self._state.active = isActive == true
	end

	---Menjalankan fungsi `setCountdown`.
	---@param value any Nilai parameter `value`.
	function StateManager:setCountdown(value)
		self._state.countdown = math.max(tonumber(value) or 0, 0)
	end

	---Menjalankan fungsi `setJoinWindow`.
	---@param value any Nilai parameter `value`.
	function StateManager:setJoinWindow(value)
		self._state.joinWindow = math.max(tonumber(value) or 0, 0)
	end

	---Menjalankan fungsi `resetSession`.
	function StateManager:resetSession()
		local wins = self._state.maxWins
		local laps = self._state.laps
		self._state.active = false
		self._state.status = RaceConfig.Statuses.Inactive
		self._state.totalJoins = 0
		self._state.maxWins = wins or RaceConfig.MinWins
		self._state.laps = laps or RaceConfig.MinLaps
		self._state.countdown = 0
		self._state.joinWindow = 0
		self._state.joinedPlayers = {}
		self._state.finishedPlayers = {}
	end

	---Menjalankan fungsi `addPlayer`.
	---@param player any Nilai parameter `player`.
	function StateManager:addPlayer(player)
		if not player then
			return false, "InvalidPlayer"
		end
		if self:getPlayer(player.UserId) then
			return false, "AlreadyJoined"
		end

		table.insert(self._state.joinedPlayers, {
			userId = player.UserId,
			name = player.Name,
			displayName = player.DisplayName,
			lapCount = 0,
			finished = false,
			status = "Joined",
		})
		self._state.totalJoins += 1
		return true
	end

	---Menjalankan fungsi `removePlayer`.
	---@param userId any Nilai parameter `userId`.
	function StateManager:removePlayer(userId)
		for index, racer in ipairs(self._state.joinedPlayers) do
			if racer.userId == userId then
				table.remove(self._state.joinedPlayers, index)
				break
			end
		end
		for index, finishedUserId in ipairs(self._state.finishedPlayers) do
			if finishedUserId == userId then
				table.remove(self._state.finishedPlayers, index)
				break
			end
		end
	end

	---Menjalankan fungsi `markLap`.
	---@param userId any Nilai parameter `userId`.
	function StateManager:markLap(userId)
		local racer = self:getPlayer(userId)
		if not racer or racer.finished then
			return false, "NotJoined"
		end

		racer.lapCount += 1
		if racer.lapCount >= self._state.laps then
			racer.status = "ReadyToFinish"
		else
			racer.status = "Racing"
		end
		return true
	end

	---Menjalankan fungsi `finishPlayer`.
	---@param userId any Nilai parameter `userId`.
	function StateManager:finishPlayer(userId)
		local racer = self:getPlayer(userId)
		if not racer or racer.finished then
			return false, "NotJoined"
		end
		racer.lapCount += 1
		if racer.lapCount >= self._state.laps then
			racer.finished = true
			racer.status = "Finished"
			table.insert(self._state.finishedPlayers, userId)
			return true, "Finished"
		end

		racer.status = string.format("Lap %d/%d", racer.lapCount, self._state.laps)
		return true, "LapProgressed"
	end

	---Menjalankan fungsi `allFinished`.
	function StateManager:allFinished()
		if #self._state.joinedPlayers == 0 then
			return false
		end
		return #self._state.finishedPlayers >= #self._state.joinedPlayers
	end

	---Menjalankan fungsi `getWinner`.
	---@return any result Hasil dari fungsi `getWinner`.
	function StateManager:getWinner()
		local winnerUserId = self._state.finishedPlayers[1]
		if not winnerUserId then
			return nil
		end
		return self:getPlayer(winnerUserId)
	end

	__module = StateManager

	if type(__module) == "table" then
		__module.__source = "Modules/Race/StateManager.luau"
	end
	Core.Modules.Race.StateManager = __module
end

---@class CoreModulesRaceTriggerBinder
---@field __source string Path sumber module `Modules/Race/TriggerBinder.luau`.
Core.Modules.Race.TriggerBinder = Core.Modules.Race.TriggerBinder or {}
do
	local __module = nil
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")

	local TriggerBinder = {}

	local TOUCH_COOLDOWN = 1

	---@private
	---Menjalankan fungsi `getPlayerFromHit`.
	---@param hit any Nilai parameter `hit`.
	---@return any result Hasil dari fungsi `getPlayerFromHit`.
	local function getPlayerFromHit(hit)
		if not hit then
			return nil
		end
		local model = hit.Parent
		if not model then
			return nil
		end
		return Players:GetPlayerFromCharacter(model)
	end

	---@private
	---Menjalankan fungsi `canTrigger`.
	---@param cache any Nilai parameter `cache`.
	---@param userId any Nilai parameter `userId`.
	---@param key any Nilai parameter `key`.
	local function canTrigger(cache, userId, key)
		cache[key] = cache[key] or {}
		local now = os.clock()
		local last = cache[key][userId]
		if last and (now - last) < TOUCH_COOLDOWN then
			return false
		end
		cache[key][userId] = now
		return true
	end

	---@private
	---Menjalankan fungsi `resolveParts`.
	---@param raceConfig any Nilai parameter `raceConfig`.
	local function resolveParts(raceConfig)
		local triggerPath = raceConfig.TriggerPath or {}
		local raceFolder = nil

		local maps = Workspace:FindFirstChild(triggerPath.Maps or "JaleMaps")
		raceFolder = maps and maps:FindFirstChild(triggerPath.Race or "Race")

		if not raceFolder then
			local checkpoints = maps and maps:FindFirstChild("Checkpoints")
			raceFolder = checkpoints and checkpoints:FindFirstChild(triggerPath.Race or "Race")
		end

		local startPart = raceFolder and raceFolder:FindFirstChild(triggerPath.Start or "Start", true)
		local finishPart = raceFolder and raceFolder:FindFirstChild(triggerPath.Finish or "Finish", true)
		return startPart, finishPart
	end

	---Menjalankan fungsi `bind`.
	---@param service any Nilai parameter `service`.
	---@param janitor any Nilai parameter `janitor`.
	---@param raceConfig any Nilai parameter `raceConfig`.
	function TriggerBinder.bind(service, janitor, raceConfig)
		local startPart, finishPart = resolveParts(raceConfig or {})
		local touchCache = {}

		if startPart and startPart:IsA("BasePart") then
			janitor:Add(startPart.Touched:Connect(function(hit)
				local player = getPlayerFromHit(hit)
				if not player then
					return
				end
				if not canTrigger(touchCache, player.UserId, "Start") then
					return
				end
				service:_onLapTouched(player)
			end), "Disconnect")
		end

		if finishPart and finishPart:IsA("BasePart") then
			janitor:Add(finishPart.Touched:Connect(function(hit)
				local player = getPlayerFromHit(hit)
				if not player then
					return
				end
				if not canTrigger(touchCache, player.UserId, "Finish") then
					return
				end
				service:_onFinishTouched(player)
			end), "Disconnect")
		end
	end

	__module = TriggerBinder

	if type(__module) == "table" then
		__module.__source = "Modules/Race/TriggerBinder.luau"
	end
	Core.Modules.Race.TriggerBinder = __module
end

---@class CoreModulesShopCatalog
---@field __source string Path sumber module `Modules/Shop/Catalog.luau`.
Core.Modules.Shop.Catalog = Core.Modules.Shop.Catalog or {}
do
	local __module = nil
	local Catalog = {}
	Catalog.__index = Catalog

	---@private
	---Menjalankan fungsi `copyTable`.
	---@param source any Nilai parameter `source`.
	local function copyTable(source)
		local result = {}
		for key, value in pairs(source or {}) do
			if type(value) == "table" then
				result[key] = table.clone(value)
			else
				result[key] = value
			end
		end
		return result
	end

	---@private
	---Menjalankan fungsi `normalizeToolName`.
	---@param name any Nilai parameter `name`.
	local function normalizeToolName(name)
		local text = tostring(name or "")
		text = string.gsub(text, "%s+", "")
		return string.lower(text)
	end

	---@private
	---Menjalankan fungsi `findToolInstance`.
	---@param folder any Nilai parameter `folder`.
	---@param toolName any Nilai parameter `toolName`.
	local function findToolInstance(folder, toolName)
		if not (folder and toolName and toolName ~= "") then
			return nil
		end

		local exact = folder:FindFirstChild(toolName)
		if exact and exact:IsA("Tool") then
			return exact
		end

		local normalizedTarget = normalizeToolName(toolName)
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("Tool") and normalizeToolName(child.Name) == normalizedTarget then
				return child
			end
		end

		return nil
	end

	---Menjalankan fungsi `new`.
	---@param serverStorage any Nilai parameter `serverStorage`.
	---@param shopConfig any Nilai parameter `shopConfig`.
	---@param toolsConfig any Nilai parameter `toolsConfig`.
	---@return any result Hasil dari fungsi `new`.
	function Catalog.new(serverStorage, shopConfig, toolsConfig)
		local self = setmetatable({}, Catalog)
		self._serverStorage = serverStorage
		self._shopConfig = shopConfig
		self._toolsConfig = toolsConfig
		self._catalog = {}
		self._catalogByToolId = {}
		self._catalogByGamePassId = {}
		self._catalogByGiftProductId = {}
		return self
	end

	---Menjalankan fungsi `GetToolsFolder`.
	---@return any result Hasil dari fungsi `GetToolsFolder`.
	function Catalog:GetToolsFolder()
		return self._serverStorage:FindFirstChild(self._shopConfig.ToolsFolderName or "ShopTools")
	end

	---Menjalankan fungsi `Rebuild`.
	function Catalog:Rebuild()
		self._catalog = {}
		self._catalogByToolId = {}
		self._catalogByGamePassId = {}
		self._catalogByGiftProductId = {}

		local folder = self:GetToolsFolder()
		if not folder then
			return
		end

		for _, toolConfig in ipairs(self._toolsConfig.Tools or {}) do
			local toolName = tostring(toolConfig.ToolName or toolConfig.Name or "")
			local gamePassId = tonumber(toolConfig.GamePassId)
			local giftProductId = tonumber(toolConfig.GiftProductId)
			local toolInstance = findToolInstance(folder, toolName)

			if toolInstance and toolInstance:IsA("Tool") and gamePassId and gamePassId > 0 then
				local entry = {
					ToolId = tostring(toolConfig.ToolId or toolName),
					ToolName = toolInstance.Name,
					Title = tostring(toolConfig.Title or toolName),
					Icon = tostring(toolConfig.Icon or ""),
					GamePassId = gamePassId,
					GiftProductId = giftProductId and giftProductId > 0 and giftProductId or nil,
				}

				table.insert(self._catalog, entry)
				self._catalogByToolId[entry.ToolId] = entry
				self._catalogByGamePassId[entry.GamePassId] = entry
				if entry.GiftProductId then
					self._catalogByGiftProductId[entry.GiftProductId] = entry
				end
			end
		end

		table.sort(self._catalog, function(a, b)
			return string.lower(a.Title) < string.lower(b.Title)
		end)
	end

	---Menjalankan fungsi `GetPublicCatalog`.
	---@return any result Hasil dari fungsi `GetPublicCatalog`.
	function Catalog:GetPublicCatalog()
		return copyTable(self._catalog)
	end

	---Menjalankan fungsi `GetEntryByToolId`.
	---@param toolId any Nilai parameter `toolId`.
	---@return any result Hasil dari fungsi `GetEntryByToolId`.
	function Catalog:GetEntryByToolId(toolId)
		return self._catalogByToolId[toolId]
	end

	---Menjalankan fungsi `GetEntryByGamePassId`.
	---@param gamePassId any Nilai parameter `gamePassId`.
	---@return any result Hasil dari fungsi `GetEntryByGamePassId`.
	function Catalog:GetEntryByGamePassId(gamePassId)
		return self._catalogByGamePassId[gamePassId]
	end

	---Menjalankan fungsi `GetEntryByGiftProductId`.
	---@param productId any Nilai parameter `productId`.
	---@return any result Hasil dari fungsi `GetEntryByGiftProductId`.
	function Catalog:GetEntryByGiftProductId(productId)
		return self._catalogByGiftProductId[productId]
	end

	---Menjalankan fungsi `GetToolInstance`.
	---@param toolName any Nilai parameter `toolName`.
	---@return any result Hasil dari fungsi `GetToolInstance`.
	function Catalog:GetToolInstance(toolName)
		return findToolInstance(self:GetToolsFolder(), toolName)
	end

	__module = Catalog

	if type(__module) == "table" then
		__module.__source = "Modules/Shop/Catalog.luau"
	end
	Core.Modules.Shop.Catalog = __module
end

---@class CoreModulesShopOwnership
---@field __source string Path sumber module `Modules/Shop/Ownership.luau`.
Core.Modules.Shop.Ownership = Core.Modules.Shop.Ownership or {}
do
	local __module = nil
	local Ownership = {}
	Ownership.__index = Ownership

	---@private
	---Menjalankan fungsi `copyTable`.
	---@param source any Nilai parameter `source`.
	local function copyTable(source)
		local result = {}
		for key, value in pairs(source or {}) do
			if type(value) == "table" then
				result[key] = table.clone(value)
			else
				result[key] = value
			end
		end
		return result
	end

	---Menjalankan fungsi `new`.
	---@param players any Nilai parameter `players`.
	---@param marketplaceService any Nilai parameter `marketplaceService`.
	---@param profiles any Nilai parameter `profiles`.
	---@param catalog any Nilai parameter `catalog`.
	---@param ownedToolsProperty any Nilai parameter `ownedToolsProperty`.
	---@return any result Hasil dari fungsi `new`.
	function Ownership.new(players, marketplaceService, profiles, catalog, ownedToolsProperty)
		local self = setmetatable({}, Ownership)
		self._players = players
		self._marketplaceService = marketplaceService
		self._profiles = profiles
		self._catalog = catalog
		self._ownedToolsProperty = ownedToolsProperty
		return self
	end

	---Menjalankan fungsi `EnsureProfile`.
	---@param player any Nilai parameter `player`.
	function Ownership:EnsureProfile(player)
		if self._profiles:GetProfile(player) then
			return true
		end

		local profile = self._profiles:Load(player)
		return profile ~= nil
	end

	---Menjalankan fungsi `SetOwnedToolsProperty`.
	---@param player any Nilai parameter `player`.
	function Ownership:SetOwnedToolsProperty(player)
		self._ownedToolsProperty:SetFor(player, copyTable(self._profiles:GetOwnedTools(player)))
	end

	---Menjalankan fungsi `GrantToolInstance`.
	---@param player any Nilai parameter `player`.
	---@param entry any Nilai parameter `entry`.
	function Ownership:GrantToolInstance(player, entry)
		if not (player and entry) then
			return
		end

		local sourceTool = self._catalog:GetToolInstance(entry.ToolName)
		if not (sourceTool and sourceTool:IsA("Tool")) then
			return
		end

		local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 10)
		local starterGear = player:FindFirstChildOfClass("StarterGear") or player:WaitForChild("StarterGear", 10)

		---@private
		---Menjalankan fungsi `cloneInto`.
		---@param container any Nilai parameter `container`.
		local function cloneInto(container)
			if not container then
				return
			end

			local existing = container:FindFirstChild(sourceTool.Name)
			if existing then
				existing:Destroy()
			end

			sourceTool:Clone().Parent = container
		end

		cloneInto(backpack)
		cloneInto(starterGear)
	end

	---Menjalankan fungsi `GrantOwnedTools`.
	---@param player any Nilai parameter `player`.
	function Ownership:GrantOwnedTools(player)
		for toolId, isOwned in pairs(self._profiles:GetOwnedTools(player)) do
			if isOwned == true then
				local entry = self._catalog:GetEntryByToolId(toolId)
				if entry then
					self:GrantToolInstance(player, entry)
				end
			end
		end
	end

	---Menjalankan fungsi `GrantToolToPlayer`.
	---@param player any Nilai parameter `player`.
	---@param toolId any Nilai parameter `toolId`.
	function Ownership:GrantToolToPlayer(player, toolId)
		if not player then
			return false
		end

		if not self:EnsureProfile(player) then
			return false
		end

		local added = self._profiles:AddTool(player, toolId)
		if not added then
			return false
		end

		local entry = self._catalog:GetEntryByToolId(toolId)
		if entry then
			self:GrantToolInstance(player, entry)
		end

		self:SetOwnedToolsProperty(player)
		return true
	end

	---Menjalankan fungsi `GrantToolByUserId`.
	---@param userId any Nilai parameter `userId`.
	---@param toolId any Nilai parameter `toolId`.
	function Ownership:GrantToolByUserId(userId, toolId)
		local onlinePlayer = self._players:GetPlayerByUserId(userId)
		if onlinePlayer then
			return self:GrantToolToPlayer(onlinePlayer, toolId)
		end

		return self._profiles:AddToolByUserId(userId, toolId)
	end

	---Menjalankan fungsi `SyncGamePassOwnership`.
	---@param player any Nilai parameter `player`.
	function Ownership:SyncGamePassOwnership(player)
		if not player then
			return
		end

		for _, entry in ipairs(self._catalog:GetPublicCatalog()) do
			if not self._profiles:HasTool(player, entry.ToolId) then
				local ok, owns = pcall(function()
					return self._marketplaceService:UserOwnsGamePassAsync(player.UserId, entry.GamePassId)
				end)

				if ok and owns == true then
					self:GrantToolToPlayer(player, entry.ToolId)
				end
			end
		end
	end

	__module = Ownership

	if type(__module) == "table" then
		__module.__source = "Modules/Shop/Ownership.luau"
	end
	Core.Modules.Shop.Ownership = __module
end

---@class CoreModulesShopPurchases
---@field __source string Path sumber module `Modules/Shop/Purchases.luau`.
---@field _catalog any Member private `_catalog` dari `Modules/Shop/Purchases.luau`.
---@field _ownership any Member private `_ownership` dari `Modules/Shop/Purchases.luau`.
---@field _pendingPurchases any Member private `_pendingPurchases` dari `Modules/Shop/Purchases.luau`.
---@field _players any Member private `_players` dari `Modules/Shop/Purchases.luau`.
---@field _profiles any Member private `_profiles` dari `Modules/Shop/Purchases.luau`.
---@field _purchaseNotice any Member private `_purchaseNotice` dari `Modules/Shop/Purchases.luau`.
Core.Modules.Shop.Purchases = Core.Modules.Shop.Purchases or {}
do
	local __module = nil
	local Purchases = {}
	Purchases.__index = Purchases

	---Menjalankan fungsi `new`.
	---@param players any Nilai parameter `players`.
	---@param profiles any Nilai parameter `profiles`.
	---@param catalog any Nilai parameter `catalog`.
	---@param ownership any Nilai parameter `ownership`.
	---@param purchaseNotice any Nilai parameter `purchaseNotice`.
	---@return any result Hasil dari fungsi `new`.
	function Purchases.new(players, profiles, catalog, ownership, purchaseNotice)
		local self = setmetatable({}, Purchases)
		self._players = players
		self._profiles = profiles
		self._catalog = catalog
		self._ownership = ownership
		self._purchaseNotice = purchaseNotice
		self._pendingPurchases = {}
		return self
	end

	---Menjalankan fungsi `BeginGift`.
	---@param player any Nilai parameter `player`.
	---@param toolId any Nilai parameter `toolId`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	function Purchases:BeginGift(player, toolId, targetUserId)
		if typeof(targetUserId) ~= "number" then
			return false, "InvalidTarget"
		end

		local entry = self._catalog:GetEntryByToolId(toolId)
		if not entry then
			return false, "UnknownTool"
		end

		if not entry.GiftProductId then
			return false, "GiftUnavailable"
		end

		local target = self._players:GetPlayerByUserId(targetUserId)
		if not target then
			return false, "TargetOffline"
		end

		if self._profiles:HasTool(target, toolId) then
			return false, "AlreadyOwned"
		end

		self._pendingPurchases[player.UserId] = {
			ToolId = toolId,
			TargetUserId = targetUserId,
			ProductId = entry.GiftProductId,
		}

		return true
	end

	---Menjalankan fungsi `HandleGamePassPurchase`.
	---@param player any Nilai parameter `player`.
	---@param gamePassId any Nilai parameter `gamePassId`.
	function Purchases:HandleGamePassPurchase(player, gamePassId)
		local entry = self._catalog:GetEntryByGamePassId(gamePassId)
		if entry then
			self._ownership:GrantToolToPlayer(player, entry.ToolId)
		end
	end

	---Menjalankan fungsi `ProcessReceipt`.
	---@param receiptInfo any Nilai parameter `receiptInfo`.
	function Purchases:ProcessReceipt(receiptInfo)
		local entry = self._catalog:GetEntryByGiftProductId(receiptInfo.ProductId)
		if not entry then
			return nil
		end

		local pending = self._pendingPurchases[receiptInfo.PlayerId]
		local targetUserId = receiptInfo.PlayerId
		if pending and pending.ProductId == receiptInfo.ProductId and pending.ToolId == entry.ToolId then
			targetUserId = pending.TargetUserId or targetUserId
			self._pendingPurchases[receiptInfo.PlayerId] = nil
		end

		local granted = self._ownership:GrantToolByUserId(targetUserId, entry.ToolId)
		if not granted then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local buyer = self._players:GetPlayerByUserId(receiptInfo.PlayerId)
		local target = self._players:GetPlayerByUserId(targetUserId)

		if buyer then
			self._purchaseNotice:Fire(
				buyer,
				entry.ToolId,
				entry.Title,
				targetUserId ~= receiptInfo.PlayerId,
				target and (target.DisplayName ~= "" and target.DisplayName or target.Name) or nil
			)
		end

		if target and target ~= buyer then
			self._purchaseNotice:Fire(target, entry.ToolId, entry.Title, false, nil)
		end

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	__module = Purchases

	if type(__module) == "table" then
		__module.__source = "Modules/Shop/Purchases.luau"
	end
	Core.Modules.Shop.Purchases = __module
end

---@class CoreModulesSpeedrunFlow
---@field __source string Path sumber module `Modules/Speedrun/Flow.luau`.
---@field cfg any Member public `cfg` dari `Modules/Speedrun/Flow.luau`.
---@field finishDebounce any Member public `finishDebounce` dari `Modules/Speedrun/Flow.luau`.
---@field startDebounce any Member public `startDebounce` dari `Modules/Speedrun/Flow.luau`.
---@field timers any Member public `timers` dari `Modules/Speedrun/Flow.luau`.
Core.Modules.Speedrun.Flow = Core.Modules.Speedrun.Flow or {}
do
	local __module = nil
	local Flow = {}
	Flow.__index = Flow

	---Menjalankan fungsi `new`.
	---@param cfg any Nilai parameter `cfg`.
	---@return any result Hasil dari fungsi `new`.
	function Flow.new(cfg)
		local self = setmetatable({}, Flow)
		self.cfg = cfg or {}
		self.timers = {}
		self.startDebounce = {}
		self.finishDebounce = {}
		return self
	end

	---Menjalankan fungsi `start`.
	---@param player any Nilai parameter `player`.
	function Flow:start(player)
		local uid = player.UserId
		if self.startDebounce[uid] then
			return false
		end
		self.startDebounce[uid] = true

		self.timers[uid] = os.clock()
		self.finishDebounce[uid] = nil

		local cooldown = tonumber(self.cfg.StartCooldown) or 2
		task.delay(cooldown, function()
			self.startDebounce[uid] = nil
		end)
		return true
	end

	---Menjalankan fungsi `finish`.
	---@param player any Nilai parameter `player`.
	function Flow:finish(player)
		local uid = player.UserId
		if self.finishDebounce[uid] then
			return false, nil, "Debounced"
		end
		self.finishDebounce[uid] = true

		local startTime = self.timers[uid]
		if not startTime then
			self:_clearFinishDebounce(uid)
			return false, nil, "NoStart"
		end

		local elapsed = math.floor(os.clock() - startTime)
		self.timers[uid] = nil

		local cooldown = tonumber(self.cfg.FinishCooldown) or 3
		task.delay(cooldown, function()
			self.finishDebounce[uid] = nil
		end)
		return true, elapsed, nil
	end

	---@private
	---Menjalankan fungsi `_clearFinishDebounce`.
	---@param uid any Nilai parameter `uid`.
	function Flow:_clearFinishDebounce(uid)
		local cooldown = tonumber(self.cfg.FinishCooldown) or 3
		task.delay(cooldown, function()
			self.finishDebounce[uid] = nil
		end)
	end

	---Menjalankan fungsi `clear`.
	---@param player any Nilai parameter `player`.
	function Flow:clear(player)
		local uid = player.UserId
		self.timers[uid] = nil
		self.startDebounce[uid] = nil
		self.finishDebounce[uid] = nil
	end

	__module = Flow

	if type(__module) == "table" then
		__module.__source = "Modules/Speedrun/Flow.luau"
	end
	Core.Modules.Speedrun.Flow = __module
end

---@class CoreModulesSpeedrunIndex
---@field __source string Path sumber module `Modules/Speedrun/Index.luau`.
Core.Modules.Speedrun.Index = Core.Modules.Speedrun.Index or {}
do
	local __module = nil
	local Workspace = game:GetService("Workspace")
	local ServerScriptService = game:GetService("ServerScriptService")

	local Server = serverFolder
	local Config = Server.Config
	local SpeedrunConfig = require(Config.SpeedrunConfig)

	local Index = {}
	Index.__index = Index

	---@private
	---Menjalankan fungsi `resolvePath`.
	---@param root any Nilai parameter `root`.
	---@param pathParts any Nilai parameter `pathParts`.
	local function resolvePath(root, pathParts)
		local current = root
		for _, name in ipairs(pathParts or {}) do
			if not current then
				return nil
			end
			current = current:FindFirstChild(name)
		end
		return current
	end

	---@private
	---Mencari banyak part berdasarkan nama tunggal atau daftar nama pada folder speedrun.
	---Pencarian dilakukan ke child langsung lalu ke seluruh descendant agar konfigurasi array
	---tetap bekerja meski part berada di dalam subfolder map.
	---@param folder Instance Folder utama speedrun.
	---@param partNames any Nama target tunggal atau array nama target.
	---@return {BasePart} parts Daftar part valid yang ditemukan.
	local function resolveParts(folder, partNames)
		local names = {}
		if type(partNames) == "table" then
			for _, value in ipairs(partNames) do
				if type(value) == "string" and value ~= "" then
					table.insert(names, value)
				end
			end
		elseif type(partNames) == "string" and partNames ~= "" then
			table.insert(names, partNames)
		end

		local parts = {}
		local seen = {}
		for _, name in ipairs(names) do
			local direct = folder:FindFirstChild(name)
			if direct and direct:IsA("BasePart") and not seen[direct] then
				seen[direct] = true
				table.insert(parts, direct)
			end

			for _, descendant in ipairs(folder:GetDescendants()) do
				if descendant.Name == name and descendant:IsA("BasePart") and not seen[descendant] then
					seen[descendant] = true
					table.insert(parts, descendant)
				end
			end
		end
		return parts
	end

	---Menjalankan fungsi `new`.
	---@return any result Hasil dari fungsi `new`.
	function Index.new()
		local self = setmetatable({}, Index)
		self.folder = resolvePath(Workspace, SpeedrunConfig.FolderPath)
		if self.folder then
			self.startParts = resolveParts(self.folder, SpeedrunConfig.StartPartName or "Start")
			self.finishParts = resolveParts(self.folder, SpeedrunConfig.FinishPartName or "Finish")
			self.startPart = self.startParts[1]
			self.finishPart = self.finishParts[1]
		end
		return self
	end

	---Menjalankan fungsi `isReady`.
	---@return any result Hasil dari fungsi `isReady`.
	function Index:isReady()
		return self.folder ~= nil and self.startPart ~= nil and self.finishPart ~= nil
	end

	__module = Index

	if type(__module) == "table" then
		__module.__source = "Modules/Speedrun/Index.luau"
	end
	Core.Modules.Speedrun.Index = __module
end

---@class CoreModulesSpeedrunSpeedrunAntiCheat
---@field __source string Path sumber module `Modules/Speedrun/SpeedrunAntiCheat.luau`.
---@field _cfg any Member private `_cfg` dari `Modules/Speedrun/SpeedrunAntiCheat.luau`.
---@field _overheadConfig any Member private `_overheadConfig` dari `Modules/Speedrun/SpeedrunAntiCheat.luau`.
---@field _roleChecker any Member private `_roleChecker` dari `Modules/Speedrun/SpeedrunAntiCheat.luau`.
Core.Modules.Speedrun.SpeedrunAntiCheat = Core.Modules.Speedrun.SpeedrunAntiCheat or {}
do
	local __module = nil
	local AntiCheat = {}
	AntiCheat.__index = AntiCheat

	---Menjalankan fungsi `new`.
	---@param cfg any Nilai parameter `cfg`.
	---@param roleChecker any Nilai parameter `roleChecker`.
	---@param overheadConfig any Nilai parameter `overheadConfig`.
	---@return any result Hasil dari fungsi `new`.
	function AntiCheat.new(cfg, roleChecker, overheadConfig)
		local self = setmetatable({}, AntiCheat)
		self._cfg = cfg
		self._roleChecker = roleChecker
		self._overheadConfig = overheadConfig
		return self
	end

	---Menjalankan fungsi `canBypass`.
	---@param player any Nilai parameter `player`.
	function AntiCheat:canBypass(player)
		if not self._roleChecker or not self._roleChecker.isPrivileged then
			return false
		end
		return self._roleChecker.isPrivileged(player, self._overheadConfig)
	end

	---Menjalankan fungsi `check`.
	---@param player any Nilai parameter `player`.
	---@param elapsed any Nilai parameter `elapsed`.
	function AntiCheat:check(player, elapsed)
		if self._cfg.EnableAntiCheat == false then
			return true
		end
		local minTime = tonumber(self._cfg.MinTimeSeconds) or 0
		if elapsed < minTime and not self:canBypass(player) then
			player:Kick(self._cfg.KickMessage or "Anti-Cheat: Unreasonable speedrun time detected.")
			return false
		end
		return true
	end

	__module = AntiCheat

	if type(__module) == "table" then
		__module.__source = "Modules/Speedrun/SpeedrunAntiCheat.luau"
	end
	Core.Modules.Speedrun.SpeedrunAntiCheat = __module
end

---@class CoreModulesSpeedrunSpeedrunFormatter
---@field __source string Path sumber module `Modules/Speedrun/SpeedrunFormatter.luau`.
---@field formatTime any Member public `formatTime` dari `Modules/Speedrun/SpeedrunFormatter.luau`.
Core.Modules.Speedrun.SpeedrunFormatter = Core.Modules.Speedrun.SpeedrunFormatter or {}
do
	local __module = nil
	local Formatter = {}

	---Menjalankan fungsi `formatTime`.
	---@param seconds any Nilai parameter `seconds`.
	function Formatter.formatTime(seconds)
		if not seconds or seconds <= 0 then
			return "00:00"
		end
		local mins = math.floor(seconds / 60)
		local secs = seconds % 60
		return string.format("%02d:%02d", mins, secs)
	end

	__module = Formatter

	if type(__module) == "table" then
		__module.__source = "Modules/Speedrun/SpeedrunFormatter.luau"
	end
	Core.Modules.Speedrun.SpeedrunFormatter = __module
end

---@class CoreModulesSpeedrunSpeedrunLeaderboard
---@field __source string Path sumber module `Modules/Speedrun/SpeedrunLeaderboard.luau`.
---@field _board any Member private `_board` dari `Modules/Speedrun/SpeedrunLeaderboard.luau`.
---@field _filterUtil any Member private `_filterUtil` dari `Modules/Speedrun/SpeedrunLeaderboard.luau`.
---@field _overheadConfig any Member private `_overheadConfig` dari `Modules/Speedrun/SpeedrunLeaderboard.luau`.
Core.Modules.Speedrun.SpeedrunLeaderboard = Core.Modules.Speedrun.SpeedrunLeaderboard or {}
do
	local __module = nil
	local SpeedrunLeaderboard = {}
	SpeedrunLeaderboard.__index = SpeedrunLeaderboard

	---Menjalankan fungsi `new`.
	---@param board any Nilai parameter `board`.
	---@param filterUtil any Nilai parameter `filterUtil`.
	---@param overheadConfig any Nilai parameter `overheadConfig`.
	---@return any result Hasil dari fungsi `new`.
	function SpeedrunLeaderboard.new(board, filterUtil, overheadConfig)
		local self = setmetatable({}, SpeedrunLeaderboard)
		self._board = board
		self._filterUtil = filterUtil
		self._overheadConfig = overheadConfig
		return self
	end

	---Menjalankan fungsi `updateBestTime`.
	---@param userId any Nilai parameter `userId`.
	---@param elapsedSeconds any Nilai parameter `elapsedSeconds`.
	---@param username any Nilai parameter `username`.
	function SpeedrunLeaderboard:updateBestTime(userId, elapsedSeconds, username)
		if not self._board or not userId then
			return
		end
		if self._filterUtil and self._filterUtil.isExemptFromLeaderboard then
			if self._filterUtil.isExemptFromLeaderboard(userId, nil, self._overheadConfig) then
				DataStoreConfig.RetryCall(function()
					self._board:RemoveAsync(tostring(userId))
				end, "Leaderboard:RemoveAsync")
				return
			end
		elseif self._filterUtil and self._filterUtil.isPrivileged then 
			if self._filterUtil.isPrivileged(userId, username, self._overheadConfig)  then
				DataStoreConfig.RetryCall(function()
					self._board:RemoveAsync(tostring(userId))
				end, "Leaderboard:RemoveAsync")
				return
			end
		end
		DataStoreConfig.RetryCall(function()
			self._board:SetAsync(tostring(userId), -elapsedSeconds)
		end, "SpeedrunLeaderboard:SetAsync")
	end

	---Menjalankan fungsi `remove`.
	---@param userId any Nilai parameter `userId`.
	function SpeedrunLeaderboard:remove(userId)
		if not self._board or not userId then
			return
		end
		pcall(function()
			self._board:RemoveAsync(tostring(userId))
		end)
	end

	__module = SpeedrunLeaderboard

	if type(__module) == "table" then
		__module.__source = "Modules/Speedrun/SpeedrunLeaderboard.luau"
	end
	Core.Modules.Speedrun.SpeedrunLeaderboard = __module
end

---@class CoreModulesSpeedrunSpeedrunStatsSync
---@field __source string Path sumber module `Modules/Speedrun/SpeedrunStatsSync.luau`.
---@field _formatter any Member private `_formatter` dari `Modules/Speedrun/SpeedrunStatsSync.luau`.
Core.Modules.Speedrun.SpeedrunStatsSync = Core.Modules.Speedrun.SpeedrunStatsSync or {}
do
	local __module = nil
	local SpeedrunStatsSync = {}
	SpeedrunStatsSync.__index = SpeedrunStatsSync

	---Menjalankan fungsi `new`.
	---@param formatter any Nilai parameter `formatter`.
	---@return any result Hasil dari fungsi `new`.
	function SpeedrunStatsSync.new(formatter)
		local self = setmetatable({}, SpeedrunStatsSync)
		self._formatter = formatter
		return self
	end

	---Menjalankan fungsi `applyToLeaderstats`.
	---@param player any Nilai parameter `player`.
	---@param bestTimeSeconds any Nilai parameter `bestTimeSeconds`.
	function SpeedrunStatsSync:applyToLeaderstats(player, bestTimeSeconds)
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then
			return
		end
		local bestTime = leaderstats:FindFirstChild("BestTime")
		if not bestTime then
			return
		end
		bestTime.Value = self._formatter.formatTime(bestTimeSeconds or 0)
	end

	---Menjalankan fungsi `resetLeaderstats`.
	---@param player any Nilai parameter `player`.
	function SpeedrunStatsSync:resetLeaderstats(player)
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then
			return
		end
		local bestTime = leaderstats:FindFirstChild("BestTime")
		if bestTime then
			bestTime.Value = "00:00"
		end
	end

	__module = SpeedrunStatsSync

	if type(__module) == "table" then
		__module.__source = "Modules/Speedrun/SpeedrunStatsSync.luau"
	end
	Core.Modules.Speedrun.SpeedrunStatsSync = __module
end

---@class CoreModulesSpeedrunTriggerBinder
---@field __source string Path sumber module `Modules/Speedrun/TriggerBinder.luau`.
Core.Modules.Speedrun.TriggerBinder = Core.Modules.Speedrun.TriggerBinder or {}
do
	local __module = nil
	local Players = game:GetService("Players")

	local TriggerBinder = {}

	---@private
	---Menjalankan fungsi `getPlayerFromHit`.
	---@param hit any Nilai parameter `hit`.
	---@return any result Hasil dari fungsi `getPlayerFromHit`.
	local function getPlayerFromHit(hit)
		local character = hit and hit.Parent
		if not character then
			return nil
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return nil
		end
		return Players:GetPlayerFromCharacter(character)
	end

	---Menjalankan fungsi `bind`.
	---@param janitor any Nilai parameter `janitor`.
	---@param startPart any Nilai parameter `startPart`.
	---@param finishPart any Nilai parameter `finishPart`.
	---@param onStart any Nilai parameter `onStart`.
	---@param onFinish any Nilai parameter `onFinish`.
	function TriggerBinder.bind(janitor, startPart, finishPart, onStart, onFinish)
		local function bindParts(partsOrPart, callback)
			if not partsOrPart then
				return
			end
			local parts = {}
			if type(partsOrPart) == "table" and partsOrPart.Touched == nil then
				parts = partsOrPart
			else
				parts = {partsOrPart}
			end

			for _, part in ipairs(parts) do
				if part and part.Touched then
					janitor:Add(part.Touched:Connect(function(hit)
						local player = getPlayerFromHit(hit)
						if player then
							callback(player)
						end
					end), "Disconnect")
				end
			end
		end

		bindParts(startPart, onStart)
		bindParts(finishPart, onFinish)
	end

	__module = TriggerBinder

	if type(__module) == "table" then
		__module.__source = "Modules/Speedrun/TriggerBinder.luau"
	end
	Core.Modules.Speedrun.TriggerBinder = __module
end

---@class CoreModulesTeleportBackBasecampHandler
---@field __source string Path sumber module `Modules/Teleport/BackBasecampHandler.luau`.
Core.Modules.Teleport.BackBasecampHandler = Core.Modules.Teleport.BackBasecampHandler or {}
do
	local __module = nil
	local Players = game:GetService("Players")

	local BackBasecampHandler = {}

	---@private
	---Mengumpulkan semua part back-to-basecamp yang valid dari folder teleport.
	---@param teleports Instance Folder teleport yang berisi target back basecamp.
	---@return {BasePart} parts Daftar part yang akan dipasang listener.
	local function resolveBackBasecampParts(teleports)
		local parts = {}
		local seen = {}

		local function addPart(inst)
			if inst and inst:IsA("BasePart") and not seen[inst] then
				seen[inst] = true
				table.insert(parts, inst)
			end
		end

		addPart(teleports:FindFirstChild("BackBasecamp"))

		for _, inst in ipairs(teleports:GetChildren()) do
			if inst:IsA("BasePart") and string.lower(inst.Name) == "backbasecamp" then
				addPart(inst)
			end
		end

		return parts
	end

	---Menjalankan fungsi `setup`.
	---@param _checkpointIndex any Nilai parameter `_checkpointIndex`.
	---@param _checkpointConfig any Nilai parameter `_checkpointConfig`.
	---@param janitor any Nilai parameter `janitor`.
	---@param onReset any Nilai parameter `onReset`.
	function BackBasecampHandler.setup(_checkpointIndex, _checkpointConfig, janitor, onReset)
		local jaleMaps = workspace:FindFirstChild("JaleMaps")
		if not jaleMaps then
			return nil
		end
		local teleports = jaleMaps:FindFirstChild("Teleports")
		if not teleports then
			return nil
		end
		local basecampParts = resolveBackBasecampParts(teleports)
		if #basecampParts == 0 then
			return nil
		end

		local debounce = {}
		local connections = {}
		local function bindPart(basecamp)
			local conn = basecamp.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if not player then
					return
				end
				local uid = player.UserId
				if debounce[uid] then
					return
				end
				debounce[uid] = true
				task.delay(1, function()
					debounce[uid] = nil
				end)
				if onReset then
					onReset(player)
				end
			end)
			table.insert(connections, conn)
			if janitor then
				janitor:Add(conn, "Disconnect")
			end
		end

		for _, basecamp in ipairs(basecampParts) do
			bindPart(basecamp)
		end

		return connections
	end

	__module = BackBasecampHandler

	if type(__module) == "table" then
		__module.__source = "Modules/Teleport/BackBasecampHandler.luau"
	end
	Core.Modules.Teleport.BackBasecampHandler = __module
end

---@class CoreModulesTeleportTeleporterBinder
---@field __source string Path sumber module `Modules/Teleport/TeleporterBinder.luau`.
---@field checkpointIndex any Member public `checkpointIndex` dari `Modules/Teleport/TeleporterBinder.luau`.
---@field defaultStartIndex any Member public `defaultStartIndex` dari `Modules/Teleport/TeleporterBinder.luau`.
Core.Modules.Teleport.TeleporterBinder = Core.Modules.Teleport.TeleporterBinder or {}
do
	local __module = nil
	local Players = game:GetService("Players")
	local TargetFinder = Core.Modules.Teleport.Util.TargetFinder
	local TeleportHelper = Core.Modules.Teleport.TeleportHelper

	local TeleporterBinder = {}
	TeleporterBinder.__index = TeleporterBinder

	---Menjalankan fungsi `new`.
	---@param defaultStartIndex any Nilai parameter `defaultStartIndex`.
	---@param checkpointIndex any Nilai parameter `checkpointIndex`.
	---@return any result Hasil dari fungsi `new`.
	function TeleporterBinder.new(defaultStartIndex, checkpointIndex)
		local self = setmetatable({}, TeleporterBinder)
		self.defaultStartIndex = defaultStartIndex or 0
		self.checkpointIndex = checkpointIndex
		return self
	end

	---Menjalankan fungsi `bind`.
	---@param janitor any Nilai parameter `janitor`.
	---@param getTargetIndex any Nilai parameter `getTargetIndex`.
	function TeleporterBinder:bind(janitor, getTargetIndex)
		local lastTeleport = {}
		if janitor then
			janitor:Add(Players.PlayerRemoving:Connect(function(player)
				lastTeleport[player] = nil
			end), "Disconnect")
		end
		for _, part in ipairs(TargetFinder.findTeleporterParts()) do
			local conn = part.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if not player then
					return
				end
				local now = os.clock()
				if lastTeleport[player] and now - lastTeleport[player] < 1 then
					return
				end
				lastTeleport[player] = now
				local index = (getTargetIndex and getTargetIndex(player)) or self.defaultStartIndex
				TeleportHelper.teleportToSpawn(player, index, self.checkpointIndex, self.defaultStartIndex)
			end)
			if janitor then
				janitor:Add(conn, "Disconnect")
			end
		end
	end

	__module = TeleporterBinder

	if type(__module) == "table" then
		__module.__source = "Modules/Teleport/TeleporterBinder.luau"
	end
	Core.Modules.Teleport.TeleporterBinder = __module
end

---@class CoreComponentsCheckpointComponent
---@field __source string Path sumber module `Components/CheckpointComponent.luau`.
Core.Components.CheckpointComponent = Core.Components.CheckpointComponent or {}
do
	local __module = nil
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")

	local Shared = ReplicatedStorage.Shared
	local Packages = Shared.Packages
	local Knit = require(Packages.Knit)
	local Component = require(Packages.Component)
	local Janitor = require(Packages.Janitor)

	local Server = serverFolder
	local Modules = Core.Modules
	local CheckpointIndex = Core.Modules.Checkpoint.Index

	local CheckpointComponent = Component.new({
		Tag = "Checkpoint",
		Ancestors = {workspace},
	})

	---Menjalankan fungsi `Construct`.
	function CheckpointComponent:Construct()
		local info = CheckpointIndex:GetInfoForInstance(self.Instance)
		self.index = info and info.index or 0
		self.isFinish = info and info.isFinish or false
		self.isStart = info and info.isStart or false
		self.summitReward = info and info.summitReward or nil
	end

	---Menjalankan fungsi `Start`.
	function CheckpointComponent:Start()
		self._janitor = Janitor.new()
		self._lastTouch = {}
		self._touchConn = self.Instance.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player then
				return
			end

			local now = os.clock()
			local last = self._lastTouch[player]
			if last and now - last < 0.3 then
				return
			end
			self._lastTouch[player] = now

			local checkpointService = Knit.GetService("CheckpointService")
			checkpointService:HandleCheckpointTouch(player, self.index, self.isFinish, self.summitReward)
		end)
		self._janitor:Add(self._touchConn, "Disconnect")
	end

	---Menjalankan fungsi `Stop`.
	function CheckpointComponent:Stop()
		if self._janitor then
			self._janitor:Destroy()
			self._janitor = nil
		end
	end

	__module = CheckpointComponent

	if type(__module) == "table" then
		__module.__source = "Components/CheckpointComponent.luau"
	end
	Core.Components.CheckpointComponent = __module
end

---@class CoreServicesAvatarHelpersAvatarChanger
---@field __source string Path sumber module `Services/AvatarHelpers/AvatarChanger.luau`.
Core.Services.AvatarHelpers.AvatarChanger = Core.Services.AvatarHelpers.AvatarChanger or {}
do
	local __module = nil
	local TweenService = game:GetService("TweenService")
	local Players = game:GetService("Players")

	local AvatarChanger = {}

	---@private
	---Menjalankan fungsi `hasTools`.
	---@param character any Nilai parameter `character`.
	---@return any result Hasil dari fungsi `hasTools`.
	local function hasTools(character)
		for _, child in pairs(character:GetChildren()) do
			if child:IsA("Tool") then
				return true
			end
		end
		return false
	end

	---@private
	---Menjalankan fungsi `playParticles`.
	---@param rootPart any Nilai parameter `rootPart`.
	local function playParticles(rootPart)
		if not rootPart then
			return
		end
		for i = 1, 20 do
			local part = Instance.new("Part")
			part.Size = Vector3.new(0.4, 0.4, 0.4)
			part.Shape = Enum.PartType.Ball
			part.Material = Enum.Material.Neon
			part.Color = Color3.fromHSV(i / 20, 1, 1)
			part.CanCollide = false
			part.Anchored = true
			part.Transparency = 0.3
			local angle = (i / 20) * math.pi * 2
			part.Position = rootPart.Position + Vector3.new(
				math.cos(angle) * 3,
				math.random(0, 3),
				math.sin(angle) * 3
			)
			part.Parent = workspace
			TweenService:Create(part, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
				Position = rootPart.Position + Vector3.new(0, 2, 0),
				Transparency = 1,
				Size = Vector3.new(0, 0, 0),
			}):Play()
			task.delay(0.6, function()
				part:Destroy()
			end)
		end
	end

	---@private
	---Menjalankan fungsi `fadeCharacter`.
	---@param character any Nilai parameter `character`.
	---@param targetTransparency any Nilai parameter `targetTransparency`.
	---@param duration any Nilai parameter `duration`.
	local function fadeCharacter(character, targetTransparency, duration)
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				TweenService:Create(part, TweenInfo.new(duration or 0.3), {
					Transparency = targetTransparency or 0,
				}):Play()
			end
		end
	end

	---Menjalankan fungsi `applyDescription`.
	---@param humanoid any Nilai parameter `humanoid`.
	---@param userId any Nilai parameter `userId`.
	function AvatarChanger.applyDescription(humanoid, userId)
		local ok, description = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(userId)
		end)
		if ok and description then
			pcall(function()
				humanoid:ApplyDescription(description)
			end)
			return true
		end
		return false
	end

	---Menjalankan fungsi `applyStoredAvatar`.
	---@param state any Nilai parameter `state`.
	---@param player any Nilai parameter `player`.
	---@param character any Nilai parameter `character`.
	function AvatarChanger.applyStoredAvatar(state, player, character)
		if not character then
			return
		end
		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then
			return
		end
		local targetUserId = state:getSelectedAvatar(player)
		if not targetUserId or targetUserId <= 0 then
			return
		end
		AvatarChanger.applyDescription(humanoid, targetUserId)
		-- FIX: Re-apply CollisionGroup setelah avatar diganti
		-- karena applyDescription bisa spawn ulang part-part karakter
		task.delay(0.5, function()
			if not character or not character.Parent then return end
			for _, inst in ipairs(character:GetDescendants()) do
				if inst:IsA("BasePart") then
					inst.CollisionGroup = "PlayersNoCollide"
				end
			end
		end)
	end

	---Menjalankan fungsi `changeAvatar`.
	---@param state any Nilai parameter `state`.
	---@param promiseLibrary any Nilai parameter `promiseLibrary`.
	---@param player any Nilai parameter `player`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	function AvatarChanger.changeAvatar(state, promiseLibrary, player, targetUserId)
		state:setSelectedAvatar(player, targetUserId)
		if not player.Character then
			return false, "NoCharacter"
		end
		if not state:consumeCooldown(player) then
			return false, "Cooldown"
		end

		local character = player.Character
		if hasTools(character) then
			return false, "HoldingTools"
		end

		local humanoid = character:FindFirstChild("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not rootPart then
			return false, "MissingHumanoid"
		end

		playParticles(rootPart)
		fadeCharacter(character, 1, 0.3)

		promiseLibrary.delay(0.4)
			:andThen(function()
				AvatarChanger.applyDescription(humanoid, targetUserId)
				return promiseLibrary.delay(0.8)
			end)
			:andThen(function()
				fadeCharacter(character, 0, 0.4)
				-- FIX: Re-apply CollisionGroup setelah avatar diganti
				task.delay(0.3, function()
					if not character or not character.Parent then return end
					for _, inst in ipairs(character:GetDescendants()) do
						if inst:IsA("BasePart") then
							inst.CollisionGroup = "PlayersNoCollide"
						end
					end
				end)
			end)

		return true
	end

	---Menjalankan fungsi `resetAvatar`.
	---@param state any Nilai parameter `state`.
	---@param promiseLibrary any Nilai parameter `promiseLibrary`.
	---@param player any Nilai parameter `player`.
	function AvatarChanger.resetAvatar(state, promiseLibrary, player)
		return AvatarChanger.changeAvatar(state, promiseLibrary, player, player.UserId)
	end

	__module = AvatarChanger

	if type(__module) == "table" then
		__module.__source = "Services/AvatarHelpers/AvatarChanger.luau"
	end
	Core.Services.AvatarHelpers.AvatarChanger = __module
end

---@class CoreServicesAvatarHelpersAvatarStore
---@field __source string Path sumber module `Services/AvatarHelpers/AvatarStore.luau`.
---@field _config any Member private `_config` dari `Services/AvatarHelpers/AvatarStore.luau`.
---@field _cooldowns any Member private `_cooldowns` dari `Services/AvatarHelpers/AvatarStore.luau`.
---@field _selectedAvatars any Member private `_selectedAvatars` dari `Services/AvatarHelpers/AvatarStore.luau`.
Core.Services.AvatarHelpers.AvatarStore = Core.Services.AvatarHelpers.AvatarStore or {}
do
	local __module = nil
	local AvatarStore = {}
	AvatarStore.__index = AvatarStore

	---Menjalankan fungsi `new`.
	---@param config any Nilai parameter `config`.
	---@return any result Hasil dari fungsi `new`.
	function AvatarStore.new(config)
		local self = setmetatable({}, AvatarStore)
		self._config = config or {}
		self._cooldowns = {}
		self._selectedAvatars = {}
		return self
	end

	---Menjalankan fungsi `setSelectedAvatar`.
	---@param player any Nilai parameter `player`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	function AvatarStore:setSelectedAvatar(player, targetUserId)
		if not player or not targetUserId then
			return
		end
		self._selectedAvatars[player.UserId] = targetUserId
	end

	---Menjalankan fungsi `getSelectedAvatar`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `getSelectedAvatar`.
	function AvatarStore:getSelectedAvatar(player)
		if not player then
			return nil
		end
		return self._selectedAvatars[player.UserId]
	end

	---Menjalankan fungsi `ensureDefaultAvatar`.
	---@param player any Nilai parameter `player`.
	function AvatarStore:ensureDefaultAvatar(player)
		if not self:getSelectedAvatar(player) then
			self:setSelectedAvatar(player, player.UserId)
		end
	end

	---Menjalankan fungsi `consumeCooldown`.
	---@param player any Nilai parameter `player`.
	function AvatarStore:consumeCooldown(player)
		local cooldown = self._config.COOLDOWN_TIME or 2
		local now = tick()
		local lastTime = self._cooldowns[player.UserId]
		if lastTime and now - lastTime < cooldown then
			return false
		end
		self._cooldowns[player.UserId] = now
		return true
	end

	---Menjalankan fungsi `removePlayer`.
	---@param player any Nilai parameter `player`.
	function AvatarStore:removePlayer(player)
		if not player then
			return
		end
		self._selectedAvatars[player.UserId] = nil
		self._cooldowns[player.UserId] = nil
	end

	__module = AvatarStore

	if type(__module) == "table" then
		__module.__source = "Services/AvatarHelpers/AvatarStore.luau"
	end
	Core.Services.AvatarHelpers.AvatarStore = __module
end

---@class CoreServicesCustomTitleColorUtil
---@field __source string Path sumber module `Services/CustomTitle/ColorUtil.luau`.
Core.Services.CustomTitle.ColorUtil = Core.Services.CustomTitle.ColorUtil or {}
do
	local __module = nil
	local ColorUtil = {}

	---Menjalankan fungsi `sanitizeColor`.
	---@param value any Nilai parameter `value`.
	function ColorUtil.sanitizeColor(value)
		if typeof(value) == "Color3" then
			return value
		end
		if typeof(value) == "table" then
			local r = value.r or value.R or value[1]
			local g = value.g or value.G or value[2]
			local b = value.b or value.B or value[3]
			if typeof(r) == "number" and typeof(g) == "number" and typeof(b) == "number" then
				return Color3.fromRGB(
					math.clamp(math.floor(r + 0.5), 0, 255),
					math.clamp(math.floor(g + 0.5), 0, 255),
					math.clamp(math.floor(b + 0.5), 0, 255)
				)
			end
		end
		return nil
	end

	---Menjalankan fungsi `encodeColors`.
	---@param colors any Nilai parameter `colors`.
	function ColorUtil.encodeColors(colors)
		if typeof(colors) ~= "table" then
			return nil
		end
		local parts = {}
		for _, c in ipairs(colors) do
			local cc = ColorUtil.sanitizeColor(c)
			if cc then
				table.insert(parts, string.format("%d,%d,%d",
					math.floor(cc.R * 255 + 0.5),
					math.floor(cc.G * 255 + 0.5),
					math.floor(cc.B * 255 + 0.5)
					))
			end
		end
		if #parts == 0 then
			return nil
		end
		return table.concat(parts, ";")
	end

	---Menjalankan fungsi `tableToColor`.
	---@param tbl any Nilai parameter `tbl`.
	function ColorUtil.tableToColor(tbl)
		if typeof(tbl) ~= "table" then
			return nil
		end
		if tbl.r and tbl.g and tbl.b then
			return Color3.fromRGB(
				math.clamp(tbl.r, 0, 255),
				math.clamp(tbl.g, 0, 255),
				math.clamp(tbl.b, 0, 255)
			)
		end
		return nil
	end

	---Menjalankan fungsi `colorsToTables`.
	---@param colors any Nilai parameter `colors`.
	function ColorUtil.colorsToTables(colors)
		if typeof(colors) ~= "table" then
			return {}
		end
		local out = {}
		for _, c in ipairs(colors) do
			local cc = ColorUtil.sanitizeColor(c)
			if cc then
				table.insert(out, {
					r = math.floor(cc.R * 255 + 0.5),
					g = math.floor(cc.G * 255 + 0.5),
					b = math.floor(cc.B * 255 + 0.5),
				})
			end
		end
		return out
	end

	---Menjalankan fungsi `colorToTable`.
	---@param color any Nilai parameter `color`.
	function ColorUtil.colorToTable(color)
		if typeof(color) ~= "Color3" then
			return nil
		end
		return {
			r = math.floor(color.R * 255 + 0.5),
			g = math.floor(color.G * 255 + 0.5),
			b = math.floor(color.B * 255 + 0.5),
		}
	end

	__module = ColorUtil

	if type(__module) == "table" then
		__module.__source = "Services/CustomTitle/ColorUtil.luau"
	end
	Core.Services.CustomTitle.ColorUtil = __module
end

---@class CoreServicesCustomTitleProfileManager
---@field __source string Path sumber module `Services/CustomTitle/ProfileManager.luau`.
Core.Services.CustomTitle.ProfileManager = Core.Services.CustomTitle.ProfileManager or {}
do
	local __module = nil
	local ProfileManager = {}

	---Menjalankan fungsi `applyProfileToPlayer`.
	---@param player any Nilai parameter `player`.
	---@param profile any Nilai parameter `profile`.
	---@param cfg any Nilai parameter `cfg`.
	---@param tableToColor any Nilai parameter `tableToColor`.
	---@param slotAttr any Nilai parameter `slotAttr`.
	function ProfileManager.applyProfileToPlayer(player, profile, cfg, tableToColor, slotAttr)
		if not profile then
			return
		end
		local data = profile.Data or {}
		local titles = data.customTitles or {}
		local maxSlots = cfg.MaxCustomTitleSlots or 7

		for i = 1, maxSlots do
			player:SetAttribute(slotAttr(cfg.CustomTitleTextAttribute, i), nil)
			player:SetAttribute(slotAttr(cfg.CustomTitleTextColorAttribute, i), nil)
			player:SetAttribute(slotAttr(cfg.CustomTitleModeAttribute, i), nil)
			player:SetAttribute(slotAttr(cfg.CustomTitleTextGradientAttribute, i), nil)
		end
		player:SetAttribute(cfg.CustomTitleSlotAttribute, nil)

		for i = 1, maxSlots do
			local entry = titles[i]
			if entry and entry.text and entry.text ~= "" then
				player:SetAttribute(slotAttr(cfg.CustomTitleTextAttribute, i), entry.text)
				player:SetAttribute(slotAttr(cfg.CustomTitleTextColorAttribute, i), tableToColor(entry.textColor))
				player:SetAttribute(slotAttr(cfg.CustomTitleModeAttribute, i), entry.mode)
				player:SetAttribute(slotAttr(cfg.CustomTitleTextGradientAttribute, i), entry.gradientStr)
			end
		end

		if data.activeSlot then
			player:SetAttribute(cfg.CustomTitleSlotAttribute, data.activeSlot)
		end
	end

	---Menjalankan fungsi `saveSlot`.
	---@param profile any Nilai parameter `profile`.
	---@param slot any Nilai parameter `slot`.
	---@param text any Nilai parameter `text`.
	---@param textColor any Nilai parameter `textColor`.
	---@param mode any Nilai parameter `mode`.
	---@param gradientStr any Nilai parameter `gradientStr`.
	---@param colorToTable any Nilai parameter `colorToTable`.
	function ProfileManager.saveSlot(profile, slot, text, textColor, mode, gradientStr, colorToTable)
		if not profile then
			return
		end
		profile.Data.customTitles = profile.Data.customTitles or {}
		profile.Data.customTitles[slot] = {
			text = text,
			textColor = colorToTable(textColor),
			mode = mode,
			gradientStr = gradientStr,
		}
		profile.Data.activeSlot = slot
	end

	---Menjalankan fungsi `clear`.
	---@param profile any Nilai parameter `profile`.
	function ProfileManager.clear(profile)
		if not profile then
			return
		end
		profile.Data.customTitles = {}
		profile.Data.activeSlot = nil
	end

	---Menjalankan fungsi `clearSlot`.
	---@param profile any Nilai parameter `profile`.
	---@param slot any Nilai parameter `slot`.
	function ProfileManager.clearSlot(profile, slot)
		if not profile then
			return
		end
		profile.Data.customTitles = profile.Data.customTitles or {}
		profile.Data.customTitles[slot] = nil
		if profile.Data.activeSlot == slot then
			profile.Data.activeSlot = nil
		end
	end

	__module = ProfileManager

	if type(__module) == "table" then
		__module.__source = "Services/CustomTitle/ProfileManager.luau"
	end
	Core.Services.CustomTitle.ProfileManager = __module
end

---@class CoreServicesCustomTitleRoleChecker
---@field __source string Path sumber module `Services/CustomTitle/RoleChecker.luau`.
Core.Services.CustomTitle.RoleChecker = Core.Services.CustomTitle.RoleChecker or {}
do
	local __module = nil
	local RoleChecker = {}

	---@private
	---Menjalankan fungsi `matches`.
	---@param listIds any Nilai parameter `listIds`.
	---@param listNames any Nilai parameter `listNames`.
	---@param player any Nilai parameter `player`.
	local function matches(listIds, listNames, player)
		for _, id in ipairs(listIds or {}) do
			if id == player.UserId then
				return true
			end
		end
		local uname = string.lower(player.Name)
		for _, name in ipairs(listNames or {}) do
			if uname == string.lower(name) then
				return true
			end
		end
		return false
	end

	---@private
	---Menjalankan fungsi `getSpecial`.
	---@param cfg any Nilai parameter `cfg`.
	---@param roleName any Nilai parameter `roleName`.
	---@return any result Hasil dari fungsi `getSpecial`.
	local function getSpecial(cfg, roleName)
		local titleConfig = cfg and cfg.TitleConfig or nil 
		local special = titleConfig and titleConfig.SpecialRoles or nil
		return special and special[roleName] or nil 
	end 

	---Menjalankan fungsi `isOwner`.
	---@param player any Nilai parameter `player`.
	---@param cfg any Nilai parameter `cfg`.
	---@return any result Hasil dari fungsi `isOwner`.
	function RoleChecker.isOwner(player, cfg)
		if cfg and cfg.PlaceOwnerId and player.UserId == cfg.PlaceOwnerId then 
			return true 
		end 
		if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
			return true
		end

		local ownerSpec = getSpecial(cfg, "Owner")
		return ownerSpec and matches(ownerSpec.UserIds, ownerSpec.Usernames, player) or false
	end

	---Menjalankan fungsi `isDeveloper`.
	---@param player any Nilai parameter `player`.
	---@param cfg any Nilai parameter `cfg`.
	---@return any result Hasil dari fungsi `isDeveloper`.
	function RoleChecker.isDeveloper(player, cfg)
		local spec = getSpecial(cfg, "Developer")
		return spec and matches(spec.UserIds, spec.Usernames, player) or nil 
	end

	---Menjalankan fungsi `isAdmin`.
	---@param player any Nilai parameter `player`.
	---@param cfg any Nilai parameter `cfg`.
	---@return any result Hasil dari fungsi `isAdmin`.
	function RoleChecker.isAdmin(player, cfg)
		local spec = getSpecial(cfg, "Admin")
		return spec and matches(spec.UserIds, spec.Usernames, player) or nil 
	end

	---Menjalankan fungsi `isModerator`.
	---@param player any Nilai parameter `player`.
	---@param cfg any Nilai parameter `cfg`.
	---@return any result Hasil dari fungsi `isModerator`.
	function RoleChecker.isModerator(player, cfg)
		local spec = getSpecial(cfg, "Moderator")
		return spec and matches(spec.UserIds, spec.Usernames, player) or nil 
	end

	---Menjalankan fungsi `getRoleFlags`.
	---@param player any Nilai parameter `player`.
	---@param cfg any Nilai parameter `cfg`.
	---@return any result Hasil dari fungsi `getRoleFlags`.
	function RoleChecker.getRoleFlags(player, cfg)
		return {
			Owner = RoleChecker.isOwner(player, cfg),
			Developer = RoleChecker.isDeveloper(player, cfg),
			Admin = RoleChecker.isAdmin(player, cfg),
			Moderator = RoleChecker.isModerator(player, cfg),
		}
	end

	---Menjalankan fungsi `canOpenMenu`.
	---@param player any Nilai parameter `player`.
	---@param cfg any Nilai parameter `cfg`.
	function RoleChecker.canOpenMenu(player, cfg)
		local access = cfg and cfg.CustomTitleAccess or nil
		if not access or access.Enabled == false then 
			return false end
		local openFor = access.OpenFor or {}
		local flags = RoleChecker.getRoleFlags(player, cfg)
		return (openFor.Owner and flags.Owner)
			or (openFor.Developer and flags.Developer)
			or (openFor.Admin and flags.Admin)
			or (openFor.Moderator and flags.Moderator)
			or false 
	end

	---Menjalankan fungsi `canManageOthers`.
	---@param player any Nilai parameter `player`.
	---@param cfg any Nilai parameter `cfg`.
	function RoleChecker.canManageOthers(player, cfg)
		local access = cfg and cfg.CustomTitleAccess or nil
		if not access or access.Enabled == false then 
			return false end
		local manageFor = access.ManageFor or {}
		local flags = RoleChecker.getRoleFlags(player, cfg)
		return (manageFor.Owner and flags.Owner)
			or (manageFor.Developer and flags.Developer)
			or (manageFor.Admin and flags.Admin)
			or (manageFor.Moderator and flags.Moderator)
			or false 
	end

	---Menjalankan fungsi `canClear`.
	---@param player any Nilai parameter `player`.
	---@param targer any Nilai parameter `targer`.
	---@param cfg any Nilai parameter `cfg`.
	function  RoleChecker.canClear(player, targer, cfg)
		if player == targer and cfg and cfg.CustomTitleAccess and cfg.CustomTitleAccess.AllowSelfClear == true then
			return true 
		end 
		return RoleChecker.canManageOthers(player, cfg)
	end

	---Menjalankan fungsi `isPrivileged`.
	---@param player any Nilai parameter `player`.
	---@param cfg any Nilai parameter `cfg`.
	---@return any result Hasil dari fungsi `isPrivileged`.
	function RoleChecker.isPrivileged(player, cfg)
		return RoleChecker.canManageOthers(player, cfg)
	end

	-- local function isOwner(player, cfg)
	--     if cfg.PlaceOwnerId and player.UserId == cfg.PlaceOwnerId then
	--         return true
	--     end
	--     if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
	--         return true
	--     end
	--     local special = cfg.TitleConfig and cfg.TitleConfig.SpecialRoles
	--     local ownerSpec = special and special.Owner
	--     if ownerSpec and matches(ownerSpec.UserIds, ownerSpec.Usernames, player) then
	--         return true
	--     end
	--     return false
	-- end

	-- function RoleChecker.isPrivileged(player, cfg)
	--     return isOwner(player, cfg)
	-- end

	__module = RoleChecker

	if type(__module) == "table" then
		__module.__source = "Services/CustomTitle/RoleChecker.luau"
	end
	Core.Services.CustomTitle.RoleChecker = __module
end

---@class CoreServicesCustomTitleCustomTitleHandler
---@field __source string Path sumber module `Services/CustomTitle/CustomTitleHandler.luau`.
Core.Services.CustomTitle.CustomTitleHandler = Core.Services.CustomTitle.CustomTitleHandler or {}
do
	local __module = nil
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local TitleModes = require(ReplicatedStorage.Shared.Config.CustomTitle.TitleModes)

	local CustomTitleHandler = {}

	local RoleChecker = Core.Services.CustomTitle.RoleChecker
	local ColorUtil = Core.Services.CustomTitle.ColorUtil
	local ProfileManager = Core.Services.CustomTitle.ProfileManager

	---@private
	---Menjalankan fungsi `slotAttr`.
	---@param base any Nilai parameter `base`.
	---@param slot any Nilai parameter `slot`.
	local function slotAttr(base, slot)
		return string.format("%s_%d", base, slot)
	end

	---@private
	---Menjalankan fungsi `sanitizeText`.
	---@param text any Nilai parameter `text`.
	---@param maxLen any Nilai parameter `maxLen`.
	local function sanitizeText(text, maxLen)
		if text == "" then
			return ""
		end
		if utf8.len(text) and utf8.len(text) > maxLen then
			local ok, shortened = pcall(function()
				local i = 0
				local iter = utf8.graphemes(text)
				local buff = {}
				for grapheme in iter do
					i += 1
					if i > maxLen then break end
					table.insert(buff, grapheme)
				end
				return table.concat(buff)
			end)
			return ok and shortened or string.sub(text, 1, maxLen)
		end
		return text
	end

	---@private
	---Menjalankan fungsi `isValidMode`.
	---@param mode any Nilai parameter `mode`.
	---@return any result Hasil dari fungsi `isValidMode`.
	local function isValidMode(mode)
		for _, name in ipairs(TitleModes.EffectModes) do
			if name == mode then
				return true
			end
		end
		return false
	end

	---@private
	---Menjalankan fungsi `resolveLimits`.
	---@param cfg any Nilai parameter `cfg`.
	local function resolveLimits(cfg)
		local access = cfg and cfg.CustomTitleAccess or nil
		local maxSlots = (access and access.MaxSlots) or cfg.MaxCustomTitleSlots or 7 
		local maxLen = (access and access.MaxLength) or cfg.MaxCustomTitleLength or 24 
		return maxSlots,maxLen
	end

	---Menjalankan fungsi `setDevice`.
	---@param player any Nilai parameter `player`.
	---@param device any Nilai parameter `device`.
	---@param cfg any Nilai parameter `cfg`.
	---@param validDevices any Nilai parameter `validDevices`.
	function CustomTitleHandler.setDevice(player, device, cfg, validDevices)
		if typeof(device) ~= "string" then
			return
		end
		if not validDevices[device] then
			return
		end
		player:SetAttribute(cfg.DeviceAttribute, device)
	end

	---Menjalankan fungsi `setCustomTitle`.
	---@param player any Nilai parameter `player`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	---@param payload any Nilai parameter `payload`.
	---@param cfg any Nilai parameter `cfg`.
	---@param profiles any Nilai parameter `profiles`.
	function CustomTitleHandler.setCustomTitle(player, targetUserId, payload, cfg, profiles)
		if not RoleChecker.canManageOthers(player, cfg) then
			return false, "NotPrivileged"
		end
		if typeof(targetUserId) ~= "number" then
			return false, "InvalidTarget"
		end
		local target = Players:GetPlayerByUserId(targetUserId)
		if not target then
			return false, "TargetOffline"
		end

		local maxSlots, maxLen = resolveLimits(cfg)
		local text = ""
		if typeof(payload) == "table" and (payload.text or payload.Text) then
			text = tostring(payload.text or payload.Text)
		elseif typeof(payload) == "string" then
			text = payload
		end
		text = sanitizeText(text, maxLen)
		if text == "" then
			return false, "EmptyText"
		end

		local colors = {}
		if typeof(payload) == "table" and typeof(payload.colors) == "table" then
			for _, entry in ipairs(payload.colors) do
				local color = ColorUtil.sanitizeColor(entry)
				if color then
					table.insert(colors, color)
				end
				if #colors >= 4 then
					break
				end
			end
		end
		if #colors == 0 then
			table.insert(colors, Color3.fromRGB(255, 255, 255))
		end
		local textColor = colors[1]
		local gradientStr = ColorUtil.encodeColors(colors)

		local mode = typeof(payload) == "table" and (payload.mode or payload.Mode) or nil
		if not isValidMode(mode) then
			mode = TitleModes.EffectModes[1]
		end

		local slot = typeof(payload) == "table" and tonumber(payload.slot or payload.Slot) or nil
		if slot then
			slot = math.clamp(math.floor(slot + 0.5), 1, cfg.MaxCustomTitleSlots or 7)
		end
		slot = slot or 1

		target:SetAttribute(slotAttr(cfg.CustomTitleTextAttribute, slot), text)
		target:SetAttribute(slotAttr(cfg.CustomTitleTextColorAttribute, slot), textColor)
		target:SetAttribute(slotAttr(cfg.CustomTitleTextGradientAttribute, slot), gradientStr)
		target:SetAttribute(slotAttr(cfg.CustomTitleModeAttribute, slot), mode)
		target:SetAttribute(cfg.CustomTitleSlotAttribute, slot)

		ProfileManager.saveSlot(profiles[target], slot, text, textColor, mode, gradientStr, ColorUtil.colorToTable)

		return true
	end

	---Menjalankan fungsi `clearCustomTitle`.
	---@param player any Nilai parameter `player`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	---@param slot any Nilai parameter `slot`.
	---@param cfg any Nilai parameter `cfg`.
	---@param profiles any Nilai parameter `profiles`.
	function CustomTitleHandler.clearCustomTitle(player, targetUserId, slot, cfg, profiles)
		if typeof(targetUserId) ~= "number" then
			return false, "InvalidTarget"
		end
		local target = Players:GetPlayerByUserId(targetUserId)
		if not target then
			return false, "TargetOffline"
		end
		if not RoleChecker.canClear(player, target, cfg) then
			return false, "NotPrivileged"
		end
		local maxSlots = resolveLimits(cfg)
		local slotNum = tonumber(slot)
		if slotNum and slotNum >= 1 and slotNum <= maxSlots then
			target:SetAttribute(slotAttr(cfg.CustomTitleTextAttribute, slotNum), nil)
			target:SetAttribute(slotAttr(cfg.CustomTitleTextColorAttribute, slotNum), nil)
			target:SetAttribute(slotAttr(cfg.CustomTitleModeAttribute, slotNum), nil)
			target:SetAttribute(slotAttr(cfg.CustomTitleTextGradientAttribute, slotNum), nil)
			ProfileManager.clearSlot(profiles[target], slotNum)
		else
			for i = 1, maxSlots do
				target:SetAttribute(slotAttr(cfg.CustomTitleTextAttribute, i), nil)
				target:SetAttribute(slotAttr(cfg.CustomTitleTextColorAttribute, i), nil)
				target:SetAttribute(slotAttr(cfg.CustomTitleModeAttribute, i), nil)
				target:SetAttribute(slotAttr(cfg.CustomTitleTextGradientAttribute, i), nil)
			end
			target:SetAttribute(cfg.CustomTitleSlotAttribute, nil)
			ProfileManager.clear(profiles[target])
		end

		return true
	end

	__module = CustomTitleHandler

	if type(__module) == "table" then
		__module.__source = "Services/CustomTitle/CustomTitleHandler.luau"
	end
	Core.Services.CustomTitle.CustomTitleHandler = __module
end

---@class CoreServicesCustomTitleCustomTitleProfiles
---@field __source string Path sumber module `Services/CustomTitle/CustomTitleProfiles.luau`.
Core.Services.CustomTitle.CustomTitleProfiles = Core.Services.CustomTitle.CustomTitleProfiles or {}
do
	local __module = nil
	local CustomTitleProfiles = {}

	local ProfileManager = Core.Services.CustomTitle.ProfileManager

	---Menjalankan fungsi `startSession`.
	---@param store any Nilai parameter `store`.
	---@param profiles any Nilai parameter `profiles`.
	---@param player any Nilai parameter `player`.
	---@param cfg any Nilai parameter `cfg`.
	---@param tableToColor any Nilai parameter `tableToColor`.
	---@param slotAttr any Nilai parameter `slotAttr`.
	function CustomTitleProfiles.startSession(store, profiles, player, cfg, tableToColor, slotAttr)
		local profile = store:StartSessionAsync(tostring(player.UserId), {Cancel = function()
			return player.Parent ~= game:GetService("Players")
		end})
		if not profile then
			return
		end
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profiles[player] = profile
		ProfileManager.applyProfileToPlayer(player, profile, cfg, tableToColor, slotAttr)
	end

	---Menjalankan fungsi `endSession`.
	---@param profiles any Nilai parameter `profiles`.
	---@param player any Nilai parameter `player`.
	function CustomTitleProfiles.endSession(profiles, player)
		local profile = profiles[player]
		if profile then
			profile:EndSession()
		end
		profiles[player] = nil
	end

	__module = CustomTitleProfiles

	if type(__module) == "table" then
		__module.__source = "Services/CustomTitle/CustomTitleProfiles.luau"
	end
	Core.Services.CustomTitle.CustomTitleProfiles = __module
end

---@class CoreServicesDanceHelpersDanceStore
---@field __source string Path sumber module `Services/DanceHelpers/DanceStore.luau`.
---@field clear any Member public `clear` dari `Services/DanceHelpers/DanceStore.luau`.
---@field get any Member public `get` dari `Services/DanceHelpers/DanceStore.luau`.
---@field new any Member public `new` dari `Services/DanceHelpers/DanceStore.luau`.
---@field set any Member public `set` dari `Services/DanceHelpers/DanceStore.luau`.
Core.Services.DanceHelpers.DanceStore = Core.Services.DanceHelpers.DanceStore or {}
do
	local __module = nil
	local DanceStore = {}
	DanceStore.__index = DanceStore

	---Menjalankan fungsi `new`.
	---@return any result Hasil dari fungsi `new`.
	function DanceStore.new()
		return setmetatable({
			_states = {},
		}, DanceStore)
	end

	---Menjalankan fungsi `set`.
	---@param userId any Nilai parameter `userId`.
	---@param state any Nilai parameter `state`.
	function DanceStore:set(userId, state)
		self._states[userId] = state
	end

	---Menjalankan fungsi `get`.
	---@param userId any Nilai parameter `userId`.
	---@return any result Hasil dari fungsi `get`.
	function DanceStore:get(userId)
		return self._states[userId]
	end

	---Menjalankan fungsi `clear`.
	---@param userId any Nilai parameter `userId`.
	function DanceStore:clear(userId)
		self._states[userId] = nil
	end

	__module = DanceStore

	if type(__module) == "table" then
		__module.__source = "Services/DanceHelpers/DanceStore.luau"
	end
	Core.Services.DanceHelpers.DanceStore = __module
end

---@class CoreServicesDanceHelpersStateValidator
---@field __source string Path sumber module `Services/DanceHelpers/StateValidator.luau`.
Core.Services.DanceHelpers.StateValidator = Core.Services.DanceHelpers.StateValidator or {}
do
	local __module = nil
	local StateValidator = {}

	---Menjalankan fungsi `sanitize`.
	---@param state any Nilai parameter `state`.
	function StateValidator.sanitize(state)
		if typeof(state) ~= "table" then
			return nil
		end

		local animationId = tostring(state.animationId or "")
		if animationId == "" then
			return nil
		end

		local speed = tonumber(state.speed) or 1
		local startedAtServerTime = tonumber(state.startedAtServerTime) or workspace:GetServerTimeNow()

		return {
			animationId = animationId,
			animationName = tostring(state.animationName or ""),
			looped = state.looped == true,
			speed = speed,
			startedAtServerTime = startedAtServerTime,
		}
	end

	__module = StateValidator

	if type(__module) == "table" then
		__module.__source = "Services/DanceHelpers/StateValidator.luau"
	end
	Core.Services.DanceHelpers.StateValidator = __module
end

---@class CoreServicesDonationHelpersDonationBoardUpdater
---@field __source string Path sumber module `Services/DonationHelpers/DonationBoardUpdater.luau`.
---@field _config any Member private `_config` dari `Services/DonationHelpers/DonationBoardUpdater.luau`.
---@field _formatter any Member private `_formatter` dari `Services/DonationHelpers/DonationBoardUpdater.luau`.
---@field _listFrame any Member private `_listFrame` dari `Services/DonationHelpers/DonationBoardUpdater.luau`.
---@field _listRenderer any Member private `_listRenderer` dari `Services/DonationHelpers/DonationBoardUpdater.luau`.
---@field _podium any Member private `_podium` dari `Services/DonationHelpers/DonationBoardUpdater.luau`.
---@field _podiumClass any Member private `_podiumClass` dari `Services/DonationHelpers/DonationBoardUpdater.luau`.
---@field _profileCache any Member private `_profileCache` dari `Services/DonationHelpers/DonationBoardUpdater.luau`.
---@field _store any Member private `_store` dari `Services/DonationHelpers/DonationBoardUpdater.luau`.
---@field _template any Member private `_template` dari `Services/DonationHelpers/DonationBoardUpdater.luau`.
---@field _uiResolver any Member private `_uiResolver` dari `Services/DonationHelpers/DonationBoardUpdater.luau`.
Core.Services.DonationHelpers.DonationBoardUpdater = Core.Services.DonationHelpers.DonationBoardUpdater or {}
do
	local __module = nil
	local DonationBoardUpdater = {}
	DonationBoardUpdater.__index = DonationBoardUpdater

	---Menjalankan fungsi `new`.
	---@param config any Nilai parameter `config`.
	---@param uiResolver any Nilai parameter `uiResolver`.
	---@param listRenderer any Nilai parameter `listRenderer`.
	---@param podiumClass any Nilai parameter `podiumClass`.
	---@param formatter any Nilai parameter `formatter`.
	---@param profileCache any Nilai parameter `profileCache`.
	---@param store any Nilai parameter `store`.
	---@return any result Hasil dari fungsi `new`.
	function DonationBoardUpdater.new(config, uiResolver, listRenderer, podiumClass, formatter, profileCache, store)
		local self = setmetatable({}, DonationBoardUpdater)
		self._config = config
		self._uiResolver = uiResolver
		self._listRenderer = listRenderer
		self._podiumClass = podiumClass
		self._formatter = formatter
		self._profileCache = profileCache
		self._store = store
		self._listFrame = nil
		self._template = nil
		self._podium = nil
		return self
	end

	---@private
	---Menjalankan fungsi `_ensureUi`.
	function DonationBoardUpdater:_ensureUi()
		if self._listFrame and self._template and self._podium then
			return true
		end

		local ok, refsOrErr = self._uiResolver.resolve()
		if not ok then
			return false
		end

		self._listFrame = refsOrErr.listFrame
		self._template = refsOrErr.template
		self._podium = self._podiumClass.new(refsOrErr.podium, self._config.Podium or {}, self._formatter)
		return true
	end

	---Menjalankan fungsi `refresh`.
	function DonationBoardUpdater:refresh()
		
		if not self._store then
			
			return
		end
		if not self:_ensureUi() then
			
			return
		end
		
		local fetchLimit = math.clamp(self._config.FetchLimit or 50, 1, 100)
		local maxRows = math.max(1, self._config.MaxRows or 50)
		local minValue = self._config.MinValue or 1

		local ok, pages = pcall(function()
			return self._store:GetSortedAsync(false, fetchLimit)
		end)
		if not ok or not pages then
			if self._listRenderer and self._listFrame then
				self._listRenderer.render(self._listFrame, self._template, {}, self._formatter)
			end
			return
		end

		local entries = {}
		for _, item in ipairs(pages:GetCurrentPage()) do
			if #entries >= maxRows then
				break
			end
			local userId = tonumber(item.key)
			local value = tonumber(item.value) or 0
			if userId and value >= minValue then
				table.insert(entries, {
					UserId = userId,
					Amount = value,
					Username = self._profileCache:getName(userId),
					DisplayName = self._profileCache:getDisplayName(userId),
					Thumbnail = self._profileCache:getThumbnail(userId),
				})
			end
		end

		self._listRenderer.render(self._listFrame, self._template, entries, self._formatter)
		if self._podium then
			self._podium:update(entries)
		end
	end

	__module = DonationBoardUpdater

	if type(__module) == "table" then
		__module.__source = "Services/DonationHelpers/DonationBoardUpdater.luau"
	end
	Core.Services.DonationHelpers.DonationBoardUpdater = __module
end

---@class CoreServicesDonationHelpersPurchaseHandler
---@field __source string Path sumber module `Services/DonationHelpers/PurchaseHandler.luau`.
---@field _config any Member private `_config` dari `Services/DonationHelpers/PurchaseHandler.luau`.
---@field _donateSignal any Member private `_donateSignal` dari `Services/DonationHelpers/PurchaseHandler.luau`.
---@field _priceCache any Member private `_priceCache` dari `Services/DonationHelpers/PurchaseHandler.luau`.
---@field _store any Member private `_store` dari `Services/DonationHelpers/PurchaseHandler.luau`.
Core.Services.DonationHelpers.PurchaseHandler = Core.Services.DonationHelpers.PurchaseHandler or {}
do
	local __module = nil
	local MarketplaceService = game:GetService("MarketplaceService")
	local Players = game:GetService("Players")

	local PurchaseHandler = {}
	PurchaseHandler.__index = PurchaseHandler

	---Menjalankan fungsi `new`.
	---@param config any Nilai parameter `config`.
	---@param store any Nilai parameter `store`.
	---@param donateSignal any Nilai parameter `donateSignal`.
	---@return any result Hasil dari fungsi `new`.
	function PurchaseHandler.new(config, store, donateSignal)
		local self = setmetatable({}, PurchaseHandler)
		self._config = config or {}
		self._store = store
		self._donateSignal = donateSignal
		self._priceCache = {}
		return self
	end

	---@private
	---Menjalankan fungsi `_shouldIgnoreProduct`.
	---@param productId any Nilai parameter `productId`.
	function PurchaseHandler:_shouldIgnoreProduct(productId)
		for _, id in ipairs(self._config.IgnoredProductIds or {}) do
			if id and id ~= 0 and id == productId then
				return true
			end
		end
		return false
	end

	---@private
	---Menjalankan fungsi `_getProductPrice`.
	---@param productId any Nilai parameter `productId`.
	function PurchaseHandler:_getProductPrice(productId)
		if self._priceCache[productId] ~= nil then
			return self._priceCache[productId]
		end
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
		end)
		local price = ok and info and info.PriceInRobux or nil
		self._priceCache[productId] = price
		return price
	end

	---Menjalankan fungsi `process`.
	---@param receiptInfo any Nilai parameter `receiptInfo`.
	function PurchaseHandler:process(receiptInfo)
		local productId = receiptInfo.ProductId
		if self:_shouldIgnoreProduct(productId) then
			return Enum.ProductPurchaseDecision.PurchaseGranted, false
		end

		local price = self:_getProductPrice(productId)
		if not price or price <= 0 then
			return Enum.ProductPurchaseDecision.PurchaseGranted, false
		end

		local userId = receiptInfo.PlayerId
		local ok = pcall(function()
			self._store:UpdateAsync(tostring(userId), function(oldValue)
				return (oldValue or 0) + price
			end)
		end)
		if not ok then
			return Enum.ProductPurchaseDecision.NotProcessedYet, false
		end

		local player = Players:GetPlayerByUserId(userId)
		if player and self._donateSignal then
			local displayName = (player.DisplayName ~= "" and player.DisplayName) or player.Name
			self._donateSignal:FireAll(player.UserId, displayName, price)
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted, true
	end

	__module = PurchaseHandler

	if type(__module) == "table" then
		__module.__source = "Services/DonationHelpers/PurchaseHandler.luau"
	end
	Core.Services.DonationHelpers.PurchaseHandler = __module
end

---@class CoreServicesLeaderboardHelpersLeaderboardRenderer
---@field __source string Path sumber module `Services/LeaderboardHelpers/LeaderboardRenderer.luau`.
Core.Services.LeaderboardHelpers.LeaderboardRenderer = Core.Services.LeaderboardHelpers.LeaderboardRenderer or {}
do
	local __module = nil
	local LeaderboardRenderer = {}

	---Menjalankan fungsi `buildEntries`.
	---@param pages any Nilai parameter `pages`.
	---@param maxRows any Nilai parameter `maxRows`.
	---@param minValue any Nilai parameter `minValue`.
	---@param filterUtil any Nilai parameter `filterUtil`.
	---@param overheadConfig any Nilai parameter `overheadConfig`.
	---@param valueMapper any Nilai parameter `valueMapper`.
	function LeaderboardRenderer.buildEntries(pages, maxRows, minValue, filterUtil, overheadConfig, valueMapper)
		local data = pages:GetCurrentPage()
		local entries = {}
		local shown = 0

		for _, entry in ipairs(data) do
			local userId = tonumber(entry.key)
			local value = tonumber(entry.value) or 0
			local mapped = valueMapper(value)

			if not userId or mapped == nil then
				continue
			end

			if mapped < minValue then
				continue
			end
			local isExempt = false
			if filterUtil then
				if filterUtil.isExemptFromLeaderboard then
					isExempt = filterUtil.isExemptFromLeaderboard(userId, nil, overheadConfig) == true 
				elseif filterUtil.isPrivileged then 
					isExempt = filterUtil.isPrivileged(userId, nil, overheadConfig) == true
				end
			end

			if isExempt then 
				continue 
			end

			shown += 1
			if shown > maxRows then
				break
			end
			table.insert(entries, {
				UserId = userId,
				Rank = shown,
				StatsText = tostring(mapped),
			})
		end
		return entries
	end

	---Menjalankan fungsi `render`.
	---@param store any Nilai parameter `store`.
	---@param pageSize any Nilai parameter `pageSize`.
	---@param maxRows any Nilai parameter `maxRows`.
	---@param minValue any Nilai parameter `minValue`.
	---@param filterUtil any Nilai parameter `filterUtil`.
	---@param overheadConfig any Nilai parameter `overheadConfig`.
	---@param valueMapper any Nilai parameter `valueMapper`.
	---@param formatter any Nilai parameter `formatter`.
	---@param listRenderer any Nilai parameter `listRenderer`.
	---@param listFrame any Nilai parameter `listFrame`.
	---@param template any Nilai parameter `template`.
	---@param profileCache any Nilai parameter `profileCache`.
	function LeaderboardRenderer.render(store, pageSize, maxRows, minValue, filterUtil, overheadConfig, valueMapper, formatter, listRenderer, listFrame, template, profileCache)
		local ok, pages = pcall(function()
			return store:GetSortedAsync(false, pageSize)
		end)
		if not ok or not pages then
			if listRenderer and listFrame then
				listRenderer.render(listFrame, template, {}, profileCache)
			end
			return
		end

		local entries = LeaderboardRenderer.buildEntries(pages, maxRows, minValue, filterUtil, overheadConfig, valueMapper)
		if formatter then
			for _, entry in ipairs(entries) do
				entry.StatsText = formatter(tonumber(entry.StatsText) or 0)
			end
		end
		listRenderer.render(listFrame, template, entries, profileCache)
	end

	__module = LeaderboardRenderer

	if type(__module) == "table" then
		__module.__source = "Services/LeaderboardHelpers/LeaderboardRenderer.luau"
	end
	Core.Services.LeaderboardHelpers.LeaderboardRenderer = __module
end

---@class CoreServicesOverheadHelpersConfigProvider
---@field __source string Path sumber module `Services/OverheadHelpers/ConfigProvider.luau`.
---@field PlaceOwnerId any Member public `PlaceOwnerId` dari `Services/OverheadHelpers/ConfigProvider.luau`.
Core.Services.OverheadHelpers.ConfigProvider = Core.Services.OverheadHelpers.ConfigProvider or {}
do
	local __module = nil
	local ConfigProvider = {}

	---Menjalankan fungsi `build`.
	---@param overheadConfig any Nilai parameter `overheadConfig`.
	function ConfigProvider.build(overheadConfig)
		local cfg = table.clone(overheadConfig)
		if (not cfg.PlaceOwnerId) and game.CreatorType == Enum.CreatorType.User then
			cfg.PlaceOwnerId = game.CreatorId
		end
		return cfg
	end

	__module = ConfigProvider

	if type(__module) == "table" then
		__module.__source = "Services/OverheadHelpers/ConfigProvider.luau"
	end
	Core.Services.OverheadHelpers.ConfigProvider = __module
end

---@class CoreServicesPlayerListHelpersProfileProvider
---@field __source string Path sumber module `Services/PlayerListHelpers/ProfileProvider.luau`.
Core.Services.PlayerListHelpers.ProfileProvider = Core.Services.PlayerListHelpers.ProfileProvider or {}
do
	local __module = nil
	local ProfileProvider = {}

	---@private
	---Menjalankan fungsi `getProfileWithRetry`.
	---@param profileStore any Nilai parameter `profileStore`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `getProfileWithRetry`.
	local function getProfileWithRetry(profileStore, player)
		if not profileStore then
			return nil
		end

		local profile = profileStore:GetProfile(player)
		if profile then
			return profile
		end

		for _ = 1, 5 do
			task.wait(0.4)
			profile = profileStore:GetProfile(player)
			if profile then
				return profile
			end
		end

		return nil
	end

	---Menjalankan fungsi `readCheckpoint`.
	---@param checkpointService any Nilai parameter `checkpointService`.
	---@param player any Nilai parameter `player`.
	function ProfileProvider.readCheckpoint(checkpointService, player)
		if not checkpointService or not checkpointService._profiles then
			return 0, 0
		end

		local profile = getProfileWithRetry(checkpointService._profiles, player)
		if not (profile and profile.Data) then
			return 0, 0
		end

		return tonumber(profile.Data.lastIndex) or 0, tonumber(profile.Data.summitCount) or 0
	end

	---Menjalankan fungsi `readBestTime`.
	---@param speedrunService any Nilai parameter `speedrunService`.
	---@param player any Nilai parameter `player`.
	function ProfileProvider.readBestTime(speedrunService, player)
		if not speedrunService or not speedrunService._profiles then
			return nil
		end

		local profile = getProfileWithRetry(speedrunService._profiles, player)
		if not (profile and profile.Data) then
			return nil
		end

		return profile.Data.bestTime
	end

	__module = ProfileProvider

	if type(__module) == "table" then
		__module.__source = "Services/PlayerListHelpers/ProfileProvider.luau"
	end
	Core.Services.PlayerListHelpers.ProfileProvider = __module
end

---@class CoreServicesPlayerListHelpersStatsProvider
---@field __source string Path sumber module `Services/PlayerListHelpers/StatsProvider.luau`.
Core.Services.PlayerListHelpers.StatsProvider = Core.Services.PlayerListHelpers.StatsProvider or {}
do
	local __module = nil
	local ServerScriptService = game:GetService("ServerScriptService")

	local Server = serverFolder
	local CheckpointIndex = Core.Modules.Checkpoint.Index
	local ProfileProvider = Core.Services.PlayerListHelpers.ProfileProvider

	local StatsProvider = {}

	---@private
	---Menjalankan fungsi `formatTime`.
	---@param seconds any Nilai parameter `seconds`.
	local function formatTime(seconds)
		if not seconds or seconds <= 0 then
			return "00:00"
		end

		local mins = math.floor(seconds / 60)
		local secs = seconds % 60
		return string.format("%02d:%02d", mins, secs)
	end

	---@private
	---Menjalankan fungsi `resolveDisplayPos`.
	---@param pos any Nilai parameter `pos`.
	local function resolveDisplayPos(pos)
		if CheckpointIndex.StartIndex ~= nil and pos == CheckpointIndex.StartIndex then
			return "Basecamp"
		end

		if CheckpointIndex.FinishStartIndex ~= nil
			and CheckpointIndex.FinishIndex ~= nil
			and pos >= CheckpointIndex.FinishStartIndex
			and pos <= CheckpointIndex.FinishIndex then
			return "Summit"
		end

		return pos
	end

	---Menjalankan fungsi `build`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	function StatsProvider.build(service, player)
		local pos, puncak = ProfileProvider.readCheckpoint(service._checkpointService, player)
		local bestTime = formatTime(ProfileProvider.readBestTime(service._speedrunService, player))

		return {
			Posisi = resolveDisplayPos(pos),
			Puncak = puncak,
			BestTime = bestTime,
		}
	end

	---Menjalankan fungsi `snapshot`.
	---@param service any Nilai parameter `service`.
	---@param players any Nilai parameter `players`.
	function StatsProvider.snapshot(service, players)
		local list = {}
		for _, player in ipairs(players) do
			list[tostring(player.UserId)] = StatsProvider.build(service, player)
		end
		return list
	end

	__module = StatsProvider

	if type(__module) == "table" then
		__module.__source = "Services/PlayerListHelpers/StatsProvider.luau"
	end
	Core.Services.PlayerListHelpers.StatsProvider = __module
end

---@class CoreServicesSpeedrunHelpersPlayerHandler
---@field __source string Path sumber module `Services/SpeedrunHelpers/PlayerHandler.luau`.
Core.Services.SpeedrunHelpers.PlayerHandler = Core.Services.SpeedrunHelpers.PlayerHandler or {}
do
	local __module = nil
	local Players = game:GetService("Players")

	local PlayerHandler = {}

	---Menjalankan fungsi `handleAdded`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	function PlayerHandler.handleAdded(service, player)
		local existingProfile = service._profiles:GetProfile(player)
		if existingProfile then
			if existingProfile.Data and existingProfile.Data.bestTime then
				service._statsSync:applyToLeaderstats(player, existingProfile.Data.bestTime)
				service._leaderboard:updateBestTime(player.UserId, existingProfile.Data.bestTime)
			end
			return
		end

		local profile = service._profiles:Load(player)
		if profile and profile.Data and profile.Data.bestTime then
			service._statsSync:applyToLeaderstats(player, profile.Data.bestTime)
			service._leaderboard:updateBestTime(player.UserId, profile.Data.bestTime)
		end
	end

	---Menjalankan fungsi `handleRemoving`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	function PlayerHandler.handleRemoving(service, player)
		service._flow:clear(player)
		service._profiles:Release(player)
	end

	---Menjalankan fungsi `bind`.
	---@param service any Nilai parameter `service`.
	---@param includeExistingPlayers any Nilai parameter `includeExistingPlayers`.
	function PlayerHandler.bind(service, includeExistingPlayers)
		service._handlePlayerAdded = function(player)
			PlayerHandler.handleAdded(service, player)
		end

		service._handlePlayerRemoving = function(player)
			PlayerHandler.handleRemoving(service, player)
		end

		service._janitor:Add(Players.PlayerAdded:Connect(service._handlePlayerAdded), "Disconnect")
		service._janitor:Add(Players.PlayerRemoving:Connect(service._handlePlayerRemoving), "Disconnect")

		if includeExistingPlayers ~= false then
			for _, player in ipairs(Players:GetPlayers()) do
				service._handlePlayerAdded(player)
			end
		end
	end

	---Menjalankan fungsi `startExisting`.
	---@param service any Nilai parameter `service`.
	function PlayerHandler.startExisting(service)
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(service._handlePlayerAdded, player)
		end
	end

	__module = PlayerHandler

	if type(__module) == "table" then
		__module.__source = "Services/SpeedrunHelpers/PlayerHandler.luau"
	end
	Core.Services.SpeedrunHelpers.PlayerHandler = __module
end

---@class CoreServicesSpeedrunHelpersResetHandler
---@field __source string Path sumber module `Services/SpeedrunHelpers/ResetHandler.luau`.
Core.Services.SpeedrunHelpers.ResetHandler = Core.Services.SpeedrunHelpers.ResetHandler or {}
do
	local __module = nil
	local Players = game:GetService("Players")

	local ResetHandler = {}

	---Menjalankan fungsi `resetBestTime`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	function ResetHandler.resetBestTime(service, player)
		service._profiles:SetBestTime(player, nil)
		service._statsSync:resetLeaderstats(player)
		service._leaderboard:remove(player.UserId)
	end

	---Menjalankan fungsi `resetBestTimeByUserId`.
	---@param service any Nilai parameter `service`.
	---@param userId any Nilai parameter `userId`.
	function ResetHandler.resetBestTimeByUserId(service, userId)
		if not userId then
			return
		end

		service._profiles:SetBestTimeByUserId(userId, nil)
		local online = Players:GetPlayerByUserId(userId)
		if online then
			service._statsSync:resetLeaderstats(online)
		end
		service._leaderboard:remove(userId)
	end

	---Menjalankan fungsi `resetAllBestTimes`.
	---@param service any Nilai parameter `service`.
	function ResetHandler.resetAllBestTimes(service)
		for _, player in ipairs(Players:GetPlayers()) do
			service._profiles:SetBestTime(player, nil)
			service._statsSync:resetLeaderstats(player)
		end

		pcall(function()
			local pages = service._bestTimeBoard:GetSortedAsync(false, 100)
			while true do
				local data = pages:GetCurrentPage()
				for _, entry in ipairs(data) do
					local key = entry.key
					local userId = tonumber(key)
					if userId then
						service._profiles:SetBestTimeByUserId(userId, nil)
					end
					service._leaderboard:remove(userId or key)
				end
				if pages.IsFinished then
					break
				end
				pages:AdvanceToNextPageAsync()
			end
		end)
	end

	__module = ResetHandler

	if type(__module) == "table" then
		__module.__source = "Services/SpeedrunHelpers/ResetHandler.luau"
	end
	Core.Services.SpeedrunHelpers.ResetHandler = __module
end

---@class CoreServicesSpeedrunHelpersTriggerHandler
---@field __source string Path sumber module `Services/SpeedrunHelpers/TriggerHandler.luau`.
Core.Services.SpeedrunHelpers.TriggerHandler = Core.Services.SpeedrunHelpers.TriggerHandler or {}
do
	local __module = nil
	local TriggerBinder = Core.Modules.Speedrun.TriggerBinder

	local TriggerHandler = {}

	---@private
	---Menjalankan fungsi `onRunStarted`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	local function onRunStarted(service, player)
		if service._flow:start(player) then
			service.Client.RunStarted:Fire(player)
		end
	end

	---@private
	---Menjalankan fungsi `onRunFinished`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	local function onRunFinished(service, player)
		local ok, elapsed = service._flow:finish(player)
		if not ok or not elapsed then
			return
		end

		if not service._antiCheat:check(player, elapsed) then
			return
		end

		local currentBest = service._profiles:GetBestTime(player)
		if elapsed > 0 and (not currentBest or elapsed < currentBest) then
			service._profiles:SetBestTime(player, elapsed)
			service._statsSync:applyToLeaderstats(player, elapsed)
			service._leaderboard:updateBestTime(player.UserId, elapsed)
		end

		service.Client.RunFinished:Fire(player, elapsed)
	end

	---Menjalankan fungsi `bind`.
	---@param service any Nilai parameter `service`.
	function TriggerHandler.bind(service)
		if not service._index:isReady() then
			warn("[Speedrun] Start/Finish not found. Check SpeedrunConfig and Workspace path.")
			return
		end

		TriggerBinder.bind(
			service._janitor,
			service._index.startParts or service._index.startPart,
			service._index.finishParts or service._index.finishPart,
			function(player)
				onRunStarted(service, player)
			end,
			function(player)
				onRunFinished(service, player)
			end
		)
	end

	__module = TriggerHandler

	if type(__module) == "table" then
		__module.__source = "Services/SpeedrunHelpers/TriggerHandler.luau"
	end
	Core.Services.SpeedrunHelpers.TriggerHandler = __module
end

---@class CoreServicesVipHelpersGamePassChecker
---@field __source string Path sumber module `Services/VipHelpers/GamePassChecker.luau`.
---@field check any Member public `check` dari `Services/VipHelpers/GamePassChecker.luau`.
Core.Services.VipHelpers.GamePassChecker = Core.Services.VipHelpers.GamePassChecker or {}
do
	local __module = nil
	local MarketplaceService = game:GetService("MarketplaceService")
	local Promise = require(game:GetService("ReplicatedStorage").Shared.Packages.Promise)

	local GamePassChecker = {}

	---Menjalankan fungsi `check`.
	---@param _service any Nilai parameter `_service`.
	---@param player any Nilai parameter `player`.
	---@param config any Nilai parameter `config`.
	function GamePassChecker.check(_service, player, config)
		local passId = config.GamePassId
		if not passId or passId == 0 then
			return Promise.resolve(false)
		end
		return Promise.new(function(resolve)
			-- M-03 Fix: Retry up to 3 times on transient API errors, cache positive ownership
			local attempts = 0
			local owns = false
			local success = false
			while attempts < 3 and not success do
				attempts += 1
				local ok, res = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
				end)
				if ok then
					success = true
					owns = (res == true)
				else
					if attempts < 3 then task.wait(0.5 * attempts) end
				end
			end
			if not success then
				warn("[GamePassChecker] Failed to check pass " .. tostring(passId) .. " for " .. player.Name .. " after 3 attempts.")
				-- Graceful degradation: do not revoke if player already has VIP attribute
				if player:GetAttribute("VIP") == true and config.Name == "VIP" then
					owns = true
				end
			end
			resolve(owns)
		end)
	end

	__module = GamePassChecker

	if type(__module) == "table" then
		__module.__source = "Services/VipHelpers/GamePassChecker.luau"
	end
	Core.Services.VipHelpers.GamePassChecker = __module
end

---@class CoreServicesVipHelpersGiftHandler
---@field __source string Path sumber module `Services/VipHelpers/GiftHandler.luau`.
Core.Services.VipHelpers.GiftHandler = Core.Services.VipHelpers.GiftHandler or {}
do
	local __module = nil
	local Players = game:GetService("Players")

	local GiftHandler = {}

	---Menjalankan fungsi `begin`.
	---@param service any Nilai parameter `service`.
	---@param player any Nilai parameter `player`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	function GiftHandler.begin(service, player, targetUserId)
		if typeof(targetUserId) ~= "number" then
			return false, "InvalidTarget"
		end
		local target = Players:GetPlayerByUserId(targetUserId)
		if target then
			if service._profiles:IsVip(target) then
				return false, "AlreadyVip"
			end
		else
			local ok, isVip = pcall(function()
				return service._profiles:IsVipByUserId(targetUserId)
			end)
			if ok and isVip == true then
				return false, "AlreadyVip"
			end
		end
		service._pendingGifts[player.UserId] = targetUserId
		return true
	end

	---Menjalankan fungsi `notify`.
	---@param service any Nilai parameter `service`.
	---@param gifterId any Nilai parameter `gifterId`.
	---@param targetId any Nilai parameter `targetId`.
	function GiftHandler.notify(service, gifterId, targetId)
		if not gifterId or not targetId then
			return
		end
		local giver = Players:GetPlayerByUserId(gifterId)
		local receiver = Players:GetPlayerByUserId(targetId)

		local giverName = giver and (giver.DisplayName ~= "" and giver.DisplayName or giver.Name) or "Unknown"
		local receiverName = receiver and (receiver.DisplayName ~= "" and receiver.DisplayName or receiver.Name) or "Unknown"

		if not giver then
			local ok, name = pcall(function()
				return Players:GetNameFromUserIdAsync(gifterId)
			end)
			if ok and name then
				giverName = name
			end
		end
		if not receiver then
			local ok, name = pcall(function()
				return Players:GetNameFromUserIdAsync(targetId)
			end)
			if ok and name then
				receiverName = name
			end
		end

		if giver then
			service.Client.GiftNotice:Fire(giver, "giver", targetId, receiverName)
		end
		if receiver then
			service.Client.GiftNotice:Fire(receiver, "receiver", gifterId, giverName)
		end
	end

	__module = GiftHandler

	if type(__module) == "table" then
		__module.__source = "Services/VipHelpers/GiftHandler.luau"
	end
	Core.Services.VipHelpers.GiftHandler = __module
end

---@class CoreServicesVipHelpersPurchaseRouter
---@field __source string Path sumber module `Services/VipHelpers/PurchaseRouter.luau`.
Core.Services.VipHelpers.PurchaseRouter = Core.Services.VipHelpers.PurchaseRouter or {}
do
	local __module = nil
	local Knit = require(game:GetService("ReplicatedStorage").Shared.Packages.Knit)

	local PurchaseRouter = {}

	---@private
	---Menjalankan fungsi `tryServiceReceipt`.
	---@param serviceName any Nilai parameter `serviceName`.
	---@param receiptInfo any Nilai parameter `receiptInfo`.
	local function tryServiceReceipt(serviceName, receiptInfo)
		local okService, service = pcall(function()
			return Knit.GetService(serviceName)
		end)
		if not (okService and service and service.ProcessReceipt) then
			return nil
		end

		local okProcess, result = pcall(function()
			return service:ProcessReceipt(receiptInfo)
		end)
		if okProcess and result then
			return result
		end

		return nil
	end

	---Menjalankan fungsi `route`.
	---@param receiptInfo any Nilai parameter `receiptInfo`.
	function PurchaseRouter.route(receiptInfo)
		return tryServiceReceipt("ShopService", receiptInfo)
			or tryServiceReceipt("DonationsService", receiptInfo)
			or Enum.ProductPurchaseDecision.NotProcessedYet
	end

	__module = PurchaseRouter

	if type(__module) == "table" then
		__module.__source = "Services/VipHelpers/PurchaseRouter.luau"
	end
	Core.Services.VipHelpers.PurchaseRouter = __module
end

---@class CoreServicesVipHelpersToolGiver
---@field __source string Path sumber module `Services/VipHelpers/ToolGiver.luau`.
Core.Services.VipHelpers.ToolGiver = Core.Services.VipHelpers.ToolGiver or {}
do
	local __module = nil
	local ServerStorage = game:GetService("ServerStorage")

	local ToolGiver = {}

	---Menjalankan fungsi `giveVipTools`.
	---@param player any Nilai parameter `player`.
	function ToolGiver.giveVipTools(player)
		local toolsFolder = ServerStorage:FindFirstChild("VIPTools")
		if not toolsFolder then
			warn("[VipService] VIPTools folder not found in ServerStorage")
			return
		end

		local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 10)
		local starterGear = player:FindFirstChildOfClass("StarterGear") or player:WaitForChild("StarterGear", 10)

		for _, tool in ipairs(toolsFolder:GetChildren()) do
			if tool:IsA("Tool") then
				if backpack then
					local existing = backpack:FindFirstChild(tool.Name)
					if existing then
						existing:Destroy()
					end
					tool:Clone().Parent = backpack
				end

				if starterGear then
					local existingSG = starterGear:FindFirstChild(tool.Name)
					if existingSG then
						existingSG:Destroy()
					end
					tool:Clone().Parent = starterGear
				end
			end
		end
	end

	__module = ToolGiver

	if type(__module) == "table" then
		__module.__source = "Services/VipHelpers/ToolGiver.luau"
	end
	Core.Services.VipHelpers.ToolGiver = __module
end

---@class CoreServicesAdminService
---@field __source string Path sumber module `Services/AdminService.luau`.
Core.Services.AdminService = Core.Services.AdminService or {}
do
	local __module = nil
	local Players = game:GetService("Players")
	local ServerStorage = game:GetService("ServerStorage")
	local MessagingService = game:GetService("MessagingService")
	local RunService = game:GetService("RunService")
	local TeleportService = game:GetService("TeleportService")
	local ServerPackages = game:FindFirstChild("ServerPackages")
	if not ServerPackages then
		local serverRoot = game:GetService("ServerScriptService"):FindFirstChild("Server")
		ServerPackages = serverRoot and serverRoot:FindFirstChild("Package")
	end

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Shared = ReplicatedStorage.Shared
	local Packages = Shared.Packages
	local Knit = require(Packages.Knit)
	local Janitor = require(Packages.Janitor)
	local Timer = require(Packages.Timer)

	local ServerScriptService = game:GetService("ServerScriptService")
	local Server = serverFolder
	local Config = Server.Config
	local Modules = Core.Modules

	if not ServerPackages then
		error("[AdminService] ServerPackages not found. Ensure ServerPackages (or Server.Package) exists.")
	end
	local ProfileStore = require(ServerPackages.ProfileStore)

	local AdminConfig = require(Config.AdminConfig)
	local OverheadConfig = require(Config.OverheadConfig)
	local CheckpointIndex = Core.Modules.Checkpoint.Index

	local AdminHelpers = Core.Modules.AdminHelpers
	local AdminUtils = Core.Modules.AdminHelpers.Utils
	local AdminPermissions = Core.Modules.AdminHelpers.Permissions
	local AdminLogs = Core.Modules.AdminHelpers.Logs
	local AdminActions = Core.Modules.AdminHelpers.Actions
	local AdminServerControl = Core.Modules.AdminHelpers.ServerControl
	local AdminJail = Core.Modules.AdminHelpers.Jail
	local AdminBinds = Core.Modules.AdminHelpers.Binds
	local AdminOverhead = Core.Modules.AdminHelpers.Overhead
	local AdminRefresh = Core.Modules.AdminHelpers.Refresh
	local AdminBootstrap = Core.Modules.AdminHelpers.Bootstrap
	local AdminProfiles = Core.Modules.AdminHelpers.Profiles
	local AdminNotifications = Core.Modules.AdminHelpers.Notifications
	local AdminUnbanBinder = Core.Modules.AdminHelpers.Commands.UnbanCommandBinder

	local AdminService = Knit.CreateService({
		Name = "AdminService",
		Client = {
			Uptime = Knit.CreateSignal(),
			Announcement = Knit.CreateSignal(),
			Log = Knit.CreateSignal(),
			Notice = Knit.CreateSignal(),
		},
	})

	---@private
	---Menjalankan fungsi `_bindUptime`.
	function AdminService:_bindUptime()
		AdminBinds.bindUptime(self)
	end

	---@private
	---Menjalankan fungsi `_bindPlayers`.
	function AdminService:_bindPlayers()
		AdminBinds.bindPlayers(self)
	end

	---@private
	---Menjalankan fungsi `_bindMessaging`.
	function AdminService:_bindMessaging()
		AdminBinds.bindMessaging(self)
	end

	---Menjalankan fungsi `KnitInit`.
	function AdminService:KnitInit()
		self._janitor = Janitor.new()
		self._startTime = os.time()
		self._extraRoles = {}
		self._jailModels = {}
		self._jailGuards = {}
		self._jailRejoinConns = {}
		self._jailLastPos = {}
		self._jailProfiles = {}
		self._banProfiles = {}
		self._roleProfiles = {}
		self._logs = {}
		self._logCounter = 0
		self._logMax = tonumber(AdminConfig.LogMax) or 100
		self._serverLocked = false
		self._summitEvent = {
			active = false,
			value = 0,
			durationHours = 0,
			startedAt = 0,
			endsAt = 0,
		}
		self._jailStore = ProfileStore.New(DataStoreConfig.Stores.AdminJailProfiles, {
			isJailed = false,
			pos = nil,
		})

		self._banStore = ProfileStore.New(AdminConfig.BanDataStoreKey or DataStoreConfig.Stores.AdminBans, {
			banned = false,
		})
		self._roleStore = ProfileStore.New(AdminConfig.RoleDataStoreKey or DataStoreConfig.Stores.AdminRoles, {
			role = "Member",
		})
		self._utils = AdminUtils
		self._adminConfig = AdminConfig
		self._players = Players
		self._runService = RunService
		self._teleportService = TeleportService
		self._messaging = MessagingService
		self._timer = Timer
		self._knit = Knit

		AdminPermissions.install(self, {
			OverheadConfig = OverheadConfig,
			Utils = AdminUtils,
		})
		AdminLogs.install(self)
		AdminJail.install(self, {
			AdminConfig = AdminConfig,
			AdminUtils = AdminUtils,
			ProfileStore = ProfileStore,
			ServerStorage = ServerStorage,
		})
		AdminOverhead.install(self, {
			OverheadConfig = OverheadConfig,
		})
		AdminRefresh.install(self, {
			ServerStorage = ServerStorage,
			CheckpointIndex = CheckpointIndex,
		})
		AdminProfiles.install(self, {
			ProfileStore = ProfileStore,
		})
		AdminNotifications.install(self)

		self:_refreshTools()
		self:_refreshTeleports()
	end

	---Menjalankan fungsi `KnitStart`.
	function AdminService:KnitStart()
		self:_bindPlayers()
		self:_bindMessaging()
		self:_bindUptime()
		AdminUnbanBinder.bind(self, self._janitor)

		local toolsFolder = ServerStorage:FindFirstChild("AdminTools")
		if toolsFolder then
			self._janitor:Add(toolsFolder.ChildAdded:Connect(function()
				self:_refreshTools()
			end), "Disconnect")
			self._janitor:Add(toolsFolder.ChildRemoved:Connect(function()
				self:_refreshTools()
			end), "Disconnect")
		end

		local teleFolder = workspace:FindFirstChild("AdminTeleports")
		if teleFolder then
			self._janitor:Add(teleFolder.ChildAdded:Connect(function()
				self:_refreshTeleports()
			end), "Disconnect")
			self._janitor:Add(teleFolder.ChildRemoved:Connect(function()
				self:_refreshTeleports()
			end), "Disconnect")
		end
	end

	---@private
	---Menjalankan fungsi `_unbanUserId`.
	---@param actor any Nilai parameter `actor`.
	---@param userId any Nilai parameter `userId`.
	function AdminService:_unbanUserId(actor, userId)
		if not self:_isAdminOnly(actor) then
			self:_notifyAdmin(actor, false, "Unban failed: NoPermission")
			return false, "NoPermission"
		end
		local id = tonumber(userId)
		if not id then
			self:_notifyAdmin(actor, false, "Unban failed: InvalidTarget")
			return false, "InvalidTarget"
		end
		local ok = self:_setBan(id, false)
		if not ok then
			self:_notifyAdmin(actor, false, "Unban failed: StoreError")
			return false, "DataStoreError"
		end
		self:_emitLog(actor, string.format("Unban UserId %d", id))
		self:_notifyAdmin(actor, true, string.format("Unbanned UserId %d", id))
		return true
	end

	---@private
	---Menjalankan fungsi `_getBootstrap`.
	---@param player any Nilai parameter `player`.
	function AdminService:_getBootstrap(player)
		return AdminBootstrap.get(self, player)
	end

	---@private
	---Menjalankan fungsi `_getSummitEvent`.
	function AdminService:_getSummitEvent()
		local data = self._summitEvent or {
			active = false,
			value = 0,
			durationHours = 0,
			startedAt = 0,
			endsAt = 0,
		}

		if data.active and (tonumber(data.endsAt) or 0) > 0 and os.time() >= data.endsAt then
			data.active = false
		end

		return {
			active = data.active == true,
			value = tonumber(data.value) or 0,
			durationHours = tonumber(data.durationHours) or 0,
			startedAt = tonumber(data.startedAt) or 0,
			endsAt = tonumber(data.endsAt) or 0,
		}
	end

	---@private
	---Menjalankan fungsi `_setSummitEvent`.
	---@param actor any Nilai parameter `actor`.
	---@param durationHours any Nilai parameter `durationHours`.
	---@param summitValue any Nilai parameter `summitValue`.
	function AdminService:_setSummitEvent(actor, durationHours, summitValue)
		if not self:_isAdminOnly(actor) then
			self:_notifyAdmin(actor, false, "Summit event failed: NoPermission")
			return false, "NoPermission"
		end

		local hours = tonumber(durationHours) or 0
		local value = tonumber(summitValue) or 0
		if hours <= 0 then
			self:_notifyAdmin(actor, false, "Summit event failed: InvalidDuration")
			return false, "InvalidDuration"
		end
		if value <= 0 then
			self:_notifyAdmin(actor, false, "Summit event failed: InvalidValue")
			return false, "InvalidValue"
		end

		local startedAt = os.time()
		local endsAt = startedAt + math.floor(hours * 3600)
		self._summitEvent = {
			active = true,
			value = value,
			durationHours = hours,
			startedAt = startedAt,
			endsAt = endsAt,
		}

		local endsAtText = os.date("!%d/%m %H:%M UTC", endsAt)
		self:_emitLog(actor, string.format("Set Summit Event: +%d summit for %dh", value, hours))
		self:_notifyAdmin(actor, true, string.format("Summit event aktif: +%d summit selama %d jam", value, hours))
		return true, nil, {
			active = true,
			value = value,
			durationHours = hours,
			startedAt = startedAt,
			endsAt = endsAt,
			endsAtText = endsAtText,
		}
	end

	---Menjalankan fungsi `GetBootstrap`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `GetBootstrap`.
	function AdminService.Client:GetBootstrap(player)
		return self.Server:_getBootstrap(player)
	end

	---Menjalankan fungsi `HasPermission`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `HasPermission`.
	function AdminService.Client:HasPermission(player)
		return self.Server:_canUsePanel(player)
	end

	---Menjalankan fungsi `IsAdminOnly`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `IsAdminOnly`.
	function AdminService.Client:IsAdminOnly(player)
		return self.Server:_isAdminOnly(player)
	end

	---Menjalankan fungsi `Announce`.
	---@param player any Nilai parameter `player`.
	---@param message any Nilai parameter `message`.
	---@param scope any Nilai parameter `scope`.
	---@param duration any Nilai parameter `duration`.
	function AdminService.Client:Announce(player, message, scope, duration)
		return AdminBootstrap.announce(self.Server, player, message, scope, duration)
	end

	---Menjalankan fungsi `SetSummitEvent`.
	---@param player any Nilai parameter `player`.
	---@param durationHours any Nilai parameter `durationHours`.
	---@param summitValue any Nilai parameter `summitValue`.
	function AdminService.Client:SetSummitEvent(player, durationHours, summitValue)
		return self.Server:_setSummitEvent(player, durationHours, summitValue)
	end

	---@private
	---Menjalankan fungsi `_findPlayerByUserId`.
	---@param userId any Nilai parameter `userId`.
	function AdminService:_findPlayerByUserId(userId)
		local id = tonumber(userId)
		if not id then return nil end
		return Players:GetPlayerByUserId(id)
	end

	---Menjalankan fungsi `Manage`.
	---@param player any Nilai parameter `player`.
	---@param action any Nilai parameter `action`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	---@param amount any Nilai parameter `amount`.
	function AdminService.Client:Manage(player, action, targetUserId, amount)
		return AdminActions.manage(self.Server, player, action, targetUserId, amount)
	end

	---Menjalankan fungsi `PlayerAction`.
	---@param player any Nilai parameter `player`.
	---@param action any Nilai parameter `action`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	function AdminService.Client:PlayerAction(player, action, targetUserId)
		return AdminActions.playerAction(self.Server, player, action, targetUserId)
	end

	---Menjalankan fungsi `AssignRole`.
	---@param player any Nilai parameter `player`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	---@param role any Nilai parameter `role`.
	function AdminService.Client:AssignRole(player, targetUserId, role)
		return AdminActions.assignRole(self.Server, player, targetUserId, role)
	end

	---Menjalankan fungsi `RemoveRole`.
	---@param player any Nilai parameter `player`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	function AdminService.Client:RemoveRole(player, targetUserId)
		return AdminActions.removeRole(self.Server, player, targetUserId)
	end

	---Menjalankan fungsi `Teleport`.
	---@param player any Nilai parameter `player`.
	---@param destinationName any Nilai parameter `destinationName`.
	function AdminService.Client:Teleport(player, destinationName)
		return AdminActions.teleport(self.Server, player, destinationName)
	end

	---Menjalankan fungsi `GiveTool`.
	---@param player any Nilai parameter `player`.
	---@param toolName any Nilai parameter `toolName`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	function AdminService.Client:GiveTool(player, toolName, targetUserId)
		return AdminActions.giveTool(self.Server, player, toolName, targetUserId)
	end

	---Menjalankan fungsi `ServerControl`.
	---@param player any Nilai parameter `player`.
	---@param action any Nilai parameter `action`.
	function AdminService.Client:ServerControl(player, action)
		return AdminServerControl.run(self.Server, player, action)
	end

	__module = AdminService

	if type(__module) == "table" then
		__module.__source = "Services/AdminService.luau"
	end
	Core.Services.AdminService = __module
end

---@class CoreServicesAvatarService
---@field __source string Path sumber module `Services/AvatarService.luau`.
Core.Services.AvatarService = Core.Services.AvatarService or {}
do
	local __module = nil
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")

	local Shared = ReplicatedStorage.Shared
	local Packages = Shared.Packages
	local Template = Core.Modules.AdminHelpers.JailHelpers.Template
	local Knit = require(Packages.Knit)
	local Promise = require(Packages.Promise)
	local Janitor = require(Packages.Janitor)

	local Server = serverFolder
	local Config = Server.Config
	local AvatarConfig = require(Config.AvatarConfig)
	local AvatarHelpers = Core.Services.AvatarHelpers
	local AvatarStore = Core.Services.AvatarHelpers.AvatarStore
	local AvatarChanger = Core.Services.AvatarHelpers.AvatarChanger

	local AvatarService = Knit.CreateService({
		Name = "AvatarService",
		Client = {
			Config = Knit.CreateProperty({
				TemplateUserId = AvatarConfig.TemplateUserId,
				Avatars = AvatarConfig.Avatars,
				COOLDOWN_TIME = AvatarConfig.COOLDOWN_TIME, 
				LogEnable = AvatarConfig.LogEnabled,
			}),
		},
	})

	---Menjalankan fungsi `ChangeAvatar`.
	---@param player any Nilai parameter `player`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	function AvatarService.Client:ChangeAvatar(player, targetUserId)
		if typeof(targetUserId) ~= "number" or targetUserId <= 0 then return end
		return AvatarChanger.changeAvatar(self.Server._state, Promise, player, targetUserId)
	end

	---Menjalankan fungsi `ResetAvatar`.
	---@param player any Nilai parameter `player`.
	function AvatarService.Client:ResetAvatar(player)
		return AvatarChanger.resetAvatar(self.Server._state, Promise, player)
	end

	---Menjalankan fungsi `GetConfig`.
	---@return any result Hasil dari fungsi `GetConfig`.
	function AvatarService.Client:GetConfig()
		return {
			TemplateUserId = AvatarConfig.TemplateUserId,
			Avatars = AvatarConfig.Avatars,
			COOLDOWN_TIME = AvatarConfig.COOLDOWN_TIME,
			LogEnabled = AvatarConfig.LogEnabled,
		}
	end

	---Menjalankan fungsi `PlayerAdded`.
	---@param player any Nilai parameter `player`.
	function AvatarService:PlayerAdded(player)
		local j = Janitor.new()
		j:Add(player.CharacterAdded:Connect(function(character)
			Promise.delay(0.1):andThen(function()
				AvatarChanger.applyStoredAvatar(self._state, player, character)
			end)
		end), "Disconnect")
		self._janitor:Add(j, "Destroy")

		self._state:ensureDefaultAvatar(player)
		if player.Character then
			Promise.delay(0):andThen(function()
				AvatarChanger.applyStoredAvatar(self._state, player, player.Character)
			end)
		end
	end

	---Menjalankan fungsi `PlayerRemoving`.
	---@param player any Nilai parameter `player`.
	function AvatarService:PlayerRemoving(player)
		self._state:removePlayer(player)
	end

	---Menjalankan fungsi `KnitInit`.
	function AvatarService:KnitInit()
		self._janitor = Janitor.new()
		self._state = AvatarStore.new(AvatarConfig)
	end

	---Menjalankan fungsi `KnitStart`.
	function AvatarService:KnitStart()
		-- FIX: Aktifkan NoPlayerCollision agar semua karakter bisa nembus sesama player
		local NoPlayerCollision = Core.Modules.Physics.NoPlayerCollision
		if NoPlayerCollision and NoPlayerCollision.enable then
			NoPlayerCollision.enable(self._janitor)
		end

		self._janitor:Add(Players.PlayerAdded:Connect(function(player)
			self:PlayerAdded(player)
		end), "Disconnect")
		self._janitor:Add(Players.PlayerRemoving:Connect(function(player)
			self:PlayerRemoving(player)
		end), "Disconnect")
		for _, plr in ipairs(Players:GetPlayers()) do
			Promise.delay(0):andThen(function()
				self:PlayerAdded(plr)
			end)
		end
	end

	---Menjalankan fungsi `KnitShutdown`.
	function AvatarService:KnitShutdown()
		if self._janitor then
			self._janitor:Destroy()
			self._janitor = nil
		end
	end

	__module = AvatarService

	if type(__module) == "table" then
		__module.__source = "Services/AvatarService.luau"
	end
	Core.Services.AvatarService = __module
end

---@class CoreServicesCarryService
---@field __source string Path sumber module `Services/CarryService.luau`.
Core.Services.CarryService = Core.Services.CarryService or {}
do
	local __module = nil
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")

	local Shared = ReplicatedStorage:WaitForChild("Shared")
	local Packages = Shared:WaitForChild("Packages")
	local Knit = require(Packages.Knit)
	local Janitor = require(Packages.Janitor)
	local Signal = require(Packages.Signal)
	local Promise = require(Packages.Promise)
	local TableUtil = require(Packages.TableUtil)
	local Timer = require(Packages.Timer)

	local Server = serverFolder
	local Modules = Core.Modules

	local CarryConfig = Core.Modules.Carry.Config
	local CarryState = Core.Modules.Carry.State
	local CarryLocks = Core.Modules.Carry.Locks
	local CarryCharacter = Core.Modules.Carry.Character
	local CarryWeld = Core.Modules.Carry.Weld
	local CarryPhysics = Core.Modules.Carry.Physics
	local CarryNotifier = Core.Modules.Carry.Notifier
	local CarryFlow = Core.Modules.Carry.Flow
	local TeleportUtil = Core.Modules.Teleport.Util.TeleportUtil

	local CarryService = Knit.CreateService({
		Name = "CarryService",
		Client = {
			CarryEvent = Knit.CreateSignal(),
		},
	})

	---@private
	---Menjalankan fungsi `_cleanupPlayer`.
	---@param player any Nilai parameter `player`.
	function CarryService:_cleanupPlayer(player)
		if not self._playerJanitors then return end 
		local playerJanitor = self._playerJanitors[player]
		if playerJanitor then 
			playerJanitor:Destroy()
			self._playerJanitors[player] = nil 
		end 
	end

	---@private
	---Menjalankan fungsi `_bindPlayer`.
	---@param player any Nilai parameter `player`.
	function CarryService:_bindPlayer(player)
		self:_cleanupPlayer(player)
		local playerJanitor = Janitor.new()
		self._playerJanitors[player] =  playerJanitor
		playerJanitor:Add(player.CharacterAdded:Connect(function(char)
			self._flow:onCharacterAdded(player, char)
		end), "Disconnect")
		if player.Character then 
			self._flow:onCharacterAdded(player, player.Character)
		end
	end

	---Menjalankan fungsi `KnitInit`.
	function CarryService:KnitInit()
		self._janitor = Janitor.new()
		self._playerJanitors = {}
		self._state = CarryState.new()

		self._flow = CarryFlow.new({
			Players = Players,
			Promise = Promise,
			TableUtil = TableUtil,
			Signal = Signal,
			Remote = self.Client.CarryEvent,
			Config = CarryConfig,
			State = self._state,
			Locks = CarryLocks,
			Character = CarryCharacter,
			Weld = CarryWeld,
			Physics = CarryPhysics,
			Notifier = CarryNotifier,
		})

		if self._flow.signals.Started then
			self._janitor:Add(self._flow.signals.Started:Connect(function(carrier, target)
				CarryNotifier.sendStart(self.Client.CarryEvent, carrier, target, self._flow:countCarried(carrier))
			end), "Disconnect")
		end
		if self._flow.signals.Ended then
			self._janitor:Add(self._flow.signals.Ended:Connect(function(carrier, target, reason)
				CarryNotifier.sendEndPair(
					self.Client.CarryEvent,
					carrier,
					target,
					reason,
					self._flow:countCarried(carrier),
					self._flow:countCarried(target)
				)
			end), "Disconnect")
		end

		self._pendingTimer = Timer.new(2)
		self._janitor:Add(self._pendingTimer, "Destroy")
		self._pendingTimer.Tick:Connect(function()
			self._flow:cleanupPending(os.clock())
		end)
		self._pendingTimer:Start()
	end

	---Menjalankan fungsi `KnitStart`.
	function CarryService:KnitStart()
		-- FIX: Aktifkan NoPlayerCollision agar karakter bisa nembus sesama player
		local NoPlayerCollision = Core.Modules.Physics.NoPlayerCollision
		if NoPlayerCollision and NoPlayerCollision.enable then
			NoPlayerCollision.enable(self._janitor)
		end

		self._janitor:Add(self.Client.CarryEvent:Connect(function(player, action, data)
			self._flow:handleRemote(player, action, data)
		end), "Disconnect")

		self._janitor:Add(Players.PlayerAdded:Connect(function(p)
			self._janitor:Add(p.CharacterAdded:Connect(function(char)
				self._flow:onCharacterAdded(p, char)
			end), "Disconnect")
		end), "Disconnect")

		self._janitor:Add(Players.PlayerRemoving:Connect(function(p)
			self._flow.state.pending[p.UserId] = nil
			self._flow.state:clearTrustForUserId(p.UserId)
			self._flow:detachIfAny(p, "left")
		end), "Disconnect")

		for _, player in ipairs(Players:GetPlayers()) do 
			self:_bindPlayer(player)
		end
	end

	---Menjalankan fungsi `KnitShutdown`.
	function CarryService:KnitShutdown()
		if self._playerJanitors then 
			for player, playerJanitor in pairs(self._playerJanitors) do 
				playerJanitor:Destroy()
				self._playerJanitors[player] = nil 
			end 
		end
		if self._janitor then
			self._janitor:Destroy()
			self._janitor = nil
		end
	end

	---Menjalankan fungsi `ForceDetach`.
	---@param player any Nilai parameter `player`.
	---@param reason any Nilai parameter `reason`.
	function CarryService:ForceDetach(player, reason)
		if not player or not self._flow then return end
		self._flow:safeDetachIfAny(player, reason or "teleport")
	end

	---Menjalankan fungsi `TeleportCarryGroup`.
	---@param player any Nilai parameter `player`.
	---@param targetPart any Nilai parameter `targetPart`.
	function CarryService:TeleportCarryGroup(player, targetPart)
		if not player or not targetPart then return false end

		-- Prefer the standalone Carry state used by the client.
		local carryFolder = ServerScriptService:FindFirstChild("Carry")
		local carryModules = carryFolder and carryFolder:FindFirstChild("Modules")
		local teleportModule = carryModules and carryModules:FindFirstChild("Teleport")
		if teleportModule then
			local ok, standalone = pcall(require, teleportModule)
			if ok and standalone then
				local handledOk, handled = pcall(standalone.TeleportCarryGroup, player, targetPart)
				if handledOk and handled then return true end
			end
		end

		if not self._flow then return false end

		local carrier = self._flow.state.carriedByTarget[player.UserId] or player
		local carrying = self._flow.state.carryingByCarrier[carrier.UserId]

		if carrying then
			local cChar, cHRP = self._flow:_getCharHRP(carrier)
			if not (cChar and cHRP) then return false end
			cHRP.AssemblyLinearVelocity = Vector3.zero
			cHRP.AssemblyAngularVelocity = Vector3.zero
			cChar:PivotTo(targetPart.CFrame + Vector3.new(0, 3, 0))
			self._flow:reindexSlots(carrier)
			return true
		end

		TeleportUtil.teleport(player.Character, targetPart)
		return true
	end

	__module = CarryService

	if type(__module) == "table" then
		__module.__source = "Services/CarryService.luau"
	end
	Core.Services.CarryService = __module
end

---@class CoreServicesCheckpointService
---@field __source string Path sumber module `Services/CheckpointService.luau`.
Core.Services.CheckpointService = Core.Services.CheckpointService or {}
do
	local __module = nil
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")
	local DataStoreService = game:GetService("DataStoreService")
	local Players = game:GetService("Players")

	local Shared = ReplicatedStorage.Shared
	local Packages = Shared.Packages
	local Knit = require(Packages.Knit)
	local Janitor = require(Packages.Janitor)
	local Promise = require(Packages.Promise)

	local Server = serverFolder
	local Modules = Core.Modules
	local Config = Server.Config
	local Components = Core.Components
	local Data = Core.Data

	local CheckpointConfig = require(Config.CheckpointConfig)
	local RewardConfig = require(Config.RewandConfig)
	local CheckpointIndex = Core.Modules.Checkpoint.Index
	local StateManager = Core.Modules.Checkpoint.StateManager
	local Flow = Core.Modules.Checkpoint.Flow
	local Respawn = Core.Modules.Checkpoint.Respawn
	local Lifecycle = Core.Modules.Checkpoint.Lifecycle
	local Bindings = Core.Modules.Checkpoint.Bindings
	local ServiceSerializer = Core.Modules.Checkpoint.ServiceSerializer
	local ServiceReset = Core.Modules.Checkpoint.ServiceReset
	local SummitCommandBinder = Core.Modules.Checkpoint.Admin.SummitCommandBinder
	local TeleportHelper = Core.Modules.Teleport.TeleportHelper
	local TargetFinder = Core.Modules.Teleport.Util.TargetFinder
	local TeleporterBinder = Core.Modules.Teleport.TeleporterBinder
	local BackBasecampHandler = Core.Modules.Teleport.BackBasecampHandler
	local CheckpointComponent = Core.Components.CheckpointComponent
	local CheckpointProfile = Core.Data.CheckpointProfile
	local Leaderstats = Core.Data.Leaderstats
	local FilterUtil = Core.Modules.Leaderboard.FilterUtil
	local OverheadConfig = require(Config.OverheadConfig)
	local CheckpointLeaderboard = Core.Modules.Checkpoint.CheckpointLeaderboard
	local CheckpointSummitActions = Core.Modules.Checkpoint.CheckpointSummitActions
	local CheckpointBackbasecamp = Core.Modules.Checkpoint.CheckpointBackbasecamp

	local CheckpointService = Knit.CreateService({
		Name = "CheckpointService",
		Client = {
			CheckpointReached = Knit.CreateSignal(),
			CheckpointRejected = Knit.CreateSignal(),
			State = Knit.CreateProperty({}),
			Config = Knit.CreateProperty({}),
		},
	})

	---Menjalankan fungsi `KnitInit`.
	function CheckpointService:KnitInit()
		self._janitor = Janitor.new()
		self._profiles = CheckpointProfile.new()
		self._playerState = {}
		self._leaderstats = {}
		self._playerConns = {}
		self._summitBoard = DataStoreService:GetOrderedDataStore(CheckpointConfig.SummitLeaderboardKey)
		self._leaderboard = CheckpointLeaderboard.new(self._summitBoard, FilterUtil, OverheadConfig)
		self:_initSummitActions()
		self._stateMgr = StateManager.new(CheckpointIndex.StartIndex or (CheckpointConfig.DefaultStartIndex or 0), CheckpointIndex.FinishIndex)
		self._flow = Flow.new(CheckpointIndex, self._profiles)
		self._respawn = Respawn.new(CheckpointIndex, CheckpointConfig.DefaultStartIndex)
		self._leaderstatsClass = Leaderstats
		self._serialize = ServiceSerializer.serialize
		self._getCarryService = function()
			local ok, carryService = pcall(function()
				return Knit.GetService("CarryService")
			end)
			if ok then
				return carryService
			end
			return nil
		end
		self.Client.Config:Set(RewardConfig)

		CheckpointIndex:GetOrdered()
		_ = CheckpointComponent

		CheckpointBackbasecamp.bind(self._janitor, {
			BackBasecampHandler = BackBasecampHandler,
			CheckpointIndex = CheckpointIndex,
			CheckpointConfig = CheckpointConfig,
			playerState = self._playerState,
			profiles = self._profiles,
			serialize = self._serialize,
			setClientState = function(player, state)
				self.Client.State:SetFor(player, state)
			end,
			syncLeaderstats = function(player, state)
				self:_syncLeaderstats(player, state)
			end,
			TargetFinder = TargetFinder,
			TeleportHelper = TeleportHelper,
			getCarryService = function()
				return Knit.GetService("CarryService")
			end,
		})
		self._teleporter = TeleporterBinder.new(CheckpointConfig.DefaultStartIndex, CheckpointIndex)
		self._teleporter:bind(self._janitor, function(player)
			local state = self._playerState[player]
			return state and state.index or CheckpointIndex.StartIndex
		end)

		Bindings.new(self):setupPlayers(false)
		SummitCommandBinder.bind(self, self._janitor)
	end

	---Menjalankan fungsi `KnitStart`.
	function CheckpointService:KnitStart()
		for _, player in ipairs(Players:GetPlayers()) do
			Promise.delay(0):andThen(function()
				self:_onPlayerAdded(player)
			end)
		end
	end

	---@private
	---Menjalankan fungsi `_updateSummitLeaderboard`.
	---@param userId any Nilai parameter `userId`.
	---@param summitCount any Nilai parameter `summitCount`.
	---@param username any Nilai parameter `username`.
	function CheckpointService:_updateSummitLeaderboard(userId, summitCount, username)
		if not self._leaderboard then 
			return
		end
		self._leaderboard:updateSummit(userId, summitCount, username)
	end
	--     if not self._summitBoard or not userId then
	--         return
	--     end
	--     local isExempt = FilterUtil.isExemptFromLeaderboard and FilterUtil.isExemptFromLeaderboard(userId, username, OverheadConfig)
	--     if isExempt == nil and FilterUtil.isPrivileged then 
	--         isExempt = FilterUtil.isPrivileged(userId, username, OverheadConfig)
	--     end

	--     if isExempt then 
	--         pcall(function()
	--         self._summitBoard:RemoveAsync(tostring(userId))
	--     end)
	--     return
	-- end
	--     pcall(function()
	--         self._summitBoard:SetAsync(tostring(userId), summitCount or 0)
	--     end)
	-- end

	---@private
	---Menjalankan fungsi `_onPlayerAdded`.
	---@param player any Nilai parameter `player`.
	function CheckpointService:_onPlayerAdded(player)
		if self._playerState[player] then
			return
		end
		Lifecycle.addPlayer(self, player)
	end

	---@private
	---Menjalankan fungsi `_onPlayerRemoving`.
	---@param player any Nilai parameter `player`.
	function CheckpointService:_onPlayerRemoving(player)
		Lifecycle.removePlayer(self, player)
	end

	---@private
	---Menjalankan fungsi `_onCharacterAdded`.
	---@param player any Nilai parameter `player`.
	---@param character any Nilai parameter `character`.
	function CheckpointService:_onCharacterAdded(player, character)
		Lifecycle.onCharacterAdded(self, player, character)
	end

	---@private
	---Menjalankan fungsi `_syncLeaderstats`.
	---@param player any Nilai parameter `player`.
	---@param state any Nilai parameter `state`.
	function CheckpointService:_syncLeaderstats(player, state)
		local stats = self._leaderstats[player]
		if not stats then
			return
		end
		stats:SetPosisi(state.index, CheckpointIndex.StartIndex, CheckpointIndex.FinishIndex, CheckpointIndex.FinishStartIndex)
		stats:SetSummit(state.summitCount)
		if not self._lastSyncedSummit then self._lastSyncedSummit = {} end
		if self._lastSyncedSummit[player.UserId] ~= state.summitCount then
			self._lastSyncedSummit[player.UserId] = state.summitCount
			self._leaderboard:updateSummit(player.UserId, state.summitCount)
		end
	end

	---@private
	---Menjalankan fungsi `_setSummit`.
	---@param player any Nilai parameter `player`.
	---@param amount any Nilai parameter `amount`.
	function CheckpointService:_setSummit(player, amount)
		if not self._summitActions then return end
		self._summitActions:set(player, amount)
	end

	---@private
	---Menjalankan fungsi `_addSummit`.
	---@param player any Nilai parameter `player`.
	---@param amount any Nilai parameter `amount`.
	function CheckpointService:_addSummit(player, amount)
		if not self._summitActions then return end
		self._summitActions:add(player, amount)
	end

	---@private
	---Menjalankan fungsi `_resetSummit`.
	---@param player any Nilai parameter `player`.
	function CheckpointService:_resetSummit(player)
		if not self._summitActions then return end
		self._summitActions:reset(player)
	end

	---@private
	---Menjalankan fungsi `_addSummitByUserId`.
	---@param userId any Nilai parameter `userId`.
	---@param amount any Nilai parameter `amount`.
	function CheckpointService:_addSummitByUserId(userId, amount)
		if not self._summitActions then return end
		self._summitActions:addByUserId(userId, amount)
	end

	---@private
	---Menjalankan fungsi `_resetSummitByUserId`.
	---@param userId any Nilai parameter `userId`.
	function CheckpointService:_resetSummitByUserId(userId)
		if not self._summitActions then return end
		self._summitActions:resetByUserId(userId)
	end

	---@private
	---Menjalankan fungsi `_setSummitByUserId`.
	---@param userId any Nilai parameter `userId`.
	---@param amount any Nilai parameter `amount`.
	function CheckpointService:_setSummitByUserId(userId, amount)
		if not self._summitActions then return end
		self._summitActions:setByUserId(userId, amount)
	end

	---@private
	---Menjalankan fungsi `_resetToStart`.
	---@param player any Nilai parameter `player`.
	function CheckpointService:_resetToStart(player)
		ServiceReset.resetToStart(self, player, CheckpointIndex, CheckpointConfig)
	end

	---@private
	---Menjalankan fungsi `_getEventSummitBonus`.
	function CheckpointService:_getEventSummitBonus()
		local ok, adminService = pcall(function()
			return Knit.GetService("AdminService")
		end)
		if not ok or not adminService or not adminService._getSummitEvent then
			return 0
		end

		local eventData = adminService:_getSummitEvent()
		if not eventData or eventData.active ~= true then
			return 0
		end

		return math.max(0, math.floor(tonumber(eventData.value) or 0))
	end

	---Menjalankan fungsi `ResetCheckpoint`.
	---@param player any Nilai parameter `player`.
	function CheckpointService.Client:ResetCheckpoint(player)
		local service = self.Server
		ServiceReset.resetToStart(service, player, CheckpointIndex, CheckpointConfig)
		return true
	end

	---Menjalankan fungsi `HandleCheckpointTouch`.
	---@param player any Nilai parameter `player`.
	---@param checkpointIndex any Nilai parameter `checkpointIndex`.
	---@param isFinish any Nilai parameter `isFinish`.
	---@param summitReward any Nilai parameter `summitReward`.
	function CheckpointService:HandleCheckpointTouch(player, checkpointIndex, isFinish, summitReward)
		local state = self._playerState[player]
		if not state then
			return
		end

		local newState, summitReached, accepted, rejectReason, expectedIndex, resolvedSummitReward =
			self._flow:handle(state, player, checkpointIndex, isFinish, summitReward)
		if not accepted and not summitReached then
			if rejectReason == "SkipDisabled" then
				self.Client.CheckpointRejected:Fire(player, rejectReason, expectedIndex, checkpointIndex)
			end
			return
		end

		local totalSummitReward = resolvedSummitReward
		if summitReached then
			local eventBonus = self:_getEventSummitBonus()
			if eventBonus > 0 then
				self:_addSummit(player, eventBonus)
				totalSummitReward = (tonumber(resolvedSummitReward) or 0) + eventBonus
			end
		end

		self.Client.CheckpointReached:Fire(player, checkpointIndex, summitReached, totalSummitReward, newState.lastRun, newState.bestTime)
		self.Client.State:SetFor(player, self._serialize(newState))
		self:_syncLeaderstats(player, newState)
	end

	-- function CheckpointService:_updateSummitLeaderboard(userId, summitCount)
	--     if self._leaderboard then
	--         self._leaderboard:updateSummit(userId, summitCount)
	--     end
	-- end

	---@private
	---Menjalankan fungsi `_initSummitActions`.
	function CheckpointService:_initSummitActions()
		self._summitActions = CheckpointSummitActions.new({
			playerState = self._playerState,
			profiles = self._profiles,
			leaderboard = self._leaderboard,
			serialize = self._serialize,
			setClientState = function(player, state)
				self.Client.State:SetFor(player, state)
			end,
			syncLeaderstats = function(player, state)
				self:_syncLeaderstats(player, state)
			end,
		})
	end

	__module = CheckpointService

	if type(__module) == "table" then
		__module.__source = "Services/CheckpointService.luau"
	end
	Core.Services.CheckpointService = __module
end

---@class CoreServicesDanceService
---@field __source string Path sumber module `Services/DanceService.luau`.
Core.Services.DanceService = Core.Services.DanceService or {}
do
	local __module = nil
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Shared = ReplicatedStorage.Shared
	local Packages = Shared.Packages
	local Knit = require(Packages.Knit)
	local Janitor = require(Packages.Janitor)
	local StateValidator = Core.Services.DanceHelpers.StateValidator
	local DanceStore = Core.Services.DanceHelpers.DanceStore

	local DanceService = Knit.CreateService({
		Name = "DanceService",
		Client = {
			StateChanged = Knit.CreateSignal(),
		},
	})

	---Menjalankan fungsi `KnitInit`.
	function DanceService:KnitInit()
		self._janitor = Janitor.new()
		self._store = DanceStore.new()
	end

	---Menjalankan fungsi `KnitStart`.
	function DanceService:KnitStart()
		self._janitor:Add(Players.PlayerRemoving:Connect(function(player)
			self._store:clear(player.UserId)
			self.Client.StateChanged:FireAll(player.UserId, nil)
		end), "Disconnect")
	end

	---Menjalankan fungsi `KnitShutdown`.
	function DanceService:KnitShutdown()
		if self._janitor then
			self._janitor:Destroy()
			self._janitor = nil
		end
	end

	---Menjalankan fungsi `UpdateState`.
	---@param player any Nilai parameter `player`.
	---@param state any Nilai parameter `state`.
	function DanceService.Client:UpdateState(player, state)
		local sanitized = StateValidator.sanitize(state)
		if not sanitized then
			DanceService._store:clear(player.UserId)
			DanceService.Client.StateChanged:FireAll(player.UserId, nil)
			return false
		end

		DanceService._store:set(player.UserId, sanitized)
		DanceService.Client.StateChanged:FireAll(player.UserId, table.clone(sanitized))
		return true
	end

	---Menjalankan fungsi `ClearState`.
	---@param player any Nilai parameter `player`.
	function DanceService.Client:ClearState(player)
		DanceService._store:clear(player.UserId)
		DanceService.Client.StateChanged:FireAll(player.UserId, nil)
		return true
	end

	---Menjalankan fungsi `RequestSync`.
	---@param _player any Nilai parameter `_player`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	function DanceService.Client:RequestSync(_player, targetUserId)
		local userId = tonumber(targetUserId)
		if not userId then
			return false, "InvalidTarget"
		end

		local targetPlayer = Players:GetPlayerByUserId(userId)
		if not targetPlayer then
			return false, "TargetNotFound"
		end

		local state = DanceService._store:get(userId)
		if not state then
			return false, "TargetNotDancing"
		end

		return true, {
			targetUserId = targetPlayer.UserId,
			targetName = targetPlayer.DisplayName ~= "" and targetPlayer.DisplayName or targetPlayer.Name,
			state = table.clone(state),
		}
	end

	__module = DanceService

	if type(__module) == "table" then
		__module.__source = "Services/DanceService.luau"
	end
	Core.Services.DanceService = __module
end

---@class CoreServicesDonationsService
---@field __source string Path sumber module `Services/DonationsService.luau`.
Core.Services.DonationsService = Core.Services.DonationsService or {}
do
	local __module = nil
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local DataStoreService = game:GetService("DataStoreService")
	local RunService = game:GetService("RunService")

	local Shared = ReplicatedStorage.Shared
	local Packages = Shared.Packages
	local Knit = require(Packages.Knit)
	local Janitor = require(Packages.Janitor)
	local Timer = require(Packages.Timer)
	local Promise = require(Packages.Promise)

	local ServerScriptService = game:GetService("ServerScriptService")
	local Server = serverFolder
	local Config = Server.Config
	local Modules = Core.Modules

	local DonationsConfig = require(Config.DonationsConfig)
	local DonationsFormatter = Core.Modules.Donations.DonationsFormatter
	local DonationsProfileCache = Core.Modules.Donations.DonationsProfileCache
	local DonationsUiResolver = Core.Modules.Donations.DonationsUiResolver
	local DonationsListRenderer = Core.Modules.Donations.DonationsListRenderer
	local DonationsPodium = Core.Modules.Donations.DonationsPodium
	local DonationHelpers = Core.Services.DonationHelpers
	local DonationBoardUpdater = Core.Services.DonationHelpers.DonationBoardUpdater
	local PurchaseHandler = Core.Services.DonationHelpers.PurchaseHandler

	local DonationsService = Knit.CreateService({
		Name = "DonationsService",
		Client = {
			DonateNotice = Knit.CreateSignal(),
		},
		_janitor = nil,
		_store = nil,
		_refreshTimer = nil,
		_priceCache = nil,
		_listFrame = nil,
		_template = nil,
		_podium = nil,
		_profileCache = nil,
		_formatter = nil,
		_leaderboardRuntime = nil,
		_receiptProcessor = nil,
	})

	---Menjalankan fungsi `RefreshLeaderboard`.
	function DonationsService:RefreshLeaderboard()
		if self._leaderboardRuntime then
			self._leaderboardRuntime:refresh()
		end
	end

	---Menjalankan fungsi `ProcessReceipt`.
	---@param receiptInfo any Nilai parameter `receiptInfo`.
	function DonationsService:ProcessReceipt(receiptInfo)
		local decision, shouldRefresh = self._receiptProcessor:process(receiptInfo)
		if shouldRefresh then
			Promise.delay(0):andThen(function()
				self:RefreshLeaderboard()
			end)
		end
		return decision
	end

	---Menjalankan fungsi `KnitInit`.
	function DonationsService:KnitInit()
		self._janitor = Janitor.new()
		local storeName = DonationsConfig.DataStoreName
		self._store = DataStoreService:GetOrderedDataStore(storeName)
		self._priceCache = {}
		self._profileCache = DonationsProfileCache.new()
		self._formatter = DonationsFormatter
		self._leaderboardRuntime = DonationBoardUpdater.new(
			DonationsConfig,
			DonationsUiResolver,
			DonationsListRenderer,
			DonationsPodium,
			self._formatter,
			self._profileCache,
			self._store
		)
		self._receiptProcessor = PurchaseHandler.new(DonationsConfig, self._store, self.Client.DonateNotice)
	end

	---Menjalankan fungsi `KnitStart`.
	function DonationsService:KnitStart()
		self._refreshTimer = Timer.new(DonationsConfig.UpdateInterval or 120)
		self._janitor:Add(self._refreshTimer, "Destroy")
		self._refreshTimer.Tick:Connect(function()
			self:RefreshLeaderboard()
		end)
		self._refreshTimer:Start()

		Promise.delay(0):andThen(function()
			self:RefreshLeaderboard()
		end)
	end

	---Menjalankan fungsi `KnitShutdown`.
	function DonationsService:KnitShutdown()
		if self._janitor then
			self._janitor:Destroy()
			self._janitor = nil
		end
	end

	__module = DonationsService

	if type(__module) == "table" then
		__module.__source = "Services/DonationsService.luau"
	end
	Core.Services.DonationsService = __module
end

---@class CoreServicesLeaderboardService
---@field __source string Path sumber module `Services/LeaderboardService.luau`.
Core.Services.LeaderboardService = Core.Services.LeaderboardService or {}
do
	local __module = nil
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local DataStoreService = game:GetService("DataStoreService")
	local ServerScriptService = game:GetService("ServerScriptService")

	local Shared = ReplicatedStorage.Shared
	local Packages = Shared.Packages
	local Knit = require(Packages.Knit)
	local Janitor = require(Packages.Janitor)
	local Timer = require(Packages.Timer)

	local Server = serverFolder
	local Config = Server.Config
	local Modules = Core.Modules

	local CheckpointConfig = require(Config.CheckpointConfig)
	local SpeedrunConfig = require(Config.SpeedrunConfig)
	local PlaytimeConfig = require(Config.PlaytimeConfig)
	local OverheadConfig = require(Config.OverheadConfig)
	local LeaderboardConfig = require(Config.LeaderboardConfig)
	local FilterUtil = Core.Modules.Leaderboard.FilterUtil
	local LeaderboardFormatter = Core.Modules.Leaderboard.LeaderboardFormatter
	local LeaderboardProfileCache = Core.Modules.Leaderboard.LeaderboardProfileCache
	local LeaderboardUiResolver = Core.Modules.Leaderboard.LeaderboardUiResolver
	local LeaderboardListRenderer = Core.Modules.Leaderboard.LeaderboardListRenderer
	local LeaderboardHelpers = Core.Services.LeaderboardHelpers
	local LeaderboardRendererModule = Core.Services.LeaderboardHelpers.LeaderboardRenderer
	local LeaderboardRenderer = Core.Services.LeaderboardHelpers.LeaderboardRenderer

	local LeaderboardService = Knit.CreateService({
		Name = "LeaderboardService",
	})

	local REFRESH_INTERVAL = 120
	local MAX_ROWS = LeaderboardConfig.MaxRows or 10
	local FETCH_LIMIT = LeaderboardConfig.FetchLimit or MAX_ROWS
	local MIN_VALUE = LeaderboardConfig.MinValue or 1

	---@private
	---Menjalankan fungsi `clampPageSize`.
	---@param n any Nilai parameter `n`.
	local function clampPageSize(n)
		n = tonumber(n) or 10
		if n < 1 then return 1 end
		if n > 100 then return 100 end
		return n
	end

	FETCH_LIMIT = clampPageSize(FETCH_LIMIT)
	MAX_ROWS = math.max(1, math.min(MAX_ROWS, FETCH_LIMIT))

	---Menjalankan fungsi `KnitInit`.
	function LeaderboardService:KnitInit()
		self._janitor = Janitor.new()
		self._summitBoard = DataStoreService:GetOrderedDataStore(CheckpointConfig.SummitLeaderboardKey)
		self._speedrunBoard = DataStoreService:GetOrderedDataStore(SpeedrunConfig.BestTimeLeaderboardKey)
		self._playtimeBoard = DataStoreService:GetOrderedDataStore(PlaytimeConfig.LeaderboardKey)
		self._profileCache = LeaderboardProfileCache.new()
		self:_resolveUi()

		self._refreshTimer = Timer.new(REFRESH_INTERVAL)
		self._janitor:Add(self._refreshTimer, "Destroy")
		self._refreshTimer.Tick:Connect(function()
			self:_refreshAll()
		end)
		self._refreshTimer:Start()
	end

	---Menjalankan fungsi `KnitStart`.
	function LeaderboardService:KnitStart()
		task.spawn(function()
			self:_refreshAll()
		end)
	end

	---@private
	---Menjalankan fungsi `_resolveUi`.
	function LeaderboardService:_resolveUi()
		local ok, refsOrErr = LeaderboardUiResolver.resolve()
		if not ok then
			warn("[Leaderboard] " .. tostring(refsOrErr))
			return false
		end
		self._summitList = refsOrErr.summitList
		self._speedrunList = refsOrErr.speedrunList
		self._playtimeList = refsOrErr.playtimeList
		self._template = refsOrErr.template
		if not self._summitList then
			warn("[Leaderboard] GlobalSummit SurfaceGui/ScrollingFrame not found")
		end
		if not self._speedrunList then
			warn("[Leaderboard] GlobalSpeedrun SurfaceGui/ScrollingFrame not found")
		end
		if not self._playtimeList then
			warn("[Leaderboard] GlobalPlaytime SurfaceGui/ScrollingFrame not found")
		end
		return true
	end

	---@private
	---Menjalankan fungsi `_refreshAll`.
	function LeaderboardService:_refreshAll()
		if self._summitList then
			self:_renderSummit()
		end
		if self._speedrunList then
			self:_renderSpeedrun()
		end
		if self._playtimeList then
			self:_renderPlaytime()
		end
	end

	---@private
	---Menjalankan fungsi `_renderSummit`.
	function LeaderboardService:_renderSummit()
		LeaderboardRenderer.render(
			self._summitBoard,
			FETCH_LIMIT,
			MAX_ROWS,
			MIN_VALUE,
			FilterUtil,
			OverheadConfig,
			function(v)
				return v
			end,
			nil,
			LeaderboardListRenderer,
			self._summitList,
			self._template,
			self._profileCache
		)
	end

	---@private
	---Menjalankan fungsi `_renderSpeedrun`.
	function LeaderboardService:_renderSpeedrun()
		LeaderboardRenderer.render(
			self._speedrunBoard,
			FETCH_LIMIT,
			MAX_ROWS,
			MIN_VALUE,
			FilterUtil,
			OverheadConfig,
			function(v)
				return math.abs(v)
			end,
			LeaderboardFormatter.formatTime,
			LeaderboardListRenderer,
			self._speedrunList,
			self._template,
			self._profileCache
		)
	end

	---@private
	---Menjalankan fungsi `_renderPlaytime`.
	function LeaderboardService:_renderPlaytime()
		LeaderboardRenderer.render(
			self._playtimeBoard,
			FETCH_LIMIT,
			MAX_ROWS,
			MIN_VALUE,
			FilterUtil,
			OverheadConfig,
			function(v)
				return v
			end,
			LeaderboardFormatter.formatTime,
			LeaderboardListRenderer,
			self._playtimeList,
			self._template,
			self._profileCache
		)
	end

	__module = LeaderboardService

	if type(__module) == "table" then
		__module.__source = "Services/LeaderboardService.luau"
	end
	Core.Services.LeaderboardService = __module
end

---@class CoreServicesOverheadService
---@field __source string Path sumber module `Services/OverheadService.luau`.
---@field KnitInit any Member public `KnitInit` dari `Services/OverheadService.luau`.
---@field KnitShutdown any Member public `KnitShutdown` dari `Services/OverheadService.luau`.
---@field KnitStart any Member public `KnitStart` dari `Services/OverheadService.luau`.
---@field PlayerAdded any Member public `PlayerAdded` dari `Services/OverheadService.luau`.
---@field PlayerRemoving any Member public `PlayerRemoving` dari `Services/OverheadService.luau`.
Core.Services.OverheadService = Core.Services.OverheadService or {}
do
	local __module = nil
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")
	local ServerPackages = game:FindFirstChild("ServerPackages")
	if not ServerPackages then
		local serverRoot = game:GetService("ServerScriptService"):FindFirstChild("Server")
		ServerPackages = serverRoot and serverRoot:FindFirstChild("Package")
	end
	if not ServerPackages then
		error("[OverheadService] ServerPackages not found.")
	end

	local Shared = ReplicatedStorage.Shared
	local Packages = Shared.Packages
	local Knit = require(Packages.Knit)
	local Janitor = require(Packages.Janitor)
	local Promise = require(Packages.Promise)

	local Server = serverFolder
	local ProfileStore = require(ServerPackages.ProfileStore)
	local CustomTitleModules = Core.Services.CustomTitle
	local OverheadHelpers = Core.Services.OverheadHelpers
	local ConfigProvider = Core.Services.OverheadHelpers.ConfigProvider
	local ColorUtil = Core.Services.CustomTitle.ColorUtil
	local CustomTitleHandler = Core.Services.CustomTitle.CustomTitleHandler
	local CustomTitleProfiles = Core.Services.CustomTitle.CustomTitleProfiles

	local OverheadConfig = require(Server.Config.OverheadConfig)

	local VALID_DEVICES = {
		Desktop = true,
		Mobile = true,
	}

	local OverheadService = Knit.CreateService({
		Name = "OverheadService",
		Client = {
			Config = Knit.CreateProperty(OverheadConfig),
		},
		profiles = {},
		store = nil,
		_janitor = nil,
	})

	---Menjalankan fungsi `SetDevice`.
	---@param player any Nilai parameter `player`.
	---@param device any Nilai parameter `device`.
	function OverheadService.Client:SetDevice(player, device)
		CustomTitleHandler.setDevice(player, device, OverheadConfig, VALID_DEVICES)
	end

	---Menjalankan fungsi `SetCustomTitle`.
	---@param player any Nilai parameter `player`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	---@param payload any Nilai parameter `payload`.
	function OverheadService.Client:SetCustomTitle(player, targetUserId, payload)
		return CustomTitleHandler.setCustomTitle(player, targetUserId, payload, OverheadService.resolvedConfig or OverheadConfig, OverheadService.profiles)
	end

	---Menjalankan fungsi `ClearCustomTitle`.
	---@param player any Nilai parameter `player`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	---@param slot any Nilai parameter `slot`.
	function OverheadService.Client:ClearCustomTitle(player, targetUserId, slot)
		return CustomTitleHandler.clearCustomTitle(player, targetUserId, slot, OverheadService.resolvedConfig or OverheadConfig, OverheadService.profiles)
	end

	---Menjalankan fungsi `KnitInit`.
	function OverheadService:KnitInit()
		self._janitor = Janitor.new()
		self._resolvedConfig = ConfigProvider.build(OverheadConfig)
		self.Client.Config:Set(ConfigProvider.build(OverheadConfig))

		self.store = ProfileStore.New(DataStoreConfig.Stores.OverheadCustomTitles, {
			customTitles = {},
			activeSlot = 1,
		})
	end

	---Menjalankan fungsi `PlayerAdded`.
	---@param player any Nilai parameter `player`.
	function OverheadService:PlayerAdded(player)
		CustomTitleProfiles.startSession(self.store, self.profiles, player, OverheadConfig, ColorUtil.tableToColor, function(base, slot)
			return string.format("%s_%d", base, slot)
		end)

		---@private
		---Menjalankan fungsi `hideDefaultTags`.
		---@param character any Nilai parameter `character`.
		local function hideDefaultTags(character)
			local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
			if humanoid then
				humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
				pcall(function()
					humanoid.NameDisplayDistance = 0
				end)
				pcall(function()
					humanoid.HealthDisplayDistance = 0
				end)
			end
		end

		if player.Character then
			hideDefaultTags(player.Character)
		end

		if self._janitor then
			self._janitor:Add(player.CharacterAdded:Connect(function(character)
				hideDefaultTags(character)
			end), "Disconnect")
		else
			player.CharacterAdded:Connect(function(character)
				hideDefaultTags(character)
			end)
		end
	end

	---Menjalankan fungsi `PlayerRemoving`.
	---@param player any Nilai parameter `player`.
	function OverheadService:PlayerRemoving(player)
		CustomTitleProfiles.endSession(self.profiles, player)
	end

	---Menjalankan fungsi `KnitStart`.
	function OverheadService:KnitStart()
		if not self._janitor then
			self._janitor = Janitor.new()
		end
		self._janitor:Add(Players.PlayerAdded:Connect(function(player)
			self:PlayerAdded(player)
		end), "Disconnect")
		self._janitor:Add(Players.PlayerRemoving:Connect(function(player)
			self:PlayerRemoving(player)
		end), "Disconnect")
		for _, plr in ipairs(Players:GetPlayers()) do
			Promise.delay(0):andThen(function()
				self:PlayerAdded(plr)
			end)
		end
	end

	---Menjalankan fungsi `KnitShutdown`.
	function OverheadService:KnitShutdown()
		if self._janitor then
			self._janitor:Destroy()
			self._janitor = nil
		end
	end

	__module = OverheadService

	if type(__module) == "table" then
		__module.__source = "Services/OverheadService.luau"
	end
	Core.Services.OverheadService = __module
end

---@class CoreServicesPlayerCommandService
---@field __source string Path sumber module `Services/PlayerCommandService.luau`.
Core.Services.PlayerCommandService = Core.Services.PlayerCommandService or {}
do
	local __module = nil
	local _Players = game:GetService("Players")
	local TeleportService = game:GetService("TeleportService")
	local RunService = game:GetService("RunService")

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Shared = ReplicatedStorage.Shared
	local Packages = Shared.Packages
	local Knit = require(Packages.Knit)
	local Janitor = require(Packages.Janitor)

	local ServerScriptService = game:GetService("ServerScriptService")
	local Server = serverFolder
	local Modules = Core.Modules

	local PlayerCommandBinder = Core.Modules.PlayerCommands.PlayerCommandBinder

	local PlayerCommandService = Knit.CreateService({
		Name = "PlayerCommandService",
		Client = {
			ToggleFps = Knit.CreateSignal(),
		},
	})

	---Menjalankan fungsi `KnitInit`.
	function PlayerCommandService:KnitInit()
		self._janitor = Janitor.new()
	end

	---Menjalankan fungsi `KnitStart`.
	function PlayerCommandService:KnitStart()
		PlayerCommandBinder.bind(self, self._janitor)
	end

	---@private
	---Menjalankan fungsi `_handleCommand`.
	---@param player any Nilai parameter `player`.
	---@param action any Nilai parameter `action`.
	function PlayerCommandService:_handleCommand(player, action)
		if not player or not action then return end
		if action == "rejoin" then
			self:_rejoin(player)
			return
		end
		if action == "fps" then
			self.Client.ToggleFps:Fire(player)
			return
		end
	end

	---@private
	---Menjalankan fungsi `_rejoin`.
	---@param player any Nilai parameter `player`.
	function PlayerCommandService:_rejoin(player)
		if not player then return end
		if RunService:IsStudio() then
			return
		end
		local ok, err = pcall(function()
			TeleportService:TeleportAsync(game.PlaceId, {player})
		end)
		if not ok then
			warn("[PlayerCommandService] Rejoin failed: " .. tostring(err))
		end
	end

	---Menjalankan fungsi `Ping`.
	---@param _player any Nilai parameter `_player`.
	---@param clientTime any Nilai parameter `clientTime`.
	function PlayerCommandService.Client:Ping(_player, clientTime)
		return clientTime
	end

	__module = PlayerCommandService

	if type(__module) == "table" then
		__module.__source = "Services/PlayerCommandService.luau"
	end
	Core.Services.PlayerCommandService = __module
end

---@class CoreServicesPlayerListService
---@field __source string Path sumber module `Services/PlayerListService.luau`.
Core.Services.PlayerListService = Core.Services.PlayerListService or {}
do
	local __module = nil
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Shared = ReplicatedStorage.Shared
	local Packages = Shared.Packages
	local Knit = require(Packages.Knit)
	local Janitor = require(Packages.Janitor)
	local Timer = require(Packages.Timer)
	local TableUtil = require(Packages.TableUtil)
	local StatsProvider = Core.Services.PlayerListHelpers.StatsProvider

	local PlayerListService = Knit.CreateService({
		Name = "PlayerListService",
		Client = {
			StatsUpdated = Knit.CreateSignal(),
		},
	})

	---@private
	---Menjalankan fungsi `_buildStats`.
	---@param player any Nilai parameter `player`.
	function PlayerListService:_buildStats(player)
		return StatsProvider.build(self, player)
	end

	---@private
	---Menjalankan fungsi `_broadcastPlayer`.
	---@param player any Nilai parameter `player`.
	function PlayerListService:_broadcastPlayer(player, force)
		if not player then
			return
		end
		local stats = self:_buildStats(player)
		if not self._lastStatsCache then
			self._lastStatsCache = {}
		end
		local last = self._lastStatsCache[player.UserId]
		if not force and last and stats and last.Posisi == stats.Posisi and last.Puncak == stats.Puncak and last.BestTime == stats.BestTime then
			return
		end
		self._lastStatsCache[player.UserId] = stats
		self.Client.StatsUpdated:FireAll(player.UserId, stats)
	end

	---@private
	---Menjalankan fungsi `_broadcastAll`.
	function PlayerListService:_broadcastAll()
		for _, player in ipairs(Players:GetPlayers()) do
			self:_broadcastPlayer(player)
		end
	end

	---Menjalankan fungsi `KnitInit`.
	function PlayerListService:KnitInit()
		self._janitor = Janitor.new()
		self._lastStatsCache = {}
		self._checkpointService = Knit.GetService("CheckpointService")
		self._speedrunService = Knit.GetService("SpeedrunService")

		self._janitor:Add(Players.PlayerAdded:Connect(function(player)
			self:_broadcastPlayer(player, true)
		end), "Disconnect")

		self._janitor:Add(Players.PlayerRemoving:Connect(function(player)
			if self._lastStatsCache then
				self._lastStatsCache[player.UserId] = nil
			end
			self.Client.StatsUpdated:FireAll(player.UserId, nil)
		end), "Disconnect")

		self._refreshTimer = Timer.new(8)
		self._janitor:Add(self._refreshTimer, "Destroy")
		self._refreshTimer.Tick:Connect(function()
			self:_broadcastAll()
		end)
		self._refreshTimer:Start()
	end

	---Menjalankan fungsi `GetSnapshot`.
	---@param _player any Nilai parameter `_player`.
	---@return any result Hasil dari fungsi `GetSnapshot`.
	function PlayerListService.Client:GetSnapshot(_player)
		return TableUtil.Copy(StatsProvider.snapshot(self.Server, Players:GetPlayers()))
	end

	__module = PlayerListService

	if type(__module) == "table" then
		__module.__source = "Services/PlayerListService.luau"
	end
	Core.Services.PlayerListService = __module
end

---@class CoreServicesPlaytimeService
---@field __source string Path sumber module `Services/PlaytimeService.luau`.
Core.Services.PlaytimeService = Core.Services.PlaytimeService or {}
do
	local __module = nil
	local Players = game:GetService("Players")
	local DataStoreService = game:GetService("DataStoreService")
	local ServerScriptService = game:GetService("ServerScriptService")

	local Shared = game:GetService("ReplicatedStorage").Shared
	local Packages = Shared.Packages
	local Knit = require(Packages.Knit)
	local Janitor = require(Packages.Janitor)

	local Server = serverFolder
	local Config = Server.Config
	local Data = Core.Data

	local PlaytimeConfig = require(Config.PlaytimeConfig)
	local PlaytimeProfile = Core.Data.PlaytimeProfile
	local OverheadConfig = require(Config.OverheadConfig)
	local FilterUtil = Core.Modules.Leaderboard.FilterUtil

	local PlaytimeService = Knit.CreateService({
		Name = "PlaytimeService",
	})

	---Menjalankan fungsi `KnitInit`.
	function PlaytimeService:KnitInit()
		self._janitor = Janitor.new()
		self._profiles = PlaytimeProfile.new(PlaytimeConfig.ProfileKey)
		self._board = DataStoreService:GetOrderedDataStore(PlaytimeConfig.LeaderboardKey)
		self._sessionStart = {}

		self:_bindPlayers(false)
		self:_startLoop()
	end

	---@private
	---Menjalankan fungsi `_bindPlayers`.
	---@param includeExistingPlayers any Nilai parameter `includeExistingPlayers`.
	function PlaytimeService:_bindPlayers(includeExistingPlayers)
		self._handlePlayerAdded = function(player)
			if self._profiles:GetProfile(player) then
				self._sessionStart[player] = self._sessionStart[player] or os.clock()
				return
			end
			self._profiles:Load(player)
			self._sessionStart[player] = os.clock()
		end

		self._handlePlayerRemoving = function(player)
			self:_flushPlayer(player)
			self._profiles:Release(player)
			self._sessionStart[player] = nil
		end

		self._janitor:Add(Players.PlayerAdded:Connect(self._handlePlayerAdded), "Disconnect")
		self._janitor:Add(Players.PlayerRemoving:Connect(self._handlePlayerRemoving), "Disconnect")
		if includeExistingPlayers ~= false then
			for _, player in ipairs(Players:GetPlayers()) do
				self._handlePlayerAdded(player)
			end
		end
	end

	---Menjalankan fungsi `KnitStart`.
	function PlaytimeService:KnitStart()
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(self._handlePlayerAdded, player)
		end
	end

	---@private
	---Menjalankan fungsi `_flushPlayer`.
	---@param player any Nilai parameter `player`.
	function PlaytimeService:_flushPlayer(player)
		local start = self._sessionStart[player]
		if not start then
			return
		end
		local elapsed = math.floor(os.clock() - start)
		if elapsed <= 0 then
			self._sessionStart[player] = os.clock()
			return
		end

		local total = self._profiles:AddSeconds(player, elapsed)
		if total then 
			local isExempt = FilterUtil.isExemptFromLeaderboard and FilterUtil.isExemptFromLeaderboard(player.UserId, player.Name, OverheadConfig)
			if isExempt == nil and FilterUtil.isPrivileged then 
				isExempt = FilterUtil.isPrivileged(player.UserId, player.Name, OverheadConfig)
			end

			if isExempt then 
				DataStoreConfig.RetryCall(function()
					self._board:RemoveAsync(tostring(player.UserId))
				end, "PlaytimeLeaderboard:RemoveAsync")
			else 
				DataStoreConfig.RetryCall(function()
					self._board:SetAsync(tostring(player.UserId), total)
				end, "PlaytimeLeaderboard:SetAsync")
			end
		end
		self._sessionStart[player] = os.clock()
	end
	--     if total then
	--         if not FilterUtil.isPrivileged(player.UserId, player.Name, OverheadConfig) then
	--             pcall(function()
	--                 self._board:SetAsync(tostring(player.UserId), total)
	--             end)
	--         end
	--     end
	--     self._sessionStart[player] = os.clock()
	-- end

	---@private
	---Menjalankan fungsi `_startLoop`.
	function PlaytimeService:_startLoop()
		local interval = tonumber(PlaytimeConfig.UpdateInterval) or 120
		self._running = true
		self._janitor:Add(function()
			self._running = false
		end, true)

		task.spawn(function()
			while self._running do
				task.wait(interval)
				if not self._running then
					break
				end
				for _, player in ipairs(Players:GetPlayers()) do
					self:_flushPlayer(player)
				end
			end
		end)
	end

	__module = PlaytimeService

	if type(__module) == "table" then
		__module.__source = "Services/PlaytimeService.luau"
	end
	Core.Services.PlaytimeService = __module
end

---@class CoreServicesRaceService
---@field __source string Path sumber module `Services/RaceService.luau`.
Core.Services.RaceService = Core.Services.RaceService or {}
do
	local __module = nil
	local Players = game:GetService("Players")
	local ServerStorage = game:GetService("ServerStorage")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")

	local Shared = ReplicatedStorage.Shared
	local Packages = Shared.Packages
	local Knit = require(Packages.Knit)
	local Janitor = require(Packages.Janitor)

	local Server = serverFolder
	local Config = Server.Config
	local RaceModules = Core.Modules.Race

	local RaceConfig = require(Config.RaceConfig)
	local StateFactory = Core.Modules.Race.StateFactory
	local StateManager = Core.Modules.Race.StateManager
	local Serializer = Core.Modules.Race.Serializer
	local RuntimeLoader = Core.Modules.Race.RuntimeLoader
	local BarrierController = Core.Modules.Race.BarrierController
	local SpawnResolver = Core.Modules.Race.SpawnResolver
	local Announcer = Core.Modules.Race.Announcer
	local JoinRequestHandler = Core.Modules.Race.JoinRequestHandler
	local PlayerBinder = Core.Modules.Race.PlayerBinder
	local TriggerBinder = Core.Modules.Race.TriggerBinder
	local Flow = Core.Modules.Race.Flow

	local RaceService = Knit.CreateService({
		Name = "RaceService",
		Client = {
			State = Knit.CreateProperty({}),
			Announcement = Knit.CreateSignal(),
			Notification = Knit.CreateSignal(),
			JoinPrompt = Knit.CreateSignal(),
		},
	})

	---Menjalankan fungsi `KnitInit`.
	function RaceService:KnitInit()
		self._janitor = Janitor.new()
		self._runtimeJanitor = Janitor.new()
		self._templateFolder = ServerStorage:FindFirstChild("Race")
		self._state = StateFactory.create()
		self._stateManager = StateManager.new(self._state)
		self._runtimeLoader = RuntimeLoader.new(self._templateFolder)
		self._announcer = Announcer.new(self)
		self._barriers = nil
		self._spawns = nil
		self._joinHandler = JoinRequestHandler.new({
			stateManager = self._stateManager,
			runtimeLoader = self._runtimeLoader,
			pushState = function(targetPlayer)
				self:_pushState(targetPlayer)
			end,
			resetProgress = function(player)
				local checkpointService = Knit.GetService("CheckpointService")
				if checkpointService and checkpointService._resetToStart then
					checkpointService:_resetToStart(player)
				end
				return true
			end,
		})
		self._flow = Flow.new({
			config = RaceConfig,
			stateManager = self._stateManager,
			runtimeLoader = self._runtimeLoader,
			buildRuntimeControllers = function(runtimeFolder)
				self:_resetRuntimeJanitor()
				self._barriers = BarrierController.new(runtimeFolder)
				self._spawns = SpawnResolver.new(runtimeFolder)
				self._joinHandler:setSpawnResolver(self._spawns)
				TriggerBinder.bind(self, self._runtimeJanitor, RaceConfig)
			end,
			clearRuntimeControllers = function()
				self._barriers = nil
				self._spawns = nil
				self._joinHandler:setSpawnResolver(nil)
				self:_resetRuntimeJanitor()
			end,
			getBarriers = function()
				return self._barriers
			end,
			announcer = self._announcer,
			pushState = function(targetPlayer)
				self:_pushState(targetPlayer)
			end,
		})
		self.Client.State:Set(self:_serialize())
	end

	---Menjalankan fungsi `KnitStart`.
	function RaceService:KnitStart()
		PlayerBinder.bind(self, Players, self._janitor)
	end

	---@private
	---Menjalankan fungsi `_resetRuntimeJanitor`.
	function RaceService:_resetRuntimeJanitor()
		if self._runtimeJanitor then
			self._runtimeJanitor:Destroy()
		end
		self._runtimeJanitor = Janitor.new()
	end

	---@private
	---Menjalankan fungsi `_serialize`.
	function RaceService:_serialize()
		return Serializer.serialize(self._stateManager:get())
	end

	---@private
	---Menjalankan fungsi `_pushState`.
	---@param targetPlayer any Nilai parameter `targetPlayer`.
	function RaceService:_pushState(targetPlayer)
		local payload = self:_serialize()
		if targetPlayer then
			self.Client.State:SetFor(targetPlayer, payload)
			return
		end
		self.Client.State:Set(payload)
	end

	---@private
	---Menjalankan fungsi `_isAdmin`.
	---@param player any Nilai parameter `player`.
	function RaceService:_isAdmin(player)
		local ok, result = pcall(function()
			local adminService = Knit.GetService("AdminService")
			if adminService and adminService._isAdminOnly then
				return adminService:_isAdminOnly(player)
			end
			return false
		end)
		return ok and result == true
	end

	---@private
	---Menjalankan fungsi `_onPlayerAdded`.
	---@param player any Nilai parameter `player`.
	function RaceService:_onPlayerAdded(player)
		self:_pushState(player)
	end

	---@private
	---Menjalankan fungsi `_onPlayerRemoving`.
	---@param player any Nilai parameter `player`.
	function RaceService:_onPlayerRemoving(player)
		self._stateManager:removePlayer(player.UserId)
		self:_pushState()
		if self._stateManager:get().active and self._flow then
			self._flow:tryAutoFinish()
		end
	end

	---@private
	---Menjalankan fungsi `_onLapTouched`.
	---@param player any Nilai parameter `player`.
	function RaceService:_onLapTouched(player)
		local state = self._stateManager:get()
		if state.status ~= RaceConfig.Statuses.Active then
			return
		end
		local ok = self._stateManager:markLap(player.UserId)
		if ok == true then
			self:_pushState()
		end
	end

	---@private
	---Menjalankan fungsi `_onFinishTouched`.
	---@param player any Nilai parameter `player`.
	function RaceService:_onFinishTouched(player)
		local state = self._stateManager:get()
		if state.status ~= RaceConfig.Statuses.Active then
			return
		end
		local ok, reason = self._stateManager:finishPlayer(player.UserId)
		if ok == true then
			if reason == "LapProgressed" then
				local checkpointService = Knit.GetService("CheckpointService")
				if checkpointService and checkpointService._resetToStart then
					checkpointService:_resetToStart(player)
				end
				self:_pushState()
				return
			end

			self:_pushState()
			self._flow:tryAutoFinish()
		end
	end

	---Menjalankan fungsi `GetState`.
	---@param player any Nilai parameter `player`.
	---@return any result Hasil dari fungsi `GetState`.
	function RaceService.Client:GetState(player)
		return self.Server:_serialize()
	end

	---Menjalankan fungsi `CreateRace`.
	---@param player any Nilai parameter `player`.
	---@param wins any Nilai parameter `wins`.
	---@param laps any Nilai parameter `laps`.
	---@return any result Hasil dari fungsi `CreateRace`.
	function RaceService.Client:CreateRace(player, wins, laps)
		if not self.Server:_isAdmin(player) then
			return false, "NoPermission"
		end
		return self.Server._flow:createRace(wins, laps)
	end

	---Menjalankan fungsi `CancelRace`.
	---@param player any Nilai parameter `player`.
	function RaceService.Client:CancelRace(player)
		if not self.Server:_isAdmin(player) then
			return false, "NoPermission"
		end
		return self.Server._flow:cancelRace()
	end

	---Menjalankan fungsi `JoinRace`.
	---@param player any Nilai parameter `player`.
	function RaceService.Client:JoinRace(player)
		return self.Server._joinHandler:accept(player)
	end

	__module = RaceService

	if type(__module) == "table" then
		__module.__source = "Services/RaceService.luau"
	end
	Core.Services.RaceService = __module
end

---@class CoreServicesShopService
---@field __source string Path sumber module `Services/ShopService.luau`.
Core.Services.ShopService = Core.Services.ShopService or {}
do
	local __module = nil
	local Players = game:GetService("Players")
	local MarketplaceService = game:GetService("MarketplaceService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")
	local ServerStorage = game:GetService("ServerStorage")

	local Shared = ReplicatedStorage.Shared
	local Packages = Shared.Packages
	local Knit = require(Packages.Knit)
	local Janitor = require(Packages.Janitor)
	local Promise = require(Packages.Promise)

	local Server = serverFolder
	local Config = Server.Config
	local Data = Core.Data
	local Modules = Core.Modules

	local ShopConfig = require(Config.ShopConfig)
	local ToolsConfig = require(Config.ToolsConfig)
	local ShopProfile = Core.Data.ShopProfile
	local ShopCatalog = Core.Modules.Shop.Catalog
	local ShopOwnership = Core.Modules.Shop.Ownership
	local ShopPurchases = Core.Modules.Shop.Purchases

	local ShopService = Knit.CreateService({
		Name = "ShopService",
		Client = {
			Catalog = Knit.CreateProperty({}),
			OwnedTools = Knit.CreateProperty({}),
			PurchaseNotice = Knit.CreateSignal(),
		},
		_janitor = nil,
		_profiles = nil,
		_catalog = nil,
		_ownership = nil,
		_purchases = nil,
	})

	---@private
	---Menjalankan fungsi `_buildCatalog`.
	function ShopService:_buildCatalog()
		self._catalog:Rebuild()
		self.Client.Catalog:Set(self._catalog:GetPublicCatalog())
	end

	---Menjalankan fungsi `BeginGift`.
	---@param player any Nilai parameter `player`.
	---@param toolId any Nilai parameter `toolId`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	function ShopService.Client:BeginGift(player, toolId, targetUserId)
		return ShopService._purchases:BeginGift(player, toolId, targetUserId)
	end

	---Menjalankan fungsi `OwnsTool`.
	---@param player any Nilai parameter `player`.
	---@param toolId any Nilai parameter `toolId`.
	function ShopService.Client:OwnsTool(player, toolId)
		return ShopService._profiles:HasTool(player, toolId)
	end

	---Menjalankan fungsi `ProcessReceipt`.
	---@param receiptInfo any Nilai parameter `receiptInfo`.
	function ShopService:ProcessReceipt(receiptInfo)
		return self._purchases:ProcessReceipt(receiptInfo)
	end

	---@private
	---Menjalankan fungsi `_playerAdded`.
	---@param player any Nilai parameter `player`.
	function ShopService:_playerAdded(player)
		if not self._ownership:EnsureProfile(player) then
			self.Client.OwnedTools:SetFor(player, {})
			return
		end

		self._ownership:SyncGamePassOwnership(player)
		self._ownership:SetOwnedToolsProperty(player)
		self._ownership:GrantOwnedTools(player)

		self._janitor:Add(player.CharacterAdded:Connect(function()
			Promise.delay(0.1):andThen(function()
				self._ownership:GrantOwnedTools(player)
			end)
		end), "Disconnect")
	end

	---@private
	---Menjalankan fungsi `_playerRemoving`.
	---@param player any Nilai parameter `player`.
	function ShopService:_playerRemoving(player)
		self.Client.OwnedTools:SetFor(player, nil)
		self._profiles:Release(player)
	end

	---Menjalankan fungsi `KnitInit`.
	function ShopService:KnitInit()
		self._janitor = Janitor.new()
		self._profiles = ShopProfile.new(ShopConfig.ProfileKey)
		self._catalog = ShopCatalog.new(ServerStorage, ShopConfig, ToolsConfig)
		self._ownership = ShopOwnership.new(Players, MarketplaceService, self._profiles, self._catalog, self.Client.OwnedTools)
		self._purchases = ShopPurchases.new(Players, self._profiles, self._catalog, self._ownership, self.Client.PurchaseNotice)
		self:_buildCatalog()
	end

	---Menjalankan fungsi `KnitStart`.
	function ShopService:KnitStart()
		self._janitor:Add(Players.PlayerAdded:Connect(function(player)
			self:_playerAdded(player)
		end), "Disconnect")
		self._janitor:Add(Players.PlayerRemoving:Connect(function(player)
			self:_playerRemoving(player)
		end), "Disconnect")

		local folder = self._catalog:GetToolsFolder()
		if folder then
			self._janitor:Add(folder.ChildAdded:Connect(function()
				self:_buildCatalog()
			end), "Disconnect")
			self._janitor:Add(folder.ChildRemoved:Connect(function()
				self:_buildCatalog()
			end), "Disconnect")
		end

		for _, player in ipairs(Players:GetPlayers()) do
			Promise.delay(0):andThen(function()
				self:_playerAdded(player)
			end)
		end

		self._janitor:Add(MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
			if not wasPurchased then
				return
			end

			self._purchases:HandleGamePassPurchase(player, gamePassId)
		end), "Disconnect")
	end

	---Menjalankan fungsi `KnitShutdown`.
	function ShopService:KnitShutdown()
		if self._janitor then
			self._janitor:Destroy()
			self._janitor = nil
		end
	end

	__module = ShopService

	if type(__module) == "table" then
		__module.__source = "Services/ShopService.luau"
	end
	Core.Services.ShopService = __module
end

---@class CoreServicesSpeedrunService
---@field __source string Path sumber module `Services/SpeedrunService.luau`.
---@field _bindPlayers any Member private `_bindPlayers` dari `Services/SpeedrunService.luau`.
---@field _bindTriggers any Member private `_bindTriggers` dari `Services/SpeedrunService.luau`.
---@field _resetAllBestTimes any Member private `_resetAllBestTimes` dari `Services/SpeedrunService.luau`.
---@field _resetBestTime any Member private `_resetBestTime` dari `Services/SpeedrunService.luau`.
---@field _resetBestTimeByUserId any Member private `_resetBestTimeByUserId` dari `Services/SpeedrunService.luau`.
---@field KnitInit any Member public `KnitInit` dari `Services/SpeedrunService.luau`.
---@field KnitStart any Member public `KnitStart` dari `Services/SpeedrunService.luau`.
Core.Services.SpeedrunService = Core.Services.SpeedrunService or {}
do
	local __module = nil
	local DataStoreService = game:GetService("DataStoreService")
	local ServerScriptService = game:GetService("ServerScriptService")

	local Shared = game:GetService("ReplicatedStorage").Shared
	local Packages = Shared.Packages
	local Knit = require(Packages.Knit)
	local Janitor = require(Packages.Janitor)

	local Server = serverFolder
	local Config = Server.Config
	local Modules = Core.Modules
	local Data = Core.Data

	local SpeedrunConfig = require(Config.SpeedrunConfig)
	local OverheadConfig = require(Config.OverheadConfig)
	local RoleChecker = Core.Services.CustomTitle.RoleChecker
	local SpeedrunProfile = Core.Data.SpeedrunProfile
	local SpeedrunIndex = Core.Modules.Speedrun.Index
	local SpeedrunFlow = Core.Modules.Speedrun.Flow
	local FilterUtil = Core.Modules.Leaderboard.FilterUtil
	local SpeedrunCommandBinder = Core.Modules.Speedrun.Admin.SpeedrunCommandBinder
	local SpeedrunFormatter = Core.Modules.Speedrun.SpeedrunFormatter
	local SpeedrunLeaderboard = Core.Modules.Speedrun.SpeedrunLeaderboard
	local SpeedrunAntiCheat = Core.Modules.Speedrun.SpeedrunAntiCheat
	local SpeedrunStatsSync = Core.Modules.Speedrun.SpeedrunStatsSync
	local PlayerHandler = Core.Services.SpeedrunHelpers.PlayerHandler
	local TriggerHandler = Core.Services.SpeedrunHelpers.TriggerHandler
	local ResetHandler = Core.Services.SpeedrunHelpers.ResetHandler

	local SpeedrunService = Knit.CreateService({
		Name = "SpeedrunService",
		Client = {
			RunStarted = Knit.CreateSignal(),
			RunFinished = Knit.CreateSignal(),
		},
	})

	---Menjalankan fungsi `KnitInit`.
	function SpeedrunService:KnitInit()
		self._janitor = Janitor.new()
		self._profiles = SpeedrunProfile.new(SpeedrunConfig.ProfileKey)
		self._flow = SpeedrunFlow.new(SpeedrunConfig)
		self._index = SpeedrunIndex.new()
		self._bestTimeBoard = DataStoreService:GetOrderedDataStore(SpeedrunConfig.BestTimeLeaderboardKey)
		self._leaderboard = SpeedrunLeaderboard.new(self._bestTimeBoard, FilterUtil, OverheadConfig)
		self._antiCheat = SpeedrunAntiCheat.new(SpeedrunConfig, RoleChecker, OverheadConfig)
		self._statsSync = SpeedrunStatsSync.new(SpeedrunFormatter)

		PlayerHandler.bind(self, false)
		TriggerHandler.bind(self)
		SpeedrunCommandBinder.bind(self, self._janitor)
	end

	---@private
	---Menjalankan fungsi `_bindPlayers`.
	---@param includeExistingPlayers any Nilai parameter `includeExistingPlayers`.
	function SpeedrunService:_bindPlayers(includeExistingPlayers)
		PlayerHandler.bind(self, includeExistingPlayers)
	end

	---Menjalankan fungsi `KnitStart`.
	function SpeedrunService:KnitStart()
		PlayerHandler.startExisting(self)
	end

	---@private
	---Menjalankan fungsi `_bindTriggers`.
	function SpeedrunService:_bindTriggers()
		TriggerHandler.bind(self)
	end

	---@private
	---Menjalankan fungsi `_resetBestTime`.
	---@param player any Nilai parameter `player`.
	function SpeedrunService:_resetBestTime(player)
		ResetHandler.resetBestTime(self, player)
	end

	---@private
	---Menjalankan fungsi `_resetBestTimeByUserId`.
	---@param userId any Nilai parameter `userId`.
	function SpeedrunService:_resetBestTimeByUserId(userId)
		ResetHandler.resetBestTimeByUserId(self, userId)
	end

	---@private
	---Menjalankan fungsi `_resetAllBestTimes`.
	function SpeedrunService:_resetAllBestTimes()
		ResetHandler.resetAllBestTimes(self)
	end

	__module = SpeedrunService

	if type(__module) == "table" then
		__module.__source = "Services/SpeedrunService.luau"
	end
	Core.Services.SpeedrunService = __module
end

---@class CoreServicesVipService
---@field __source string Path sumber module `Services/VipService.luau`.
Core.Services.VipService = Core.Services.VipService or {}
do
	local __module = nil
	local Players = game:GetService("Players")
	local MarketplaceService = game:GetService("MarketplaceService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")

	local Shared = ReplicatedStorage.Shared
	local Packages = Shared.Packages
	local Knit = require(Packages.Knit)
	local Janitor = require(Packages.Janitor)
	local Promise = require(Packages.Promise)

	local Server = serverFolder
	local Data = Core.Data
	local Config = Server.Config

	local VipProfile = Core.Data.VipProfile
	local VipConfig = require(Config.VipConfig)
	local OverheadConfig = require(Config.OverheadConfig)
	local PurchaseRouter = Core.Services.VipHelpers.PurchaseRouter
	local ToolGiver = Core.Services.VipHelpers.ToolGiver
	local GiftHandler = Core.Services.VipHelpers.GiftHandler
	local GamePassChecker = Core.Services.VipHelpers.GamePassChecker

	local VipService = Knit.CreateService({
		Name = "VipService",
		Client = {
			Config = Knit.CreateProperty(VipConfig),
			GiftNotice = Knit.CreateSignal(),
		},
		_profiles = nil,
		_pendingGifts = {},
		_janitor = nil,
	})

	---@private
	---Menjalankan fungsi `setVipAttribute`.
	---@param player any Nilai parameter `player`.
	---@param enabled any Nilai parameter `enabled`.
	local function setVipAttribute(player, enabled)
		local attr = OverheadConfig.VipAttribute or "VIP"
		player:SetAttribute(attr, enabled == true)
	end

	---Menjalankan fungsi `BeginGift`.
	---@param player any Nilai parameter `player`.
	---@param targetUserId any Nilai parameter `targetUserId`.
	function VipService.Client:BeginGift(player, targetUserId)
		return GiftHandler.begin(VipService, player, targetUserId)
	end

	---@private
	---Menjalankan fungsi `_grantVipByUserId`.
	---@param userId any Nilai parameter `userId`.
	function VipService:_grantVipByUserId(userId)
		local plr = Players:GetPlayerByUserId(userId)
		if plr then
			self._profiles:SetVip(plr, true)
			setVipAttribute(plr, true)
			ToolGiver.giveVipTools(plr)
			return true
		end

		local ok = self._profiles:SetVipByUserId(userId, true)
		if ok ~= nil then
			return true
		end
		return false
	end

	---@private
	---Menjalankan fungsi `_grantVip`.
	---@param player any Nilai parameter `player`.
	function VipService:_grantVip(player)
		self._profiles:SetVip(player, true)
		setVipAttribute(player, true)
		ToolGiver.giveVipTools(player)
	end

	---@private
	---Menjalankan fungsi `_checkGamePass`.
	---@param player any Nilai parameter `player`.
	function VipService:_checkGamePass(player)
		return GamePassChecker.check(self, player, VipConfig)
	end

	---@private
	---Menjalankan fungsi `_processReceipt`.
	---@param receiptInfo any Nilai parameter `receiptInfo`.
	function VipService:_processReceipt(receiptInfo)
		local giftId = VipConfig.GiftProductId
		if not giftId or giftId == 0 then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if receiptInfo.ProductId ~= giftId then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local gifterId = receiptInfo.PlayerId
		local targetId = self._pendingGifts[gifterId] or gifterId
		self._pendingGifts[gifterId] = nil

		local granted = self:_grantVipByUserId(targetId)
		if granted then
			self:_notifyGift(gifterId, targetId)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	---@private
	---Menjalankan fungsi `_notifyGift`.
	---@param gifterId any Nilai parameter `gifterId`.
	---@param targetId any Nilai parameter `targetId`.
	function VipService:_notifyGift(gifterId, targetId)
		GiftHandler.notify(self, gifterId, targetId)
	end

	---Menjalankan fungsi `KnitInit`.
	function VipService:KnitInit()
		self._profiles = VipProfile.new()
		self._janitor = Janitor.new()

		self.Client.Config:Set(VipConfig)

		-- [REFACTORED]: MarketplaceService.ProcessReceipt is authoritatively handled by UnifiedPurchaseGateway
		-- to prevent race conditions and guarantee persistent receipt deduplication.
	end

	---Menjalankan fungsi `PlayerAdded`.
	---@param player any Nilai parameter `player`.
	function VipService:PlayerAdded(player)
		self._profiles:Load(player)
		local storedVip = self._profiles:IsVip(player)
		setVipAttribute(player, storedVip)
		if storedVip then
			ToolGiver.giveVipTools(player)
		end

		self:_checkGamePass(player):andThen(function(owns)
			if owns then
				self:_grantVip(player)
			end
		end)
	end

	---Menjalankan fungsi `PlayerRemoving`.
	---@param player any Nilai parameter `player`.
	function VipService:PlayerRemoving(player)
		self._profiles:Release(player)
	end

	---Menjalankan fungsi `KnitStart`.
	function VipService:KnitStart()
		self._janitor:Add(Players.PlayerAdded:Connect(function(player)
			self:PlayerAdded(player)
		end), "Disconnect")
		self._janitor:Add(Players.PlayerRemoving:Connect(function(player)
			self:PlayerRemoving(player)
		end), "Disconnect")
		for _, plr in ipairs(Players:GetPlayers()) do
			Promise.delay(0):andThen(function()
				self:PlayerAdded(plr)
			end)
		end

		self._janitor:Add(MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
			if gamePassId == VipConfig.GamePassId and wasPurchased then
				self:_grantVip(player)
			end
		end), "Disconnect")

		-- [REFACTORED]: VIP gifting is granted exclusively via ProcessReceipt inside UnifiedPurchaseGateway.
		-- PromptProductPurchaseFinished must NEVER grant products (causes duplicate grants & recipient corruption).
	end

	---Menjalankan fungsi `KnitShutdown`.
	function VipService:KnitShutdown()
		if self._janitor then
			self._janitor:Destroy()
			self._janitor = nil
		end
	end

	__module = VipService

	if type(__module) == "table" then
		__module.__source = "Services/VipService.luau"
	end
	Core.Services.VipService = __module
end


Core.Init = function(self)
	if self._armed then return end
	self._armed = true
end

Core.AdminHelpers = Core.Modules.AdminHelpers
Core.AdminService = Core.Services.AdminService
Core.AvatarHelpers = Core.Services.AvatarHelpers
Core.AvatarService = Core.Services.AvatarService
Core.Carry = Core.Modules.Carry
Core.CarryService = Core.Services.CarryService
Core.Checkpoint = Core.Modules.Checkpoint
Core.CheckpointService = Core.Services.CheckpointService
Core.CustomTitle = Core.Services.CustomTitle
Core.DanceHelpers = Core.Services.DanceHelpers
Core.DanceService = Core.Services.DanceService
Core.DonationHelpers = Core.Services.DonationHelpers
Core.Donations = Core.Modules.Donations
Core.DonationsService = Core.Services.DonationsService
Core.Leaderboard = Core.Modules.Leaderboard
Core.LeaderboardHelpers = Core.Services.LeaderboardHelpers
Core.LeaderboardService = Core.Services.LeaderboardService
Core.OverheadHelpers = Core.Services.OverheadHelpers
Core.OverheadService = Core.Services.OverheadService
Core.Physics = Core.Modules.Physics
Core.PlayerCommandService = Core.Services.PlayerCommandService
Core.PlayerCommands = Core.Modules.PlayerCommands
Core.PlayerListHelpers = Core.Services.PlayerListHelpers
Core.PlayerListService = Core.Services.PlayerListService
Core.PlaytimeService = Core.Services.PlaytimeService
Core.Race = Core.Modules.Race
Core.RaceService = Core.Services.RaceService
Core.Shop = Core.Modules.Shop
Core.ShopService = Core.Services.ShopService
Core.Speedrun = Core.Modules.Speedrun
Core.SpeedrunHelpers = Core.Services.SpeedrunHelpers
Core.SpeedrunService = Core.Services.SpeedrunService
Core.Teleport = Core.Modules.Teleport
Core.VipHelpers = Core.Services.VipHelpers
Core.VipService = Core.Services.VipService

return Core