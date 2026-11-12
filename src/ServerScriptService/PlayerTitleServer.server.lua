--!nonstrict
-- ==============================================================================
-- PlayerTitleServer
-- Menangani pembuatan title kustom teks (kuota 2x/24h, min 1 summit) & title gambar
-- Terintegrasi dengan ProfileStore OverheadCustomTitles, Knit OverheadService & Admin
-- Implementasi: ServerScriptService > Title > Modules
-- ==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FeatureFlags = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("FeatureFlags"))
if not FeatureFlags.Titles then return end

local TitleModules = script.Parent:WaitForChild("Title"):WaitForChild("Modules")
local Runtime = require(TitleModules:WaitForChild("Runtime"))
local TitleData = require(TitleModules:WaitForChild("TitleData"))
local TitleSlots = require(TitleModules:WaitForChild("TitleSlots"))
local Networking = require(TitleModules:WaitForChild("Networking"))
local Lifecycle = require(TitleModules:WaitForChild("Lifecycle"))

Runtime.Start()

Networking.Start({
	GetTitleData = TitleData.Get,
	SetTitle = TitleSlots.Set,
	ClearSlot = TitleSlots.Clear,
})

Lifecycle.Start()

print("[PlayerTitleServer] ✅ Player Title Server initialized successfully!")
