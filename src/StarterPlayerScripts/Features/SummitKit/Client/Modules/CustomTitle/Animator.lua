--!nonstrict
local TweenService = game:GetService("TweenService")

local Animator = {}
Animator.__index = Animator

local function offsetPos(pos, dyScale, dyOffset)
	return UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale + dyScale, pos.Y.Offset + dyOffset)
end

function Animator.new(root)
	local self = setmetatable({}, Animator)
	self._root = root
	self._shownPos = nil
	self._hiddenPos = nil
	self._defaultPos = root and root.Position or nil
	self._defaultAnchor = root and root.AnchorPoint or nil
	self._tween = nil
	self._tweenId = 0
	return self
end

function Animator:Open()
	local root = self._root
	if not root then return end
	if self._tween then
		self._tween:Cancel()
		self._tween = nil
	end
	self._tweenId += 1
	local id = self._tweenId
	if not self._shownPos then
		self._shownPos = root:GetAttribute("ShownPos") or UDim2.fromScale(0.5, 0.5)
	end
	if not self._hiddenPos then
		self._hiddenPos = root:GetAttribute("HiddenPos") or offsetPos(self._shownPos, -0.2, -200)
	end
	if self._hiddenPos == self._shownPos then
		self._hiddenPos = offsetPos(self._shownPos, -0.2, -200)
	end

	root.Visible = true
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = self._hiddenPos
	self._tween = TweenService:Create(
		root,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = self._shownPos or root.Position }
	)
	local conn = self._tween.Completed:Connect(function()
		if id ~= self._tweenId then return end
		self._tween = nil
	end)
	self._tween:Play()
	return conn
end

function Animator:Close()
	local root = self._root
	if not root then return end
	if self._tween then
		self._tween:Cancel()
		self._tween = nil
	end
	self._tweenId += 1
	local id = self._tweenId
	if not self._shownPos then
		self._shownPos = root:GetAttribute("ShownPos") or UDim2.fromScale(0.5, 0.5)
	end
	if not self._hiddenPos then
		self._hiddenPos = root:GetAttribute("HiddenPos") or offsetPos(self._shownPos, -0.2, -200)
	end
	if self._hiddenPos == self._shownPos then
		self._hiddenPos = offsetPos(self._shownPos, -0.2, -200)
	end

	self._tween = TweenService:Create(
		root,
		TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = self._hiddenPos or root.Position }
	)
	local conn = self._tween.Completed:Connect(function()
		if id ~= self._tweenId then return end
		root.Visible = false
		if self._defaultAnchor then
			root.AnchorPoint = self._defaultAnchor
		end
		if self._defaultPos then
			root.Position = self._defaultPos
		end
		self._tween = nil
	end)
	self._tween:Play()
	return conn
end

return Animator
