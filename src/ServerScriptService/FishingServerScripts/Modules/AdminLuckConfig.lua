-- Admin config, authorization and small formatting helpers for AdminLuckManager.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local RoleConfig = require(ReplicatedStorage:WaitForChild("RoleConfig"))
local AdminPrivateConfig = require(ServerScriptService:WaitForChild("Configs"):WaitForChild("AdminPrivateConfig"))

local Config = {}

Config.GLOBAL_TOPIC = AdminPrivateConfig.GlobalLuckTopic

-- GENERATE SERVER ID UNIK
Config.SERVER_ID = game.JobId
if Config.SERVER_ID == "" then
	Config.SERVER_ID = "Studio_" .. tostring(HttpService:GenerateGUID(false))
end

function Config.isPlayerAuthorized(player)
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

	-- 4. Cek Group Rank jika Group Game
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

function Config.getPlayerDisplayName(player)
	return player and player.DisplayName or (player and player.Name) or "Admin"
end

function Config.formatTime(seconds)
	if seconds >= 60 then
		return string.format("%d menit", math.floor(seconds / 60))
	else
		return string.format("%d detik", seconds)
	end
end

return Config
