--!strict
-- Universal Toolbar Interaction & Modal Window Manager
-- Handles: Figma Styled Static Buttons (45x45), Fredoka One Bottom Labels, Tactile Click Bounce, Dynamic Docking, and Mutual Exclusion (Zero Overlap)

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local StarterGuiService = game:GetService("StarterGui")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local gameUI = script.Parent.Parent.Parent
local component = script.Parent.Parent
local buttonsFrame = script.Parent

local leftHolder = buttonsFrame:WaitForChild("LeftHolder") :: Frame
local topRight = buttonsFrame:WaitForChild("TopRight") :: Frame
local topMid = buttonsFrame:WaitForChild("TopMid") :: Frame
local adminRight = buttonsFrame:WaitForChild("AdminRight") :: Frame
local masterMenu = buttonsFrame:WaitForChild("MasterMenu") :: ImageButton

-- UI Tweens
local TWEEN_BOUNCE = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_SQUASH = TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_HOVER = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local FIGMA_ASSET_ID = "rbxassetid://89727429088839"

-- Button Metadata Config (All Caps Fredoka One labels)
local BUTTON_CONFIGS: { [string]: string } = {
	-- LeftHolder
	["Freecam"] = "FREECAM",
	["Index"] = "INDEX",
	["Shop"] = "SHOP",
	["Spectate"] = "SPECTATE",
	-- TopRight (4 buttons)
	["Donate"] = "DONATE",
	["Reset"] = "RESET",
	["Hide"] = "HIDE",
	-- TopMid
	["Setting"] = "SETTINGS",
	["Dance"] = "EMOTE",
	["Music"] = "MUSIC",
	["Avatar"] = "AVATAR",
	-- AdminRight
	["Title"] = "TITLE",
	["Panel"] = "ADMIN",
}

-- Ensure frames allow layout without clipping
leftHolder.ClipsDescendants = false
topRight.ClipsDescendants = false
topMid.ClipsDescendants = false
adminRight.ClipsDescendants = false

-- Calculate exact container width in UI Offset units (Immune to GUI Scale / Screen Resolution)
local function getContainerOffsetWidth(container: GuiObject): number
	local total = 0
	local count = 0
	for _, ch in ipairs(container:GetChildren()) do
		if ch:IsA("GuiObject") then
			total += ch.Size.X.Offset
			count += 1
		end
	end
	if count == 0 then return 147 end
	return total + math.max(0, count - 1) * 6
end

-- Keep LeftHolder dynamically docked next to TopRight (Seamless 6px gap, zero overlap at all resolutions)
local function updateDocking()
	if buttonsFrame:GetAttribute("MenuOpen") == true and leftHolder.Visible and topRight.Visible then
		local trScale = topRight.Position.X.Scale
		local trRightOffset = topRight.Position.X.Offset
		local trWidthOffset = getContainerOffsetWidth(topRight)
		if trWidthOffset < 45 then trWidthOffset = 147 end
		local targetLeftOffset = trRightOffset - trWidthOffset - 6
		leftHolder.Position = UDim2.new(trScale, targetLeftOffset, 0, 16)
	end
end

-- M-04 Fix: Event-driven docking updates instead of per-frame RenderStepped polling
local function queueDockUpdate()
	task.defer(updateDocking)
end

buttonsFrame:GetAttributeChangedSignal("MenuOpen"):Connect(queueDockUpdate)
leftHolder:GetPropertyChangedSignal("Visible"):Connect(queueDockUpdate)
topRight:GetPropertyChangedSignal("Visible"):Connect(queueDockUpdate)
topRight:GetPropertyChangedSignal("Position"):Connect(queueDockUpdate)
topRight:GetPropertyChangedSignal("Size"):Connect(queueDockUpdate)
topRight.ChildAdded:Connect(queueDockUpdate)
topRight.ChildRemoved:Connect(queueDockUpdate)
local cam = Workspace.CurrentCamera
if cam then
	cam:GetPropertyChangedSignal("ViewportSize"):Connect(queueDockUpdate)
end
updateDocking()

