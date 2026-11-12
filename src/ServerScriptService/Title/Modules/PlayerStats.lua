--!nonstrict
-- ============================================================
-- Title/Modules/PlayerStats (ModuleScript)
-- Summit / fish count / VIP reads, title quota and text helpers.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local MarketplaceService = game:GetService("MarketplaceService")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local MonetizationConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("MonetizationConfig"))

local PlayerStats = {}

function PlayerStats.getSummit(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local summit = leaderstats and leaderstats:FindFirstChild("Summit")
	if summit and summit:IsA("IntValue") then
		return summit.Value
	end
	return 0
end

function PlayerStats.getFishCount(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local tangkapan = leaderstats and leaderstats:FindFirstChild("Tangkapan")
	if tangkapan and tangkapan:IsA("IntValue") then
		return tangkapan.Value
	end
	local bindable = FishingSystem:FindFirstChild("GetFishIndexBindable")
	if bindable then
		local ok, data = pcall(function()
			return bindable:Invoke(player)
		end)
		if ok and type(data) == "table" then
			local count = 0
			for _ in pairs(data) do
				count += 1
			end
			return count
		end
	end
	return 0
end

function PlayerStats.getVip(player)
	if player:GetAttribute("VIP") == true then
		return true
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, MonetizationConfig.VIP.GamePassId)
	end)
	return ok and owns == true
end

function PlayerStats.getQuota(profile)
	local now = os.time()
	profile.Data.titleQuota = profile.Data.titleQuota or {}
	local quota = profile.Data.titleQuota
	if not quota.resetTime or now >= quota.resetTime then
		quota.count = 0
		quota.resetTime = now + 86400
	end
	return quota
end

function PlayerStats.filterText(player, text)
	if not text or text == "" then return "" end
	local ok, res = pcall(function()
		local obj = TextService:FilterStringAsync(text, player.UserId)
		return obj:GetNonChatStringForBroadcastAsync()
	end)
	if ok and res then
		return res
	end
	return ""
end

function PlayerStats.encodeColors(colors)
	if not colors or #colors == 0 then return "" end
	local parts = {}
	for _, c in ipairs(colors) do
		local r = math.round(c.R * 255)
		local g = math.round(c.G * 255)
		local b = math.round(c.B * 255)
		table.insert(parts, string.format("%d,%d,%d", r, g, b))
	end
	return table.concat(parts, ";")
end

function PlayerStats.sanitizeColor(c)
	if typeof(c) == "Color3" then
		return c
	elseif typeof(c) == "table" then
		local r = c.r or c.R or c[1] or 255
		local g = c.g or c.G or c[2] or 255
		local b = c.b or c.B or c[3] or 255
		if r <= 1 and g <= 1 and b <= 1 and (r > 0 or g > 0 or b > 0) then
			return Color3.new(r, g, b)
		end
		return Color3.fromRGB(math.clamp(r, 0, 255), math.clamp(g, 0, 255), math.clamp(b, 0, 255))
	end
	return Color3.fromRGB(255, 255, 255)
end

return PlayerStats
