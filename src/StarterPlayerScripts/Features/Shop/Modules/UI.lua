local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Panel = require(script.Parent.Parent.Parent.SummitKit.Client.Modules.UI.Panel)

local TWEEN_HOVER = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SQUASH = TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_BOUNCE = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_HEADER_TRANS = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local Module = {}

function Module.Install(Controller)
-- ===================================================================
-- SOUND ENGINE
-- ===================================================================
local soundCache = {}

local function getCachedSound(soundId: string): Sound
	local cached = soundCache[soundId]
	if cached and cached.Parent then
		return cached
	end
	local sound = Instance.new("Sound")
	sound.Name = "ShopSound"
	sound.SoundId = soundId
	sound.Parent = SoundService
	soundCache[soundId] = sound
	return sound
end

function Controller:PlaySound(soundId: string, volume: number?)
	if not soundId or soundId == "" then
		return
	end
	-- Pakai sound yang sudah di-cache supaya tidak menunggu asset load.
	local sound = getCachedSound(soundId)
	sound.Volume = volume or 0.35
	sound.TimePosition = 0
	sound:Play()
end

-- ===================================================================
-- RESOLVE UI REFERENCES
-- ===================================================================
function Controller:ResolveUI(): boolean
	local gameUI = self.playerGui:WaitForChild("GameUI", 30)
	if not gameUI then return false end
	self.gameUI = gameUI

	local menus = gameUI:WaitForChild("Menus", 20)
	self.menus = menus
	local shopFeature = menus:WaitForChild("ShopFeature", 20) :: Frame
	if not shopFeature then return false end
	self.shopFeature = shopFeature

	self.closeBtn = shopFeature:WaitForChild("CloseButton") :: ImageButton
	local btnHeader = shopFeature:WaitForChild("ButtonHeader") :: Frame
	self.btnHeader = btnHeader

	self.rodsTabBtn = (btnHeader:FindFirstChild("RodsButoon") or btnHeader:FindFirstChild("RodsButton")) :: ImageButton
	self.exclusiveTabBtn = (btnHeader:FindFirstChild("ExclusiveButoon") or btnHeader:FindFirstChild("ExclusiveButton")) :: ImageButton
	self.trailsTabBtn = (btnHeader:FindFirstChild("TrailsButoon") or btnHeader:FindFirstChild("TrailsButton")) :: ImageButton

	self.exclusiveTab = shopFeature:WaitForChild("Exclusive") :: ScrollingFrame
	self.rodsTab = shopFeature:WaitForChild("Rods") :: ScrollingFrame
	self.trailsTab = shopFeature:WaitForChild("Trails") :: ScrollingFrame
	self.rodTemplate = self.rodsTab:WaitForChild("Template") :: Frame
	self.rodTemplate.Visible = false

	self.modal = shopFeature:WaitForChild("PlayerSelectionModal") :: Frame
	local modalHeader = self.modal:WaitForChild("Header") :: Frame
	self.modalHeader = modalHeader
	self.modalTitle = modalHeader:WaitForChild("Title") :: TextLabel
	self.modalSubtitle = modalHeader:WaitForChild("Subtitle") :: TextLabel
	self.modalCloseBtn = modalHeader:WaitForChild("CloseButton") :: TextButton
	self.modalContainer = self.modal:WaitForChild("Container") :: ScrollingFrame
	self.modalTemplate = self.modalContainer:WaitForChild("Template") :: Frame
	self.modalTemplate.Visible = false

	local buttonsFolder = gameUI:WaitForChild("Component"):WaitForChild("ButtonsNew")
	local menuAtas = buttonsFolder:WaitForChild("MenuAtas")
	local topFrame = menuAtas:WaitForChild("Frame")
	self.shopToolbarBtn = topFrame:FindFirstChild("ShopButton") :: GuiButton?

	self:ApplyTactileEffectsToContainer(shopFeature)
	self:ApplyTactileEffectsToContainer(self.modal)
	self:PreloadSounds()
	return true
end

-- Preload semua sound shop sekali supaya tidak delay saat klik.
function Controller:PreloadSounds()
	local list = {}
	for _, id in pairs(self.SOUNDS or {}) do
		if type(id) == "string" and id ~= "" then
			table.insert(list, getCachedSound(id))
		end
	end
	task.spawn(function()
		pcall(function()
			game:GetService("ContentProvider"):PreloadAsync(list)
		end)
	end)
end