-- Setup individual button
local function setupButton(btn: GuiButton, labelText: string)
	-- Ensure Figma Background Image
	if btn:IsA("ImageButton") then
		btn.Image = FIGMA_ASSET_ID
		btn.BackgroundTransparency = 1
		btn.ScaleType = Enum.ScaleType.Stretch
	end
	btn.Size = UDim2.new(0, 45, 0, 45)

	-- Remove clashing frame strokes & corners on button
	for _, ch in ipairs(btn:GetChildren()) do
		if ch:IsA("UICorner") or (ch:IsA("UIStroke") and ch.Name ~= "TextStroke") then
			ch:Destroy()
		end
	end

	-- 1. Ensure UIScale for Click Squash & Bounce
	local scale = btn:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Parent = btn
	end

	-- 2. Icon positioning: centered upper half
	local icon = btn:FindFirstChild("Icon") :: GuiObject?
	if icon then
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.new(0.5, 0, 0.38, 0)
		icon.Size = UDim2.new(0, 23, 0, 23)
		icon.BackgroundTransparency = 1
		icon.ZIndex = 2
	end

	-- 3. Ensure ButtonLabel at bottom center
	local label = btn:FindFirstChild("ButtonLabel") :: TextLabel
	if not label then
		label = Instance.new("TextLabel")
		label.Name = "ButtonLabel"
		label.Parent = btn
	end

	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 8.5
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextTransparency = 0
	label.Text = labelText
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.new(0.5, 0, 0.81, 0)
	label.Size = UDim2.new(1, -2, 0, 12)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.None
	label.ClipsDescendants = false
	label.ZIndex = 3

	-- UIStroke on label (preserve thickness 1 as configured)
	local textStroke = label:FindFirstChildOfClass("UIStroke")
	if not textStroke then
		textStroke = Instance.new("UIStroke")
		textStroke.Name = "TextStroke"
		textStroke.Color = Color3.fromRGB(0, 0, 0)
		textStroke.Thickness = 1
		textStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		textStroke.Parent = label
	else
		textStroke.Color = Color3.fromRGB(0, 0, 0)
		textStroke.Thickness = 1
		textStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	end

	-- Click Squash & Bounce Feedback
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TWEEN_SQUASH, { Scale = 0.92 }):Play()
	end)

	btn.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TWEEN_BOUNCE, { Scale = 1.0 }):Play()
	end)

	btn.MouseEnter:Connect(function()
		TweenService:Create(scale, TWEEN_HOVER, { Scale = 1.05 }):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(scale, TWEEN_HOVER, { Scale = 1.0 }):Play()
	end)
end

-- Initialize all configured buttons
for _, container in ipairs({ leftHolder, topRight, topMid, adminRight }) do
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiButton") and BUTTON_CONFIGS[child.Name] then
			setupButton(child, BUTTON_CONFIGS[child.Name])
		end
	end
end

-- Ensure Roblox native leaderboard (Tab) is enabled
pcall(function()
	StarterGuiService:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
end)

-- Setup MasterMenu
if masterMenu and masterMenu:IsA("ImageButton") then
	masterMenu.Size = UDim2.new(0, 45, 0, 45)
	masterMenu.Image = FIGMA_ASSET_ID
	masterMenu.BackgroundTransparency = 1
	masterMenu.ScaleType = Enum.ScaleType.Stretch
	for _, ch in ipairs(masterMenu:GetChildren()) do
		if ch:IsA("UICorner") or ch:IsA("UIStroke") then
			ch:Destroy()
		end
	end
	local iconFrame = masterMenu:FindFirstChild("IconFrame")
	if iconFrame then
		iconFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		iconFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		iconFrame.Size = UDim2.new(0, 24, 0, 18)
	end
	local mScale = masterMenu:FindFirstChildOfClass("UIScale")
	if not mScale then
		mScale = Instance.new("UIScale")
		mScale.Parent = masterMenu
	end
	masterMenu.MouseButton1Down:Connect(function()
		TweenService:Create(mScale, TWEEN_SQUASH, { Scale = 0.92 }):Play()
	end)
	masterMenu.MouseButton1Up:Connect(function()
		TweenService:Create(mScale, TWEEN_BOUNCE, { Scale = 1.0 }):Play()
	end)
	masterMenu.MouseEnter:Connect(function()
		TweenService:Create(mScale, TWEEN_HOVER, { Scale = 1.05 }):Play()
	end)
	masterMenu.MouseLeave:Connect(function()
		TweenService:Create(mScale, TWEEN_HOVER, { Scale = 1.0 }):Play()
	end)
end

-- ===================================================================
-- UNIVERSAL MODAL WINDOW MANAGER (Zero Overlap / Anti-Tumpang Tindih)
-- ===================================================================
local isManagingModals = false

type ModalEntry = {
	name: string,
	button: GuiButton?,
	isOpen: () -> boolean,
	close: () -> ()
}

local registeredModals: { ModalEntry } = {}

