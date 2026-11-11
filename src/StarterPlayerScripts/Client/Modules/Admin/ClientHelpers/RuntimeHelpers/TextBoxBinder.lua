--!nonstrict
local UserInputService = game:GetService("UserInputService")

local TextBoxBinder = {}

function TextBoxBinder.bindTextBox(runtime, box)
	if not box or not box:IsA("TextBox") then
		return
	end

	box.ClearTextOnFocus = false
	box.TextEditable = true
	box.Active = true

	runtime._janitor:Add(box.InputBegan:Connect(function(input)
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
	end), "Disconnect")
end

function TextBoxBinder.bindAll(runtime)
	local refs = runtime._refs
	local boxes = {}

	local function push(box)
		if box and box:IsA("TextBox") then
			table.insert(boxes, box)
		end
	end

	push(refs.Pages.Announce and refs.Pages.Announce.InputText)
	push(refs.Pages.Event and refs.Pages.Event.DurationText)
	push(refs.Pages.Event and refs.Pages.Event.ValueText)
	push(refs.Pages.Manager and refs.Pages.Manager.ValueText)
	push(refs.Pages.Manager and refs.Pages.Manager.InputText)

	for _, box in ipairs(boxes) do
		TextBoxBinder.bindTextBox(runtime, box)
	end
end

return TextBoxBinder
