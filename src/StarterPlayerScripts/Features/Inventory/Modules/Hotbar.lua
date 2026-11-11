local Module = {}

function Module.Install(Controller)
-- Visual for Slot 1: Rod (STRICTLY RODS ONLY)
function Controller:UpdateRodVisual(rodName)
	if not rodName or rodName == "" then
		if self.Hotbar.RodViewport then self.Hotbar.RodViewport:ClearAllChildren(); self.Hotbar.RodViewport.Visible = false end
		if self.Hotbar.RodImage then self.Hotbar.RodImage.Image = "" end
		if self.Hotbar.RodName then
			self.Hotbar.RodName.Text = "ROD"
			self.Hotbar.RodName.TextColor3 = Color3.fromRGB(255, 255, 255)
			self.Hotbar.RodName.TextTransparency = 0
		end
		if self.Hotbar.RodSlot then
			self.Hotbar.RodSlot.ImageColor3 = Color3.fromRGB(255, 255, 255)
			self.Hotbar.RodSlot.BackgroundTransparency = 1
		end
		return
	end

	if self.Hotbar.RodViewport then
		self.Hotbar.RodViewport.ZIndex = 3
		self.Hotbar.RodViewport.Visible = true
		self:SetupRodViewport(self.Hotbar.RodViewport, rodName)
	end
	if self.Hotbar.RodImage then self.Hotbar.RodImage.Image = "" end
	if self.Hotbar.RodName then
		self.Hotbar.RodName.Text = rodName
		self.Hotbar.RodName.TextColor3 = Color3.fromRGB(255, 255, 255)
		self.Hotbar.RodName.TextTransparency = 0
	end

	local char = self.player.Character
	local isHolding = char and char:FindFirstChild(rodName)

	if self.Hotbar.RodSlot then
		self.Hotbar.RodSlot.BackgroundTransparency = 1
		if isHolding then
			self.Hotbar.RodSlot.ImageColor3 = Color3.fromRGB(255, 230, 160)
		else
			self.Hotbar.RodSlot.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

-- Visual for Slot 2: Tool 1 (STRICTLY NON-ROD TOOLS ONLY)
function Controller:UpdateToolVisual1(toolName)
	if not toolName or toolName == "" or self:IsRodName(toolName) then
		if self.Hotbar.ToolViewport1 then self.Hotbar.ToolViewport1:ClearAllChildren(); self.Hotbar.ToolViewport1.Visible = false end
		if self.Hotbar.ToolImage1 then self.Hotbar.ToolImage1.Image = "" end
		if self.Hotbar.ToolName1 then
			self.Hotbar.ToolName1.Text = "TOOLS"
			self.Hotbar.ToolName1.TextColor3 = Color3.fromRGB(255, 255, 255)
			self.Hotbar.ToolName1.TextTransparency = 0
		end
		if self.Hotbar.ToolSlot1 then
			self.Hotbar.ToolSlot1.ImageColor3 = Color3.fromRGB(255, 255, 255)
			self.Hotbar.ToolSlot1.BackgroundTransparency = 1
		end
		return
	end

	local icon = ""
	local tool = self.player.Backpack:FindFirstChild(toolName) or (self.player.Character and self.player.Character:FindFirstChild(toolName))
	if tool and tool:IsA("Tool") and tool.TextureId ~= "" then
		icon = tool.TextureId
	end

	if icon and icon ~= "" then
		if not icon:match("rbxassetid") and not icon:match("http") then
			icon = "rbxassetid://" .. icon
		end
		if self.Hotbar.ToolImage1 then
			self.Hotbar.ToolImage1.Image = icon
			self.Hotbar.ToolImage1.ImageTransparency = 0
			self.Hotbar.ToolImage1.Visible = true
		end
		if self.Hotbar.ToolViewport1 then self.Hotbar.ToolViewport1.Visible = false end
	else
		if self.Hotbar.ToolImage1 then self.Hotbar.ToolImage1.Image = "" end
		if self.Hotbar.ToolViewport1 then
			self.Hotbar.ToolViewport1.ZIndex = 3
			self.Hotbar.ToolViewport1.Visible = true
			self:SetupToolViewport(self.Hotbar.ToolViewport1, toolName)
		end
	end

	if self.Hotbar.ToolName1 then
		self.Hotbar.ToolName1.Text = toolName
		self.Hotbar.ToolName1.TextColor3 = Color3.fromRGB(255, 255, 255)
		self.Hotbar.ToolName1.TextTransparency = 0
	end

	local char = self.player.Character
	local isHolding = char and char:FindFirstChild(toolName)

	if self.Hotbar.ToolSlot1 then
		self.Hotbar.ToolSlot1.BackgroundTransparency = 1
		if isHolding then
			self.Hotbar.ToolSlot1.ImageColor3 = Color3.fromRGB(255, 230, 160)
		else
			self.Hotbar.ToolSlot1.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

