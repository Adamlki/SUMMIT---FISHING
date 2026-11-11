--!nonstrict
local UserInputService = game:GetService("UserInputService")

local TextBoxBinder = {}

local function bindMobileFocus(box)
	if not box or not box:IsA("TextBox") then
		return
	end

	box.ClearTextOnFocus = false
	box.TextEditable = true
	box.Active = true

	box.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if UserInputService:GetFocusedTextBox() == box then
			return
		end
		task.defer(function()
			if box.Parent and box.Visible and box.AbsoluteSize.X > 0 and box.AbsoluteSize.Y > 0 then
				box:CaptureFocus()
			end
		end)
	end)
end

function TextBoxBinder.bind(box, onChange)
	if not box then
		return
	end
	bindMobileFocus(box)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		onChange(box.Text)
	end)
end

return TextBoxBinder
