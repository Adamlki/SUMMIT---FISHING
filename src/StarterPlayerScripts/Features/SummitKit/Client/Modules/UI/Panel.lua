--!nonstrict
-- One motion system for every GameUI panel: slide + pop open, quick ease-out close,
-- exclusive (only one panel open), dim click-to-close backdrop, and HUD focus mode.
-- Posisi diambil dari attribute ShownPos/HiddenPos kalau ada; kalau tidak, digeser 32px
-- dari arah SlideDir ("up" default).
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local HudVisibility = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("UI"):WaitForChild("HudVisibility"))

local Panel = {}

local OPEN_INFO = TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local CLOSE_INFO = TweenInfo.new(0.20, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
local FADE_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local SLIDE = 32
local BACKDROP_Z = 5
local BACKDROP_ALPHA = 0.55

local entries = {}
local openSet = {}
local backdrop
local backdropTween

local function ensureScale(frame)
	local scale = frame:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "PanelScale"
		scale.Parent = frame
	end
	return scale
end

local function slideFrom(shown, dir)
	if dir == "down" then
		return UDim2.new(shown.X.Scale, shown.X.Offset, shown.Y.Scale, shown.Y.Offset + SLIDE)
	elseif dir == "left" then
		return UDim2.new(shown.X.Scale, shown.X.Offset - SLIDE, shown.Y.Scale, shown.Y.Offset)
	elseif dir == "right" then
		return UDim2.new(shown.X.Scale, shown.X.Offset + SLIDE, shown.Y.Scale, shown.Y.Offset)
	end
	return UDim2.new(shown.X.Scale, shown.X.Offset, shown.Y.Scale, shown.Y.Offset - SLIDE)
end

local function entryFor(frame, opts)
	local entry = entries[frame]
	if entry then
		if opts then
			if opts.shown then entry.shown = opts.shown end
			if opts.hidden then entry.hidden = opts.hidden end
			if opts.noDim ~= nil then entry.noDim = opts.noDim end
			if opts.backdropGui then entry.backdropGui = opts.backdropGui end
			if opts.backdropZ then entry.backdropZ = opts.backdropZ end
		end
		return entry
	end
	local shown = (opts and opts.shown) or frame:GetAttribute("ShownPos") or frame.Position
	local hidden = (opts and opts.hidden) or frame:GetAttribute("HiddenPos") or slideFrom(shown, frame:GetAttribute("SlideDir") or "up")
	entry = {
		shown = shown,
		hidden = hidden,
		noDim = (opts and opts.noDim) or frame:GetAttribute("NoDim") == true,
		backdropGui = opts and opts.backdropGui,
		backdropZ = opts and opts.backdropZ,
		scale = ensureScale(frame),
		open = false,
		serial = 0,
		posTween = nil,
		scaleTween = nil,
	}
	entries[frame] = entry
	return entry
end

function Panel.mount(frame, opts)
	if not frame then
		return nil
	end
	return entryFor(frame, opts)
end

local function ensureBackdrop(gui, zIndex)
	if backdrop and backdrop.Parent == gui then
		if zIndex and backdrop.ZIndex ~= zIndex then
			backdrop.ZIndex = zIndex
		end
		return backdrop
	end
	if backdrop then
		backdrop:Destroy()
	end
	backdrop = Instance.new("Frame")
	backdrop.Name = "PanelBackdrop"
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 1
	backdrop.BorderSizePixel = 0
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.ZIndex = zIndex or BACKDROP_Z
	backdrop.Active = true
	backdrop.Visible = false
	backdrop.Parent = gui
	backdrop.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Panel.closeAll()
		end
	end)
	return backdrop
end

local function gameGui()
	local pg = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
	return pg and pg:FindFirstChild("GameUI")
end

