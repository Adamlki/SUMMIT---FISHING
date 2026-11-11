-- ServerScriptService/FishingServerScripts/AdminLuckManager
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RoleConfig = require(ReplicatedStorage:WaitForChild("RoleConfig"))
local TextChatService = game:GetService("TextChatService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")

print("🔒 [AdminLuck] Security System Active.")

-- ==============================================================================
-- ⚙️ KONFIGURASI ADMIN
-- ==============================================================================
local ADMIN_IDS = {
	7319628066,
	8978185974, -- Game Creator
}

local ADMIN_NAMES = {
	["guard_zvxjekybix"] = true,
}

local GLOBAL_TOPIC = "GlobalLuckEvent"

-- GENERATE SERVER ID UNIK
local SERVER_ID = game.JobId
if SERVER_ID == "" then
	SERVER_ID = "Studio_" .. tostring(HttpService:GenerateGUID(false))
end

print("[AdminLuck] Server ID:", SERVER_ID)

-- ==============================================================================
-- 🛠️ AUTO-SETUP REPLICATED STORAGE VALUES
-- ==============================================================================
local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem", 15)

local LuckValue = FishingSystem:FindFirstChild("GlobalLuckMultiplier")
if not LuckValue then
	LuckValue = Instance.new("NumberValue")
	LuckValue.Name = "GlobalLuckMultiplier"
	LuckValue.Value = 1
	LuckValue.Parent = FishingSystem
end

local MutationValue = FishingSystem:FindFirstChild("GlobalMutationMultiplier")
if not MutationValue then
	MutationValue = Instance.new("NumberValue")
	MutationValue.Name = "GlobalMutationMultiplier"
	MutationValue.Value = 1
	MutationValue.Parent = FishingSystem
end

local ActiveEventName = FishingSystem:FindFirstChild("ActiveEventName")
if not ActiveEventName then
	ActiveEventName = Instance.new("StringValue")
	ActiveEventName.Name = "ActiveEventName"
	ActiveEventName.Value = ""
	ActiveEventName.Parent = FishingSystem
end

local TimerValue = FishingSystem:FindFirstChild("LuckBoostTimer")
if not TimerValue then
	TimerValue = Instance.new("IntValue")
	TimerValue.Name = "LuckBoostTimer"
	TimerValue.Value = 0
	TimerValue.Parent = FishingSystem
end

local TriggerAdminEvent = FishingSystem:FindFirstChild("TriggerAdminEvent")
if not TriggerAdminEvent then
	TriggerAdminEvent = Instance.new("RemoteEvent")
	TriggerAdminEvent.Name = "TriggerAdminEvent"
	TriggerAdminEvent.Parent = FishingSystem
end

local AdminEventActivated = FishingSystem:FindFirstChild("AdminEventActivated")
if not AdminEventActivated then
	AdminEventActivated = Instance.new("RemoteEvent")
	AdminEventActivated.Name = "AdminEventActivated"
	AdminEventActivated.Parent = FishingSystem
end

local ShowNotification = FishingSystem:WaitForChild("ShowNotification")
local SendChatMessage = FishingSystem:WaitForChild("SendChatMessage")
local currentBoostTask = nil

-- ==============================================================================
-- ⚙️ FUNGSI BANTUAN & VALIDASI ADMIN
-- ==============================================================================

