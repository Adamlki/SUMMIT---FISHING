--!nonstrict
-- One motion system for client UI: spring pop open/close, tactile buttons,
-- and floating warning text. Panels that already use SummitKit's Panel keep it;
-- this is for popups, cards, and anything tagging itself as AnimatedButton.
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local UIEffects = {}

local TAG = "AnimatedButton"

local OPEN = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLOSE = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local HOVER = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PRESS = TweenInfo.new(0.07, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local RELEASE = TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local activeTween = setmetatable({}, { __mode = "k" })
local bound = setmetatable({}, { __mode = "k" })

-- GUI is authored with its own UIScale; reuse it so one instance drives the layout.
local function scaleFor(gui)
	local existing = gui:FindFirstChildOfClass("UIScale")
	if existing then
		return existing
	end
	local scale = Instance.new("UIScale")
	scale.Name = "UIEffectsScale"
	scale.Parent = gui
	return scale
end

local function setScale(gui, info, target, delay)
	if activeTween[gui] then
		activeTween[gui]:Cancel()
	end
	local tween = info
	if delay then
		tween = TweenInfo.new(info.Time, info.EasingStyle, info.EasingDirection, info.RepeatCount, info.Reverses, delay)
	end
	local created = TweenService:Create(scaleFor(gui), tween, { Scale = target })
	activeTween[gui] = created
	created:Play()
	return created
end

-- Pop in from nothing (overshoot) so a window/card feels like it lands.
function UIEffects.pop(gui, delay)
	scaleFor(gui).Scale = 0
	return setScale(gui, OPEN, 1, delay)
end

function UIEffects.unpop(gui)
	return setScale(gui, CLOSE, 0)
end

function UIEffects.tactile(button)
	if not button:IsA("GuiButton") or bound[button] then
		return
	end
	bound[button] = true

	local scale = button:FindFirstChild("ButtonScale")
	if not (scale and scale:IsA("UIScale")) then
		scale = Instance.new("UIScale")
		scale.Name = "ButtonScale"
		scale.Parent = button
	end

	button.MouseEnter:Connect(function()
		TweenService:Create(scale, HOVER, { Scale = 1.04 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, HOVER, { Scale = 1 }):Play()
	end)
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, PRESS, { Scale = 0.92 }):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(scale, RELEASE, { Scale = 1 }):Play()
	end)
end

function UIEffects.bindContainer(container)
	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("GuiButton") then
			UIEffects.tactile(descendant)
		end
	end
	container.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("GuiButton") then
			UIEffects.tactile(descendant)
		end
	end)
end

-- Red "NEED 100K COINS!" text that floats off a button and fades.
function UIEffects.warning(origin, text, hold)
	if not origin or not text or text == "" then
		return
	end

	local label = Instance.new("TextLabel")
	label.Name = "UIWarning"
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 0, 0)
	label.Size = UDim2.new(0, 0, 0, 28)
	label.AutomaticSize = Enum.AutomaticSize.X
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 22
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 72, 72)
	label.TextStrokeColor3 = Color3.fromRGB(28, 12, 12)
	label.TextStrokeTransparency = 0.1
	label.ZIndex = 200
	label.Parent = origin

	local stay = hold or 0.35
	TweenService:Create(label, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, -34),
	}):Play()
	TweenService:Create(label, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, stay), {
		Position = UDim2.new(0.5, 0, 0, -58),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()

	task.delay(stay + 0.5, function()
		if label.Parent then
			label:Destroy()
		end
	end)
end

-- Any button tagged AnimatedButton gets the same feel without extra wiring.
for _, tagged in ipairs(CollectionService:GetTagged(TAG)) do
	if tagged:IsA("GuiButton") then
		UIEffects.tactile(tagged)
	end
end
CollectionService:GetInstanceAddedSignal(TAG):Connect(function(tagged)
	if tagged:IsA("GuiButton") then
		UIEffects.tactile(tagged)
	end
end)

return UIEffects
