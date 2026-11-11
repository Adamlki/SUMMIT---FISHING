local MobileCameraFramework = {}
local players = game:GetService("Players")
local runservice = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")
local uis = game:GetService("UserInputService")
local player = players.LocalPlayer
local camera = workspace.CurrentCamera
local button = script.Parent

-- Variabel karakter (akan di-update setiap respawn)
local character
local root
local humanoid

local function setupCharacter(newCharacter)
	character = newCharacter
	root = character:WaitForChild("HumanoidRootPart")
	humanoid = character:WaitForChild("Humanoid")
end

-- Setup awal
setupCharacter(player.Character or player.CharacterAdded:Wait())

-- Update setiap respawn
player.CharacterAdded:Connect(function(newCharacter)
	setupCharacter(newCharacter)

	-- Reset shift lock saat respawn
	if active and typeof(active) ~= "boolean" then
		pcall(function()
			active:Disconnect()
		end)
	end
	active = false
	UpdateImage("OFF")
end)

-- Visibility (mobile only)
local ismobile = uis.TouchEnabled
button.Visible = ismobile

local states = {
	OFF = "rbxasset://textures/ui/mouseLock_off@2x.png",
	ON = "rbxasset://textures/ui/mouseLock_on@2x.png"
}
local MAX_LENGTH = 900000
local active = false
local ENABLED_OFFSET = CFrame.new(1.7, 0, 0)
local DISABLED_OFFSET = CFrame.new(-1.7, 0, 0)

function UpdateImage(STATE)
	button.Image = states[STATE]
end

local function UpdateAutoRotate(BOOL)
	if humanoid then
		humanoid.AutoRotate = BOOL
	end
end

local function GetUpdatedCameraCFrame()
	return CFrame.new(
		root.Position,
		Vector3.new(
			camera.CFrame.LookVector.X * MAX_LENGTH,
			root.Position.Y,
			camera.CFrame.LookVector.Z * MAX_LENGTH
		)
	)
end

local function EnableShiftlock()
	if not root or not root.Parent then return end
	if not humanoid or not humanoid.Parent then return end
	UpdateAutoRotate(false)
	UpdateImage("ON")
	root.CFrame = GetUpdatedCameraCFrame()
	camera.CFrame = camera.CFrame * ENABLED_OFFSET
end

local function DisableShiftlock()
	UpdateAutoRotate(true)
	UpdateImage("OFF")
	camera.CFrame = camera.CFrame * DISABLED_OFFSET
	pcall(function()
		if active and typeof(active) ~= "boolean" then
			active:Disconnect()
		end
		active = nil
	end)
end

UpdateImage("OFF")
active = false

function ShiftLock()
	if not active then
		active = runservice.RenderStepped:Connect(function()
			EnableShiftlock()
		end)
	else
		DisableShiftlock()
	end
end

CAS:BindAction("ShiftLOCK", ShiftLock, false)
CAS:SetPosition("ShiftLOCK", UDim2.new(0.8, 0, 0.8, 0))

button.MouseButton1Click:Connect(function()
	ShiftLock()
end)

return MobileCameraFramework
