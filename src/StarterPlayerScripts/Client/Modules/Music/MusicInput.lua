--!nonstrict
local UserInputService = game:GetService("UserInputService")

local Input = {}

local function bindButton(janitor, button, onClick)
	if not button then return end
	local debounce = false
	local function trigger()
		if debounce then return end
		debounce = true
		task.delay(0.08, function() debounce = false end)
		onClick()
	end

	if button:IsA("GuiButton") then
		button.Active = true
		janitor:Add(button.Activated:Connect(trigger), "Disconnect")
	else
		button.Active = true
		janitor:Add(button.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				trigger()
			end
		end), "Disconnect")
	end
end

function Input.bindButton(janitor, button, onClick)
	bindButton(janitor, button, onClick)
end

function Input.bindVolumeDrag(janitor, volumeBar, volumeFill, onDragStart, onDragMove, onDragEnd)
	local function handleInput(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			onDragStart()
		end
	end

	if volumeBar then
		janitor:Add(volumeBar.InputBegan:Connect(handleInput), "Disconnect")
	end
	if volumeFill then
		janitor:Add(volumeFill.InputBegan:Connect(handleInput), "Disconnect")
	end
	janitor:Add(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			onDragEnd()
		end
	end), "Disconnect")
	janitor:Add(UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			onDragMove()
		end
	end), "Disconnect")
end

function Input.getPointerX()
	return UserInputService:GetMouseLocation().X
end

return Input
