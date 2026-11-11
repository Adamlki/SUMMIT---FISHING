--!nonstrict
local VipEffectsConfig = {}

VipEffectsConfig.Gradient = {
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 0, 0)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 128, 0)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(251, 255, 0)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0, 255, 170)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(0, 4, 255)),
}

VipEffectsConfig.SpeedSeconds = 1.2

return VipEffectsConfig
