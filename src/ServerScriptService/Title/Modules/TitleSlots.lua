--!nonstrict
-- ============================================================
-- Title/Modules/TitleSlots (ModuleScript)
-- Equip/clear custom title slots in the profile and player attributes.
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Runtime = require(script.Parent.Runtime)
local PlayerStats = require(script.Parent.PlayerStats)
local Unlocks = require(script.Parent.Unlocks)

local ImageTitleConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("TitleConfig"))
local RoleConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("RoleConfig"))

local TitleSlots = {}

function TitleSlots.Set(player, slot, titleType, payload, targetUserId)
	slot = tonumber(slot)
	if not slot or slot < 1 or slot > 6 then
		return { Success = false, Message = "Slot title tidak valid (1-6)!" }
	end

	-- Validasi: Slot 1-3 khusus Text, Slot 4-6 khusus Image
	if slot >= 1 and slot <= 3 then
		if titleType ~= "Text" then
			return { Success = false, Message = "Slot 1–3 khusus untuk Title Teks!" }
		end
	elseif slot >= 4 and slot <= 6 then
		if titleType ~= "Image" then
			return { Success = false, Message = "Slot 4–6 khusus untuk Title Gambar!" }
		end
	end

	local isCallerAdmin = RoleConfig.IsAdmin(player)
	local targetPlayer = player
	if targetUserId and targetUserId ~= player.UserId then
		if not isCallerAdmin then
			return { Success = false, Message = "Hanya Admin yang dapat mengubah title pemain lain!" }
		end
		targetPlayer = Players:GetPlayerByUserId(targetUserId)
		if not targetPlayer then
			return { Success = false, Message = "Pemain target sedang offline!" }
		end
	end

	local profile = Runtime.getProfile(targetPlayer)
	if not profile then
		return { Success = false, Message = "Profil data pemain belum siap. Coba beberapa saat lagi!" }
	end

	local summit = PlayerStats.getSummit(targetPlayer)
	local fishCount = PlayerStats.getFishCount(targetPlayer)
	local hasVip = PlayerStats.getVip(targetPlayer)

	-- Cek syarat slot baris (1 = 3 summit, 2 = 1.000 summit, dst.)
	if not isCallerAdmin then
		local unlocked, reason = Unlocks.checkSlot(targetPlayer, slot, summit, fishCount)
		if not unlocked then
			return { Success = false, Message = string.format("Slot %d terkunci! %s", slot, reason) }
		end
	end

	if titleType == "Text" then
		if not isCallerAdmin then
			if summit < ImageTitleConfig.TextRules.MinSummit then
				return { Success = false, Message = string.format("Minimal %d Summit untuk membuat Title Teks kustom!", ImageTitleConfig.TextRules.MinSummit) }
			end

			local quota = PlayerStats.getQuota(profile)
			if quota.count >= ImageTitleConfig.TextRules.DailyQuota and os.time() < quota.resetTime then
				local remainingSec = quota.resetTime - os.time()
				local hours = math.floor(remainingSec / 3600)
				local mins = math.floor((remainingSec % 3600) / 60)
				return {
					Success = false,
					Message = string.format("Batas pembuatan title kustom 2x per hari tercapai! Tunggu %d jam %d menit.", hours, mins),
					Cooldown = remainingSec,
				}
			end
		end

		local rawText = payload and (payload.Text or payload.text) or ""
		rawText = tostring(rawText)
		if #rawText == 0 then
			return { Success = false, Message = "Teks title tidak boleh kosong!" }
		end
		if #rawText > ImageTitleConfig.TextRules.MaxLength then
			rawText = string.sub(rawText, 1, ImageTitleConfig.TextRules.MaxLength)
		end

		local cleanText = PlayerStats.filterText(player, rawText)
		if #cleanText == 0 then
			return { Success = false, Message = "Teks tidak lolos filter sensor Roblox!" }
		end

		local mode = payload and (payload.Mode or payload.mode) or "Rainbow Flow"
		local rawColors = payload and (payload.Colors or payload.colors) or {}
		local colors = {}
		for _, c in ipairs(rawColors) do
			table.insert(colors, PlayerStats.sanitizeColor(c))
		end
		if #colors == 0 then
			table.insert(colors, Color3.fromRGB(255, 255, 255))
		end

		local textColor = colors[1]
		local gradientStr = PlayerStats.encodeColors(colors)

		-- Simpan ke Profile
		profile.Data.customTitles = profile.Data.customTitles or {}
		profile.Data.customTitles[slot] = {
			titleType = "Text",
			text = cleanText,
			textColor = { r = math.round(textColor.R * 255), g = math.round(textColor.G * 255), b = math.round(textColor.B * 255) },
			mode = mode,
			gradientStr = gradientStr,
		}
		profile.Data.activeSlot = slot

		-- Potong kuota (jika bukan admin)
		if not isCallerAdmin then
			local quota = PlayerStats.getQuota(profile)
			quota.count += 1
		end

		-- Update atribut pemain (menghapus imageId)
		targetPlayer:SetAttribute("CustomTitleImage_" .. slot, nil)
		targetPlayer:SetAttribute("CustomTitleText_" .. slot, cleanText)
		targetPlayer:SetAttribute("CustomTitleTextColor_" .. slot, textColor)
		targetPlayer:SetAttribute("CustomTitleMode_" .. slot, mode)
		targetPlayer:SetAttribute("CustomTitleTextGradient_" .. slot, gradientStr)
		targetPlayer:SetAttribute("CustomTitleSlot", slot)

		return { Success = true, Message = string.format("Title Baris %d berhasil disimpan!", slot) }

	elseif titleType == "Image" then
		local imageKey = payload and (payload.ImageKey or payload.imageKey or payload.Id or payload.id)
		local foundEntry = nil
		for _, entry in ipairs(ImageTitleConfig.ImageTitles) do
			if entry.Id == imageKey then
				foundEntry = entry
				break
			end
		end

		if not foundEntry then
			return { Success = false, Message = "Title Gambar tidak ditemukan di daftar!" }
		end

		if not isCallerAdmin then
			local unlocked = Unlocks.checkImage(targetPlayer, foundEntry, summit, fishCount, hasVip)
			if not unlocked then
				return { Success = false, Message = string.format("Title Gambar ini belum terbuka! Syarat: %s", foundEntry.Description) }
			end
		end

		-- Simpan ke Profile
		profile.Data.customTitles = profile.Data.customTitles or {}
		profile.Data.customTitles[slot] = {
			titleType = "Image",
			imageId = foundEntry.ImageId,
			imageKey = foundEntry.Id,
		}
		profile.Data.activeSlot = slot

		-- Update atribut pemain (menghapus text)
		targetPlayer:SetAttribute("CustomTitleText_" .. slot, nil)
		targetPlayer:SetAttribute("CustomTitleTextColor_" .. slot, nil)
		targetPlayer:SetAttribute("CustomTitleMode_" .. slot, nil)
		targetPlayer:SetAttribute("CustomTitleTextGradient_" .. slot, nil)
		targetPlayer:SetAttribute("CustomTitleImage_" .. slot, foundEntry.ImageId)
		targetPlayer:SetAttribute("CustomTitleSlot", slot)

		return { Success = true, Message = string.format("Title Gambar Baris %d berhasil dipasang!", slot) }
	else
		return { Success = false, Message = "Tipe title tidak dikenal!" }
	end