local function setBackdrop(show)
	local active = next(openSet)
	local entry = active and entries[active]
	local gui = (entry and entry.backdropGui) or gameGui() or (active and active:FindFirstAncestorOfClass("ScreenGui"))
	if show then
		if not gui then
			return
		end
		ensureBackdrop(gui, entry and entry.backdropZ)
	elseif not backdrop then
		return
	end

	if backdropTween then
		backdropTween:Cancel()
	end
	if show and entry and entry.noDim then
		-- Panel tanpa backdrop gelap (Emote, Spectate): tetap ada hit-area
		-- transparan untuk klik-di-luar = close.
		backdrop.BackgroundTransparency = 1
		backdrop.Visible = true
		return
	end
	if show then
		backdrop.Visible = true
		backdropTween = TweenService:Create(backdrop, FADE_INFO, { BackgroundTransparency = BACKDROP_ALPHA })
	else
		backdropTween = TweenService:Create(backdrop, FADE_INFO, { BackgroundTransparency = 1 })
		local conn
		conn = backdropTween.Completed:Connect(function()
			conn:Disconnect()
			if not next(openSet) and backdrop then
				backdrop.Visible = false
			end
		end)
	end
	backdropTween:Play()
end

local hudFocused = false

local function setHudFocus(focused)
	if hudFocused == focused then
		return
	end
	hudFocused = focused

	local active = next(openSet)
	local sourceGui = active and active:FindFirstAncestorOfClass("ScreenGui")
	HudVisibility:SetPanelFocus(focused, sourceGui)
end

local function refresh()
	for frame in pairs(openSet) do
		if not frame.Parent then
			openSet[frame] = nil
		end
	end
	local anyOpen = next(openSet) ~= nil
	setBackdrop(anyOpen)
	setHudFocus(anyOpen)
end

function Panel.open(frame)
	if not frame or not frame.Parent then
		return
	end

	local gui = gameGui() or frame:FindFirstAncestorOfClass("ScreenGui")
	if not gui then
		return
	end

	local entry = entryFor(frame)
	if entry.open then
		return
	end

	Panel.closeAll(frame)

	entry.open = true
	entry.serial += 1
	openSet[frame] = true
	frame:SetAttribute("IsOpen", true)
	frame.Visible = true
	frame.Position = entry.hidden
	entry.scale.Scale = 0.96

	if entry.posTween then
		entry.posTween:Cancel()
	end
	if entry.scaleTween then
		entry.scaleTween:Cancel()
	end
	entry.posTween = TweenService:Create(frame, OPEN_INFO, { Position = entry.shown })
	entry.scaleTween = TweenService:Create(entry.scale, OPEN_INFO, { Scale = 1 })
	entry.posTween:Play()
	entry.scaleTween:Play()

	refresh()
end

function Panel.close(frame)
	local entry = entries[frame]
	if not entry or not entry.open then
		return
	end

	entry.open = false
	entry.serial += 1
	local serial = entry.serial
	openSet[frame] = nil

	if entry.posTween then
		entry.posTween:Cancel()
	end
	if entry.scaleTween then
		entry.scaleTween:Cancel()
	end
	entry.posTween = TweenService:Create(frame, CLOSE_INFO, { Position = entry.hidden })
	entry.scaleTween = TweenService:Create(entry.scale, CLOSE_INFO, { Scale = 0.97 })
	local conn
	conn = entry.posTween.Completed:Connect(function()
		conn:Disconnect()
		if entry.serial ~= serial or entry.open then
			return
		end
		frame.Visible = false
		frame:SetAttribute("IsOpen", false)
		refresh()
	end)
	entry.posTween:Play()
	entry.scaleTween:Play()
end

-- Tutup tanpa animasi, tapi tetap bersihkan state internal (backdrop + HUD focus).
function Panel.hideNow(frame)
	if not frame then
		return
	end
	local entry = entries[frame]
	if entry then
		entry.open = false
		entry.serial += 1
		if entry.posTween then
			entry.posTween:Cancel()
		end
		if entry.scaleTween then
			entry.scaleTween:Cancel()
		end
		openSet[frame] = nil
		frame:SetAttribute("IsOpen", false)
	end
	frame.Visible = false
	refresh()
end

function Panel.toggle(frame)
	if Panel.isOpen(frame) then
		Panel.close(frame)
	else
		Panel.open(frame)
	end
end

function Panel.isOpen(frame)
	local entry = entries[frame]
	if entry then
		return entry.open
	end
	return frame ~= nil and frame.Visible == true
end

function Panel.closeAll(except)
	for frame in pairs(openSet) do
		if frame ~= except then
			Panel.close(frame)
		end
	end
end

return Panel
