-- Rod ownership and equipped-rod persistence.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RoleConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("RoleConfig"))

local Rods = {}

function Rods:AddRod(player, rodName)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	if not profile.Data.OwnedRods then profile.Data.OwnedRods = {} end

	for _, r in ipairs(profile.Data.OwnedRods) do
		if r == rodName then return true end
	end

	table.insert(profile.Data.OwnedRods, rodName)
	return true
end

function Rods:HasRod(player, rodName)
	if rodName == "Basic Rod" then return true end
	if RoleConfig and RoleConfig.IsOwner(player) then return true end
	local profile = self:GetProfile(player)
	if not profile or not profile.Data.OwnedRods then return false end

	for _, r in ipairs(profile.Data.OwnedRods) do
		if r == rodName then return true end
	end

	return false
end

function Rods:GetOwnedRods(player)
	if RoleConfig and RoleConfig.IsOwner(player) then
		local rods = {}
		local allRods = ServerStorage:FindFirstChild("AllRods")
		if allRods then
			for _, r in ipairs(allRods:GetChildren()) do
				table.insert(rods, r.Name)
			end
		end
		if not table.find(rods, "Basic Rod") then table.insert(rods, "Basic Rod") end
		return rods
	end
	local profile = self:GetProfile(player)
	if not profile then return {"Basic Rod"} end
	local list = profile.Data.OwnedRods or {}
	if not table.find(list, "Basic Rod") then
		table.insert(list, "Basic Rod")
	end
	return list
end

function Rods:SetLastEquippedRod(player, rodName)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	profile.Data.LastEquippedRod = rodName
	return true
end

function Rods:GetLastEquippedRod(player)
	local profile = self:GetProfile(player)
	if not profile then return nil end
	return profile.Data.LastEquippedRod
end

return Rods
