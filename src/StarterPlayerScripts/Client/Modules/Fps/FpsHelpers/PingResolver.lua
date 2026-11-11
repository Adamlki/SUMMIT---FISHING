--!nonstrict
local Stats = game:GetService("Stats")

local PingResolver = {}

local function resolvePingItem(serverStats)
	if not serverStats then
		return nil
	end
	local pingItem = serverStats:FindFirstChild("Network Ping")
		or serverStats:FindFirstChild("Avg Data Ping")
		or serverStats:FindFirstChild("Avg Data Ping ms")
		or serverStats:FindFirstChild("Data Ping")
		or serverStats:FindFirstChild("Ping")
	if pingItem then
		return pingItem
	end
	for _, child in ipairs(serverStats:GetChildren()) do
		if child.Name:lower():find("ping") then
			return child
		end
	end
	return nil
end

local function findPingAnywhere(root)
	if not root then
		return nil
	end
	for _, child in ipairs(root:GetDescendants()) do
		if child.Name:lower():find("ping") and (child.GetValue or child.GetValueString) then
			return child
		end
	end
	return nil
end

function PingResolver.ensure(runtime)
	if runtime._pingItem and runtime._pingItem.Parent then
		return
	end
	if runtime._pingResolverRunning then
		return
	end
	runtime._pingResolverRunning = true
	task.spawn(function()
		local network = Stats:FindFirstChild("Network") or Stats:WaitForChild("Network", 10)
		local serverStats = network and (network:FindFirstChild("ServerStatsItem") or network:WaitForChild("ServerStatsItem", 10))
		runtime._pingItem = resolvePingItem(serverStats)
		if not runtime._pingItem then
			runtime._pingItem = findPingAnywhere(Stats)
		end
		runtime._pingResolverRunning = false
	end)
end

function PingResolver.getMs(pingItem)
	if not pingItem then
		return nil
	end
	if pingItem.GetValue then
		local ok, value = pcall(function()
			return pingItem:GetValue()
		end)
		if ok and type(value) == "number" then
			return value
		end
	end
	if pingItem.GetValueString then
		local ok, value = pcall(function()
			return pingItem:GetValueString()
		end)
		if ok and type(value) == "string" then
			local num = tonumber(value:match("([%d%.]+)"))
			if num then
				return num
			end
		end
	end
	return nil
end

return PingResolver
