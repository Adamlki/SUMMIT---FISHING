--!nonstrict
-- ============================================================
-- Title/Modules/Unlocks (ModuleScript)
-- Slot-row and image title unlock checks.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ImageTitleConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("TitleConfig"))

local Unlocks = {}

function Unlocks.checkSlot(player, slot, summit, fishCount)
	local slotReq = ImageTitleConfig.SlotMilestones[slot]
	if not slotReq then return true, "" end

	if slotReq.UnlockType == "Summit" then
		local req = slotReq.ReqSummit or 0
		if summit < req then
			return false, string.format("Butuh %s (Saat ini: %d Summit)", slotReq.Label, summit)
		end
	elseif slotReq.UnlockType == "FishCount" then
		local req = slotReq.ReqFishCount or 0
		if fishCount < req then
			return false, string.format("Butuh %s (Saat ini: %d Mancing)", slotReq.Label, fishCount)
		end
	elseif slotReq.UnlockType == "Group" then
		local ok, inGroup = pcall(function()
			return player:IsInGroup(slotReq.GroupId or 352750447)
		end)
		if not (ok and inGroup) then
			return false, slotReq.Reason or "Wajib Join Komunitas Roblox & Like Map"
		end
	end
	return true, ""
end

function Unlocks.checkImage(player, entry, summit, fishCount, hasVip)
	if entry.UnlockType == "Group" then
		local ok, inGroup = pcall(function()
			return player:IsInGroup(entry.GroupId or 352750447)
		end)
		return ok and inGroup == true
	elseif entry.UnlockType == "Summit" then
		return summit >= (entry.ReqSummit or 0)
	elseif entry.UnlockType == "FishIndex" or entry.UnlockType == "FishCount" then
		return fishCount >= (entry.ReqFishCount or 0)
	elseif entry.UnlockType == "VIP" then
		return hasVip == true
	elseif entry.UnlockType == "Free" then
		return true
	end
	return false
end

return Unlocks
