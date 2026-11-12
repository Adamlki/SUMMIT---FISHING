--!nonstrict
-- DonationConfig: Pengaturan Daftar Produk Donasi & Robux
-- Ubah nominal Robux dan ProductId di sini. GUI akan otomatis sinkron!

local MonetizationConfig = require(script.Parent:WaitForChild("MonetizationConfig"))
local DonationConfig = {}

-- Daftar produk donasi:
-- - Robux: Jumlah nominal Robux (angka)
-- - ProductId: ID Developer Product dari Roblox Creator Hub
-- - Text: (Opsional) Format teks di TotalRobux, default: "[Robux] Robux"
DonationConfig.Products = {
	{
		Robux = 10,
		ProductId = MonetizationConfig.Donations[10], -- Ganti dengan ID Developer Product untuk 10 Robux
		Text = "10 Robux",
	},
	{
		Robux = 50,
		ProductId = MonetizationConfig.Donations[50], -- Ganti dengan ID Developer Product untuk 50 Robux
		Text = "50 Robux",
	},
	{
		Robux = 100,
		ProductId = MonetizationConfig.Donations[100], -- Ganti dengan ID Developer Product untuk 100 Robux
		Text = "100 Robux",
	},
	{
		Robux = 250,
		ProductId = MonetizationConfig.Donations[250], -- Ganti dengan ID Developer Product untuk 250 Robux
		Text = "250 Robux",
	},
	{
		Robux = 500,
		ProductId = MonetizationConfig.Donations[500], -- Ganti dengan ID Developer Product untuk 500 Robux
		Text = "500 Robux",
	},
	{
		Robux = 1000,
		ProductId = MonetizationConfig.Donations[1000], -- Ganti dengan ID Developer Product untuk 1000 Robux
		Text = "1000 Robux",
	},
}

return DonationConfig
