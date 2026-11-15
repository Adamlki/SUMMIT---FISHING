local Players = game:GetService("Players")

local Module = {}

local Panel
local function getPanel()
	if not Panel then
		Panel = require(
			Players.LocalPlayer:WaitForChild("PlayerScripts")
				:WaitForChild("Features")
				:WaitForChild("SummitKit")
				:WaitForChild("Client")
				:WaitForChild("Modules")
				:WaitForChild("UI")
				:WaitForChild("Panel", 30)
		)
	end
	return Panel
end

function Module.Install(Controller)
function Controller:SetIndexVisible(visible)
	self.mainFrame:SetAttribute("IsOpen", visible)
	self.gui:SetAttribute("IsOpen", visible)

	if visible then
		self.gui.Enabled = true
		if self.refreshGrid then
			task.spawn(self.refreshGrid)
		end
		getPanel().open(self.mainFrame)
	else
		getPanel().close(self.mainFrame)
	end
end

function Controller:ToggleIndex()
	local now = os.clock()
	if now - self.lastToggleTime < 0.25 then return end
	self.lastToggleTime = now
	self:SetIndexVisible(not getPanel().isOpen(self.mainFrame))
end

function Controller:SetupWindow()
	self.closeBtn.MouseButton1Click:Connect(function()
		self:SetIndexVisible(false)
	end)

	self.mainFrame:GetAttributeChangedSignal("IsOpen"):Connect(function()
		if self.mainFrame:GetAttribute("IsOpen") ~= true and getPanel().isOpen(self.mainFrame) then
			self:SetIndexVisible(false)
		end
	end)

	task.spawn(function()
		local playerGui = self.player:WaitForChild("PlayerGui")
		local gameUI = playerGui:WaitForChild("GameUI", 15)
		if gameUI then
			local component = gameUI:WaitForChild("Component", 15)
			local buttons = component and component:WaitForChild("ButtonsNew", 15)
			local menuAtas = buttons and buttons:WaitForChild("MenuAtas", 15)
			local topFrame = menuAtas and menuAtas:WaitForChild("Frame", 15)
			local indexBtn = topFrame and topFrame:WaitForChild("IndexButton", 15)
			if indexBtn then
				indexBtn.MouseButton1Click:Connect(function()
					self:ToggleIndex()
				end)
			end
		end
	end)

	self.mainFrame:SetAttribute("ShownPos", self.INDEX_SHOWN_POS)
	self.mainFrame:SetAttribute("HiddenPos", self.INDEX_HIDDEN_POS)
	self.mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	self.mainFrame.Position = self.INDEX_HIDDEN_POS
	self.mainFrame.Visible = false
	self.mainFrame:SetAttribute("IsOpen", false)
	self.gui:SetAttribute("IsOpen", false)
	self.gui.Enabled = false
end

end

return Module
