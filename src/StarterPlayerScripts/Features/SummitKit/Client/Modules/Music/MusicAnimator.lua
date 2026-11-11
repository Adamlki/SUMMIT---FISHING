--!nonstrict
local TweenService = game:GetService("TweenService")

local Animator = {}
Animator.__index = Animator

function Animator.new(menu)
	local self = setmetatable({}, Animator)
	self._menu = menu
	self._defaultAnchor = menu and menu.AnchorPoint or nil
	self._defaultPos = menu and menu.Position or nil
	self._tween = nil
	self._tweenId = 0
	return self
end

function Animator:Open()
	local menu = self._menu
	if not menu then return nil end
	if self._tween then
		self._tween:Cancel()
		self._tween = nil
	end

	self._tweenId += 1
	local currentId = self._tweenId

	if not self._defaultAnchor then
		self._defaultAnchor = menu.AnchorPoint
	end
	if not self._defaultPos then
		self._defaultPos = menu.Position
	end

	menu.AnchorPoint = Vector2.new(0.5, 0.5)
	menu.Position = UDim2.new(0.5, 0, 0, -menu.AbsoluteSize.Y)
	menu.Visible = true

	self._tween = TweenService:Create(
		menu,
		TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.5, 0.5) }
	)
	local conn = self._tween.Completed:Connect(function()
		if currentId ~= self._tweenId then return end
		self._tween = nil
	end)
	self._tween:Play()
	return conn
end

function Animator:Close()
	local menu = self._menu
	if not menu then return nil end
	if self._tween then
		self._tween:Cancel()
		self._tween = nil
	end

	self._tweenId += 1
	local currentId = self._tweenId

	self._tween = TweenService:Create(
		menu,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = UDim2.new(0.5, 0, 0, -menu.AbsoluteSize.Y) }
	)
	local conn = self._tween.Completed:Connect(function()
		if currentId ~= self._tweenId then return end
		menu.Visible = false
		if self._defaultAnchor then
			menu.AnchorPoint = self._defaultAnchor
		end
		if self._defaultPos then
			menu.Position = self._defaultPos
		end
		self._tween = nil
	end)
	self._tween:Play()
	return conn
end

return Animator
