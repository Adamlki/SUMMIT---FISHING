local Module = {}

function Module.Install(Controller)
-- ===================================================================
-- FORWARD DECLARATIONS
-- ===================================================================
-- Helper to equip / unequip tool locally or via server
function Controller:ToggleEquipToolByName(toolName, fallbackTab)
	if not toolName or toolName == "" then
		self:ToggleInventory(true)
		if fallbackTab then self:SwitchTab(fallbackTab) end
		return
	end

	local char = self.player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local backpack = self.player:FindFirstChild("Backpack")

	if humanoid then
		local equippedTool = char:FindFirstChild(toolName)
		if equippedTool and equippedTool:IsA("Tool") then
			humanoid:UnequipTools()
			return
		end

		local bpTool = backpack and backpack:FindFirstChild(toolName)
		if bpTool and bpTool:IsA("Tool") then
			humanoid:UnequipTools()
			humanoid:EquipTool(bpTool)
			return
		end
	end

	if self.isVIP then
		self.NetworkGateway:Request("PUT", "/inventory/equip-vip-tool", { ToolName = toolName })
	else
		self.NetworkGateway:Request("PUT", "/inventory/equip-tool", { ToolName = toolName })
	end
end

-- Helper when a tool is selected from self.Inventory
function Controller:OnAnyToolSelected(selectedToolName)
	self:PlayClickSound()
	if not selectedToolName or selectedToolName == "" then return end

	-- Slot 1 is STRICTLY for Rods. If a rod is selected, it belongs ONLY in Slot 1
	if self:IsRodName(selectedToolName) then
		self.lastEquippedRodName = selectedToolName
		self:SaveHotbarState()
		self:UpdateRodVisual(selectedToolName)
		self.NetworkGateway:Request("PUT", "/inventory/equip-rod", { RodName = selectedToolName })
		return
	end

	-- Tool non-rod is STRICTLY for Slot 2 and Slot 3!
	if self.lastEquippedToolName1 == selectedToolName then
		self:ToggleEquipToolByName(selectedToolName)
	elseif self.lastEquippedToolName2 == selectedToolName then
		self:ToggleEquipToolByName(selectedToolName)
	else
		if not self.lastEquippedToolName1 or self.lastEquippedToolName1 == "" then
			self.lastEquippedToolName1 = selectedToolName
			self:UpdateToolVisual1(selectedToolName)
		elseif not self.lastEquippedToolName2 or self.lastEquippedToolName2 == "" then
			self.lastEquippedToolName2 = selectedToolName
			self:UpdateToolVisual2(selectedToolName)
		else
			self.lastEquippedToolName1 = selectedToolName
			self:UpdateToolVisual1(selectedToolName)
		end
		self:SaveHotbarState()
		self:ToggleEquipToolByName(selectedToolName)
	end
end

-- ===================================================================
-- KEYBOARD SHORTCUTS (1-5 keys for hotbar, ~ / 4 for bag)
-- ===================================================================
function Controller:HandleKeyPress(input, gameProcessed)
	if gameProcessed then return end

	local keyCode = input.KeyCode

	-- Shortcut: Toggle Tas (Bag) via Backquote (~)
	if keyCode == Enum.KeyCode.Backquote or keyCode == Enum.KeyCode.Tilde then
		self:PlayClickSound()
		self:ToggleInventory(not self.isInventoryOpen)
		return
	end

	if self.isInventoryOpen then return end

	-- Shortcut 1: Rod
	if keyCode == Enum.KeyCode.One then
		self:PlayClickSound()
		local char = self.player.Character
		local currentTool = char and char:FindFirstChildOfClass("Tool")

		if currentTool and self.CollectionService:HasTag(currentTool, "Rod") then
			self.NetworkGateway:Request("DELETE", "/inventory/unequip-all", {})
		else
			if self.lastEquippedRodName then
				self.NetworkGateway:Request("PUT", "/inventory/equip-rod", { RodName = self.lastEquippedRodName })
			end
		end

	-- Shortcut 2: Tool 1 (biasa / admin)
	elseif keyCode == Enum.KeyCode.Two then
		if self.lastEquippedToolName1 and self.lastEquippedToolName1 ~= "" then
			self:PlayClickSound()
			self:ToggleEquipToolByName(self.lastEquippedToolName1, self.isVIP and "VIP" or "Tools")
		end

	-- Shortcut 3: Tool 2 (biasa / admin)
	elseif keyCode == Enum.KeyCode.Three then
		if self.lastEquippedToolName2 and self.lastEquippedToolName2 ~= "" then
			self:PlayClickSound()
			self:ToggleEquipToolByName(self.lastEquippedToolName2, self.isVIP and "VIP" or "Tools")
		end

	-- Shortcut 4: Fish 1 (Slot 4)
	elseif keyCode == Enum.KeyCode.Four then
		if self.lastEquippedFishId1 and self.Hotbar.FishSlot1 and self.Hotbar.FishSlot1.Visible then
			self:PlayClickSound()
			local char = self.player.Character
			local currentTool = char and char:FindFirstChildOfClass("Tool")

			if currentTool and currentTool:FindFirstChild("FishId") and currentTool.FishId.Value == self.lastEquippedFishId1 then
				self.NetworkGateway:Request("DELETE", "/inventory/unequip-all", {})
			else
				self.NetworkGateway:Request("PUT", "/inventory/equip-fish", { FishUniqueId = self.lastEquippedFishId1 })
			end
		end

	-- Shortcut 5: Fish 2 (Slot 5)
	elseif keyCode == Enum.KeyCode.Five then
		if self.lastEquippedFishId2 and self.Hotbar.FishSlot2 and self.Hotbar.FishSlot2.Visible then
			self:PlayClickSound()
			local char = self.player.Character
			local currentTool = char and char:FindFirstChildOfClass("Tool")

			if currentTool and currentTool:FindFirstChild("FishId") and currentTool.FishId.Value == self.lastEquippedFishId2 then
				self.NetworkGateway:Request("DELETE", "/inventory/unequip-all", {})
			else
				self.NetworkGateway:Request("PUT", "/inventory/equip-fish", { FishUniqueId = self.lastEquippedFishId2 })
			end
		end
	end
