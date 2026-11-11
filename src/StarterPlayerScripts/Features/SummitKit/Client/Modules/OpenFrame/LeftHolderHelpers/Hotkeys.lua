--!nonstrict
local UserInputService = game:GetService("UserInputService")

local Hotkeys = {}

local function isMobileDevice()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function findContainer(button)
	if not button then
		return nil
	end

	return button:FindFirstChild("Hotkeys") or button:FindFirstChild("Hotkey")
end

function Hotkeys.setupVisibility(button)
	local hotkeys = findContainer(button)
	if hotkeys and hotkeys:IsA("GuiObject") then
		hotkeys.Visible = not isMobileDevice()
	end
end

function Hotkeys.setText(container, value)
	if not container then
		return
	end

	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
			descendant.Text = value
		end
	end
end

function Hotkeys.getContainer(button)
	return findContainer(button)
end

return Hotkeys
