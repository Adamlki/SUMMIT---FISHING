--!nonstrict
-- ================================================
-- Join Community Auto Dapat Title NOVA (1 Slot)
-- Created by: when NOVASTUDIO
-- Version: 1.0
-- Jangan hapus atau modif credit ini!
-- Join DC: https://discord.gg/saNDWMhVt9
-- ================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GROUP_ID = 352750447

-- Path yang benar sesuai struktur Explorer kamu
local CustomTitleModules = ServerScriptService.Server.Services.CustomTitle
local ColorUtil           = require(CustomTitleModules.ColorUtil)
local ProfileManager      = require(CustomTitleModules.ProfileManager)

-- Tunggu Knit siap
local Knit = require(ReplicatedStorage.Shared.Packages.Knit)

-- Konfigurasi title NOVA
local TITLE_PAYLOAD = {
	text   = "👑VASTORIA COMUNITY👑",
	mode   = "Rainbow Gradient",
	colors = {
		{r = 255, g = 0, b = 0},
	},
	slot   = 1,
}

local TITLE_SLOT = 1

-- ─────────────────────────────────────────────
-- Helper: cek member grup
-- ─────────────────────────────────────────────
local function isInGroup(player)
	local ok, result = pcall(function()
		return player:IsInGroup(GROUP_ID)
	end)
	return ok and result
end

-- ─────────────────────────────────────────────
-- Helper: slotAttr
-- ─────────────────────────────────────────────
local function slotAttr(base, slot)
	return string.format("%s_%d", base, slot)
end

-- ─────────────────────────────────────────────
-- Give title langsung (bypass RoleChecker, server-side)
-- ─────────────────────────────────────────────
local function giveTitle(player, OverheadService)
	local cfg      = OverheadService.Client.Config:Get()
	local profiles = OverheadService.profiles

	-- Sanitasi colors
	-- BARU - gradient benar
	local colors = {}
	for _, entry in ipairs(TITLE_PAYLOAD.colors) do
		local color = ColorUtil.sanitizeColor(entry)
		if color then
			table.insert(colors, color)
		end
		if #colors >= 4 then break end
	end
	if #colors == 0 then
		table.insert(colors, Color3.fromRGB(255, 255, 255))
	end

	local textColor   = colors[1]
	local gradientStr = ColorUtil.encodeColors(TITLE_PAYLOAD.colors) -- ← pakai raw tabel, bukan colors
	local slot        = TITLE_SLOT
	local text        = TITLE_PAYLOAD.text
	local mode        = TITLE_PAYLOAD.mode

	-- Set attribute ke player
	player:SetAttribute(slotAttr(cfg.CustomTitleTextAttribute,         slot), text)
	player:SetAttribute(slotAttr(cfg.CustomTitleTextColorAttribute,    slot), textColor)
	player:SetAttribute(slotAttr(cfg.CustomTitleTextGradientAttribute, slot), gradientStr)
	player:SetAttribute(slotAttr(cfg.CustomTitleModeAttribute,         slot), mode)
	player:SetAttribute(cfg.CustomTitleSlotAttribute, slot)

	-- Simpan ke profile (permanen)
	ProfileManager.saveSlot(
		profiles[player],
		slot,
		text,
		textColor,
		mode,
		gradientStr,
		ColorUtil.colorToTable
	)

	print(string.format("[NOVATitle] ✅ Title diberikan ke %s", player.Name))
end

-- ─────────────────────────────────────────────
-- Hapus title slot 1
-- ─────────────────────────────────────────────
local function removeTitle(player, OverheadService)
	local cfg      = OverheadService.Client.Config:Get()
	local profiles = OverheadService.profiles

	player:SetAttribute(slotAttr(cfg.CustomTitleTextAttribute,         TITLE_SLOT), nil)
	player:SetAttribute(slotAttr(cfg.CustomTitleTextColorAttribute,    TITLE_SLOT), nil)
	player:SetAttribute(slotAttr(cfg.CustomTitleModeAttribute,         TITLE_SLOT), nil)
	player:SetAttribute(slotAttr(cfg.CustomTitleTextGradientAttribute, TITLE_SLOT), nil)
	player:SetAttribute(cfg.CustomTitleSlotAttribute, nil)

	ProfileManager.clearSlot(profiles[player], TITLE_SLOT)

	print(string.format("[NOVATitle] ❌ Title dihapus dari %s (bukan member grup)", player.Name))
end

-- ─────────────────────────────────────────────
-- Handle per player
-- ─────────────────────────────────────────────
local function handlePlayer(player, OverheadService)
	-- Tunggu profile siap (ProfileStore butuh waktu load)
	local waited = 0
	while not OverheadService.profiles[player] and waited < 10 do
		task.wait(0.5)
		waited += 0.5
	end

	if not OverheadService.profiles[player] then
		warn(string.format("[NOVATitle] ⚠️ Profile %s tidak siap dalam 10 detik, skip.", player.Name))
		return
	end

	if isInGroup(player) then
		giveTitle(player, OverheadService)
	else
		removeTitle(player, OverheadService)
	end
end

-- ─────────────────────────────────────────────
-- Main: jalankan setelah Knit start
-- ─────────────────────────────────────────────
task.spawn(function()
	Knit.OnStart():await()

	local OverheadService = Knit.GetService("OverheadService")

	-- Player yang join setelah script ini jalan
	Players.PlayerAdded:Connect(function(player)
		task.spawn(handlePlayer, player, OverheadService)
	end)

	-- Player yang sudah ada sebelum script ini jalan
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(handlePlayer, player, OverheadService)
	end
end)