-- Owned and equipped trails.
local Trails = {}

function Trails:GetOwnedTrails(player)
	local profile = self:GetProfile(player)
	if not profile then return {} end
	if not profile.Data.OwnedTrails then
		profile.Data.OwnedTrails = {}
	end
	return profile.Data.OwnedTrails
end

function Trails:HasTrail(player, trailId)
	local owned = self:GetOwnedTrails(player)
	for _, id in ipairs(owned) do
		if id == trailId then return true end
	end
	return false
end

function Trails:AddTrail(player, trailId)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end
	if not profile.Data.OwnedTrails then
		profile.Data.OwnedTrails = {}
	end
	for _, id in ipairs(profile.Data.OwnedTrails) do
		if id == trailId then return true end
	end
	table.insert(profile.Data.OwnedTrails, trailId)
	return true
end

function Trails:GetEquippedTrail(player)
	local profile = self:GetProfile(player)
	if not profile then return "" end
	return profile.Data.EquippedTrail or ""
end

function Trails:SetEquippedTrail(player, trailId)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end
	profile.Data.EquippedTrail = trailId
	return true
end

return Trails
