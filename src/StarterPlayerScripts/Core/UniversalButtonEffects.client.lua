--!strict
-- UniversalButtonEffects: Provides Tactile Hover (Scale 1.04) and Click (Squash/Bounce with Sound) to ALL Buttons in PlayerGui
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local CollectionService = game:GetService("CollectionService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local TWEEN_HOVER = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SQUASH = TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_BOUNCE = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local CLICK_SOUND_ID = "rbxassetid://6895079853"
local CLICK_VOLUME = 0.28
local SOUND_POOL_SIZE = 3

local lastClickSoundTime = 0
local clickSounds: { Sound } = {}
local clickIndex = 0

-- Sound di-cache & di-preload sekali: kalau bikin Sound baru tiap klik, Roblox
-- harus load asset dulu -> suara klik terasa delay.
local function ensureClickSounds()
	if #clickSounds > 0 then
		return
	end
	for i = 1, SOUND_POOL_SIZE do
		local sound = Instance.new("Sound")
		sound.Name = "UniversalClick_" .. tostring(i)
		sound.SoundId = CLICK_SOUND_ID
		sound.Volume = CLICK_VOLUME
		sound.Parent = SoundService
		table.insert(clickSounds, sound)
	end
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(clickSounds)
		end)
	end)
end

local function playClickSound()
	local now = os.clock()
	if now - lastClickSoundTime < 0.08 then
		return
	end
	lastClickSoundTime = now

	ensureClickSounds()
	clickIndex = (clickIndex % #clickSounds) + 1
	local sound = clickSounds[clickIndex]
	sound.TimePosition = 0
	sound:Play()
end

local function attachTactile(btn: GuiObject)
	if not (btn:IsA("GuiButton")) then return end
	if btn:GetAttribute("HasTactileEffect") == true then return end
	btn:SetAttribute("HasTactileEffect", true)

	-- Tombol yang sudah punya sound sendiri (tag ButtonClick/ButtonOpen) jangan
	-- diputar sound-nya dua kali.
	local hasCustomSound = CollectionService:HasTag(btn, "ButtonClick") or CollectionService:HasTag(btn, "ButtonOpen")

	local scale = btn:FindFirstChild("TactileScale") :: UIScale?
	if not scale then
		scale = btn:FindFirstChildOfClass("UIScale")
		if not scale then
			scale = Instance.new("UIScale")
			scale.Name = "TactileScale"
			scale.Scale = 1.0
			scale.Parent = btn
		end
	end

	local baseScale = scale.Scale

	btn.MouseEnter:Connect(function()
		TweenService:Create(scale, TWEEN_HOVER, { Scale = baseScale * 1.04 }):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(scale, TWEEN_HOVER, { Scale = baseScale }):Play()
	end)

	btn.MouseButton1Down:Connect(function()
		if not hasCustomSound then
			playClickSound()
		end
		TweenService:Create(scale, TWEEN_SQUASH, { Scale = baseScale * 0.93 }):Play()
	end)

	btn.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TWEEN_BOUNCE, { Scale = baseScale }):Play()
	end)
end

for _, desc in ipairs(playerGui:GetDescendants()) do
	if desc:IsA("GuiButton") then
		attachTactile(desc)
	end
end

-- Mulai preload lebih awal supaya klik pertama pun langsung bunyi.
ensureClickSounds()

playerGui.DescendantAdded:Connect(function(desc)
	if desc:IsA("GuiButton") then
		attachTactile(desc)
	end
end)

print("✅ [UniversalButtonEffects] Active across all buttons in PlayerGui.")
