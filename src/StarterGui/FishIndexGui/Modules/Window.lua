local Module = {}

function Module.Install(Controller)
function Controller:SetIndexVisible(visible)
	self.indexTweenId += 1
	local curId = self.indexTweenId
	if self.indexTween then
		self.indexTween:Cancel()
		self.indexTween = nil
	end

	self.mainFrame:SetAttribute("IsOpen", visible)
	self.gui:SetAttribute("IsOpen", visible)

	if visible then
		self.gui.Enabled = true
		self.mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		self.mainFrame.Position = self.INDEX_HIDDEN_POS
		self.mainFrame.Visible = true

		if self.refreshGrid then
			task.spawn(self.refreshGrid)
		end

		self.indexTween = self.TweenService:Create(
			self.mainFrame,
			TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = self.INDEX_SHOWN_POS }
		)
		self.indexTween.Completed:Connect(function()
			if curId == self.indexTweenId then
				self.indexTween = nil
			end
		end)
		self.indexTween:Play()
	else
		self.indexTween = self.TweenService:Create(
			self.mainFrame,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = self.INDEX_HIDDEN_POS }
		)
		self.indexTween.Completed:Connect(function()
			if curId == self.indexTweenId then
				self.mainFrame.Visible = false
				self.gui.Enabled = false
				self.indexTween = nil
			end
		end)
		self.indexTween:Play()
	end
end

function Controller:ToggleIndex()
	local now = os.clock()
	if now - self.lastToggleTime < 0.25 then return end
	self.lastToggleTime = now

	local isOpen = self.mainFrame:GetAttribute("IsOpen") == true
	self:SetIndexVisible(not isOpen)
end

function Controller:SetupWindow()
	self.closeBtn.MouseButton1Click:Connect(function()
		self:SetIndexVisible(false)
	end)

	self.mainFrame:GetAttributeChangedSignal("IsOpen"):Connect(function()
		local isOpen = self.mainFrame:GetAttribute("IsOpen") == true
		if not isOpen and (self.mainFrame.Visible or self.gui.Enabled) and (not self.indexTween or self.mainFrame.Position == self.INDEX_SHOWN_POS) then
			self:SetIndexVisible(false)
		end
	end)

	task.spawn(function()
		local playerGui = self.player:WaitForChild("PlayerGui")
		local gameUI = playerGui:WaitForChild("GameUI", 15)
		if gameUI then
			local component = gameUI:WaitForChild("Component", 15)
			local buttons = component and component:WaitForChild("Buttons", 15)
			local leftHolder = buttons and buttons:WaitForChild("LeftHolder", 15)
			local indexBtn = leftHolder and leftHolder:WaitForChild("Index", 15)
			if indexBtn then
				indexBtn.MouseButton1Click:Connect(function()
					self:ToggleIndex()
				end)
			end
		end
	end)

	self.mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	self.mainFrame.Position = self.INDEX_HIDDEN_POS
	self.mainFrame.Visible = false
	self.mainFrame:SetAttribute("IsOpen", false)
	self.gui:SetAttribute("IsOpen", false)
	self.gui.Enabled = false
end

end

return Module
