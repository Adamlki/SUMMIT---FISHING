--!nonstrict
local TweenService = game:GetService("TweenService")
local Packages = game:GetService("ReplicatedStorage").Shared.Packages
local Janitor = require(Packages.Janitor)

local MenuAnimator = {}
MenuAnimator.__index = MenuAnimator

function MenuAnimator.new()
	local self = setmetatable({
		_janitor = Janitor.new(),
		_tween = nil,
		_tweenId = 0,
	}, MenuAnimator)
	return self
end

function MenuAnimator:play(refs, visible)
	local menu = refs and refs.Menu
	if not menu then
		return
	end
	if self._tween then
		self._tween:Cancel()
		self._tween = nil
	end
	self._tweenId += 1
	local currentId = self._tweenId
	local hiddenPos = refs.HiddenPos or menu.Position
	local shownPos = refs.ShownPos or UDim2.fromScale(0.5, 0.5)
	if visible then
		menu.Visible = true
	end
	menu.AnchorPoint = Vector2.new(0.5, 0.5)

	self._tween = TweenService:Create(
		menu,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, visible and Enum.EasingDirection.Out or Enum.EasingDirection.In),
		{ Position = visible and shownPos or hiddenPos }
	)
	self._janitor:Add(self._tween, "Cancel")
	local conn = self._tween.Completed:Connect(function()
		if currentId ~= self._tweenId then
			return
		end
		if not visible then
			menu.Visible = false
		end
	end)
	self._janitor:Add(conn, "Disconnect")
	self._tween:Play()
end

function MenuAnimator:cleanup()
	self._janitor:Cleanup()
end

return MenuAnimator
