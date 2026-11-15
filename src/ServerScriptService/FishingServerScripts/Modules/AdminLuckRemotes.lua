-- Global MessagingService topic + admin panel RemoteEvent wiring.
local MessagingService = game:GetService("MessagingService")

local Config = require(script.Parent.AdminLuckConfig)
local Values = require(script.Parent.AdminLuckValues)
local Effects = require(script.Parent.AdminLuckEffects)
local Boost = require(script.Parent.AdminLuckBoost)

local Remotes = {}

local function onTriggerAdminEvent(player, data)
	print("⚡ [AdminLuck] Received event request from:", player.Name, "Action:", data and data.action)

	if not Config.isPlayerAuthorized(player) then
		warn("⛔ UNAUTHORIZED: " .. player.Name .. " mencoba memicu Admin Event!")
		Values.ShowNotification:FireClient(player, "⛔ Akses Ditolak: Anda bukan Admin!", 4, Color3.fromRGB(255, 50, 50))
		return
	end

	if data.action == "STOP" then
		Boost.stop()
		Boost.resetValues()

		Effects.clearSkyAndSound()
		Effects.restoreLuckyInWorkspace()

		Values.ShowNotification:FireAllClients("Event dihentikan oleh Admin " .. player.DisplayName, 4, Color3.fromRGB(255, 100, 100))
		return
	end

	-- AKTIFKAN EVENT
	local eventName = data.eventName or "Secret Event"
	local luck = tonumber(data.luck) or 30
	local mutation = tonumber(data.mutation) or 7
	local durationMin = tonumber(data.durationMinutes) or 30
	local durationSec = durationMin * 60
	local isGlobal = (data.scope == "Global")

	if Values.ActiveEventName then Values.ActiveEventName.Value = eventName end
	if Values.MutationValue then Values.MutationValue.Value = mutation end

	print(string.format("🌟 [AdminLuck] Memulai Event '%s' (Luck x%d, Mutasi x%d, %d Menit, Scope: %s)",
		eventName, luck, mutation, durationMin, data.scope or "Global"))

	-- 1. Broadcast Animasi Sinematik Banner ke SEMUA client (tanpa double notifikasi)
	Values.AdminEventActivated:FireAllClients({
		title = eventName,
		admin = player.DisplayName,
		durationMinutes = durationMin,
		luck = luck,
		mutation = mutation
	})

	-- 2. Jika Global, publish via MessagingService
	if isGlobal then
		pcall(function()
			MessagingService:PublishAsync(Config.GLOBAL_TOPIC, {
				m = luck,
				d = durationSec,
				a = player.DisplayName,
				s = Config.SERVER_ID,
				mut = mutation,
				event = eventName
			})
		end)
	end

	-- 3. Jalankan boost logic utama di server ini (efek visual 5.5s, boost aktif durationSec)
	Boost.execute(luck, durationSec, isGlobal, player.DisplayName)
end

local function onGlobalMessage(msg)
	local d = msg.Data
	if d and d.s ~= Config.SERVER_ID then
		if d.mut and Values.MutationValue then Values.MutationValue.Value = d.mut end
		if d.event and Values.ActiveEventName then Values.ActiveEventName.Value = d.event end

		Values.AdminEventActivated:FireAllClients({
			title = d.event or "Secret Event",
			admin = d.a or "Admin",
			durationMinutes = math.floor((d.d or 1800) / 60),
			luck = d.m or 30,
			mutation = d.mut or 7
		})

		Boost.execute(d.m, d.d, true, d.a, d.s)
	end
end

function Remotes.Start()
	-- Subscribe Global Topic
	pcall(function()
		MessagingService:SubscribeAsync(Config.GLOBAL_TOPIC, onGlobalMessage)
	end)

	Values.TriggerAdminEvent.OnServerEvent:Connect(onTriggerAdminEvent)

	print("✅ [AdminLuck] TriggerAdminEvent Remote Listener fully connected!")
end

return Remotes
