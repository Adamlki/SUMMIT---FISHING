--!strict
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

-- 1. Remove default Roblox loading screen immediately
ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 2. Build Clean, Simple Loading Screen GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "IntroLoadingGui"
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999999
screenGui.ResetOnSpawn = false

local canvas = Instance.new("CanvasGroup")
canvas.Name = "MainCanvas"
canvas.Size = UDim2.fromScale(1, 1)
canvas.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
canvas.BorderSizePixel = 0
canvas.Parent = screenGui

local center = Instance.new("Frame")
center.Name = "Center"
center.AnchorPoint = Vector2.new(0.5, 0.5)
center.Position = UDim2.fromScale(0.5, 0.5)
center.Size = UDim2.new(0, 380, 0, 270)
center.BackgroundTransparency = 1
center.Parent = canvas

-- Game Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 36)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "SUMMIT & FISHING"
title.TextSize = 24
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = center

-- Subtitle
local sub = Instance.new("TextLabel")
sub.Name = "Sub"
sub.Size = UDim2.new(1, 0, 0, 20)
sub.Position = UDim2.new(0, 0, 0, 38)
sub.BackgroundTransparency = 1
sub.Font = Enum.Font.GothamMedium
sub.Text = "PILIH MUSIK"
sub.TextSize = 12
sub.TextColor3 = Color3.fromRGB(120, 135, 160)
sub.Parent = center

-- 2x2 Music Options Grid
local grid = Instance.new("Frame")
grid.Name = "Grid"
grid.Position = UDim2.new(0, 0, 0, 72)
grid.Size = UDim2.new(1, 0, 0, 110)
grid.BackgroundTransparency = 1
grid.Parent = center

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.new(0.5, -6, 0, 48)
layout.CellPadding = UDim2.new(0, 12, 0, 12)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Parent = grid

local options = {
	{ key = "Indo", label = "🇮🇩  Indonesia" },
	{ key = "Jawa", label = "🪕  Jawa" },
	{ key = "Inggris", label = "🌍  English" },
	{ key = "None", label = "🔇  Tanpa Musik" },
}

local selectedKey = "Indo"
local buttons = {}

local CLICK_SOUND = "rbxassetid://6895079853"
local START_SOUND = "rbxassetid://6895079853"

local function playSfx(id: string, vol: number?)
	task.spawn(function()
		pcall(function()
			local s = Instance.new("Sound")
			s.SoundId = id
			s.Volume = vol or 0.35
			s.Parent = SoundService
			s:Play()
			s.Ended:Connect(function() s:Destroy() end)
		end)
	end)
end

local function updateButtons()
	for key, btn in pairs(buttons) do
		local isSel = (key == selectedKey)
		btn.BackgroundColor3 = isSel and Color3.fromRGB(0, 125, 235) or Color3.fromRGB(22, 26, 36)
		btn.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(175, 185, 205)
		local stroke = btn:FindFirstChild("Stroke") :: UIStroke?
		if stroke then
			stroke.Color = isSel and Color3.fromRGB(80, 185, 255) or Color3.fromRGB(40, 48, 64)
			stroke.Thickness = isSel and 1.5 or 1
		end
	end
end

for _, opt in ipairs(options) do
	local btn = Instance.new("TextButton")
	btn.Name = "Btn_" .. opt.key
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.Text = opt.label
	btn.AutoButtonColor = false
	btn.Parent = grid

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Name = "Stroke"
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = btn

	buttons[opt.key] = btn

	btn.Activated:Connect(function()
		selectedKey = opt.key
		playSfx(CLICK_SOUND, 0.3)
		updateButtons()
	end)
end

updateButtons()

-- Play / Masuk Button
local playBtn = Instance.new("TextButton")
playBtn.Name = "PlayButton"
playBtn.Position = UDim2.new(0, 0, 0, 206)
playBtn.Size = UDim2.new(1, 0, 0, 48)
playBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
playBtn.Font = Enum.Font.GothamBold
playBtn.Text = "MASUK GAME"
playBtn.TextSize = 14
playBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playBtn.AutoButtonColor = false
playBtn.Parent = center

local playCorner = Instance.new("UICorner")
playCorner.CornerRadius = UDim.new(0, 8)
playCorner.Parent = playBtn

local playStroke = Instance.new("UIStroke")
playStroke.Color = Color3.fromRGB(100, 200, 255)
playStroke.Thickness = 1
playStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
playStroke.Parent = playBtn

-- Button interaction
local playScale = Instance.new("UIScale")
playScale.Parent = playBtn

playBtn.MouseEnter:Connect(function()
	TweenService:Create(playBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(10, 165, 255) }):Play()
end)
playBtn.MouseLeave:Connect(function()
	TweenService:Create(playBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(0, 150, 255) }):Play()
end)

local hasStarted = false
playBtn.Activated:Connect(function()
	if hasStarted then return end
	hasStarted = true

	playSfx(START_SOUND, 0.45)
	TweenService:Create(playScale, TweenInfo.new(0.08), { Scale = 0.96 }):Play()

	-- 1. Apply Music Choice via Attribute & Runtime
	player:SetAttribute("InitialMusicCategory", selectedKey)
	if selectedKey ~= "None" and _G.ActiveMusicRuntime then
		_G.ActiveMusicRuntime:switchCategory(selectedKey, 1)
	end

	-- 2. Clean, fast fade-out
	local tweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local fade = TweenService:Create(canvas, tweenInfo, { GroupTransparency = 1 })
	fade:Play()
	fade.Completed:Connect(function()
		screenGui:Destroy()
	end)
end)

-- Mount into PlayerGui
screenGui.Parent = playerGui
print("[ReplicatedFirst] Simple Intro Loading Screen initialized!")
