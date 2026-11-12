--!nonstrict
-- ==============================================================================
-- Config.lua
-- Data & aturan statis TitleMenu: draft slot, definisi mode warna, unlock slot.
-- ==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ImageTitleConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("TitleConfig"))
local Effects = require(script.Parent.Parent:WaitForChild("Effects"))

local Config = {}

function Config.encodeColors(colors)
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

function Config.formatCooldown(seconds)
	if seconds <= 0 then return "0s" end
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = math.floor(seconds % 60)
	if h > 0 then
		return string.format("%d jam %d mnt", h, m)
	elseif m > 0 then
		return string.format("%d mnt %d dtk", m, s)
	else
		return string.format("%d dtk", s)
	end
end

-- Draft baru untuk satu slot. Slot 1-3 Text, Slot 4-6 Image.
function Config.newDraft(isText)
	return {
		titleType = isText and "Text" or "Image",
		text = "",
		mode = "Rainbow Flow",
		colors = Effects.getPalette("Rainbow Flow"),
		imageId = nil,
		imageKey = nil,
	}
end

function Config.newDrafts()
	local drafts = {}
	for i = 1, 6 do
		drafts[i] = Config.newDraft(i <= 3)
	end
	return drafts
end

function Config.buildColorDefs()
	return {
		Col_Purple = { Name = "Cosmic",  Mode = "Cosmic Spin",  Desc = "Putaran Galaksi Kosmik", Colors = Effects.getPalette("Cosmic Spin"), Icon = "🌌" },
		Col_Orange = { Name = "Sunset",  Mode = "Sunset Flare", Desc = "Aliran Kobaran Senja",    Colors = Effects.getPalette("Sunset Flare"), Icon = "🔥" },
		Col_Blue   = { Name = "Ocean",   Mode = "Ocean Wave",   Desc = "Gelombang Ombak Samudra",Colors = Effects.getPalette("Ocean Wave"), Icon = "🌊" },
		Col_Green  = { Name = "Aurora",  Mode = "Aurora Drift", Desc = "Cahaya Kutub Diagonal",  Colors = Effects.getPalette("Aurora Drift"), Icon = "🌿" },
		Col_Gold   = { Name = "Gold",    Mode = "Royal Gold",   Desc = "Kilau Emas & Perunggu",  Colors = Effects.getPalette("Royal Gold"), Icon = "👑" },
		Col_Pink   = { Name = "Rainbow", Mode = "Rainbow Flow", Desc = "Spektrum Pelangi Penuh", Colors = Effects.getPalette("Rainbow Flow"), Icon = "✨" },
	}
end

-- Pengecekan status unlock slot (server data dulu, fallback milestone lokal).
function Config.isSlotUnlocked(ctx, slotNum)
	local serverData = ctx.state.serverData
	local localPlayer = ctx.localPlayer

	if serverData and serverData.IsAdmin then
		return true, ""
	end
	if serverData and serverData.SlotUnlocks and serverData.SlotUnlocks[slotNum] then
		return serverData.SlotUnlocks[slotNum].Unlocked, serverData.SlotUnlocks[slotNum].Reason or ""
	end

	local req = ImageTitleConfig.SlotMilestones[slotNum]
	if not req then return true, "" end

	local currentSummit = serverData and serverData.Summit or 0
	local currentFish = serverData and serverData.FishCount or 0

	if req.UnlockType == "Summit" then
		if currentSummit < (req.ReqSummit or 0) then
			return false, string.format("Butuh %s (Saat ini: %d Summit)", req.Label, currentSummit)
		end
	elseif req.UnlockType == "FishCount" then
		if currentFish < (req.ReqFishCount or 0) then
			return false, string.format("Butuh %s (Saat ini: %d Mancing)", req.Label, currentFish)
		end
	elseif req.UnlockType == "Group" then
		local inGroup = localPlayer and localPlayer:IsInGroup(req.GroupId or 352750447)
		if not inGroup then
			return false, req.Reason or "Wajib Join Komunitas Roblox & Like Map"
		end
	end
	return true, ""
end

return Config
