--!nonstrict
-- Celebration popup used for purchases and claims.
-- GUI lives in StarterGui.RewardPopupGui (authored in Studio); this file only animates it.
--
--	RewardPopup.show({ Title = "PURCHASED!", ItemName = "Gold Rod", Icon = "rbxassetid://123" })
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local UIEffects = require(script.Parent.UIEffects)

local RewardPopup = {}
RewardPopup.DefaultSoundId = "rbxassetid://4612378086"

local POP = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local POP_LATE = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.16)
local FADE = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FADE_LATE = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.32)
local OUT = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local gui, overlay, root, anim
local sunburst, card, icon, iconScale, ribbon, title, itemName, itemLabel, okButton
local particles, templates

local ribbonShown
local spinConnection
local serial = 0
local closing = false

local function playSound(soundId, volume)
	if not soundId or soundId == "" then
		return
	end
	-- Satu sound aktif saja: popup baru menghentikan popup sebelumnya biar tidak dobel.
	if RewardPopup._activeSound then
		pcall(function()
			RewardPopup._activeSound:Stop()
			RewardPopup._activeSound:Destroy()
		end)
		RewardPopup._activeSound = nil
	end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.Parent = SoundService
	sound:Play()
	RewardPopup._activeSound = sound
	sound.Ended:Connect(function()
		if RewardPopup._activeSound == sound then
			RewardPopup._activeSound = nil
		end
		sound:Destroy()
	end)
	-- Ended never fires if the asset fails to load; do not leak the instance.
	task.delay(8, function()
		if sound.Parent then
			if RewardPopup._activeSound == sound then
				RewardPopup._activeSound = nil
			end
			sound:Destroy()
		end
	end)
end

local function ensureScale(guiObject, childName)
	local child = guiObject:FindFirstChild(childName)
	if child and child:IsA("UIScale") then
		return child
	end
	local created = Instance.new("UIScale")
	created.Name = childName
	created.Parent = guiObject
	return created
end

-- Roblox only honours ONE UIScale per GuiObject, so the pop factor cannot live in
-- its own UIScale next to PopupScale (owned by AutoResize). Tween a NumberValue
-- instead; AutoResize multiplies it into PopupScale.
local function ensureAnimNumber(guiObject)
	local child = guiObject:FindFirstChild("PopupAnim")
	if child and child:IsA("NumberValue") then
		return child
	end
	local created = Instance.new("NumberValue")
	created.Name = "PopupAnim"
	created.Value = 1
	created.Parent = guiObject
	return created
end

local function burst(count)
	local center = UDim2.fromScale(0.5, 0.32) -- card center in the 420x662 PopupRoot
	for index = 1, count do
		local template = templates[index % 3 == 0 and "star" or (index % 2 == 0 and "coin" or "square")]
		local particle = template:Clone()
		local angle = math.rad(math.random() * 360)
		local distance = math.random(110, 250)
		local spin = math.random(-260, 260)

		particle.Visible = true
		particle.Position = center
		particle.Rotation = math.random(-180, 180)
		particle.Parent = particles

		local travel = TweenService:Create(particle, TweenInfo.new(0.5 + math.random() * 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, math.cos(angle) * distance, 0.32, math.sin(angle) * distance),
			Rotation = particle.Rotation + spin,
		})
		local fadeInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.35)
		local fade = TweenService:Create(particle, fadeInfo,
			if particle:IsA("TextLabel") then { TextTransparency = 1 } else { BackgroundTransparency = 1 })

		travel:Play()
		fade:Play()
		fade.Completed:Once(function()
			particle:Destroy()
		end)
	end
end

local function startSpin()
	if spinConnection then
		spinConnection:Disconnect()
	end
	sunburst.Rotation = 0
	spinConnection = RunService.RenderStepped:Connect(function(delta)
		sunburst.Rotation = (sunburst.Rotation + delta * 18) % 360
	end)
end

