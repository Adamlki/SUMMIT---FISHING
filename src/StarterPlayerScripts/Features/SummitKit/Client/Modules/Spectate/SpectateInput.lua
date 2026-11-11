--!nonstrict
local Input = {}

function Input.bindButton(janitor, button, onClick)
	if not button then return end
	if button:IsA("GuiButton") then
		janitor:Add(button.Activated:Connect(onClick), "Disconnect")
	else
		button.Active = true
		janitor:Add(button.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				onClick()
			end
		end), "Disconnect")
	end
end

return Input
