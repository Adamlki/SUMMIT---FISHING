-- ReplicatedStorage/FishingSystem/RodVFXConfig.luau
-- Konfigurasi Efek Visual (VFX) dan Suara (SFX) Unik untuk Skin Pancing

local RodVFXConfig = {}

RodVFXConfig.Themes = {
	Lightning = {
		PrimaryColor = Color3.fromRGB(80, 210, 255),
		SecondaryColor = Color3.fromRGB(255, 240, 90),
		CastSound = "rbxassetid://6340511690", -- Listrik Zap
		CastSoundVolume = 0.65,
		BurstTextures = {
			"rbxassetid://11861733639", -- ToonLightning
			"rbxassetid://15057992719", -- Lightning
		},
		BurstCount = 18,
		BurstSpeed = NumberRange.new(8, 22),
		BurstLifetime = NumberRange.new(0.2, 0.45),
		ReelTexture = "rbxassetid://17005865240", -- Lightning Spark
		ReelRate = 12,
		SplashColor = Color3.fromRGB(90, 220, 255),
	},
	Frost = {
		PrimaryColor = Color3.fromRGB(160, 235, 255),
		SecondaryColor = Color3.fromRGB(240, 250, 255),
		CastSound = "rbxassetid://5650258743", -- Ice Crystal Shimmer
		CastSoundVolume = 0.6,
		BurstTextures = {
			"rbxassetid://84347911820112", -- Sparks
			"rbxassetid://73555928607348", -- Ice crystal
		},
		BurstCount = 20,
		BurstSpeed = NumberRange.new(6, 16),
		BurstLifetime = NumberRange.new(0.3, 0.6),
		ReelTexture = "rbxassetid://99422919490106", -- Ice shimmer
		ReelRate = 10,
		SplashColor = Color3.fromRGB(190, 245, 255),
	},
	Blade = {
		PrimaryColor = Color3.fromRGB(200, 110, 255),
		SecondaryColor = Color3.fromRGB(240, 220, 255),
		CastSound = "rbxassetid://6650544248", -- Sword Slash
		CastSoundVolume = 0.7,
		BurstTextures = {
			"rbxassetid://14054642335", -- Aura slash
			"rbxassetid://13603608421", -- Swirl
		},
		BurstCount = 12,
		BurstSpeed = NumberRange.new(10, 24),
		BurstLifetime = NumberRange.new(0.15, 0.4),
		ReelTexture = "rbxassetid://9504165696", -- Blade spark
		ReelRate = 10,
		SplashColor = Color3.fromRGB(210, 130, 255),
	},
	Glitch = {
		PrimaryColor = Color3.fromRGB(255, 45, 75),
		SecondaryColor = Color3.fromRGB(30, 30, 30),
		CastSound = "rbxassetid://6650544248", -- Cyber slash
		CastSoundVolume = 0.7,
		BurstTextures = {
			"rbxassetid://134321812133122", -- Glitch numbers
			"rbxassetid://16867444334",     -- 29v code
		},
		BurstCount = 24,
		BurstSpeed = NumberRange.new(8, 20),
		BurstLifetime = NumberRange.new(0.25, 0.5),
		ReelTexture = "rbxassetid://9563819936", -- Error square
		ReelRate = 14,
		HasSurfaceEffect = true,
		SplashColor = Color3.fromRGB(255, 50, 80),
	},
	Flame = {
		PrimaryColor = Color3.fromRGB(255, 85, 40),
		SecondaryColor = Color3.fromRGB(255, 140, 200),
		CastSound = "rbxassetid://6650544248", -- Fire whoosh
		CastSoundVolume = 0.65,
		BurstTextures = {
			"rbxassetid://98999511417166", -- Fire flame
			"rbxassetid://12942158384",    -- Embers
		},
		BurstCount = 22,
		BurstSpeed = NumberRange.new(7, 18),
		BurstLifetime = NumberRange.new(0.25, 0.55),
		ReelTexture = "rbxassetid://10205180639", -- Flame sparks
		ReelRate = 12,
		SplashColor = Color3.fromRGB(255, 110, 50),
	},
	Divine = {
		PrimaryColor = Color3.fromRGB(255, 220, 85),
		SecondaryColor = Color3.fromRGB(215, 120, 255),
		CastSound = "rbxassetid://5650258743", -- Celestial Chime
		CastSoundVolume = 0.7,
		BurstTextures = {
			"rbxassetid://14032901187", -- Radiant rays
			"rbxassetid://12090248314", -- Divine star
			"rbxassetid://14762708319", -- Pulse ring
		},
		BurstCount = 28,
		BurstSpeed = NumberRange.new(6, 20),
		BurstLifetime = NumberRange.new(0.3, 0.6),
		ReelTexture = "rbxassetid://8084911316", -- Radiant arcs
		ReelRate = 15,
		SplashColor = Color3.fromRGB(255, 230, 110),
	},
	Prismatic = {
		PrimaryColor = Color3.fromRGB(110, 255, 235),
		SecondaryColor = Color3.fromRGB(230, 160, 255),
		CastSound = "rbxassetid://5650258743",
		CastSoundVolume = 0.6,
		BurstTextures = {
			"rbxassetid://12090248314",
			"rbxassetid://14006783533",
		},
		BurstCount = 18,
		BurstSpeed = NumberRange.new(6, 18),
		BurstLifetime = NumberRange.new(0.25, 0.5),
		ReelTexture = "rbxassetid://12090248314",
		ReelRate = 10,
		SplashColor = Color3.fromRGB(130, 255, 240),
	},
	Shadow = {
		PrimaryColor = Color3.fromRGB(130, 55, 195),
		SecondaryColor = Color3.fromRGB(45, 25, 75),
		CastSound = "rbxassetid://6650544248",
		CastSoundVolume = 0.65,
		BurstTextures = {
			"rbxassetid://13013256540", -- Dark mist
			"rbxassetid://14054642335", -- Shadow aura
		},
		BurstCount = 16,
		BurstSpeed = NumberRange.new(5, 15),
		BurstLifetime = NumberRange.new(0.3, 0.6),
		ReelTexture = "rbxassetid://13013256540",
		ReelRate = 10,
		SplashColor = Color3.fromRGB(140, 65, 210),
	},
	Default = {
		PrimaryColor = Color3.fromRGB(220, 240, 255),
		SecondaryColor = Color3.fromRGB(180, 210, 240),
		CastSound = "rbxassetid://119135010875996",
		CastSoundVolume = 0.5,
		BurstTextures = {
			"rbxassetid://9504165696",
		},
		BurstCount = 6,
		BurstSpeed = NumberRange.new(4, 12),
		BurstLifetime = NumberRange.new(0.2, 0.4),
		ReelTexture = "rbxassetid://9504165696",
		ReelRate = 5,
		SplashColor = Color3.fromRGB(200, 230, 255),
	},
}

