--!strict
-- Spin Reward Wheel: hadiah, bobot, free spin, dan Developer Products.
-- Urutan Segments HARUS sama dengan urutan wedge di gambar wheel (searah jarum jam
-- mulai dari jam 12): Cople Rod, 25K, 10K, Luck, 50K, 5K.
local SpinConfig = {}

SpinConfig.FreeSpin = {
	CooldownSeconds = 30, -- free spin baru setiap 30 detik setelah dipakai
	MaxFreeSpins = 1, -- tidak menumpuk
}

-- Developer Products. ProductId 0 = belum dikonfigurasi di Dashboard.
SpinConfig.Products = {
	X2 = { ProductId = 0, Price = 49, Spins = 2, Label = "x2 Spins" },
	X7 = { ProductId = 0, Price = 199, Spins = 7, Label = "x7 Spins" },
}

local BLUE = Color3.fromRGB(52, 132, 226)
local ORANGE = Color3.fromRGB(245, 150, 45)
local PURPLE = Color3.fromRGB(128, 82, 205)
local GOLD = Color3.fromRGB(247, 193, 58)
local GREEN = Color3.fromRGB(58, 186, 104)
local RED = Color3.fromRGB(232, 70, 62)

-- 6 segmen (60° tiap wedge), urut searah jarum jam dari jam 12.
-- Bobot mengikuti angka yang tertulis di gambar wheel.
SpinConfig.Segments = {
	{
		Type = "Rod",
		RodName = "Cople x1x1x",
		Weight = 2,
		Label = "Cople Rod",
		Color = ORANGE,
		Icon = "rbxassetid://83154227607248",
		DupeCoins = 60000,
	},
	{
		Type = "Coins",
		Amount = 25000,
		Weight = 15,
		Label = "25K",
		Color = BLUE,
		Icon = "rbxassetid://128313126627517",
	},
	{
		Type = "Coins",
		Amount = 10000,
		Weight = 24,
		Label = "10K",
		Color = BLUE,
		Icon = "rbxassetid://128313126627517",
	},
	{
		Type = "Luck",
		Multiplier = 5,
		Seconds = 900,
		Weight = 10,
		Label = "LUCK x5",
		Color = PURPLE,
		Icon = "rbxassetid://101739550540739",
	},
	{
		Type = "Coins",
		Amount = 50000,
		Weight = 15,
		Label = "50K",
		Color = BLUE,
		Icon = "rbxassetid://128313126627517",
	},
	{
		Type = "Coins",
		Amount = 5000,
		Weight = 33,
		Label = "5K",
		Color = BLUE,
		Icon = "rbxassetid://128313126627517",
	},
}

SpinConfig.CoinIcon = "rbxassetid://128313126627517"
SpinConfig.LuckIcon = "rbxassetid://101739550540739"

SpinConfig.SpinSound = ""
SpinConfig.WinSound = "rbxassetid://4525871712"

return SpinConfig