-- Visual for Slot 3: Tool 2 (STRICTLY NON-ROD TOOLS ONLY)
function Controller:UpdateToolVisual2(toolName)
	if not toolName or toolName == "" or self:IsRodName(toolName) then
		if self.Hotbar.ToolViewport2 then self.Hotbar.ToolViewport2:ClearAllChildren(); self.Hotbar.ToolViewport2.Visible = false end
		if self.Hotbar.ToolImage2 then self.Hotbar.ToolImage2.Image = "" end
		if self.Hotbar.ToolName2 then
			self.Hotbar.ToolName2.Text = "TOOLS"
			self.Hotbar.ToolName2.TextColor3 = Color3.fromRGB(255, 255, 255)
			self.Hotbar.ToolName2.TextTransparency = 0
		end
		if self.Hotbar.ToolSlot2 then
			self.Hotbar.ToolSlot2.ImageColor3 = Color3.fromRGB(255, 255, 255)
			self.Hotbar.ToolSlot2.BackgroundTransparency = 1
		end
		return
	end

	local icon = ""
	local tool = self.player.Backpack:FindFirstChild(toolName) or (self.player.Character and self.player.Character:FindFirstChild(toolName))
	if tool and tool:IsA("Tool") and tool.TextureId ~= "" then
		icon = tool.TextureId
	end

	if icon and icon ~= "" then
		if not icon:match("rbxassetid") and not icon:match("http") then
			icon = "rbxassetid://" .. icon
		end
		if self.Hotbar.ToolImage2 then
			self.Hotbar.ToolImage2.Image = icon
			self.Hotbar.ToolImage2.ImageTransparency = 0
			self.Hotbar.ToolImage2.Visible = true
		end
		if self.Hotbar.ToolViewport2 then self.Hotbar.ToolViewport2.Visible = false end
	else
		if self.Hotbar.ToolImage2 then self.Hotbar.ToolImage2.Image = "" end
		if self.Hotbar.ToolViewport2 then
			self.Hotbar.ToolViewport2.ZIndex = 3
			self.Hotbar.ToolViewport2.Visible = true
			self:SetupToolViewport(self.Hotbar.ToolViewport2, toolName)
		end
	end

	if self.Hotbar.ToolName2 then
		self.Hotbar.ToolName2.Text = toolName
		self.Hotbar.ToolName2.TextColor3 = Color3.fromRGB(255, 255, 255)
		self.Hotbar.ToolName2.TextTransparency = 0
	end

	local char = self.player.Character
	local isHolding = char and char:FindFirstChild(toolName)

	if self.Hotbar.ToolSlot2 then
		self.Hotbar.ToolSlot2.BackgroundTransparency = 1
		if isHolding then
			self.Hotbar.ToolSlot2.ImageColor3 = Color3.fromRGB(255, 230, 160)
		else
			self.Hotbar.ToolSlot2.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

