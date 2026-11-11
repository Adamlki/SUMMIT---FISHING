--!nonstrict
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local ButtonClickSoundPlayer = require(script.Parent.Parent.Parent.ButtonClickSoundPlayer)
local Constants = require(script.Parent.Constants)
local Hotkeys = require(script.Parent.Hotkeys)
local Sizing = require(script.Parent.Sizing)

local MenuAnimator = {}

function MenuAnimator.initializeButton(state, openButton, child)
	if not child:IsA("ImageButton") then
		return
	end

	Hotkeys.setupVisibility(child)

	if child == openButton then
		child.Visible = true
		return
	end

	local stroke = child:FindFirstChildOfClass("UIStroke")
	state.leftButtons[child] = {
		OriginalSize = child.Size,
		OriginalImageTransparency = child.ImageTransparency,
		OriginalBackgroundTransparency = child.BackgroundTransparency,
		Stroke = stroke,
		OriginalStrokeTransparency = stroke and stroke.Transparency or nil,
	}
	child.Size = UDim2.fromScale(0, 0)
	child.ImageTransparency = 1
	child.BackgroundTransparency = 1
	child.Visible = false
	if stroke then
		stroke.Transparency = 1
	end
end

function MenuAnimator.getOrderedButtons(state, leftHolder)
	local list = {}
	for button in pairs(state.leftButtons) do
		if button.Parent == leftHolder then
			table.insert(list, button)
		end
	end
	table.sort(list, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	return list
end

function MenuAnimator.animateOpenButton(state, openButton)
	local isHovering = state.hovering and state.hovering[openButton] == true
	local targetSize = (state.isOpen or isHovering)
		and Sizing.scaleUDim2(state.openDefaultSize, Constants.OPEN_SHRINK_SCALE)
		or state.openDefaultSize
	openButton.Size = targetSize

	local shrinkTween = TweenService:Create(openButton, Constants.OPEN_SHRINK_TWEEN, {
		Size = Sizing.scaleUDim2(targetSize, Constants.OPEN_SHRINK_SCALE),
	})
	local bounceTween = TweenService:Create(openButton, Constants.OPEN_BOUNCE_TWEEN, {
		Size = targetSize,
		Rotation = 0,
	})

	shrinkTween:Play()
	shrinkTween.Completed:Connect(function()
		bounceTween:Play()
	end)
end

function MenuAnimator.setMenuOpen(state, leftHolder, isOpen)
	state.isOpen = isOpen
	if CollectionService:HasTag(state.openButton, "ButtonOpen") then
		task.delay(Constants.BUTTON_STAGGER, function()
			if state.isOpen == isOpen and state.openButton and state.openButton.Parent then
				ButtonClickSoundPlayer.play("ButtonOpen", state.openButton)
			end
		end)
	end

	for index, button in ipairs(MenuAnimator.getOrderedButtons(state, leftHolder)) do
		local data = state.leftButtons[button]
		task.delay(index * Constants.BUTTON_STAGGER, function()
			if not (button and button.Parent and data) then
				return
			end

			if isOpen then
				button.Visible = true
				TweenService:Create(button, Constants.APPEAR_TWEEN, {
					Size = data.OriginalSize,
					ImageTransparency = data.OriginalImageTransparency,
					BackgroundTransparency = data.OriginalBackgroundTransparency,
					Rotation = 0,
				}):Play()
				if data.Stroke then
					TweenService:Create(data.Stroke, Constants.APPEAR_TWEEN, {
						Transparency = data.OriginalStrokeTransparency or 0,
					}):Play()
				end
			else
				local tween = TweenService:Create(button, Constants.DISAPPEAR_TWEEN, {
					Size = UDim2.fromScale(0, 0),
					ImageTransparency = 1,
					BackgroundTransparency = 1,
					Rotation = 0,
				})
				if data.Stroke then
					TweenService:Create(data.Stroke, Constants.DISAPPEAR_TWEEN, {
						Transparency = 1,
					}):Play()
				end
				tween:Play()
				tween.Completed:Connect(function()
					if state.isOpen ~= true and button.Parent == leftHolder then
						button.Visible = false
					end
				end)
			end
		end)
	end
end

return MenuAnimator
