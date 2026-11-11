--!nonstrict
local UserInputService = game:GetService("UserInputService")

local FreecamInput = {}
local DESKTOP_MOUSE_DELTA_SCALE = 0.28
local TOUCH_DELTA_SCALE = 0.02

function FreecamInput.zero(runtime)
	for key in pairs(runtime._keyboard) do
		runtime._keyboard[key] = 0
	end

	runtime._mouseDelta = Vector2.zero
	runtime._mouseWheel = 0
	runtime._mobileZoomIn = false
	runtime._mobileZoomOut = false
	runtime._touchPanId = nil
	runtime._touchPanLast = nil
	runtime._navSpeed = 1
end

function FreecamInput.getNavVelocity(runtime, dt, navAdjustSpeed, navShiftMultiplier)
	runtime._navSpeed = math.clamp(runtime._navSpeed + dt * (runtime._keyboard.Up - runtime._keyboard.Down) * navAdjustSpeed, 0.01, 4)

	local base = Vector3.new(
		runtime._keyboard.D - runtime._keyboard.A,
		runtime._keyboard.E - runtime._keyboard.Q,
		runtime._keyboard.S - runtime._keyboard.W
	)

	local shiftHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
	local speedMul = shiftHeld and navShiftMultiplier or 1

	return base * (runtime._navSpeed * speedMul)
end

function FreecamInput.getPanDelta(runtime)
	local delta = runtime._mouseDelta
	runtime._mouseDelta = Vector2.zero
	return delta
end

function FreecamInput.getFovDelta(runtime, dt)
	local wheel = runtime._mouseWheel
	runtime._mouseWheel = 0

	local hold = 0
	if runtime._mobileZoomIn then
		hold -= 1.6 * dt
	end
	if runtime._mobileZoomOut then
		hold += 1.6 * dt
	end

	return wheel + hold
end

function FreecamInput.startCapture(runtime)
	runtime._captureJanitor:Cleanup()

	runtime._captureJanitor:Add(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not runtime._active then
			return
		end
		if input.UserInputType == Enum.UserInputType.Touch and not gameProcessed then
			runtime._touchPanId = input
			runtime._touchPanLast = input.Position
			return
		end
		if gameProcessed then
			return
		end

		local key = input.KeyCode.Name
		if runtime._keyboard[key] ~= nil then
			runtime._keyboard[key] = 1
		end
	end), "Disconnect")

	runtime._captureJanitor:Add(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and input == runtime._touchPanId then
			runtime._touchPanId = nil
			runtime._touchPanLast = nil
			return
		end

		local key = input.KeyCode.Name
		if runtime._keyboard[key] ~= nil then
			runtime._keyboard[key] = 0
		end
	end), "Disconnect")

	runtime._captureJanitor:Add(UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if not runtime._active then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			runtime._mouseDelta += Vector2.new(-input.Delta.Y, -input.Delta.X) * DESKTOP_MOUSE_DELTA_SCALE
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			runtime._mouseWheel -= input.Position.Z
			return
		end
		if input.UserInputType == Enum.UserInputType.Touch and input == runtime._touchPanId and runtime._touchPanLast and not gameProcessed then
			local delta = input.Position - runtime._touchPanLast
			runtime._touchPanLast = input.Position
			runtime._mouseDelta += Vector2.new(-delta.Y, -delta.X) * TOUCH_DELTA_SCALE
		end
	end), "Disconnect")
end

function FreecamInput.stopCapture(runtime)
	runtime._captureJanitor:Cleanup()
	FreecamInput.zero(runtime)
end

function FreecamInput.bindHoldButton(janitor, button, onPress, onRelease)
	if not button then
		return
	end

	janitor:Add(button.MouseButton1Down:Connect(onPress), "Disconnect")
	janitor:Add(button.MouseButton1Up:Connect(onRelease), "Disconnect")
	janitor:Add(button.MouseLeave:Connect(onRelease), "Disconnect")
end

return FreecamInput
