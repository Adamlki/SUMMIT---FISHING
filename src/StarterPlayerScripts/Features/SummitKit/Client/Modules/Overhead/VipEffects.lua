--!nonstrict
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VipEffectsConfig = require(ReplicatedStorage.Shared.Config.Overhead.VipEffectsConfig)

local VipEffects = {}
VipEffects.__index = VipEffects

function VipEffects.new(janitor, label)
	local self = setmetatable({}, VipEffects)
	self._janitor = janitor
	self._label = label
	self._gradient = nil
	self._tween = nil
	return self
end

function VipEffects:_ensureGradient()
	if not self._label then return nil end
	local grad = self._label:FindFirstChildWhichIsA("UIGradient")
	if not grad then
		grad = Instance.new("UIGradient")
		grad.Name = "VipGradient"
		grad.Parent = self._label
	end
	self._gradient = grad
	return grad
end

function VipEffects:apply(enabled)
	if not self._label then return end
	if not enabled then
		if self._gradient then
			self._gradient.Enabled = false
		end
		if self._tween then
			self._tween:Cancel()
			self._tween = nil
		end
		return
	end

	local grad = self:_ensureGradient()
	if not grad then return end
	grad.Enabled = true
	grad.Color = ColorSequence.new(VipEffectsConfig.Gradient)
	grad.Offset = Vector2.new(-1, 0)

	local speed = VipEffectsConfig.SpeedSeconds or 1.2
	if not self._tween then
		self._tween = TweenService:Create(
			grad,
			TweenInfo.new(speed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, true),
			{ Offset = Vector2.new(1, 0) }
		)
		self._tween:Play()
		if self._janitor then
			self._janitor:Add(self._tween, "Cancel")
		end
	end
end

return VipEffects