end

function TitleSlots.Clear(player, slot, targetUserId)
	slot = tonumber(slot)
	if not slot or slot < 1 or slot > 6 then
		return { Success = false, Message = "Slot baris tidak valid (1-6)!" }
	end

	local isCallerAdmin = RoleConfig.IsAdmin(player)
	local targetPlayer = player
	if targetUserId and targetUserId ~= player.UserId then
		if not isCallerAdmin then
			return { Success = false, Message = "Hanya Admin yang dapat menghapus title pemain lain!" }
		end
		targetPlayer = Players:GetPlayerByUserId(targetUserId)
		if not targetPlayer then
			return { Success = false, Message = "Pemain target sedang offline!" }
		end
	end

	local profile = Runtime.getProfile(targetPlayer)
	if profile and profile.Data and profile.Data.customTitles then
		profile.Data.customTitles[slot] = nil
	end

	targetPlayer:SetAttribute("CustomTitleText_" .. slot, nil)
	targetPlayer:SetAttribute("CustomTitleTextColor_" .. slot, nil)
	targetPlayer:SetAttribute("CustomTitleMode_" .. slot, nil)
	targetPlayer:SetAttribute("CustomTitleTextGradient_" .. slot, nil)
	targetPlayer:SetAttribute("CustomTitleImage_" .. slot, nil)

	return { Success = true, Message = string.format("Title Baris %d berhasil dihapus!", slot) }
end

return TitleSlots
