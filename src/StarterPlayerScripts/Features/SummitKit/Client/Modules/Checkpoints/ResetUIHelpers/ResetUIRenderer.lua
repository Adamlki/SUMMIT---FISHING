--!nonstrict
local TweenService = game:GetService("TweenService")

local ResetUIRenderer = {}

local activeTween = nil
local activeTweenId = 0

local TWEEN_IN = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_OUT = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local function getOrCreateScale(menuFrame: GuiObject): UIScale
	local scale = menuFrame:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "ModalScale"
		scale.Scale = 1.0
		scale.Parent = menuFrame
	end
	return scale
end

function ResetUIRenderer.initHidden(refs)
	if not refs or not refs.menuFrame then return end
	local menuFrame = refs.menuFrame
	menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	menuFrame.Position = UDim2.fromScale(0.5, 0.5)
	local scale = getOrCreateScale(menuFrame)
	scale.Scale = 1.0
	menuFrame.Visible = false
end

function ResetUIRenderer.setVisible(refs, state: boolean, instant: boolean?)
	if not refs or not refs.menuFrame then return end
	local menuFrame = refs.menuFrame
	local scale = getOrCreateScale(menuFrame)

	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end

	activeTweenId += 1
	local currentId = activeTweenId

	menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	menuFrame.Position = UDim2.fromScale(0.5, 0.5)

	if state then
		menuFrame.Visible = true
		if instant then
			scale.Scale = 1.0
		else
			scale.Scale = 0.88
			activeTween = TweenService:Create(scale, TWEEN_IN, { Scale = 1.0 })
			activeTween:Play()
		end
	else
		if instant then
			menuFrame.Visible = false
			scale.Scale = 1.0
		else
			activeTween = TweenService:Create(scale, TWEEN_OUT, { Scale = 0.88 })
			activeTween.Completed:Connect(function()
				if currentId == activeTweenId then
					menuFrame.Visible = false
					scale.Scale = 1.0
				end
			end)
			activeTween:Play()
		end
	end
end

function ResetUIRenderer.toggle(refs)
	if not refs or not refs.menuFrame then return end
	local isCurrentlyOpen = refs.menuFrame.Visible
	ResetUIRenderer.setVisible(refs, not isCurrentlyOpen, false)
end

return ResetUIRenderer
