-- ============================================================
-- Carry/Modules/Config (ModuleScript)
-- Timing, distance, capacity, scale, and formation constants.
-- ============================================================

local Config = {}

local PENDING_TIMEOUT = 10
local MAX_DISTANCE = 25
local MAX_CARRY = 35
local CARRY_SCALE_FACTOR = 0.65

Config.PENDING_TIMEOUT = PENDING_TIMEOUT
Config.MAX_DISTANCE = MAX_DISTANCE
Config.MAX_CARRY = MAX_CARRY
Config.CARRY_SCALE_FACTOR = CARRY_SCALE_FACTOR
Config.LOCK_TIMEOUT = 3.0

-- Formasi Sejajar Dua Kolom (Pasangan Kanan & Kiri):
-- Baris 1: Kanan (X=+1.8, Z=2.0) & Kiri (X=-1.8, Z=2.0)
-- Baris 2: Kanan (X=+1.8, Z=4.0) & Kiri (X=-1.8, Z=4.0)
-- Baris N: Kanan (X=+1.8, Z=2.0+(N-1)*2.0) & Kiri (X=-1.8, Z=2.0+(N-1)*2.0)
local BASE_Z = 2.0
local ROW_SPACING_Z = 2.0
local SIDE_OFFSET_X = 1.8
local FLOAT_Y = 1.2

function Config.slotOffset(i: number): CFrame
	local zeroIndex = i - 1
	local row = math.floor(zeroIndex / 2)
	local isRight = (zeroIndex % 2 == 0)
	local x = isRight and SIDE_OFFSET_X or -SIDE_OFFSET_X
	local z = BASE_Z + row * ROW_SPACING_Z
	return CFrame.new(x, FLOAT_Y, z)
end

return Config
