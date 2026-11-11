--!nonstrict
local Select = {}

function Select.applySelectVisual(button, selected)
	if not button then return end
	local selectedColor = button:GetAttribute("SelectedColor")
	local defaultColor = button:GetAttribute("DefaultColor")
	local color = selected and selectedColor or defaultColor
	if not color or typeof(color) ~= "Color3" then
		color = selected and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 255, 255)
	end

	if button.BackgroundTransparency < 1 then
		button.BackgroundColor3 = color
	else
		local bg = button:FindFirstChild("Background", true)
		if bg and bg:IsA("Frame") and bg.BackgroundTransparency < 1 then
			bg.BackgroundColor3 = color
		end
	end
end

function Select.makeSingleSelect(applyFn)
	local state = {selected = nil}
	return function(button)
		if state.selected and state.selected.Parent then
			applyFn(state.selected, false)
		end
		state.selected = button
		if button then
			applyFn(button, true)
		end
	end
end

return Select
