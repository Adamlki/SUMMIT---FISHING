--!nonstrict
local FlagIcons = {}

-- 1 Ikon Bendera Uni Eropa (EU) untuk seluruh negara Eropa
local EU_FLAG = "rbxassetid://9575366030"

-- Pemetaan negara-negara Eropa ke 1 bendera EU (Eropa terpadu & efisien)
local EUROPE_CODES = {
	GB = true, UK = true, FR = true, DE = true, IT = true, ES = true,
	NL = true, BE = true, SE = true, PL = true, NO = true, DK = true,
	FI = true, IE = true, PT = true, CH = true, AT = true, GR = true,
	CZ = true, RO = true, HU = true, UA = true, RU = true, HR = true,
	BG = true, SK = true, RS = true, SI = true, LT = true, LV = true,
	EE = true, IS = true, LU = true, MT = true, CY = true, AL = true,
	BA = true, ME = true, MK = true, MD = true, BY = true, MC = true,
	AD = true, LI = true, SM = true, VA = true, EU = true,
}

-- Pemetaan bendera negara-negara Asia (per-negara)
-- Kamu dapat menambah atau mengubah Asset ID bendera di tabel ini kapan saja
FlagIcons.AsiaFlags = {
	ID = "rbxassetid://6579887771", -- Indonesia
	MY = "rbxassetid://11886913591", -- Malaysia
	SG = "rbxassetid://12221297293", -- Singapura
	PH = "rbxassetid://453452486", -- Filipina
	JP = "rbxassetid://82688155", -- Jepang
	KR = "rbxassetid://12220988564", -- Korea Selatan
	TH = "rbxassetid://12221319202", -- Thailand
	VN = "rbxassetid://12221356789", -- Vietnam
	CN = "rbxassetid://12220794935", -- China
	IN = "rbxassetid://12220919137", -- India
	TW = "rbxassetid://12221312345", -- Taiwan
	HK = "rbxassetid://12220902999", -- Hong Kong
	MO = "rbxassetid://12220902999", -- Macau
	BN = "rbxassetid://12220794935", -- Brunei
	KH = "rbxassetid://12220794935", -- Kamboja
	LA = "rbxassetid://12220794935", -- Laos
	MM = "rbxassetid://12220794935", -- Myanmar
	PK = "rbxassetid://12220919137", -- Pakistan
	BD = "rbxassetid://12220919137", -- Bangladesh
	SA = "rbxassetid://12220794935", -- Arab Saudi
	AE = "rbxassetid://12220794935", -- UAE
	QA = "rbxassetid://12220794935", -- Qatar
}

-- Cache untuk asset pack eksternal
local _externalDict = nil
local function getExternalDict()
	if _externalDict == nil then
		local ok, dict = pcall(function()
			return require(13144850866)
		end)
		if ok and typeof(dict) == "table" then
			_externalDict = dict
		else
			_externalDict = false
		end
	end
	return _externalDict or nil
end

function FlagIcons.getImage(countryCode: string?): string?
	if not countryCode or countryCode == "" or countryCode == "XX" or countryCode == "UNKNOWN" then
		return nil
	end
	local code = string.upper(tostring(countryCode))

	-- 1. Jika wilayah Eropa -> Kembalikan 1 ikon bendera Uni Eropa
	if EUROPE_CODES[code] then
		return EU_FLAG
	end

	-- 2. Jika wilayah Asia -> Cek tabel AsiaFlags
	local asiaFlag = FlagIcons.AsiaFlags[code]
	if asiaFlag then
		return asiaFlag
	end

	-- 3. Fallback dinamis dari dictionary external jika tersedia
	local dict = getExternalDict()
	if dict and dict[code] and dict[code].Flag then
		return "rbxassetid://" .. tostring(dict[code].Flag)
	end

	return nil
end

function FlagIcons.apply(flagLabel: Instance?, countryCode: string?)
	if not flagLabel or not flagLabel:IsA("ImageLabel") then
		return
	end
	local image = FlagIcons.getImage(countryCode)
	if image and image ~= "" then
		flagLabel.Image = image
		flagLabel.Visible = true
	else
		flagLabel.Visible = false
	end
end

return FlagIcons
