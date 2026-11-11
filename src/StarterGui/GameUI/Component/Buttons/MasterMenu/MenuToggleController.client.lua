--!strict
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local masterBtn = script.Parent :: ImageButton
local buttons = masterBtn.Parent :: Frame
local iconFrame = masterBtn:WaitForChild("IconFrame") :: Frame

local barTop = iconFrame:WaitForChild("BarTop") :: Frame
local barMid = iconFrame:WaitForChild("BarMid") :: Frame
local barBot = iconFrame:WaitForChild("BarBot") :: Frame

local topRight = buttons:WaitForChild("TopRight") :: Frame
local leftHolder = buttons:WaitForChild("LeftHolder") :: Frame
local topMid = buttons:WaitForChild("TopMid") :: Frame
local adminRight = buttons:WaitForChild("AdminRight") :: Frame

local isOpen = false
local tweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- Anchored closed position (collapses behind MasterMenu at {1.066, -95}, {0, 16})
local posClosed = UDim2.new(1.066, -95, 0, 16)

-- Open positions (Leftwards & Downwards)
-- MasterMenu: right at (1.066*W - 95), left at (1.066*W - 140)
-- TopRight (4 buttons @ 45px + 3 gaps @ 6px = 198px): right at (1.066*W - 146)
local posTopRightOpen = UDim2.new(1.066, -146, 0, 16)
-- LeftHolder (4 buttons @ 45px + 3 gaps @ 6px = 198px): right at (1.066*W - 350)
local posLeftHolderOpen = UDim2.new(1.066, -299, 0, 16)
-- TopMid (4 buttons @ 45px vertical + 3 gaps @ 6px = 198px): top at Y = 67 (16 + 45 + 6)
local posTopMidOpen = UDim2.new(1.066, -95, 0, 67)
-- AdminRight (2 buttons @ 45px vertical + 1 gap @ 6px = 96px): top at Y = 271 (67 + 198 + 6)
local posAdminRightOpen = UDim2.new(1.066, -95, 0, 271)

-- Initial ensure closed
buttons:SetAttribute("MenuOpen", false)
topRight.Position = posClosed
topRight.Visible = false
leftHolder.Position = posClosed
leftHolder.Visible = false
topMid.Position = posClosed
topMid.Visible = false
adminRight.Position = posClosed
adminRight.Visible = false

local function setOpen(targetOpen: boolean)
	if isOpen == targetOpen then return end
	isOpen = targetOpen
	buttons:SetAttribute("MenuOpen", isOpen)

	if isOpen then
		-- Open animation
		topRight.Position = posClosed
		leftHolder.Position = posClosed
		topMid.Position = posClosed
		adminRight.Position = posClosed

		topRight.Visible = true
		leftHolder.Visible = true
		topMid.Visible = true
		adminRight.Visible = true

		-- Tween all frames outward
		TweenService:Create(topRight, tweenInfo, {Position = posTopRightOpen}):Play()
		TweenService:Create(leftHolder, tweenInfo, {Position = posLeftHolderOpen}):Play()
		TweenService:Create(topMid, tweenInfo, {Position = posTopMidOpen}):Play()
		TweenService:Create(adminRight, tweenInfo, {Position = posAdminRightOpen}):Play()

		-- Tween icon morph (Hamburger -> X)
		TweenService:Create(barTop, tweenInfo, {Position = UDim2.new(0.5, 0, 0.5, 0), Rotation = 45}):Play()
		TweenService:Create(barMid, tweenInfo, {BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 2)}):Play()
		TweenService:Create(barBot, tweenInfo, {Position = UDim2.new(0.5, 0, 0.5, 0), Rotation = -45}):Play()

		-- Master button highlight
		TweenService:Create(masterBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(36, 52, 78)}):Play()
	else
		-- Close animation
		local tw1 = TweenService:Create(topRight, tweenInfo, {Position = posClosed})
		local tw2 = TweenService:Create(leftHolder, tweenInfo, {Position = posClosed})
		local tw3 = TweenService:Create(topMid, tweenInfo, {Position = posClosed})
		local tw4 = TweenService:Create(adminRight, tweenInfo, {Position = posClosed})

		tw1:Play()
		tw2:Play()
		tw3:Play()
		tw4:Play()

		-- Tween icon morph (X -> Hamburger)
		TweenService:Create(barTop, tweenInfo, {Position = UDim2.new(0.5, 0, 0.15, 0), Rotation = 0}):Play()
		TweenService:Create(barMid, tweenInfo, {BackgroundTransparency = 0, Size = UDim2.new(1, 0, 0, 2)}):Play()
		TweenService:Create(barBot, tweenInfo, {Position = UDim2.new(0.5, 0, 0.85, 0), Rotation = 0}):Play()

		-- Master button default tint
		TweenService:Create(masterBtn, tweenInfo, {BackgroundColor3 = Color3.fromRGB(20, 24, 34)}):Play()

		task.delay(0.28, function()
			if not isOpen then
				topRight.Visible = false
				leftHolder.Visible = false
				topMid.Visible = false
				adminRight.Visible = false
			end
		end)
	end
end

masterBtn.MouseButton1Click:Connect(function()
	setOpen(not isOpen)
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.M then
		setOpen(not isOpen)
	end
end)