function RewardPopup.init()
	if gui and gui.Parent then
		return gui
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	gui = playerGui:WaitForChild("RewardPopupGui", 30)
	if not gui then
		return nil
	end

	overlay = gui:WaitForChild("Overlay")
	root = gui:WaitForChild("PopupRoot")
	anim = ensureAnimNumber(root) -- pop/close multiplier; AutoResize multiplies it into PopupScale
	sunburst = root:WaitForChild("Sunburst")
	card = root:WaitForChild("Card")
	icon = card:WaitForChild("Icon")
	iconScale = ensureScale(icon, "IconScale")
	ribbon = root:WaitForChild("Ribbon")
	title = ribbon:WaitForChild("Title")
	itemName = root:WaitForChild("ItemName")
	itemLabel = itemName:WaitForChild("Label")
	okButton = root:WaitForChild("OkButton")
	particles = root:WaitForChild("ParticleLayer")
	templates = {
		star = particles:WaitForChild("ParticleStar"),
		coin = particles:WaitForChild("ParticleCoin"),
		square = particles:WaitForChild("ParticleSquare"),
	}
	ribbonShown = ribbon.Position

	okButton.Activated:Connect(RewardPopup.close)
	UIEffects.tactile(okButton)
	overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			-- Only taps outside the popup dismiss it; a frame over the overlay does not
			-- swallow clicks on its own, so hit-test the root rect by hand.
			local pos, origin, size = input.Position, root.AbsolutePosition, root.AbsoluteSize
			local inside = pos.X >= origin.X and pos.X <= origin.X + size.X
				and pos.Y >= origin.Y and pos.Y <= origin.Y + size.Y
			if not inside then
				RewardPopup.close()
			end
		end
	end)

	return gui
end

function RewardPopup.show(data)
	data = data or {}
	if not RewardPopup.init() then
		return
	end

	serial += 1
	closing = false

	title.Text = data.Title or "PURCHASED!"
	itemLabel.Text = data.ItemName or "Reward"
	-- Trails have no icon; keep the card so the popup keeps its shape instead of
	-- leaving bare sunburst rays behind the ribbon.
	local hasIcon = data.Icon ~= nil and data.Icon ~= ""
	icon.Image = data.Icon or ""
	icon.Visible = hasIcon

	overlay.Visible = true
	overlay.BackgroundTransparency = 1
	TweenService:Create(overlay, FADE, { BackgroundTransparency = 0.45 }):Play()

	anim.Value = 0.25
	root.Visible = true
	TweenService:Create(anim, POP, { Value = 1 }):Play()

	iconScale.Scale = 0.35
	TweenService:Create(iconScale, POP_LATE, { Scale = 1 }):Play()

	ribbon.Position = UDim2.new(ribbonShown.X.Scale, ribbonShown.X.Offset, ribbonShown.Y.Scale, ribbonShown.Y.Offset + 46)
	ribbon.Rotation = -9
	TweenService:Create(ribbon, POP_LATE, { Position = ribbonShown, Rotation = -2 }):Play()

	itemName.BackgroundTransparency = 1
	itemLabel.TextTransparency = 1
	TweenService:Create(itemName, FADE_LATE, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(itemLabel, FADE_LATE, { TextTransparency = 0 }):Play()

	UIEffects.pop(okButton, 0.32)
	startSpin()
	task.delay(0.06, function()
		if root.Visible and not closing then
			burst(18)
		end
	end)
	playSound(data.SoundId or RewardPopup.DefaultSoundId, data.Volume)
end

function RewardPopup.close()
	if not gui or closing then
		return
	end
	closing = true
	local shownFor = serial

	if spinConnection then
		spinConnection:Disconnect()
		spinConnection = nil
	end

	TweenService:Create(anim, OUT, { Value = 0.55 }):Play()
	TweenService:Create(overlay, FADE, { BackgroundTransparency = 1 }):Play()

	task.delay(0.22, function()
		if serial ~= shownFor then
			return -- a new popup opened while this one was closing
		end
		closing = false
		root.Visible = false
		overlay.Visible = false
	end)
end

function RewardPopup.isOpen()
	return root ~= nil and root.Visible == true
end

return RewardPopup
