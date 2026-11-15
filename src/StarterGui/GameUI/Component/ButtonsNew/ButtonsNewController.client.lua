--!strict
-- Slide toggles for ButtonsNew: MenuAtas (up/down) and MenuKiri (left/right).
-- Button actions (Shop, Index, menus, Freecam, Title) stay owned by their controllers.
local TweenService = game:GetService("TweenService")

local buttons = script.Parent
local top = buttons:WaitForChild("MenuAtas")
local topFrame = top:WaitForChild("Frame")
local topToggle = top:WaitForChild("ToggleSlideBtn")
local left = buttons:WaitForChild("MenuKiri")
local leftFrame = left:WaitForChild("FrameBtn")
local leftToggle = left:WaitForChild("ToggleSlideBtn")
local right = buttons:WaitForChild("MenuKanan")
local rewards = buttons:WaitForChild("Rewards")

local TWEEN = TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local DEBOUNCE = 0.15

local topShown = topFrame.Position
local topHidden = UDim2.new(
	topShown.X.Scale,
	topShown.X.Offset,
	0,
	-(topFrame.Size.Y.Offset + 16)
)

local leftShown = leftFrame.Position
local leftHidden = UDim2.new(
	leftShown.X.Scale,
	leftShown.X.Offset - leftFrame.Size.X.Offset - 16,
	leftShown.Y.Scale,
	leftShown.Y.Offset
)
local leftToggleShown = leftToggle.Position
local leftToggleHidden = UDim2.new(
	0,
	leftToggle.Size.X.Offset,
	leftToggleShown.Y.Scale,
	leftToggleShown.Y.Offset
)

local topRotation = topToggle.Rotation
local leftRotation = leftToggle.Rotation
local topOpen = true
local leftOpen = true
local topTween: Tween? = nil
local leftTween: Tween? = nil
local lastTop = 0
local lastLeft = 0

local rightShown = right.Position
local rewardsShown = rewards.Position
local function offscreenX(frame: GuiObject): UDim2
	local shown = frame.Position
	return UDim2.new(shown.X.Scale, shown.X.Offset + frame.Size.X.Offset + 32, shown.Y.Scale, shown.Y.Offset)
end
local rightHidden = offscreenX(right)
local rewardsHidden = offscreenX(rewards)
local sideState: { [GuiObject]: { open: boolean, tween: Tween? } } = {}

local function slideTop(open: boolean)
	if topOpen == open then
		return
	end
	topOpen = open
	if topTween then
		topTween:Cancel()
	end
	topFrame.Visible = true
	topTween = TweenService:Create(topFrame, TWEEN, { Position = if open then topShown else topHidden })
	topTween:Play()
	TweenService:Create(topToggle, TWEEN, { Rotation = if open then topRotation else topRotation + 180 }):Play()
	if not open then
		topTween.Completed:Connect(function()
			if not topOpen then
				topFrame.Visible = false
			end
		end)
	end
end

local function slideLeft(open: boolean)
	if leftOpen == open then
		return
	end
	leftOpen = open
	if leftTween then
		leftTween:Cancel()
	end
	leftFrame.Visible = true
	leftTween = TweenService:Create(leftFrame, TWEEN, { Position = if open then leftShown else leftHidden })
	leftTween:Play()
	TweenService:Create(leftToggle, TWEEN, { Position = if open then leftToggleShown else leftToggleHidden, Rotation = if open then leftRotation else leftRotation + 180 }):Play()
	if not open then
		leftTween.Completed:Connect(function()
			if not leftOpen then
				leftFrame.Visible = false
			end
		end)
	end
end

topToggle.Activated:Connect(function()
	local now = os.clock()
	if now - lastTop < DEBOUNCE then
		return
	end
	lastTop = now
	slideTop(not topOpen)
end)

leftToggle.Activated:Connect(function()
	local now = os.clock()
	if now - lastLeft < DEBOUNCE then
		return
	end
	lastLeft = now
	slideLeft(not leftOpen)
end)

-- Focus mode: dipakai Panel.lua saat sebuah panel dibuka, biar HUD tidak
-- menutupi / menumpuk dengan panel.
local function slideSide(frame: GuiObject, shownPos: UDim2, hiddenPos: UDim2, open: boolean)
	local state = sideState[frame]
	if not state then
		state = { open = true, tween = nil }
		sideState[frame] = state
	end
	if state.open == open then
		return
	end
	state.open = open
	if state.tween then
		state.tween:Cancel()
	end
	frame.Visible = true
	state.tween = TweenService:Create(frame, TWEEN, { Position = if open then shownPos else hiddenPos })
	state.tween:Play()
	if not open then
		state.tween.Completed:Connect(function()
			if not state.open then
				frame.Visible = false
			end
		end)
	end
end

local focused = false
local topWasOpen = true
local leftWasOpen = true

local function setFocus(value: boolean)
	if focused == value then
		return
	end
	focused = value
	if value then
		topWasOpen = topOpen
		leftWasOpen = leftOpen
		topToggle.Visible = false
		leftToggle.Visible = false
		slideTop(false)
		slideLeft(false)
		slideSide(right, rightShown, rightHidden, false)
		slideSide(rewards, rewardsShown, rewardsHidden, false)
	else
		topToggle.Visible = true
		leftToggle.Visible = true
		slideTop(topWasOpen)
		slideLeft(leftWasOpen)
		slideSide(right, rightShown, rightHidden, true)
		slideSide(rewards, rewardsShown, rewardsHidden, true)
	end
end

buttons:GetAttributeChangedSignal("Focus"):Connect(function()
	setFocus(buttons:GetAttribute("Focus") == true)
end)
if buttons:GetAttribute("Focus") == true then
	setFocus(true)
end
