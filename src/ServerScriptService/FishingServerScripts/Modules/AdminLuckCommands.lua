-- Chat command parsing (/luck, /unluck) for the luck system.
local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local TextChatService = game:GetService("TextChatService")

local Config = require(script.Parent.AdminLuckConfig)
local Values = require(script.Parent.AdminLuckValues)
local Effects = require(script.Parent.AdminLuckEffects)
local Boost = require(script.Parent.AdminLuckBoost)

local Commands = {}

function Commands.processCommand(player, text)
	text = string.gsub(text, "^%s*(.-)%s*$", "%1")

	local prefix = string.sub(text, 1, 1)
	local commandBody = string.sub(text, 2)
	local args = string.split(commandBody, " ")
	local cmd = string.lower(args[1] or "")

	if prefix ~= "/" and prefix ~= ":" and prefix ~= "!" then return end

	if cmd == "luck" then
		if not Config.isPlayerAuthorized(player) then
			warn("⛔ SECURITY ALERT: " .. player.Name .. " mencoba pakai command admin!")
			Values.ShowNotification:FireClient(player, "⛔ Anda bukan Admin!", 3, Color3.fromRGB(255, 50, 50))
			return
		end

		local adminName = Config.getPlayerDisplayName(player)
		local scope = string.lower(args[2] or "server")
		local mult = tonumber(args[3]) or 30
		local minutes = tonumber(args[4]) or 30
		local duration = minutes * 60

		if scope == "server" then
			Boost.execute(mult, duration, false, adminName)
		elseif scope == "global" then
			pcall(function()
				MessagingService:PublishAsync(Config.GLOBAL_TOPIC, {m=mult, d=duration, a=adminName, s=Config.SERVER_ID, mut=1, event="Mega Luck"})
			end)
			Boost.execute(mult, duration, true, adminName, Config.SERVER_ID)
		end

	elseif cmd == "unluck" then
		if Config.isPlayerAuthorized(player) then
			Boost.stop()
			Boost.resetValues()

			Effects.clearSkyAndSound()

			Values.ShowNotification:FireAllClients("🚫 Boost dibatalkan Admin.", 4, Color3.fromRGB(255, 100, 100))

			Effects.restoreLuckyFromStorage()
		end
	end
end

function Commands.Start()
	Players.PlayerAdded:Connect(function(player)
		print("👤 LOGIN: " .. player.Name .. " | ID: " .. player.UserId)
		player.Chatted:Connect(function(msg)
			Commands.processCommand(player, msg)
		end)
	end)

	if TextChatService:FindFirstChild("TextChannels") then
		local general = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
		if general then
			general.ShouldDeliverCallback = function(message, source)
				Commands.processCommand(Players:GetPlayerByUserId(source.UserId), message.Text)
				return true
			end
		end
	end
end

return Commands
