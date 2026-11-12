-- Luck boost lifecycle: multiplier/timer values, chat announcement, countdown.
local Config = require(script.Parent.AdminLuckConfig)
local Values = require(script.Parent.AdminLuckValues)
local Effects = require(script.Parent.AdminLuckEffects)

local Boost = {}

local currentBoostTask = nil

function Boost.stop()
	if currentBoostTask then
		task.cancel(currentBoostTask)
		currentBoostTask = nil
	end
end

function Boost.resetValues()
	if Values.LuckValue then Values.LuckValue.Value = 1 end
	if Values.MutationValue then Values.MutationValue.Value = 1 end
	if Values.TimerValue then Values.TimerValue.Value = 0 end
	if Values.ActiveEventName then Values.ActiveEventName.Value = "" end
end

function Boost.execute(multiplier, duration, isGlobal, adminName, senderServerId)
	local isLocalExecution = not senderServerId or senderServerId == Config.SERVER_ID

	Boost.stop()

	currentBoostTask = task.spawn(function()
		if Values.LuckValue then Values.LuckValue.Value = multiplier end
		if Values.TimerValue then Values.TimerValue.Value = duration end

		if isLocalExecution then
			Effects.playIntro()
		end

		local scopeText = isGlobal and "GLOBAL" or "SERVER"
		local chatChannel = isGlobal and "Global" or "General"
		local chatRarity = "Uncommon"

		local chatFishName = string.format("Owner %s mengaktifkan %s Booster Luck x%d selama %s",
			adminName,
			scopeText,
			multiplier,
			Config.formatTime(duration)
		)

		print("🚀 [AdminLuck] BOOST AKTIF: " .. chatFishName)

		-- Kirim Chat log ke pemain tanpa double pop-up bar di atas
		if isLocalExecution then
			pcall(function()
				Values.SendChatMessage:FireAllClients(chatChannel, "SYSTEM", chatFishName, 0, chatRarity)
			end)
		end

		-- Countdown Timer Loop (Berjalan di background sesuai durasi)
		local timeLeft = duration
		while timeLeft > 0 do
			task.wait(1)
			timeLeft = timeLeft - 1
			if Values.TimerValue then Values.TimerValue.Value = timeLeft end
		end

		-- Selesai waktu event
		Boost.resetValues()

		Values.ShowNotification:FireAllClients("Event Luck & Mutasi Telah Berakhir.", 4, Color3.fromRGB(200, 200, 200))
		print("🏁 [AdminLuck] Boost Selesai.")
	end)
end

return Boost
