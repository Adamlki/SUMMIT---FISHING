--!strict

-- ReplicatedStorage/ToolDistributionConfig

-- ==============================================================================

-- 🛠️ CENTRAL TOOL DISTRIBUTION & CONFIGURATION

-- Satu-satunya tempat untuk mengatur pembagian tools: Free, VIP, Admin, dan Shop

-- Semua tools merujuk langsung ke nama Tool yang ada di ServerStorage.AllTools!

-- ==============================================================================


export type ShopToolItem = {

	ToolName: string,

	DisplayName: string,

	GamePassId: number,

	PriceRobux: number,

	Description: string,

	Icon: string,

}


local ToolDistributionConfig = {}


-- ==============================================================================

-- 1. 🆓 PEMAIN BIASA (FREE TOOLS)

-- Tool yang otomatis didapat oleh SEMUA pemain secara gratis saat spawn

-- Kosongkan {} jika pemain biasa tidak dapat tool gratis (hanya fishing rod bawaan)

-- ==============================================================================

ToolDistributionConfig.FreeTools = {

	-- Contoh: "Default",

}


-- ==============================================================================

-- 2. ⭐ PEMAIN VIP (VIP GAMEPASS)

-- Tool yang otomatis didapat atau bisa di-equip lewat inventory oleh pemilik VIP

-- ==============================================================================

ToolDistributionConfig.VIPTools = {

	"Kunai",

}


-- Gamepass ID untuk akses VIP (Mendukung ID gamepass utama & legacy)

ToolDistributionConfig.VIPGamepassIds = {

	1874479701, -- Gamepass VIP di Toko Eksklusif

	1590939529, -- Gamepass VIP Legacy

}


-- ==============================================================================

-- 3. 🛡️ JAJARAN ROLE & ADMIN (AUTO-GRANT SAAT RESPAWN)

-- Tool yang otomatis masuk ke Backpack dan StarterGear sesuai rank pemain

-- ==============================================================================

ToolDistributionConfig.RoleTools = {

	Owner = {

		"Admin",

		"Poison",

		"Void",

		"BoomBox",

	},

	Developer = {

		"Admin",

	},

	Admin = {

		"Admin",

	},

	Moderator = {},

}


-- ==============================================================================

-- 4. 💎 TOOLS TOKO EKSKLUSIF (DIJUAL TERPISAH VIA GAMEPASS / ROBUX)

-- Daftar tools berbayar untuk Toko Eksklusif. Cukup masukkan nama Tool dari AllTools!

-- ==============================================================================

ToolDistributionConfig.ShopTools = {

	{

		ToolName = "BoomBox",

		DisplayName = "Boombox Radio",

		GamePassId = 0, -- Masukkan ID Gamepass dari Creator Hub

		PriceRobux = 20,

		Description = "Putar musik favoritmu dan dengarkan bersama pemain lain!",

		Icon = "rbxassetid://97126236767050",

	},

	{

		ToolName = "Void",

		DisplayName = "Void Sword",

		GamePassId = 0,

		PriceRobux = 100,

		Description = "Pedang energi void mistis dengan efek partikel gelap!",

		Icon = "rbxassetid://511340819",

	},

	{

		ToolName = "Poison",

		DisplayName = "Poison Dagger",

		GamePassId = 0,

		PriceRobux = 75,

		Description = "Belati racun mematikan!",

		Icon = "rbxassetid://511340819",

	},

}


-- ==============================================================================

-- 🔍 HELPER FUNCTIONS

-- ==============================================================================


--- Cek apakah suatu tool termasuk kategori VIP

function ToolDistributionConfig.IsVIPTool(toolName: string): boolean

	for _, name in ipairs(ToolDistributionConfig.VIPTools) do

		if name == toolName then

			return true

		end

	end

	return false

end


--- Cek apakah suatu tool termasuk dalam daftar jualan toko

function ToolDistributionConfig.GetShopItem(toolName: string): ShopToolItem?

	for _, item in ipairs(ToolDistributionConfig.ShopTools) do

		if item.ToolName == toolName then

			return item

		end

	end

	return nil

end


return ToolDistributionConfig