local function isPlayerAuthorized(player)
	if not player then return false end

	-- 1. Selalu izinkan saat testing di Roblox Studio
	if RunService:IsStudio() then
		return true
	end

	-- 2. H-02: Single source of truth via RoleConfig (covers Owner, Owner#2, Developer, Admin)
	if RoleConfig and RoleConfig.IsAdmin and RoleConfig.IsAdmin(player) then
		return true
	end

	-- 3. Cek Game Creator
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end

	-- 4. Fallback Cek ID dalam daftar Admin
	for _, id in ipairs(ADMIN_IDS) do
		if player.UserId == id then
			return true
		end
	end

	-- 5. Fallback Cek Username
	if ADMIN_NAMES[string.lower(player.Name)] then
		return true
	end

	-- 6. Cek Group Rank jika Group Game
	if game.CreatorType == Enum.CreatorType.Group then
		local s, rank = pcall(function()
			return player:GetRankInGroup(game.CreatorId)
		end)
		if s and rank and rank >= 250 then
			return true
		end
	end

	return false
end

local function getPlayerDisplayName(player)
	return player and player.DisplayName or (player and player.Name) or "Admin"
end

local function formatTime(seconds)
	if seconds >= 60 then
		return string.format("%d menit", math.floor(seconds / 60))
	else
		return string.format("%d detik", seconds)
	end
end

local function anchorModel(model, isAnchored)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("UnionOperation") then
			part.Anchored = isAnchored
		end
	end
end

local function toggleVisualEffects(model, isEnabled)
	for _, child in model:GetDescendants() do
		if child:IsA("ParticleEmitter") or child:IsA("Beam") or child:IsA("Trail") then
			child.Enabled = isEnabled
		end
	end
end

-- ==============================================================================
-- 🧠 LOGIKA UTAMA BOOST
-- ==============================================================================

local function executeLuckBoost(multiplier, duration, isGlobal, adminName, senderServerId)
	local isLocalExecution = not senderServerId or senderServerId == SERVER_ID

	if currentBoostTask then
		task.cancel(currentBoostTask)
		currentBoostTask = nil
	end

	currentBoostTask = task.spawn(function()
		if LuckValue then LuckValue.Value = multiplier end
		if TimerValue then TimerValue.Value = duration end

		-- ==========================================================
		-- 🌟 EFEK INTRO HANYA 5.5 DETIK, LALU OTOMATIS NORMAL KEMBALI
		-- ==========================================================
		if isLocalExecution then
			task.spawn(function()
				-- 1. Lucky Model
				local luckyModel = ReplicatedStorage:FindFirstChild("lucky")
				if luckyModel then
					anchorModel(luckyModel, true)
					luckyModel.Parent = Workspace
					toggleVisualEffects(luckyModel, true)
				end

				-- 2. Sky Lucky
				local skyLucky = ReplicatedStorage:FindFirstChild("SkyLucky")
				local activeSkyLucky = nil
				if skyLucky then
					local oldSky = Lighting:FindFirstChild("EventSkyLucky")
					if oldSky then oldSky:Destroy() end
					activeSkyLucky = skyLucky:Clone()
					activeSkyLucky.Name = "EventSkyLucky"
					activeSkyLucky.Parent = Lighting
				end

				-- 3. Sound Lucky
				local luckysound = ReplicatedStorage:FindFirstChild("luckysound")
				local activeLuckySound = nil
				if luckysound then
					local oldSnd = Lighting:FindFirstChild("ActiveLuckySound")
					if oldSnd then oldSnd:Destroy() end
					activeLuckySound = luckysound:Clone()
					activeLuckySound.Name = "ActiveLuckySound"
					activeLuckySound.Parent = Lighting
					activeLuckySound.Looped = false
					activeLuckySound:Play()
				end

				-- ⏱️ TUNGGU 5.5 DETIK PAS INTRO SELESAI, KEMBALI KE BIASA!
				task.wait(5.5)

				if luckyModel and luckyModel.Parent == Workspace then
					toggleVisualEffects(luckyModel, false)
					luckyModel.Parent = ReplicatedStorage
					anchorModel(luckyModel, false)
				end

				if activeSkyLucky and activeSkyLucky.Parent == Lighting then
					activeSkyLucky:Destroy()
				end

				if activeLuckySound and activeLuckySound.Parent == Lighting then
					activeLuckySound:Stop()
					activeLuckySound:Destroy()
				end
			end)
		end

		local scopeText = isGlobal and "GLOBAL" or "SERVER"
		local chatChannel = isGlobal and "Global" or "General"
		local chatRarity = "Uncommon"

		local chatFishName = string.format("Owner %s mengaktifkan %s Booster Luck x%d selama %s",
			adminName,
			scopeText,
			multiplier,
			formatTime(duration)
		)

		print("🚀 [AdminLuck] BOOST AKTIF: " .. chatFishName)

		-- Kirim Chat log ke pemain tanpa double pop-up bar di atas
		if isLocalExecution then
			pcall(function()
				SendChatMessage:FireAllClients(chatChannel, "SYSTEM", chatFishName, 0, chatRarity)
			end)
		end

		-- Countdown Timer Loop (Berjalan di background sesuai durasi)
		local timeLeft = duration
		while timeLeft > 0 do
			task.wait(1)
			timeLeft = timeLeft - 1
			if TimerValue then TimerValue.Value = timeLeft end
		end

		-- Selesai waktu event
		if LuckValue then LuckValue.Value = 1 end
		if MutationValue then MutationValue.Value = 1 end
		if TimerValue then TimerValue.Value = 0 end
		if ActiveEventName then ActiveEventName.Value = "" end

		ShowNotification:FireAllClients("Event Luck & Mutasi Telah Berakhir.", 4, Color3.fromRGB(200, 200, 200))
		print("🏁 [AdminLuck] Boost Selesai.")
	end)
end

-- ==============================================================================
-- 🧠 PROCESSOR CHAT COMMAND
-- ==============================================================================
local function processCommand(player, text)
	text = string.gsub(text, "^%s*(.-)%s*$", "%1")

	local prefix = string.sub(text, 1, 1)
	local commandBody = string.sub(text, 2)
	local args = string.split(commandBody, " ")
	local cmd = string.lower(args[1] or "")

	if prefix ~= "/" and prefix ~= ":" and prefix ~= "!" then return end

	if cmd == "luck" then
		if not isPlayerAuthorized(player) then
			warn("⛔ SECURITY ALERT: " .. player.Name .. " mencoba pakai command admin!")
			ShowNotification:FireClient(player, "⛔ Anda bukan Admin!", 3, Color3.fromRGB(255, 50, 50))
			return
		end

		local adminName = getPlayerDisplayName(player)
		local scope = string.lower(args[2] or "server")
		local mult = tonumber(args[3]) or 30
		local minutes = tonumber(args[4]) or 30
		local duration = minutes * 60

		if scope == "server" then
			executeLuckBoost(mult, duration, false, adminName)
		elseif scope == "global" then
			pcall(function()
				MessagingService:PublishAsync(GLOBAL_TOPIC, {m=mult, d=duration, a=adminName, s=SERVER_ID, mut=1, event="Mega Luck"})
			end)
			executeLuckBoost(mult, duration, true, adminName, SERVER_ID)
		end

	elseif cmd == "unluck" then
		if isPlayerAuthorized(player) then
			if currentBoostTask then
				task.cancel(currentBoostTask)
				currentBoostTask = nil
			end
			if LuckValue then LuckValue.Value = 1 end
			if MutationValue then MutationValue.Value = 1 end
			if TimerValue then TimerValue.Value = 0 end
			if ActiveEventName then ActiveEventName.Value = "" end

			local activeSky = Lighting:FindFirstChild("EventSkyLucky")
			if activeSky then activeSky:Destroy() end

			local activeSound = Lighting:FindFirstChild("ActiveLuckySound")
			if activeSound then activeSound:Destroy() end

			ShowNotification:FireAllClients("🚫 Boost dibatalkan Admin.", 4, Color3.fromRGB(255, 100, 100))

			local luckyModel = ReplicatedStorage:FindFirstChild("lucky")
			if luckyModel and luckyModel.Parent == Workspace then
				toggleVisualEffects(luckyModel, false)
				luckyModel.Parent = ReplicatedStorage
				anchorModel(luckyModel, false)
			end
		end
	end
end

-- ==============================================================================
-- 👂 LISTENERS
-- ==============================================================================

Players.PlayerAdded:Connect(function(player)
	print("👤 LOGIN: " .. player.Name .. " | ID: " .. player.UserId)
	player.Chatted:Connect(function(msg)
		processCommand(player, msg)
	end)
end)

if TextChatService:FindFirstChild("TextChannels") then
	local general = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
	if general then
		general.ShouldDeliverCallback = function(message, source)
			processCommand(Players:GetPlayerByUserId(source.UserId), message.Text)
			return true
		end
	end
end

-- Subscribe Global Topic
pcall(function()
	MessagingService:SubscribeAsync(GLOBAL_TOPIC, function(msg)
		local d = msg.Data
		if d and d.s ~= SERVER_ID then
			if d.mut and MutationValue then MutationValue.Value = d.mut end
			if d.event and ActiveEventName then ActiveEventName.Value = d.event end
			
			AdminEventActivated:FireAllClients({
				title = d.event or "Secret Event",
				admin = d.a or "Admin",
				durationMinutes = math.floor((d.d or 1800) / 60),
				luck = d.m or 30,
				mutation = d.mut or 7,
				bonusLuck = string.format("+%d%%", (d.m or 30) * 666)
			})
			
			executeLuckBoost(d.m, d.d, true, d.a, d.s)
		end
	end)
end)

-- ==============================================================================
-- 📡 REMOTE EVENT TRIGGER DARI ADMIN PANEL (GUI)
-- ==============================================================================

TriggerAdminEvent.OnServerEvent:Connect(function(player, data)
	print("⚡ [AdminLuck] Received event request from:", player.Name, "Action:", data and data.action)

	if not isPlayerAuthorized(player) then
		warn("⛔ UNAUTHORIZED: " .. player.Name .. " mencoba memicu Admin Event!")
		ShowNotification:FireClient(player, "⛔ Akses Ditolak: Anda bukan Admin!", 4, Color3.fromRGB(255, 50, 50))
		return
	end

	if data.action == "STOP" then
		if currentBoostTask then
			task.cancel(currentBoostTask)
			currentBoostTask = nil
		end
		if LuckValue then LuckValue.Value = 1 end
		if MutationValue then MutationValue.Value = 1 end
		if TimerValue then TimerValue.Value = 0 end
		if ActiveEventName then ActiveEventName.Value = "" end

		local activeSky = Lighting:FindFirstChild("EventSkyLucky")
		if activeSky then activeSky:Destroy() end

		local activeSound = Lighting:FindFirstChild("ActiveLuckySound")
		if activeSound then activeSound:Destroy() end

		local luckyModel = Workspace:FindFirstChild("lucky")
		if luckyModel then
			toggleVisualEffects(luckyModel, false)
			luckyModel.Parent = ReplicatedStorage
			anchorModel(luckyModel, false)
		end

		ShowNotification:FireAllClients("Event dihentikan oleh Admin " .. player.DisplayName, 4, Color3.fromRGB(255, 100, 100))
		return
	end

	-- AKTIFKAN EVENT
	local eventName = data.eventName or "Secret Event"
	local luck = tonumber(data.luck) or 30
	local mutation = tonumber(data.mutation) or 7
	local durationMin = tonumber(data.durationMinutes) or 30
	local durationSec = durationMin * 60
	local isGlobal = (data.scope == "Global")

	if ActiveEventName then ActiveEventName.Value = eventName end
	if MutationValue then MutationValue.Value = mutation end

	print(string.format("🌟 [AdminLuck] Memulai Event '%s' (Luck x%d, Mutasi x%d, %d Menit, Scope: %s)",
		eventName, luck, mutation, durationMin, data.scope or "Global"))

	-- 1. Broadcast Animasi Sinematik Banner ke SEMUA client (tanpa double notifikasi)
	AdminEventActivated:FireAllClients({
		title = eventName,
		admin = player.DisplayName,
		durationMinutes = durationMin,
		luck = luck,
		mutation = mutation,
		bonusLuck = string.format("+%d%%", luck * 666)
	})

	-- 2. Jika Global, publish via MessagingService
	if isGlobal then
		pcall(function()
			MessagingService:PublishAsync(GLOBAL_TOPIC, {
				m = luck,
				d = durationSec,
				a = player.DisplayName,
				s = SERVER_ID,
				mut = mutation,
				event = eventName
			})
		end)
	end

	-- 3. Jalankan boost logic utama di server ini (efek visual 5.5s, boost aktif durationSec)
	executeLuckBoost(luck, durationSec, isGlobal, player.DisplayName)
end)

print("✅ [AdminLuck] TriggerAdminEvent Remote Listener fully connected!")

-- ==============================================================================
-- 👑 ADMIN TARGETED PLAYER ACTIONS (GIVE COINS & GIVE LUCK)
-- ==============================================================================
local AdminPlayerAction = FishingSystem:WaitForChild("AdminPlayerAction") :: RemoteFunction
local GameProfileService = require(ServerScriptService.Data.PetCore:WaitForChild("FishData"))

local function formatNumber(n)
	local str = tostring(math.floor(tonumber(n) or 0))
	return string.reverse(string.gsub(string.reverse(str), "(%d%d%d)", "%1,")):gsub("^,", "")
end

AdminPlayerAction.OnServerInvoke = function(player, action, targetUserId, amount)
	-- 1. Validasi otorisasi Admin
	if not isPlayerAuthorized(player) then
		return { success = false, message = "Kamu tidak memiliki akses Admin!" }
	end

	-- 2. Resolve target player
	local targetId = tonumber(targetUserId)
	if not targetId then
		return { success = false, message = "Pilih pemain target terlebih dahulu!" }
	end

	local targetPlayer = Players:GetPlayerByUserId(targetId)
	if not targetPlayer then
		return { success = false, message = "Pemain target tidak ditemukan di server!" }
	end

	local numVal = tonumber(amount) or 0

	if action == "GiveCoins" then
		if numVal <= 0 then
			return { success = false, message = "Nominal koin harus lebih dari 0!" }
		end

		GameProfileService:AddCoins(targetPlayer, numVal)

		-- Notifikasi ke target
		ShowNotification:FireClient(
			targetPlayer,
			string.format("💰 Kamu menerima +%s Koin dari Admin %s!", formatNumber(numVal), player.DisplayName),
			4,
			Color3.fromRGB(80, 255, 120)
		)

		-- Notifikasi ke Admin
		ShowNotification:FireClient(
			player,
			string.format("✓ Berhasil mengirim %s Koin ke %s!", formatNumber(numVal), targetPlayer.DisplayName),
			3,
			Color3.fromRGB(100, 220, 255)
		)

		return {
			success = true,
			message = string.format("Berhasil mengirim %s Koin ke %s!", formatNumber(numVal), targetPlayer.DisplayName)
		}

	elseif action == "GiveLuck" then
		local luckMult = math.max(1, numVal)
		targetPlayer:SetAttribute("PersonalLuckMultiplier", luckMult)

		-- 30 menit durasi boost
		task.spawn(function()
			task.wait(1800)
			if targetPlayer and targetPlayer.Parent then
				targetPlayer:SetAttribute("PersonalLuckMultiplier", nil)
				ShowNotification:FireClient(
					targetPlayer,
					"🍀 Durasi Personal Luck Boost dari Admin telah berakhir.",
					4,
					Color3.fromRGB(200, 200, 200)
				)
			end
		end)

		-- Notifikasi ke target
		ShowNotification:FireClient(
			targetPlayer,
			string.format("🍀 Admin %s memberimu Personal Luck Boost %dx selama 30 Menit!", player.DisplayName, luckMult),
			5,
			Color3.fromRGB(255, 230, 80)
		)

		-- Notifikasi ke Admin
		ShowNotification:FireClient(
			player,
			string.format("✓ Berhasil memberi Luck Boost %dx ke %s (30m)!", luckMult, targetPlayer.DisplayName),
			3,
			Color3.fromRGB(100, 220, 255)
		)

		return {
			success = true,
			message = string.format("Berhasil memberi Luck Boost %dx ke %s!", luckMult, targetPlayer.DisplayName)
		}
	end

	return { success = false, message = "Aksi tidak dikenali" }
end

print("✅ [AdminLuck] AdminPlayerAction listener fully connected!")
