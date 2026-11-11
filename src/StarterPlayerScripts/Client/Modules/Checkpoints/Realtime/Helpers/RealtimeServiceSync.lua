--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Shared.Packages.Knit)

local RealtimeServiceSync = {}

local serviceReady = false
local playerListService = nil

function RealtimeServiceSync.getService()
	if serviceReady then
		return playerListService
	end
	serviceReady = true
	local ok, svc = pcall(function()
		return Knit.GetService("PlayerListService")
	end)
	if ok then
		playerListService = svc
	end
	return playerListService
end

function RealtimeServiceSync.bindStatsUpdated(entry, janitor, service)
	if service and service.StatsUpdated then
		janitor:Add(service.StatsUpdated:Connect(function(userId, stats)
			if userId == entry.player.UserId and stats then
				local dataFrame = entry.frame:FindFirstChild("Data")
				local bestTimeLbl = dataFrame and dataFrame:FindFirstChild("BestTime")
				if bestTimeLbl then
					bestTimeLbl.Text = "⏱️ " .. tostring(stats.BestTime or "00:00")
				end
			end
		end), "Disconnect")
	end
end

function RealtimeServiceSync.applySnapshot(entry, service)
	if not (service and service.GetSnapshot) then
		return
	end
	local ok, result = pcall(function()
		return service:GetSnapshot()
	end)
	local function applyStats(stats)
		if stats then
			local dataFrame = entry.frame:FindFirstChild("Data")
			local bestTimeLbl = dataFrame and dataFrame:FindFirstChild("BestTime")
			if bestTimeLbl then
				bestTimeLbl.Text = "⏱️ " .. tostring(stats.BestTime or "00:00")
			end
		end
	end
	if ok and result and type(result.andThen) == "function" then
		result:andThen(function(snapshot)
			applyStats(snapshot and snapshot[tostring(entry.player.UserId)])
		end)
	elseif ok and type(result) == "table" then
		applyStats(result[tostring(entry.player.UserId)])
	end
end

return RealtimeServiceSync