-- Visual for Slot 4: Fish 1
function Controller:UpdateFishVisual1(fishId)
	if not fishId then
		if self.Hotbar.FishViewport1 then self.Hotbar.FishViewport1:ClearAllChildren(); self.Hotbar.FishViewport1.Visible = false end
		if self.Hotbar.FishImage1 then self.Hotbar.FishImage1.Image = "" end
		if self.Hotbar.FishName1 then self.Hotbar.FishName1.Text = "FISH" end
		if self.Hotbar.FishSlot1 then
			self.Hotbar.FishSlot1.Visible = true
			self.Hotbar.FishSlot1.ImageColor3 = Color3.fromRGB(255, 255, 255)
			self.Hotbar.FishSlot1.BackgroundTransparency = 1
		end
		return
	end

	local fishData = nil
	for _, f in ipairs(self.allFishData) do
		if f.uniqueId == fishId then
			fishData = f
			break
		end
	end

	if fishData then
		local fishTemplate = self.fishAssetFolder:FindFirstChild(fishData.name)
		local textureId = ""

		if fishTemplate and fishTemplate:IsA("Tool") and fishTemplate.TextureId ~= "" then
			local textureIdString = tostring(fishTemplate.TextureId)
			textureId = textureIdString
			if not textureId:match("rbxassetid") then
				textureId = "rbxassetid://" .. textureId
			end
		end

		if self.Hotbar.FishViewport1 then
			self:SetupFishViewport(self.Hotbar.FishViewport1, fishData.name)
			self.Hotbar.FishViewport1.Visible = true
		end
		if self.Hotbar.FishImage1 then self.Hotbar.FishImage1.Image = "" end
		if self.Hotbar.FishName1 then self.Hotbar.FishName1.Text = fishData.name end
		if self.Hotbar.FishSlot1 then
			self.Hotbar.FishSlot1.Visible = true
			self.Hotbar.FishSlot1.BackgroundTransparency = 1
		end
	else
		if self.Hotbar.FishImage1 then self.Hotbar.FishImage1.Image = "" end
		if self.Hotbar.FishName1 then self.Hotbar.FishName1.Text = "FISH" end
		if self.Hotbar.FishSlot1 then
			self.Hotbar.FishSlot1.Visible = true
			self.Hotbar.FishSlot1.BackgroundTransparency = 1
		end
		return
	end

	local char = self.player.Character
	local currentTool = char and char:FindFirstChildOfClass("Tool")
	local isHoldingThisFish = (currentTool and currentTool:FindFirstChild("FishId") and currentTool.FishId.Value == fishId)

	if self.Hotbar.FishSlot1 then
		self.Hotbar.FishSlot1.BackgroundTransparency = 1
		if isHoldingThisFish then
			self.Hotbar.FishSlot1.ImageColor3 = Color3.fromRGB(255, 230, 160)
		else
			self.Hotbar.FishSlot1.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

-- Visual for Slot 5: Fish 2
function Controller:UpdateFishVisual2(fishId)
	if not fishId then
		if self.Hotbar.FishViewport2 then self.Hotbar.FishViewport2:ClearAllChildren(); self.Hotbar.FishViewport2.Visible = false end
		if self.Hotbar.FishImage2 then self.Hotbar.FishImage2.Image = "" end
		if self.Hotbar.FishName2 then self.Hotbar.FishName2.Text = "FISH" end
		if self.Hotbar.FishSlot2 then
			self.Hotbar.FishSlot2.Visible = true
			self.Hotbar.FishSlot2.ImageColor3 = Color3.fromRGB(255, 255, 255)
			self.Hotbar.FishSlot2.BackgroundTransparency = 1
		end
		return
	end

	local fishData = nil
	for _, f in ipairs(self.allFishData) do
		if f.uniqueId == fishId then
			fishData = f
			break
		end
	end

	if fishData then
		local fishTemplate = self.fishAssetFolder:FindFirstChild(fishData.name)
		local textureId = ""

		if fishTemplate and fishTemplate:IsA("Tool") and fishTemplate.TextureId ~= "" then
			local textureIdString = tostring(fishTemplate.TextureId)
			textureId = textureIdString
			if not textureId:match("rbxassetid") then
				textureId = "rbxassetid://" .. textureId
			end
		end

		if self.Hotbar.FishViewport2 then
			self:SetupFishViewport(self.Hotbar.FishViewport2, fishData.name)
			self.Hotbar.FishViewport2.Visible = true
		end
		if self.Hotbar.FishImage2 then self.Hotbar.FishImage2.Image = "" end
		if self.Hotbar.FishName2 then self.Hotbar.FishName2.Text = fishData.name end
		if self.Hotbar.FishSlot2 then
			self.Hotbar.FishSlot2.Visible = true
			self.Hotbar.FishSlot2.BackgroundTransparency = 1
		end
	else
		if self.Hotbar.FishImage2 then self.Hotbar.FishImage2.Image = "" end
		if self.Hotbar.FishName2 then self.Hotbar.FishName2.Text = "FISH" end
		if self.Hotbar.FishSlot2 then
			self.Hotbar.FishSlot2.Visible = true
			self.Hotbar.FishSlot2.BackgroundTransparency = 1
		end
		return
	end

	local char = self.player.Character
	local currentTool = char and char:FindFirstChildOfClass("Tool")
	local isHoldingThisFish = (currentTool and currentTool:FindFirstChild("FishId") and currentTool.FishId.Value == fishId)

	if self.Hotbar.FishSlot2 then
		self.Hotbar.FishSlot2.BackgroundTransparency = 1
		if isHoldingThisFish then
			self.Hotbar.FishSlot2.ImageColor3 = Color3.fromRGB(255, 230, 160)
		else
			self.Hotbar.FishSlot2.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