-- ===================================================================
-- UNIVERSAL TACTILE BUTTON ANIMATOR
-- ===================================================================
function Controller:AttachTactileEffect(btn: GuiButton)
	if self.boundButtons[btn] then return end
	self.boundButtons[btn] = true

	local scale = btn:FindFirstChild("ButtonScale") :: UIScale?
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "ButtonScale"
		scale.Parent = btn
	end

	btn.MouseEnter:Connect(function()
		TweenService:Create(scale, TWEEN_HOVER, { Scale = 1.04 }):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(scale, TWEEN_HOVER, { Scale = 1.0 }):Play()
	end)

	btn.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TWEEN_SQUASH, { Scale = 0.93 }):Play()
	end)

	btn.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TWEEN_BOUNCE, { Scale = 1.0 }):Play()
	end)
end

function Controller:ApplyTactileEffectsToContainer(container: Instance)
	for _, desc in ipairs(container:GetDescendants()) do
		if desc:IsA("GuiButton") then
			self:AttachTactileEffect(desc)
		end
	end
	container.DescendantAdded:Connect(function(desc)
		if desc:IsA("GuiButton") then
			self:AttachTactileEffect(desc)
		end
	end)
end

-- ===================================================================
-- BUTTONHEADER SMOOTH ANIMATED SELECTION
-- BackgroundTransparency = 0 (Selected) vs 1 (Unselected)
-- ===================================================================
function Controller:UpdateHeaderButtonVisuals(activeTabName: string)
	local tabs = {
		{ Btn = self.exclusiveTabBtn, Name = "Exclusive" },
		{ Btn = self.rodsTabBtn, Name = "Rods" },
		{ Btn = self.trailsTabBtn, Name = "Trails" },
	}

	for _, t in ipairs(tabs) do
		if t.Btn then
			local isSelected = (t.Name == activeTabName)
			local targetTrans = isSelected and 0 or 1
			TweenService:Create(t.Btn, TWEEN_HEADER_TRANS, {
				BackgroundTransparency = targetTrans
			}):Play()
		end
	end
end

-- ===================================================================
-- TAB NAVIGATION ENGINE
-- ===================================================================
local function popTab(tab: GuiObject)
	local scale = tab:FindFirstChild("TabScale") :: UIScale?
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "TabScale"
		scale.Parent = tab
	end
	scale.Scale = 0.97
	TweenService:Create(scale, TWEEN_HEADER_TRANS, { Scale = 1 }):Play()
end

function Controller:SwitchTab(tabName: string)
	self.currentTab = tabName
	self:UpdateHeaderButtonVisuals(tabName)

	self.exclusiveTab.Visible = (tabName == "Exclusive")
	self.rodsTab.Visible = (tabName == "Rods")
	self.trailsTab.Visible = (tabName == "Trails")

	if tabName == "Exclusive" then
		self:ApplyExclusiveMasterConfig()
		popTab(self.exclusiveTab)
	elseif tabName == "Rods" then
		self:RenderRodsCatalogImmediate()
		popTab(self.rodsTab)
	elseif tabName == "Trails" then
		self:RenderTrailsCatalog()
		popTab(self.trailsTab)
	end
end

-- ===================================================================
-- WINDOW VISIBILITY (shared Panel motion: slide + pop, exclusive)
-- ===================================================================
function Controller:OpenShop(initialTab: string?)
	self.modal.Visible = false
	self:SwitchTab(initialTab or self.currentTab or "Exclusive")
	self:RefreshData()
	Panel.open(self.shopFeature)
end

function Controller:CloseShop()
	self.modal.Visible = false
	Panel.close(self.shopFeature)
end

function Controller:WireWindowControls()
	if self.rodsTabBtn then
		self.rodsTabBtn.MouseButton1Click:Connect(function() self:SwitchTab("Rods") end)
	end
	if self.exclusiveTabBtn then
		self.exclusiveTabBtn.MouseButton1Click:Connect(function() self:SwitchTab("Exclusive") end)
	end
	if self.trailsTabBtn then
		self.trailsTabBtn.MouseButton1Click:Connect(function() self:SwitchTab("Trails") end)
	end

	self.closeBtn.MouseButton1Click:Connect(function() self:CloseShop() end)

	self.shopFeature:GetAttributeChangedSignal("IsOpen"):Connect(function()
		if self.shopFeature:GetAttribute("IsOpen") ~= true and Panel.isOpen(self.shopFeature) then
			self:CloseShop()
		end
	end)

	if self.shopToolbarBtn then
		self.shopToolbarBtn.MouseButton1Click:Connect(function()
			if Panel.isOpen(self.shopFeature) then
				self:CloseShop()
			else
				self:OpenShop("Exclusive")
			end
		end)
	end
end
end

return Module
