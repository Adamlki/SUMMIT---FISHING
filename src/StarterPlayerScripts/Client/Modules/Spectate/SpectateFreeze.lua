--!nonstrict
local Players = game:GetService("Players")

local Freeze = {}
Freeze.__index = Freeze

function Freeze.new()
	local self = setmetatable({}, Freeze)
	self._saved = {
		ws = nil,
		jp = nil,
		jh = nil,
		ujp = nil,
		ar = nil,
	}
	return self
end

local function getHumanoid()
	local char = Players.LocalPlayer.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

function Freeze:freeze()
	local hum = getHumanoid()
	if not hum then
		return
	end

	if self._saved.ws == nil then
		self._saved.ws = hum.WalkSpeed
	end
	if self._saved.ujp == nil then
		self._saved.ujp = hum.UseJumpPower
	end
	if self._saved.jp == nil then
		self._saved.jp = hum.JumpPower
	end
	if self._saved.jh == nil then
		self._saved.jh = hum.JumpHeight
	end
	if self._saved.ar == nil then
		self._saved.ar = hum.AutoRotate
	end

	local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end

	hum.AutoRotate = false
	hum.WalkSpeed = 0
	if hum.UseJumpPower then
		hum.JumpPower = 0
	else
		hum.JumpHeight = 0
	end
end

function Freeze:unfreeze()
	local hum = getHumanoid()
	if not hum then
		return
	end

	hum.AutoRotate = (self._saved.ar ~= nil) and self._saved.ar or true
	hum.WalkSpeed = (self._saved.ws ~= nil) and self._saved.ws or 16
	if hum.UseJumpPower then
		hum.JumpPower = (self._saved.jp ~= nil) and self._saved.jp or 50
	else
		hum.JumpHeight = (self._saved.jh ~= nil) and self._saved.jh or 7.2
	end
end

return Freeze
