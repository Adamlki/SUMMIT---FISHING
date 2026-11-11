--!nonstrict
local UserInputService = game:GetService("UserInputService")

local Input = {}

local function clamp01(x)
	if x < 0 then
		return 0
	end
	if x > 1 then
		return 1
	end
	return x
end

local function adjustColor(color, factor)
	return Color3.new(
		clamp01(color.R * factor),
		clamp01(color.G * factor),
		clamp01(color.B * factor)
	)
end

local function flashButton(button)
	if not button then
		return
	end
	if button:GetAttribute("NoClickFlash") == true then
		return
	end

	local hasBg = button.BackgroundTransparency < 1
	local hasImg = button:IsA("ImageButton") and button.ImageTransparency < 1

	local originalBg = hasBg and button.BackgroundColor3 or nil
	local originalImg = hasImg and button.ImageColor3 or nil

	if hasBg then
		button.BackgroundColor3 = adjustColor(button.BackgroundColor3, 0.85)
	end
	if hasImg then
		button.ImageColor3 = adjustColor(button.ImageColor3, 0.85)
	end

	task.delay(0.12, function()
		if button and button.Parent then
			if originalBg then
				button.BackgroundColor3 = originalBg
			end
			if originalImg then
				button.ImageColor3 = originalImg
			end
		end
	end)
end

local function bindButton(janitor, button, onClick)
	if not button then
		return
	end
	if button:IsA("GuiButton") then
		button.Active = true
		janitor:Add(button.Activated:Connect(function()
			flashButton(button)
			onClick()
		end), "Disconnect")
	else
		button.Active = true
		janitor:Add(button.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				flashButton(button)
				onClick()
			end
		end), "Disconnect")
	end
end

function Input.bindButton(janitor, button, onClick)
	bindButton(janitor, button, onClick)
end

function Input.bindToggle(janitor, toggleBtn, onToggle)
	bindButton(janitor, toggleBtn, onToggle)
end

function Input.bindTabToggle(janitor, onToggle)
	janitor:Add(UserInputService.InputBegan:Connect(function(input, gp)
		if gp or UserInputService:GetFocusedTextBox() then return end
		if input.KeyCode == Enum.KeyCode.F2 then
			onToggle()
		end
	end), "Disconnect")
end

return Input
