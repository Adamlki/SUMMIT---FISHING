-- StarterGui/EventNotificationGui/NotifyController
-- Unified Toast Notification Controller (Server & Client)

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. GUI References
local screenGui = script.Parent
local notifyFrame = screenGui:WaitForChild("NotifyFrame")
local messageLabel = notifyFrame:WaitForChild("Message")
local iconImage = notifyFrame:FindFirstChild("Icon")

-- 2. Event References
local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local showNotificationEvent = FishingSystem:WaitForChild("ShowNotification")
local clientNotificationEvent = FishingSystem:WaitForChild("ClientNotification")

-- State variables
local currentTween = nil
local currentWait = nil

local function showNotification(message, durationFromServer, textColor, iconId)
	if not notifyFrame or not messageLabel then return end

	local duration = durationFromServer or 3.5
	textColor = textColor or Color3.fromRGB(255, 255, 255)

	-- Cancel previous tween / timer cleanly
	if currentTween then
		currentTween:Cancel()
		currentTween = nil
	end
	if currentWait then
		task.cancel(currentWait)
		currentWait = nil
	end

	-- Configure contents
	messageLabel.Text = tostring(message or "")
	messageLabel.TextColor3 = textColor

	if iconImage then
		if iconId and iconId ~= "" then
			iconImage.Image = iconId
			iconImage.Visible = true
		else
			iconImage.Image = ""
			iconImage.Visible = false
		end
	end

	notifyFrame.Visible = true
	notifyFrame.Position = UDim2.new(0.5, 0, -0.15, 0)

	-- Animate In
	local tweenInfoIn = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	currentTween = TweenService:Create(notifyFrame, tweenInfoIn, {Position = UDim2.new(0.5, 0, 0.05, 0)})
	currentTween:Play()

	-- Animate Out after duration
	currentWait = task.delay(duration, function()
		local tweenInfoOut = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		currentTween = TweenService:Create(notifyFrame, tweenInfoOut, {Position = UDim2.new(0.5, 0, -0.15, 0)})
		currentTween:Play()

		currentTween.Completed:Connect(function()
			notifyFrame.Visible = false
			if iconImage then iconImage.Visible = false end
			currentTween = nil
			currentWait = nil
		end)
	end)
end

-- 3. Connections
showNotificationEvent.OnClientEvent:Connect(showNotification)
clientNotificationEvent.Event:Connect(showNotification)
