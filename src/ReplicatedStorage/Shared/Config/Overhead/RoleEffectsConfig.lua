--!nonstrict
local RoleEffectsConfig = {}

RoleEffectsConfig.Gradients = {
	Owner = {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 80, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 0)),
	},
	Developer = {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 240, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 140, 255)),
	},
	Admin = {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 0)),
	},
	Moderator = {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 255, 120)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 255, 200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 180, 120)),
	},
}

RoleEffectsConfig.SpeedByRole = {
	Owner = 3,
	Developer = 0.9,
	Admin = 0.8,
	Moderator = 0.8,
}

return RoleEffectsConfig
