--!strict
-- Konfigurasi Terpusat untuk Title Gambar, Kuota Teks & Syarat Unlock Slot

local MonetizationConfig = require(script.Parent:WaitForChild("MonetizationConfig"))

export type UnlockType = "Group" | "Summit" | "FishCount" | "FishIndex" | "VIP" | "Free"

export type ImageTitleEntry = {
	Id: string,
	Name: string,
	ImageId: string,
	UnlockType: UnlockType,
	Description: string,
	GroupId: number?,
	ReqSummit: number?,
	ReqFishCount: number?,
	GamepassId: number?,
}

local ImageTitleConfig = {}

-- Aturan Kuota Pembuatan Title Teks
ImageTitleConfig.TextRules = {
	MinSummit = 3,
	DailyQuota = 2,
	CooldownSeconds = 86400, -- 24 jam
	MaxLength = 25,
}

-- Syarat Pembukaan Slot Baris 1 - 6
-- Slot 1-3: Khusus Title Teks
-- Slot 4-6: Khusus Title Gambar
ImageTitleConfig.SlotMilestones = {
	[1] = { SlotType = "Text", UnlockType = "Summit", ReqSummit = 3, Label = "3 Summit", Reason = "Butuh 3 Summit" },
	[2] = { SlotType = "Text", UnlockType = "Summit", ReqSummit = 1000, Label = "1.000 Summit", Reason = "Butuh 1.000 Summit" },
	[3] = { SlotType = "Text", UnlockType = "FishCount", ReqFishCount = 500, Label = "500 Mancing", Reason = "Butuh 500 Count Mancing" },
	[4] = { SlotType = "Image", UnlockType = "Group", GroupId = 352750447, Label = "Join Community", RewardId = "Community", Reason = "Wajib Join Komunitas Roblox & Like Map" },
	[5] = { SlotType = "Image", UnlockType = "Summit", ReqSummit = 5000, Label = "5.000 Summit", Reason = "Butuh 5.000 Summit" },
	[6] = { SlotType = "Image", UnlockType = "FishCount", ReqFishCount = 1000, Label = "1.000 Mancing", Reason = "Butuh 1.000 Count Mancing" },
}

-- Daftar Title Gambar (Image Badges 2x3 Grid)
-- Kamu dapat mengganti nilai ImageId kapan saja di sini!
ImageTitleConfig.ImageTitles = {
	{
		Id = "Community",
		Name = "PASUKAN DRAMATIS",
		ImageId = "rbxassetid://135894154942918",
		UnlockType = "Group",
		GroupId = 352750447,
		Description = "Join Community & Like Map",
	},
	{
		Id = "Summit1000",
		Name = "1.000 SUMMIT",
		ImageId = "rbxassetid://80133773367022",
		UnlockType = "Summit",
		ReqSummit = 1000,
		Description = "Buka dengan mencapai 1.000 Summit",
	},
	{
		Id = "Summit5000",
		Name = "5.000 SUMMIT",
		ImageId = "rbxassetid://6031075938",
		UnlockType = "Summit",
		ReqSummit = 5000,
		Description = "Buka dengan mencapai 5.000 Summit",
	},
	{
		Id = "Summit10000",
		Name = "10.000 SUMMIT",
		ImageId = "rbxassetid://6031075938", -- Placeholder, ganti dengan asset eksklusif 10K Summit kapan saja
		UnlockType = "Summit",
		ReqSummit = 10000,
		Description = "Buka dengan mencapai 10.000 Summit",
	},
	{
		Id = "Fish500",
		Name = "500 MANCING",
		ImageId = "rbxassetid://12916400638",
		UnlockType = "FishCount",
		ReqFishCount = 500,
		Description = "Capai 500 Count Mancing",
	},
	{
		Id = "Fish1000",
		Name = "1.000 MANCING",
		ImageId = "rbxassetid://12916400638",
		UnlockType = "FishCount",
		ReqFishCount = 1000,
		Description = "Capai 1.000 Count Mancing",
	},
	-- Entri opsional lama untuk kompatibilitas
	{
		Id = "Senadi",
		Name = "SENADI",
		ImageId = "rbxassetid://80133773367022",
		UnlockType = "Summit",
		ReqSummit = 100,
		Description = "Buka dengan mencapai 100 Summit",
	},
	{
		Id = "VIP",
		Name = "VIP CROWN",
		ImageId = "rbxassetid://12916400638",
		UnlockType = "VIP",
		GamepassId = MonetizationConfig.VIP.GamePassId,
		Description = "Miliki Gamepass VIP",
	},
}

-- Helper pencarian cepat berdasarkan ID
ImageTitleConfig.Registry = {}
for _, entry in ipairs(ImageTitleConfig.ImageTitles) do
	ImageTitleConfig.Registry[entry.Id] = entry
end

return ImageTitleConfig
