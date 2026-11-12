--!strict
-- Runtime feature toggles. All default to true to preserve current behaviour.
-- NOTE: These flags gate standalone scripts only. Inline services in Server/Core.lua
-- (CarryService, OverheadService, CustomTitle) stay active even when the flag is false.
local FeatureFlags = {
	Fishing = true,
	Inventory = true,
	Shop = true,
	Carry = true,
	Titles = true,
	FishIndex = true,
	Gendong = true,
	Trails = true,
	RoleTools = true,
	AdminLuck = true,
}

return FeatureFlags
