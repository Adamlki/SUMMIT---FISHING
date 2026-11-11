--!nonstrict
local UserInputService = game:GetService("UserInputService")

local DragBinder = {}

function DragBinder.bind(runtime, handle)
	local root = runtime._refs and runtime._refs.Root
	local dragJanitor = runtime._dragJanitor
	if not handle or not root or not dragJanitor then
		return
	end

	dragJanitor:Cleanup()
	if handle:IsA("GuiObject") then
		handle.Active = true
	end
	if root:IsA("GuiObject") then
		root.Active = true
	end

	local inputChanged
	local inputEnded
	local screenGui = root:FindFirstAncestorOfClass("ScreenGui")
	local leadFrame = Instance.new("Frame")
	leadFrame.AnchorPoint = root.AnchorPoint
	leadFrame.Position = root.Position
	leadFrame.Size = root.Size
	leadFrame.Name = "Lead " .. root.Name
	leadFrame.Visible = false
	leadFrame.Parent = root.Parent
	dragJanitor:Add(leadFrame, "Destroy")

	local function getBoundsRelations(guiObject)
		if not screenGui then
			return true, {}
		end
		local bounds = screenGui.AbsoluteSize
		local topLeft = screenGui.IgnoreGuiInset and guiObject.AbsolutePosition + Vector2.new(0, 36) or guiObject.AbsolutePosition
		local bottomRight = topLeft + guiObject.AbsoluteSize
		local boundRelations = {
			Top = topLeft.Y < 0 and math.abs(topLeft.Y) or nil,
			Left = topLeft.X < 0 and math.abs(topLeft.X) or nil,
			Right = bottomRight.X > bounds.X and math.abs(bottomRight.X - bounds.X) or nil,
			Bottom = bottomRight.Y > bounds.Y and math.abs(bottomRight.Y - bounds.Y) or nil,
		}
		local inBounds = not boundRelations.Top
			and not boundRelations.Bottom
			and not boundRelations.Left
			and not boundRelations.Right
		return inBounds, boundRelations
	end

	dragJanitor:Add(handle.InputBegan:Connect(function(inputObject)
		if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1
			and inputObject.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local lastMousePosition = UserInputService:GetMouseLocation()
		local goalPosition = root.Position

		if inputChanged then
			inputChanged:Disconnect()
		end
		if inputEnded then
			inputEnded:Disconnect()
		end

		inputChanged = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				local currentMousePosition = UserInputService:GetMouseLocation()
				local mouseDelta = currentMousePosition - lastMousePosition

				goalPosition += UDim2.fromOffset(mouseDelta.X, mouseDelta.Y)
				leadFrame.Position = goalPosition

				local isInBounds, relations = getBoundsRelations(leadFrame)
				if not isInBounds then
					local x = (relations.Left or 0) - (relations.Right or 0)
					local y = (relations.Top or 0) - (relations.Bottom or 0)
					goalPosition += UDim2.fromOffset(x, y)
				end

				root.Position = goalPosition
				lastMousePosition = currentMousePosition
			end
		end)

		inputEnded = handle.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				if inputChanged then
					inputChanged:Disconnect()
				end
				if inputEnded then
					inputEnded:Disconnect()
				end
				inputChanged = nil
				inputEnded = nil
			end
		end)
	end), "Disconnect")
end

return DragBinder
