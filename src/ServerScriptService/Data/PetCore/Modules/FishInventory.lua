-- Saved fish inventory, favourites, catch index and catch totals.
local HttpService = game:GetService("HttpService")

local FishInventory = {}

function FishInventory:GetFishInventoryLimit(player)
	local profile = self:GetProfile(player)
	if not profile then return 500 end
	return profile.Data.FishInventoryLimit or 500
end

function FishInventory:AddFish(player, fishData)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false, nil end

	if not profile.Data.SavedFish then profile.Data.SavedFish = {} end

	local limit = profile.Data.FishInventoryLimit or 500
	if #profile.Data.SavedFish >= limit then
		return false, nil
	end

	local uniqueId = HttpService:GenerateGUID(false)
	local fishEntry = {
		name = fishData.name,
		weight = fishData.weight,
		rarity = fishData.rarity or "Common",
		uniqueId = uniqueId,
		timestamp = tick(),
		isFavorited = false
	}

	table.insert(profile.Data.SavedFish, fishEntry)

	return true, uniqueId
end

-- Insert an existing entry without changing its uniqueId (transfers must preserve identity).
function FishInventory:AddExistingFish(player, fishEntry)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false, nil end
	if type(fishEntry) ~= "table" or type(fishEntry.uniqueId) ~= "string" or fishEntry.uniqueId == "" then
		return false, nil
	end
	if type(fishEntry.name) ~= "string" or type(fishEntry.weight) ~= "number" then
		return false, nil
	end

	if not profile.Data.SavedFish then profile.Data.SavedFish = {} end

	local limit = profile.Data.FishInventoryLimit or 500
	if #profile.Data.SavedFish >= limit then
		return false, nil
	end

	for _, fish in ipairs(profile.Data.SavedFish) do
		if fish.uniqueId == fishEntry.uniqueId then
			return false, nil
		end
	end

	table.insert(profile.Data.SavedFish, {
		name = fishEntry.name,
		weight = fishEntry.weight,
		rarity = fishEntry.rarity or "Common",
		uniqueId = fishEntry.uniqueId,
		timestamp = type(fishEntry.timestamp) == "number" and fishEntry.timestamp or tick(),
		isFavorited = fishEntry.isFavorited == true
	})

	return true, fishEntry.uniqueId
end

function FishInventory:RemoveFish(player, fishUniqueId)
	local profile = self:GetProfile(player)
	if not profile or not profile.Data.SavedFish then return false, nil end

	for i, fish in ipairs(profile.Data.SavedFish) do
		if fish.uniqueId == fishUniqueId then
			-- Favorited fish cannot be deleted or sold.
			if fish.isFavorited == true then
				return false, nil
			end
			local removed = table.remove(profile.Data.SavedFish, i)
			return true, removed
		end
	end

	return false, nil
end

function FishInventory:RemoveFishBatch(player, idSet)
	local profile = self:GetProfile(player)
	if not profile or not profile.Data.SavedFish then return 0 end

	local kept = {}
	local removed = {}
	for _, fish in ipairs(profile.Data.SavedFish) do
		if idSet[fish.uniqueId] and fish.isFavorited ~= true then
			table.insert(removed, fish)
		else
			table.insert(kept, fish)
		end
	end
	profile.Data.SavedFish = kept
	return #removed, removed
end

function FishInventory:GetSavedFish(player)
	local profile = self:GetProfile(player)
	if not profile then return {} end
	return profile.Data.SavedFish or {}
end

function FishInventory:ToggleFavoriteFish(player, fishUniqueId)
	local profile = self:GetProfile(player)
	if not profile or not profile.Data.SavedFish then return nil end

	for _, fish in ipairs(profile.Data.SavedFish) do
		if fish.uniqueId == fishUniqueId then
			fish.isFavorited = not fish.isFavorited
			return fish.isFavorited
		end
	end

	return nil
end

function FishInventory:GetFishIndex(player)
	local profile = self:GetProfile(player)
	if not profile then return {} end
	if type(profile.Data.FishIndex) ~= "table" then
		profile.Data.FishIndex = {}
	end
	return profile.Data.FishIndex
end

function FishInventory:GetTotalFishCaught(player)
	local profile = self:GetProfile(player)
	if not profile then return 0 end
	return profile.Data.TotalFishCaught or 0
end

function FishInventory:RecordFishCatch(player, fishName)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return 0, 0 end

	profile.Data.TotalFishCaught = (profile.Data.TotalFishCaught or 0) + 1
	if type(profile.Data.FishIndex) ~= "table" then
		profile.Data.FishIndex = {}
	end
	profile.Data.FishIndex[fishName] = (profile.Data.FishIndex[fishName] or 0) + 1

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local catch = leaderstats:FindFirstChild("Tangkapan")
		if catch then
			catch.Value = profile.Data.TotalFishCaught
		end
	end

	return profile.Data.TotalFishCaught, profile.Data.FishIndex[fishName]
end

return FishInventory
