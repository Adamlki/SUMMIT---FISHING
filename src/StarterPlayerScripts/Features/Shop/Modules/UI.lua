local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local TWEEN_HOVER = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SQUASH = TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_BOUNCE = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_HEADER_TRANS = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local Module = {}

function Module.Install(Controller)
-- ===================================================================
-- SOUND ENGINE
-- ===================================================================
function Controller:PlaySound(soundId: string, volume: number?)
	task.spawn(function()
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = volume or 0.35
		sound.Parent = SoundService
		sound:Play()
		sound.Ended:Connect(function() sound:Destroy() end)
	end)
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

	local buttonsFolder = gameUI:WaitForChild("Component"):WaitForChild("Buttons")
	local leftHolder = buttonsFolder:WaitForChild("LeftHolder")
	self.shopToolbarBtn = leftHolder:FindFirstChild("Shop") :: GuiButton?

	self:ApplyTactileEffectsToContainer(shopFeature)
	self:ApplyTactileEffectsToContainer(self.modal)
	return true
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
function Controller:SwitchTab(tabName: string)
	self.currentTab = tabName
	self:UpdateHeaderButtonVisuals(tabName)

	self.exclusiveTab.Visible = (tabName == "Exclusive")
	self.rodsTab.Visible = (tabName == "Rods")
	self.trailsTab.Visible = (tabName == "Trails")

	if tabName == "Exclusive" then
		self:ApplyExclusiveMasterConfig()
	elseif tabName == "Rods" then
		self:RenderRodsCatalogImmediate()
	elseif tabName == "Trails" then
		self:RenderTrailsCatalog()
	end
end

-- ===================================================================
-- WINDOW VISIBILITY & ANIMATION CONTROLS (Top-to-Bottom Smooth Easing)
-- ===================================================================
function Controller:OpenShop(initialTab: string?)
	self.shopTweenId += 1
	local curId = self.shopTweenId
	if self.shopTween then
		self.shopTween:Cancel()
		self.shopTween = nil
	end

	self.shopFeature.AnchorPoint = Vector2.new(0.5, 0.5)
	self.shopFeature.Position = self.SHOP_HIDDEN_POS
	self.shopFeature.Visible = true
	self.shopFeature:SetAttribute("IsOpen", true)
	self.modal.Visible = false
	self:SwitchTab(initialTab or self.currentTab or "Exclusive")
	self:RefreshData()

	self.shopTween = TweenService:Create(
		self.shopFeature,
		TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = self.SHOP_SHOWN_POS }
	)
	self.shopTween.Completed:Connect(function()
		if curId == self.shopTweenId then
			self.shopTween = nil
		end
	end)
	self.shopTween:Play()
end

function Controller:CloseShop()
	self.shopTweenId += 1
	local curId = self.shopTweenId
	if self.shopTween then
		self.shopTween:Cancel()
		self.shopTween = nil
	end

	self.shopFeature:SetAttribute("IsOpen", false)
	self.modal.Visible = false

	self.shopTween = TweenService:Create(
		self.shopFeature,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = self.SHOP_HIDDEN_POS }
	)
	self.shopTween.Completed:Connect(function()
		if curId == self.shopTweenId then
			self.shopFeature.Visible = false
			self.shopTween = nil
		end
	end)
	self.shopTween:Play()
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
		local isOpen = self.shopFeature:GetAttribute("IsOpen") == true
		if not isOpen and self.shopFeature.Visible and (not self.shopTween or self.shopFeature.Position == self.SHOP_SHOWN_POS) then
			self:CloseShop()
		end
	end)

	if self.shopToolbarBtn then
		self.shopToolbarBtn.MouseButton1Click:Connect(function()
			if self.shopFeature:GetAttribute("IsOpen") == true then
				self:CloseShop()
			else
				self:OpenShop("Exclusive")
			end
		end)
	end
end
end

return Module
