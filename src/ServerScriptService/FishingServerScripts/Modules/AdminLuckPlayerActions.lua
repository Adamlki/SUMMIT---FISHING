-- Target-ed player actions (GiveCoins / GiveLuck) via the AdminPlayerAction RemoteFunction.
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(script.Parent.AdminLuckConfig)
local Values = require(script.Parent.AdminLuckValues)

local PlayerActions = {}

local GameProfileService

local function formatNumber(n)
	local str = tostring(math.floor(tonumber(n) or 0))
	return string.reverse(string.gsub(string.reverse(str), "(%d%d%d)", "%1,")):gsub("^,", "")
end

local function giveCoins(player, targetPlayer, numVal)
	GameProfileService:AddCoins(targetPlayer, numVal)

	-- Notifikasi ke target
	Values.ShowNotification:FireClient(
		targetPlayer,
		string.format("💰 Kamu menerima +%s Koin dari Admin %s!", formatNumber(numVal), player.DisplayName),
		4,
		Color3.fromRGB(80, 255, 120)
	)

	-- Notifikasi ke Admin
	Values.ShowNotification:FireClient(
		player,
		string.format("✓ Berhasil mengirim %s Koin ke %s!", formatNumber(numVal), targetPlayer.DisplayName),
		3,
		Color3.fromRGB(100, 220, 255)
	)

	return {
		success = true,
		message = string.format("Berhasil mengirim %s Koin ke %s!", formatNumber(numVal), targetPlayer.DisplayName)
	}
end

local function giveLuck(player, targetPlayer, numVal)
	local luckMult = math.max(1, numVal)
	targetPlayer:SetAttribute("PersonalLuckMultiplier", luckMult)

	-- 30 menit durasi boost
	task.spawn(function()
		task.wait(1800)
		if targetPlayer and targetPlayer.Parent then
			targetPlayer:SetAttribute("PersonalLuckMultiplier", nil)
			Values.ShowNotification:FireClient(
				targetPlayer,
				"🍀 Durasi Personal Luck Boost dari Admin telah berakhir.",
				4,
				Color3.fromRGB(200, 200, 200)
			)
		end
	end)

	-- Notifikasi ke target
	Values.ShowNotification:FireClient(
		targetPlayer,
		string.format("🍀 Admin %s memberimu Personal Luck Boost %dx selama 30 Menit!", player.DisplayName, luckMult),
		5,
		Color3.fromRGB(255, 230, 80)
	)

	-- Notifikasi ke Admin
	Values.ShowNotification:FireClient(
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

function PlayerActions.Start()
	GameProfileService = require(ServerScriptService.Data.PetCore:WaitForChild("FishData"))
	local AdminPlayerAction = Values.FishingSystem:WaitForChild("AdminPlayerAction") :: RemoteFunction

	AdminPlayerAction.OnServerInvoke = function(player, action, targetUserId, amount)
		-- 1. Validasi otorisasi Admin
		if not Config.isPlayerAuthorized(player) then
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

			return giveCoins(player, targetPlayer, numVal)

		elseif action == "GiveLuck" then
			return giveLuck(player, targetPlayer, numVal)
		end

		return { success = false, message = "Aksi tidak dikenali" }
	end

	print("✅ [AdminLuck] AdminPlayerAction listener fully connected!")
end

return PlayerActions
