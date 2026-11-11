--!nonstrict
local TweenService = game:GetService("TweenService")

local Constants = require(script.Parent.Constants)
local Sizing = require(script.Parent.Sizing)

local HoverBinder = {}

function HoverBinder.bind(state, janitor, button, getBaseSize, hoverScale)
	if not button:IsA("GuiButton") then
		return
	end

	state.hoveredButtons = state.hoveredButtons or {}
	if state.hoveredButtons[button] then
		return
	end
	state.hovering = state.hovering or {}

	local currentTween
	local function tweenTo(size, rotation)
		if currentTween then
			currentTween:Cancel()
		end
		currentTween = TweenService:Create(button, Constants.HOVER_TWEEN, {
			Size = size,
			Rotation = rotation,
		})
		currentTween:Play()
	end

	janitor:Add(button.MouseEnter:Connect(function()
		state.hovering[button] = true
		local baseSize = getBaseSize()
		tweenTo(Sizing.scaleUDim2(baseSize, hoverScale or Constants.HOVER_SCALE_DEFAULT), Constants.HOVER_ROTATION)
	end), "Disconnect")

	janitor:Add(button.MouseLeave:Connect(function()
		state.hovering[button] = false
		tweenTo(getBaseSize(), 0)
	end), "Disconnect")

	state.hoveredButtons[button] = true
end

return HoverBinder
