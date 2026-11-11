--!nonstrict
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoleEffectsConfig = require(ReplicatedStorage.Shared.Config.Overhead.RoleEffectsConfig)

local RoleEffects = {}
RoleEffects.__index = RoleEffects

function RoleEffects.new(janitor, label)
	local self = setmetatable({}, RoleEffects)
	self._janitor = janitor
	self._label = label
	self._gradient = nil
	self._tween = nil
	self._duration = nil
	self._defaultTextColor = label and label.TextColor3 or nil
	return self
end

function RoleEffects:_ensureGradient()
	if not self._label then return nil end
	if self._gradient and self._gradient.Parent == self._label then
		return self._gradient
	end
	local grad = self._label:FindFirstChildWhichIsA("UIGradient")
	if not grad then
		grad = Instance.new("UIGradient")
		grad.Name = "RoleGradient"
		grad.Parent = self._label
	end
	self._gradient = grad
	return grad
end

function RoleEffects:apply(isSpecial, roleName)
	if not self._label then return end
	if not isSpecial then
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
	local gradient = (RoleEffectsConfig.Gradients and RoleEffectsConfig.Gradients[roleName])
	if not gradient then
		return
	end
	grad.Color = ColorSequence.new(gradient)
	grad.Offset = Vector2.new(-1, 0)

	local duration = (RoleEffectsConfig.SpeedByRole and RoleEffectsConfig.SpeedByRole[roleName]) or 0.8
	if not self._tween or self._duration ~= duration then
		if self._tween then
			self._tween:Cancel()
			self._tween = nil
		end
		self._tween = TweenService:Create(
			grad,
			TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, true),
			{ Offset = Vector2.new(1, 0) }
		)
		self._tween:Play()
		self._duration = duration
		if self._janitor then
			self._janitor:Add(self._tween, "Cancel")
		end
	end
end

return RoleEffects