local function setupModalRegistry()
	local menus = gameUI:WaitForChild("Menus", 10)
	if not menus then return end

	-- 1. ShopFeature
	local shopFeature = menus:FindFirstChild("ShopFeature")
	if shopFeature then
		table.insert(registeredModals, {
			name = "Shop",
			button = leftHolder:FindFirstChild("Shop") :: GuiButton?,
			isOpen = function()
				return shopFeature:GetAttribute("IsOpen") == true
			end,
			close = function()
				shopFeature:SetAttribute("IsOpen", false)
			end
		})
	end

	-- 2. FishIndexGui
	local fishIndex = playerGui:WaitForChild("FishIndexGui", 10)
	if fishIndex then
		local mainFrame = fishIndex:FindFirstChild("MainFrame")
		table.insert(registeredModals, {
			name = "Index",
			button = leftHolder:FindFirstChild("Index") :: GuiButton?,
			isOpen = function()
				return (mainFrame and mainFrame:GetAttribute("IsOpen") == true) or (fishIndex.Enabled and mainFrame ~= nil and mainFrame.Visible)
			end,
			close = function()
				if mainFrame then
					mainFrame:SetAttribute("IsOpen", false)
				else
					fishIndex.Enabled = false
				end
			end
		})
	end

	-- 3. Menus inside GameUI.Menus (Setting, Dance, Music, Avatar, Donate, Admin, Title, Reset, Spectate)
	local menuMap = {
		["Setting"] = { btn = topMid:FindFirstChild("Setting"), name = "Setting" },
		["Dance"] = { btn = topMid:FindFirstChild("Dance"), name = "Dance" },
		["Music"] = { btn = topMid:FindFirstChild("Music"), name = "Music" },
		["Avatar"] = { btn = topMid:FindFirstChild("Avatar"), name = "Avatar" },
		["Donate"] = { btn = topRight:FindFirstChild("Donate"), name = "Donate" },
		["Admin"] = { btn = adminRight:FindFirstChild("Panel"), name = "Admin" },
		["Title"] = { btn = adminRight:FindFirstChild("Title"), name = "Title" },
		["Reset"] = { btn = topRight:FindFirstChild("Reset"), name = "Reset" },
		["Spectate"] = { btn = leftHolder:FindFirstChild("Spectate"), name = "Spectate" },
	}

	for frameName, info in pairs(menuMap) do
		local mFrame = menus:FindFirstChild(frameName)
		if mFrame then
			table.insert(registeredModals, {
				name = info.name,
				button = info.btn :: GuiButton?,
				isOpen = function()
					return mFrame.Visible
				end,
				close = function()
					mFrame.Visible = false
				end
			})
		end
	end

	-- 4. CustomInventoryGui (Tas / Slot 3)
	local customInv = playerGui:WaitForChild("CustomInventoryGui", 10)
	if customInv then
		local invFrame = customInv:FindFirstChild("MainInventoryFrame")
		if invFrame then
			table.insert(registeredModals, {
				name = "Inventory",
				button = nil,
				isOpen = function()
					return invFrame.Visible
				end,
				close = function()
					invFrame.Visible = false
				end
			})
		end
	end
end

task.spawn(setupModalRegistry)

-- Enforce Single Active Modal Rule (Intelligent Last-Opened Priority)
local previousOpenStates: { [string]: boolean } = {}
local activeModalName: string? = nil

local function checkAndEnforceModals()
	if isManagingModals then return end
	isManagingModals = true

	local newlyOpened: ModalEntry? = nil
	local openModals: { ModalEntry } = {}

	for _, m in ipairs(registeredModals) do
		local open = m.isOpen()
		if open then
			table.insert(openModals, m)
			if not previousOpenStates[m.name] then
				newlyOpened = m
			end
		end
	end

	local currentActive: ModalEntry? = nil

	if newlyOpened then
		currentActive = newlyOpened
		for _, m in ipairs(openModals) do
			if m.name ~= newlyOpened.name then
				m.close()
			end
		end
	elseif #openModals > 0 then
		for _, m in ipairs(openModals) do
			if m.name == activeModalName then
				currentActive = m
				break
			end
		end
		if not currentActive then
			currentActive = openModals[1]
		end
		for _, m in ipairs(openModals) do
			if m.name ~= currentActive.name then
				m.close()
			end
		end
	end

	activeModalName = currentActive and currentActive.name or nil

	for _, m in ipairs(registeredModals) do
		previousOpenStates[m.name] = (currentActive ~= nil and currentActive.name == m.name)
	end

	isManagingModals = false
end

-- M-04 Fix: Throttled modal checking (10 Hz instead of 60-120 Hz Heartbeat) to reduce CPU load
local lastModalCheck = 0
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if now - lastModalCheck < 0.1 then return end
	lastModalCheck = now
	checkAndEnforceModals()
end)

print("[ToolbarInteractionManager] Active: 45x45 Figma Buttons (Players Restored), Dynamic Docking (-350), Anti-Overlap Modals!")
