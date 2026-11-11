--!nonstrict
local UserInputService = game:GetService("UserInputService")

local Constants = require(script.Parent.LeftHolderHelpers.Constants)
local Hotkeys = require(script.Parent.LeftHolderHelpers.Hotkeys)
local HoverBinder = require(script.Parent.LeftHolderHelpers.HoverBinder)
local MenuAnimator = require(script.Parent.LeftHolderHelpers.MenuAnimator)
local Sizing = require(script.Parent.LeftHolderHelpers.Sizing)

local LeftHolderMenu = {}

function LeftHolderMenu.setup(gameUI, janitor)
	local component = gameUI:FindFirstChild("Component")
	local buttons = component and component:FindFirstChild("Buttons")
	local leftHolder = buttons and buttons:FindFirstChild("LeftHolder")
	if not leftHolder then
		return nil
	end

	local openButton = leftHolder:FindFirstChild("Open")
	if not (openButton and openButton:IsA("ImageButton")) then
		return nil
	end

	local state = {
		leftButtons = {},
		hoveredButtons = {},
		isOpen = false,
		openButton = openButton,
		openDefaultSize = openButton.Size,
	}

	Hotkeys.setupVisibility(openButton)
	Hotkeys.setText(openButton:FindFirstChild("Hotkeys"), "M")
	HoverBinder.bind(state, janitor, openButton, function()
		if state.isOpen then
			return Sizing.scaleUDim2(state.openDefaultSize, Constants.OPEN_SHRINK_SCALE)
		end
		return state.openDefaultSize
	end, Constants.HOVER_SCALE_OPEN)

	for _, child in ipairs(leftHolder:GetChildren()) do
		MenuAnimator.initializeButton(state, openButton, child)
		if child:IsA("GuiButton") and child ~= openButton then
			HoverBinder.bind(state, janitor, child, function()
				local data = state.leftButtons[child]
				return (data and data.OriginalSize) or child.Size
			end, Constants.HOVER_SCALE_DEFAULT)
		end
	end

	local function toggleMenu()
		MenuAnimator.setMenuOpen(state, leftHolder, not state.isOpen)
		MenuAnimator.animateOpenButton(state, openButton)
	end

	janitor:Add(openButton.MouseButton1Click:Connect(toggleMenu), "Disconnect")

	janitor:Add(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.M then
			toggleMenu()
		end
	end), "Disconnect")

	janitor:Add(leftHolder.ChildAdded:Connect(function(child)
		MenuAnimator.initializeButton(state, openButton, child)
		if child:IsA("GuiButton") and child ~= openButton then
			HoverBinder.bind(state, janitor, child, function()
				local data = state.leftButtons[child]
				return (data and data.OriginalSize) or child.Size
			end, Constants.HOVER_SCALE_DEFAULT)
		end
	end), "Disconnect")

	return state
end

return LeftHolderMenu