-- ===================================================================
-- STATE MANAGEMENT FUNCTIONS
-- ===================================================================

function Controller:RestoreHotbarState()
	self.lastEquippedRodName = self.HotbarState.rod
	self.lastEquippedToolName1 = self.HotbarState.tool1
	self.lastEquippedToolName2 = self.HotbarState.tool2
	self.lastEquippedFishId1 = self.HotbarState.fish1
	self.lastEquippedFishId2 = self.HotbarState.fish2

	self:UpdateRodVisual(self.lastEquippedRodName)
	self:UpdateToolVisual1(self.lastEquippedToolName1)
	self:UpdateToolVisual2(self.lastEquippedToolName2)
	self:UpdateFishVisual1(self.lastEquippedFishId1)
	self:UpdateFishVisual2(self.lastEquippedFishId2)
end

function Controller:ValidateHotbarItems()
	local backpack = self.player:FindFirstChild("Backpack")
	if not backpack then return end

	-- Validate Rod
	if self.lastEquippedRodName then
		local rodExists = backpack:FindFirstChild(self.lastEquippedRodName) or
			(self.player.Character and self.player.Character:FindFirstChild(self.lastEquippedRodName))
		if not rodExists then
			local hasRod = false
			for _, rodName in ipairs(self.allRodData) do
				if rodName == self.lastEquippedRodName then
					hasRod = true
					break
				end
			end
			if not hasRod then
				self.lastEquippedRodName = nil
				self:UpdateRodVisual(nil)
			end
		end
	end

	-- Validate Tool 1
	if self.lastEquippedToolName1 then
		local toolExists = backpack:FindFirstChild(self.lastEquippedToolName1) or
			(self.player.Character and self.player.Character:FindFirstChild(self.lastEquippedToolName1))
		if not toolExists then
			self.lastEquippedToolName1 = nil
			self:UpdateToolVisual1(nil)
			self:SaveHotbarState()
		end
	end

	-- Validate Tool 2
	if self.lastEquippedToolName2 then
		local toolExists = backpack:FindFirstChild(self.lastEquippedToolName2) or
			(self.player.Character and self.player.Character:FindFirstChild(self.lastEquippedToolName2))
		if not toolExists then
			self.lastEquippedToolName2 = nil
			self:UpdateToolVisual2(nil)
			self:SaveHotbarState()
		end
	end

	-- Validate Fish 1
	if self.lastEquippedFishId1 then
		local fishExists = false
		for _, fishData in ipairs(self.allFishData) do
			if fishData.uniqueId == self.lastEquippedFishId1 then
				fishExists = true
				break
			end
		end
		if not fishExists then
			self.lastEquippedFishId1 = nil
			self:UpdateFishVisual1(nil)
			self:SaveHotbarState()
		end
	end

	-- Validate Fish 2
	if self.lastEquippedFishId2 then
		local fishExists = false
		for _, fishData in ipairs(self.allFishData) do
			if fishData.uniqueId == self.lastEquippedFishId2 then
				fishExists = true
				break
			end
		end
		if not fishExists then
			self.lastEquippedFishId2 = nil
			self:UpdateFishVisual2(nil)
			self:SaveHotbarState()
		end
	end
end