RodVFXConfig.RodToTheme = {
	-- Petir / Listrik
	["Lightning"] = "Lightning",
	["LightingPunk Rod"] = "Lightning",

	-- Es / Frost
	["Frozen Rod"] = "Frost",

	-- Bilah / Pedang
	["Katana"] = "Blade",
	["Purple Saber"] = "Blade",
	["Dragon Spine"] = "Blade",

	-- Glitch / Cyber
	["Corruption Edge"] = "Glitch",
	["Binary Edge"] = "Glitch",
	["x1x1x1 Hammer"] = "Glitch",
	["Cople x1x1x"] = "Glitch",
	["Copblue x1x1x"] = "Glitch",

	-- Api Magma
	["Flery"] = "Flame",
	["Loving"] = "Flame",

	-- Ilahi / Royal / Admin
	["Admin Rod"] = "Divine",
	["Owner Rod"] = "Divine",
	["Developer Rod"] = "Divine",
	["Gold Rod"] = "Divine",
	["Manifest"] = "Divine",

	-- Prisma / Suci / Kristal
	["Angelic Rod"] = "Prismatic",
	["Aqua Prism"] = "Prismatic",
	["Crystalized"] = "Prismatic",
	["Lucky Rod"] = "Prismatic",
	["Polarized"] = "Prismatic",
	["Fluorescent Rod"] = "Prismatic",

	-- Bayangan / Kematian
	["GhostRod"] = "Shadow",
	["Forsaken"] = "Shadow",
	["ZombieRod"] = "Shadow",
	["Pirate Octopus"] = "Shadow",

	-- Standar
	["Basic Rod"] = "Default",
	["Earthly"] = "Default",
	["Umbrella"] = "Default",
	["Megalofriend"] = "Default",
	["default"] = "Default",
}

function RodVFXConfig.GetTheme(rodName: string?)
	if not rodName then return RodVFXConfig.Themes.Default end
	local themeKey = RodVFXConfig.RodToTheme[rodName] or "Default"
	return RodVFXConfig.Themes[themeKey] or RodVFXConfig.Themes.Default
end

return RodVFXConfig
