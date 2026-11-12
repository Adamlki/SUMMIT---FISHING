-- Coin balance methods. profile.Data.Coins is the single source of truth.
local Coins = {}

local function syncCoins(player, value)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then coins.Value = value end
	end
	player:SetAttribute("Coins", value)
end

function Coins:AddCoins(player, amount)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	profile.Data.Coins = math.max(0, (profile.Data.Coins or 0) + amount)
	syncCoins(player, profile.Data.Coins)
	return true
end

function Coins:SetCoins(player, amount)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	profile.Data.Coins = math.max(0, amount)
	syncCoins(player, profile.Data.Coins)
	return true
end

function Coins:TryPurchase(player, cost)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false, 0 end

	local currentCoins = profile.Data.Coins or 0
	if currentCoins < cost then return false, currentCoins end

	profile.Data.Coins = currentCoins - cost
	syncCoins(player, profile.Data.Coins)
	return true, profile.Data.Coins
end

function Coins:GetCoins(player)
	local profile = self:GetProfile(player)
	if not profile then return 0 end
	return profile.Data.Coins or 0
end

function Coins:SavePlayerData(player)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins and typeof(coins.Value) == "number" then
			if coins.Value > 0 then
				profile.Data.Coins = coins.Value
			elseif (profile.Data.Coins or 0) > 0 then
				-- Restore view from authoritative profile data if leaderstats was corrupted/zeroed
				coins.Value = profile.Data.Coins
			end
		end
	end

	return true
end

return Coins