function Controller:AutoFillHotbarSlots()
	self:ValidateHotbarItems()

	local backpack = self.player:FindFirstChild("Backpack")
	local char = self.player.Character

	-- Auto fill rod if slot 1 is empty
	if not self.lastEquippedRodName or self.lastEquippedRodName == "" then
		local foundRod = nil
		if table.find(self.allRodData, "Basic Rod") then
			foundRod = "Basic Rod"
		elseif backpack and backpack:FindFirstChild("Basic Rod") then
			foundRod = "Basic Rod"
		elseif char and char:FindFirstChild("Basic Rod") then
			foundRod = "Basic Rod"
		elseif #self.allRodData > 0 then
			foundRod = self.allRodData[1]
		else
			local function findRodIn(parent)
				if not parent then return end
				for _, item in ipairs(parent:GetChildren()) do
					if item:IsA("Tool") and self.CollectionService:HasTag(item, "Rod") then
						return item.Name
					end
				end
			end
			foundRod = findRodIn(backpack) or findRodIn(char)
		end

		if foundRod then
			self.lastEquippedRodName = foundRod
			self:UpdateRodVisual(self.lastEquippedRodName)
		end
	end

	-- Clean up if any rod accidentally leaked into tool slots
	if self.lastEquippedToolName1 and self:IsRodName(self.lastEquippedToolName1) then
		self.lastEquippedToolName1 = nil
	end
	if self.lastEquippedToolName2 and self:IsRodName(self.lastEquippedToolName2) then
		self.lastEquippedToolName2 = nil
	end

	-- Auto fill tools if slots are empty (STRICTLY NON-ROD TOOLS)
	local backpack = self.player:FindFirstChild("Backpack")
	local char = self.player.Character
	local availableTools = {}

	local function collectTools(parent)
		if not parent then return end
		for _, item in ipairs(parent:GetChildren()) do
			if item:IsA("Tool") and not self:IsRodName(item.Name) and not self.CollectionService:HasTag(item, "Rod") and not item:FindFirstChild("FishId") then
				if not table.find(availableTools, item.Name) then
					table.insert(availableTools, item.Name)
				end
			end
		end
	end

	collectTools(char)
	collectTools(backpack)

	if not self.lastEquippedToolName1 and #availableTools > 0 then
		self.lastEquippedToolName1 = availableTools[1]
		self:UpdateToolVisual1(self.lastEquippedToolName1)
	end

	if not self.lastEquippedToolName2 and #availableTools > 1 then
		for _, tName in ipairs(availableTools) do
			if tName ~= self.lastEquippedToolName1 then
				self.lastEquippedToolName2 = tName
				self:UpdateToolVisual2(self.lastEquippedToolName2)
				break
			end
		end
	end

	self:SaveHotbarState()
end

function Controller:OnToolChanged(tool)
	if tool and tool:IsA("Tool") and (self:IsRodName(tool.Name) or self.CollectionService:HasTag(tool, "Rod")) then
		self.lastEquippedRodName = tool.Name
		self:SaveHotbarState()
		self:UpdateRodVisual(tool.Name)
		self:UpdateToolVisual1(self.lastEquippedToolName1)
		self:UpdateToolVisual2(self.lastEquippedToolName2)
		self:UpdateFishVisual1(self.lastEquippedFishId1)
		self:UpdateFishVisual2(self.lastEquippedFishId2)
	elseif tool and tool:IsA("Tool") and tool:FindFirstChild("FishId") then
		self:UpdateRodVisual(self.lastEquippedRodName)
		self:UpdateToolVisual1(self.lastEquippedToolName1)
		self:UpdateToolVisual2(self.lastEquippedToolName2)
		self:UpdateFishVisual1(self.lastEquippedFishId1)
		self:UpdateFishVisual2(self.lastEquippedFishId2)
	elseif tool and tool:IsA("Tool") then
		-- Strictly non-rod tool: never put into slot 1.
		if self.lastEquippedToolName1 == tool.Name then
			-- already in slot 2
		elseif self.lastEquippedToolName2 == tool.Name then
			-- already in slot 3
		else
			if not self.lastEquippedToolName1 or self.lastEquippedToolName1 == "" then
				self.lastEquippedToolName1 = tool.Name
			elseif not self.lastEquippedToolName2 or self.lastEquippedToolName2 == "" then
				self.lastEquippedToolName2 = tool.Name
			else
				self.lastEquippedToolName1 = tool.Name
			end
		end
		self:SaveHotbarState()
		self:UpdateRodVisual(self.lastEquippedRodName)
		self:UpdateToolVisual1(self.lastEquippedToolName1)
		self:UpdateToolVisual2(self.lastEquippedToolName2)
		self:UpdateFishVisual1(self.lastEquippedFishId1)
		self:UpdateFishVisual2(self.lastEquippedFishId2)
	else
		self:UpdateRodVisual(self.lastEquippedRodName)
		self:UpdateToolVisual1(self.lastEquippedToolName1)
		self:UpdateToolVisual2(self.lastEquippedToolName2)
		self:UpdateFishVisual1(self.lastEquippedFishId1)
		self:UpdateFishVisual2(self.lastEquippedFishId2)
	end
end
end

return Module