end

-- ===================================================================
-- BUTTON EVENT SETUP
-- ===================================================================

function Controller:SetupButtonEvents()
	for _, conn in ipairs(self.buttonConnections) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(self.buttonConnections)

	-- Slot 4: BagButton
	if self.Hotbar.BagButton then
		table.insert(self.buttonConnections, self.Hotbar.BagButton.MouseButton1Click:Connect(function()
			self:PlayClickSound()
			self:ToggleInventory(not self.isInventoryOpen)
		end))
	end

	-- Slot 1: RodSlot
	if self.Hotbar.RodSlot then
		table.insert(self.buttonConnections, self.Hotbar.RodSlot.MouseButton1Click:Connect(function()
			self:PlayClickSound()

			if self.isInventoryOpen then
				if self.lastEquippedRodName then
					self.NetworkGateway:Request("DELETE", "/inventory/unequip-all", {})
					self.lastEquippedRodName = nil
					self:UpdateRodVisual(nil)
					self:SaveHotbarState()
				end
				return
			end

			local char = self.player.Character
			local currentTool = char and char:FindFirstChildOfClass("Tool")

			if currentTool and self.CollectionService:HasTag(currentTool, "Rod") then
				self.NetworkGateway:Request("DELETE", "/inventory/unequip-all", {})
			else
				if self.lastEquippedRodName then
					local hasRod = false
					for _, rodName in ipairs(self.allRodData) do
						if rodName == self.lastEquippedRodName then
							hasRod = true
							break
						end
					end

					if hasRod then
						self.NetworkGateway:Request("PUT", "/inventory/equip-rod", { RodName = self.lastEquippedRodName })
					else
						self.lastEquippedRodName = nil
						self:UpdateRodVisual(nil)
						self:SaveHotbarState()
					end
				end
			end
		end))
	end

	-- Slot 2: ToolSlot1
	if self.Hotbar.ToolSlot1 then
		table.insert(self.buttonConnections, self.Hotbar.ToolSlot1.MouseButton1Click:Connect(function()
			self:PlayClickSound()
			self:ToggleEquipToolByName(self.lastEquippedToolName1, self.isVIP and "VIP" or "Tools")
		end))
	end

	-- Slot 3: ToolSlot2
	if self.Hotbar.ToolSlot2 then
		table.insert(self.buttonConnections, self.Hotbar.ToolSlot2.MouseButton1Click:Connect(function()
			self:PlayClickSound()
			self:ToggleEquipToolByName(self.lastEquippedToolName2, self.isVIP and "VIP" or "Tools")
		end))
	end

	-- Slot 4: FishSlot1
	if self.Hotbar.FishSlot1 then
		table.insert(self.buttonConnections, self.Hotbar.FishSlot1.MouseButton1Click:Connect(function()
			self:PlayClickSound()

			if self.isInventoryOpen then
				if self.lastEquippedFishId1 then
					self.NetworkGateway:Request("DELETE", "/inventory/unequip-all", {})
					self.lastEquippedFishId1 = nil
					self:UpdateFishVisual1(nil)
					self:SaveHotbarState()
				end
				return
			end

			local char = self.player.Character
			local currentTool = char and char:FindFirstChildOfClass("Tool")

			if currentTool and currentTool:FindFirstChild("FishId") and currentTool.FishId.Value == self.lastEquippedFishId1 then
				self.NetworkGateway:Request("DELETE", "/inventory/unequip-all", {})
			else
				if self.lastEquippedFishId1 then
					self.NetworkGateway:Request("PUT", "/inventory/equip-fish", { FishUniqueId = self.lastEquippedFishId1 })
				end
			end
		end))
	end

	-- Slot 5: FishSlot2
	if self.Hotbar.FishSlot2 then
		table.insert(self.buttonConnections, self.Hotbar.FishSlot2.MouseButton1Click:Connect(function()
			self:PlayClickSound()

			if self.isInventoryOpen then
				if self.lastEquippedFishId2 then
					self.NetworkGateway:Request("DELETE", "/inventory/unequip-all", {})
					self.lastEquippedFishId2 = nil
					self:UpdateFishVisual2(nil)
					self:SaveHotbarState()
				end
				return
			end

			local char = self.player.Character
			local currentTool = char and char:FindFirstChildOfClass("Tool")

			if currentTool and currentTool:FindFirstChild("FishId") and currentTool.FishId.Value == self.lastEquippedFishId2 then
				self.NetworkGateway:Request("DELETE", "/inventory/unequip-all", {})
			else
				if self.lastEquippedFishId2 then
					self.NetworkGateway:Request("PUT", "/inventory/equip-fish", { FishUniqueId = self.lastEquippedFishId2 })
				end
			end
		end))
	end

	-- self.Inventory Buttons
	if self.Inventory.CloseButton then
		local lastCloseClick = 0
		local function onCloseClick()
			if os.clock() - lastCloseClick < 0.2 then return end
			lastCloseClick = os.clock()
			self:PlayClickSound()
			self:ToggleInventory(false)
		end
		table.insert(self.buttonConnections, self.Inventory.CloseButton.MouseButton1Click:Connect(onCloseClick))
		table.insert(self.buttonConnections, self.Inventory.CloseButton.Activated:Connect(onCloseClick))
	end

	if self.Inventory.FishTabButton then
		table.insert(self.buttonConnections, self.Inventory.FishTabButton.MouseButton1Click:Connect(function()
			self:PlayClickSound()
			self:SwitchTab("Fish")
		end))
	end

	if self.Inventory.RodTabButton then
		table.insert(self.buttonConnections, self.Inventory.RodTabButton.MouseButton1Click:Connect(function()
			self:PlayClickSound()
			self:SwitchTab("Rods")
		end))
	end

	if self.Inventory.ToolTabButton then
		table.insert(self.buttonConnections, self.Inventory.ToolTabButton.MouseButton1Click:Connect(function()
			self:PlayClickSound()
			self:SwitchTab("Tools")
		end))
	end

	if self.Inventory.VIPTabButton then
		local lastVipClick = 0
		local function onVipClick()
			if os.clock() - lastVipClick < 0.2 then return end
			lastVipClick = os.clock()
			self:PlayClickSound()
			self:SwitchTab("VIP")
		end
		table.insert(self.buttonConnections, self.Inventory.VIPTabButton.MouseButton1Click:Connect(onVipClick))
	end

	if self.Inventory.SellAllButton then
		table.insert(self.buttonConnections, self.Inventory.SellAllButton.MouseButton1Click:Connect(function()
			self:PlayClickSound()

			if not self:HasRemoteSellPermission() then
				local fishingSys = self.ReplicatedStorage:FindFirstChild("FishingSystem")
				local cn = fishingSys and fishingSys:FindFirstChild("ClientNotification")
				if cn and cn:IsA("BindableEvent") then
					cn:Fire("Perk required! Purchase Remote Sell in the Exclusive Shop.", 3.5, Color3.fromRGB(255, 100, 100))
				end
				return
			end

			local ok, res = self.NetworkGateway:Request("DELETE", "/inventory/sell-all", {}):await()
			local sellSuccess = ok and type(res) == "table" and res.Success
			local earnedCoins = (sellSuccess and tonumber(res.Data)) or 0
			if sellSuccess then
				self.lastEquippedFishId1 = nil
				self.lastEquippedFishId2 = nil
				self:UpdateFishVisual1(nil)
				self:UpdateFishVisual2(nil)
				self:SaveHotbarState()

				self:RefreshAllData()

				local fishingSys = self.ReplicatedStorage:FindFirstChild("FishingSystem")
				local cn = fishingSys and fishingSys:FindFirstChild("ClientNotification")
				if cn and cn:IsA("BindableEvent") then
					cn:Fire(res.Message or string.format("Successfully sold fish! +%d Coins", earnedCoins), 3.5, Color3.fromRGB(100, 255, 140))
				end
			end
		end))
	end
end
end

return Module
