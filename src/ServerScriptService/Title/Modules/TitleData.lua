--!nonstrict
-- ============================================================
-- Title/Modules/TitleData (ModuleScript)
-- Builds the GetTitleData payload (quota, slots, unlock maps).
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Runtime = require(script.Parent.Runtime)
local PlayerStats = require(script.Parent.PlayerStats)
local Unlocks = require(script.Parent.Unlocks)

local ImageTitleConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("TitleConfig"))
local RoleConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("RoleConfig"))

local TitleData = {}

function TitleData.Get(player)
	local waited = 0
	while not Runtime.getProfile(player) and waited < 10 do
		task.wait(0.5)
		waited += 0.5
	end

	local profile = Runtime.getProfile(player)
	local summit = PlayerStats.getSummit(player)
	local fishCount = PlayerStats.getFishCount(player)
	local hasVip = PlayerStats.getVip(player)
	local isAdmin = RoleConfig.IsAdmin(player)

	local quota = profile and PlayerStats.getQuota(profile) or { count = 0, resetTime = os.time() + 86400 }
	local remaining = math.max(0, 2 - (quota.count or 0))
	local cooldown = math.max(0, (quota.resetTime or 0) - os.time())

	local slots = {}
	if profile and profile.Data and profile.Data.customTitles then
		for i = 1, 6 do
			local item = profile.Data.customTitles[i]
			if item then
				slots[i] = item
			end
		end
	end

	local imageUnlockStatus = {}
	for _, img in ipairs(ImageTitleConfig.ImageTitles) do
		imageUnlockStatus[img.Id] = Unlocks.checkImage(player, img, summit, fishCount, hasVip) or isAdmin
	end

	local slotUnlockStatus = {}
	for i = 1, 6 do
		local isUnlocked, reason = Unlocks.checkSlot(player, i, summit, fishCount)
		slotUnlockStatus[i] = {
			Unlocked = isUnlocked or isAdmin,
			Reason = reason,
		}
	end

	return {
		Success = true,
		Summit = summit,
		FishCount = fishCount,
		HasVip = hasVip,
		IsAdmin = isAdmin,
		ActiveSlot = profile and profile.Data and profile.Data.activeSlot or 1,
		Slots = slots,
		Quota = {
			Remaining = remaining,
			Total = 2,
			ResetTime = quota.resetTime,
			CooldownSeconds = cooldown,
		},
		ImageUnlocks = imageUnlockStatus,
		SlotUnlocks = slotUnlockStatus,
	}
end

return TitleData
