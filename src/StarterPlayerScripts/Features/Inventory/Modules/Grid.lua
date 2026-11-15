local Module = {}

function Module.Install(Controller)
-- ===================================================================
-- LOGIC FUNCTIONS
-- ===================================================================

function Controller:PopulateFishGrid()
	if not self.Templates.Item then
		warn("[CustomInventory] ItemTemplate not found in CustomInventoryGui.Templates")
		return
	end

	for _, child in ipairs(self.Inventory.FishContent:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	local rarityOrder = {
		Secret = 8,
		Mitos = 7,
		Legendary = 6,
		Mythical = 5,
		Epic = 4,
		Rare = 3,
		Uncommon = 2,
		Common = 1
	}

	table.sort(self.allFishData, function(a, b)
		if a.isFavorited ~= b.isFavorited then return a.isFavorited end
		local rarityA = rarityOrder[a.rarity] or 0
		local rarityB = rarityOrder[b.rarity] or 0
		if rarityA ~= rarityB then return rarityA > rarityB end
		return a.weight > b.weight
	end)

	for _, fishData in ipairs(self.allFishData) do
		local card = self.Templates.Item:Clone()
		card.Name = fishData.uniqueId
		card.Visible = true
		card:SetAttribute("HotbarType", "Fish")
		card:SetAttribute("HotbarId", fishData.uniqueId)

		local itemImage = card:FindFirstChild("ItemImage")
		local itemIcon = itemImage and itemImage:FindFirstChild("ItemIcon")
		local itemName = card:FindFirstChild("ItemName")
		local itemInfo = card:FindFirstChild("ItemInfo")
		local itemRarity = card:FindFirstChild("ItemRarity")
		local favoriteButton = card:FindFirstChild("FavoriteButton")
		local clickArea = card:FindFirstChild("ClickArea")
		local badge = card:FindFirstChild("Badge")
		local uiStroke = card:FindFirstChildOfClass("UIStroke") or (itemImage and itemImage:FindFirstChildOfClass("UIStroke"))

		if not itemImage or not itemName or not itemInfo or not itemRarity or not favoriteButton or not clickArea then
			card:Destroy()
			continue
		end

		if badge then badge.Visible = false end
		favoriteButton.Visible = true
		itemRarity.Visible = true
		if itemIcon then
			itemIcon.Image = ""
			itemIcon.Visible = false
		end

		local itemViewport = itemImage:FindFirstChild("ItemViewport")
		if not itemViewport then
			itemViewport = Instance.new("ViewportFrame")
			itemViewport.Name = "ItemViewport"
			itemViewport.Size = UDim2.new(1, 0, 1, 0)
			itemViewport.Position = UDim2.new(0, 0, 0, 0)
			itemViewport.BackgroundTransparency = 1
			itemViewport.BorderSizePixel = 0
			itemViewport.ZIndex = itemImage.ZIndex + 1
			itemViewport.Parent = itemImage
		end

		itemViewport.Visible = true
		self:SetupFishViewport(itemViewport, fishData.name)
		local rarityColor = self:GetRarityColor(fishData.rarity)
		local mutationName = fishData.mutation
		local mutationColor = mutationName and mutationName ~= "" and self.FishingConfig.GetMutationColor(mutationName) or nil
		if uiStroke then uiStroke.Color = mutationColor or rarityColor end

		itemName.Text = fishData.name
		itemInfo.Text = string.format("%.1fkg", fishData.weight)
		if mutationName and mutationName ~= "" then
			itemRarity.Text = string.format("%s %s", mutationName, fishData.rarity)
			itemRarity.TextColor3 = mutationColor
		else
			itemRarity.Text = fishData.rarity
			itemRarity.TextColor3 = rarityColor
		end

		if fishData.isFavorited then
			favoriteButton.Text = "⭐"
			favoriteButton.TextColor3 = Color3.fromRGB(255, 220, 0)
		else
			favoriteButton.Text = "☆"
			favoriteButton.TextColor3 = Color3.fromRGB(150, 150, 150)
		end

		favoriteButton.MouseButton1Click:Connect(function()
			self:PlayClickSound()
			local ok, res = self.NetworkGateway:Request("PUT", "/inventory/toggle-favorite", { FishUniqueId = fishData.uniqueId }):await()
			if ok and type(res) == "table" and res.Success then
				local newStatus = res.Data
				fishData.isFavorited = newStatus
				if newStatus then
					favoriteButton.Text = "⭐"
					favoriteButton.TextColor3 = Color3.fromRGB(255, 220, 0)
				else
					favoriteButton.Text = "☆"
					favoriteButton.TextColor3 = Color3.fromRGB(150, 150, 150)
				end
			end
		end)

		-- Klik Ikan di Tas: Assign ke Slot 5 atau Slot 6
		clickArea.MouseButton1Click:Connect(function()
			self:PlayClickSound()
			local equippedFishId = fishData.uniqueId
			local targetFishId = nil

			if self.lastEquippedFishId1 == equippedFishId then
				targetFishId = equippedFishId
			elseif self.lastEquippedFishId2 == equippedFishId then
				targetFishId = equippedFishId
			else
				if not self.lastEquippedFishId1 then
					self.lastEquippedFishId1 = equippedFishId
					targetFishId = equippedFishId
					self:UpdateFishVisual1(equippedFishId)
				elseif not self.lastEquippedFishId2 then
					self.lastEquippedFishId2 = equippedFishId
					targetFishId = equippedFishId
					self:UpdateFishVisual2(equippedFishId)
				else
					self.lastEquippedFishId1 = equippedFishId
					targetFishId = equippedFishId
					self:UpdateFishVisual1(equippedFishId)
				end
				self:SaveHotbarState()
			end

			if targetFishId then
				local char = self.player.Character
				local currentTool = char and char:FindFirstChildOfClass("Tool")
				if currentTool and currentTool:FindFirstChild("FishId") and currentTool.FishId.Value == targetFishId then
					self.NetworkGateway:Request("DELETE", "/inventory/unequip-all", {})
				else
					self.NetworkGateway:Request("PUT", "/inventory/equip-fish", { FishUniqueId = targetFishId })
				end
			end
		end)

		card.Parent = self.Inventory.FishContent
	end

	self:UpdateFishCount()
	self:UpdateEmptyState()
	self:RefreshCardHighlights()
end

function Controller:PopulateRodGrid()
	if not self.Templates.Item then
		warn("[CustomInventory] ItemTemplate not found in CustomInventoryGui.Templates")
		return
	end

	for _, child in ipairs(self.Inventory.RodContent:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	local currentMultiplier = self.GlobalLuckVal and self.GlobalLuckVal.Value or 1

	table.sort(self.allRodData, function(a, b)
		local statsA = self.rodToolStats[a] and self.rodToolStats[a].Stats or self.FishingConfig.GetRodConfig(a)
		local statsB = self.rodToolStats[b] and self.rodToolStats[b].Stats or self.FishingConfig.GetRodConfig(b)
		local luckA = statsA.baseLuck or 0
		local luckB = statsB.baseLuck or 0
		return luckA > luckB
	end)

	for _, rodName in ipairs(self.allRodData) do
		local card = self.Templates.Item:Clone()
		card.Name = rodName
		card.Visible = true
		card:SetAttribute("HotbarType", "Rod")
		card:SetAttribute("HotbarId", rodName)

		local itemName = card:FindFirstChild("ItemName")
		local itemImage = card:FindFirstChild("ItemImage")
		local itemIcon = itemImage and itemImage:FindFirstChild("ItemIcon")
		local itemInfo = card:FindFirstChild("ItemInfo")
		local itemRarity = card:FindFirstChild("ItemRarity")
		local favoriteButton = card:FindFirstChild("FavoriteButton")
		local clickArea = card:FindFirstChild("ClickArea")
		local badge = card:FindFirstChild("Badge")

		if not itemName or not itemImage or not itemInfo or not clickArea then
			card:Destroy()
			continue
		end

		if favoriteButton then favoriteButton.Visible = false end
		if itemRarity then itemRarity.Visible = false end
		if badge then badge.Visible = false end
		if itemIcon then
			itemIcon.Image = ""
			itemIcon.Visible = false
		end

		local cachedData = self.rodToolStats[rodName]
		local stats = cachedData and cachedData.Stats or self.FishingConfig.GetRodConfig(rodName)
		local textureId = cachedData and cachedData.TextureId or ""

		if textureId ~= "" and not textureId:match("rbxassetid") then
			textureId = "rbxassetid://" .. textureId
		end

		itemName.Text = rodName
		local itemViewport = itemImage:FindFirstChild("ItemViewport")
		if not itemViewport then
			itemViewport = Instance.new("ViewportFrame")
			itemViewport.Name = "ItemViewport"
			itemViewport.Size = UDim2.new(1, 0, 1, 0)
			itemViewport.Position = UDim2.new(0, 0, 0, 0)
			itemViewport.BackgroundTransparency = 1
			itemViewport.BorderSizePixel = 0
			itemViewport.Active = false
			itemViewport.ZIndex = itemImage.ZIndex + 1
			itemViewport.Parent = itemImage
		end
		self:SetupRodViewport(itemViewport, rodName)

		local baseLuck = stats.baseLuck or 1.0
		local finalLuck = baseLuck * currentMultiplier
		local roundedLuck = math.round(finalLuck)
		local weight = stats.maxWeight or 0
		local luckPercentage = roundedLuck * 100

		if currentMultiplier > 1 then
			itemInfo.RichText = true
			itemInfo.Text = string.format("Luck: <font color='#00FF00'><b>%d%%</b></font>\nWeight: %dkg", luckPercentage, weight)
		else
			itemInfo.RichText = false
			itemInfo.Text = string.format("Luck: %d%%\nWeight: %dkg", luckPercentage, weight)
		end

		clickArea.MouseButton1Click:Connect(function()
			self:PlayClickSound()
			self.lastEquippedRodName = rodName
			self:SaveHotbarState()
			self:UpdateRodVisual(rodName)
			self.NetworkGateway:Request("PUT", "/inventory/equip-rod", { RodName = rodName })
		end)

		card.Parent = self.Inventory.RodContent
	end

	self:UpdateEmptyState()
	self:RefreshCardHighlights()
end

function Controller:PopulateToolGrid()
	if not self.Templates.Item then
		warn("[CustomInventory] ItemTemplate not found in CustomInventoryGui.Templates")
		return
	end

	for _, child in ipairs(self.Inventory.ToolContent:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	local genericTools = {}
	local addedTools = {}
	-- VIP players keep access to their VIP tools through the Tools tab;
	-- admins get them in the Admin tab instead.
	local includeVIPTools = self.isVIP and not self.isAdmin

	local function isExcludedTool(toolName)
		for _, r in pairs(self.RoleConfig.Roles) do
			if r.AutoGrantTools and table.find(r.AutoGrantTools, toolName) then
				return true
			end
		end
		return false
	end

	local backpack = self.player:WaitForChild("Backpack")
	for _, tool in ipairs(backpack:GetChildren()) do
		if not tool:IsA("Tool") then continue end

		local isFish = tool:FindFirstChild("FishId")
		local isRod = self.CollectionService:HasTag(tool, "Rod")
		local isVIPTool = self.CollectionService:HasTag(tool, "VIPTool")
		local isRoleTool = isExcludedTool(tool.Name)

		if not isFish and not isRod and (not isVIPTool or includeVIPTools) and not isRoleTool and not addedTools[tool.Name] then
			table.insert(genericTools, tool)
			addedTools[tool.Name] = true
		end
	end

	for _, tool in ipairs(self.StarterPack:GetChildren()) do
		if not tool:IsA("Tool") then continue end

		local isFish = tool:FindFirstChild("FishId")
		local isRod = self.CollectionService:HasTag(tool, "Rod")
		local isVIPTool = self.CollectionService:HasTag(tool, "VIPTool")
		local isRoleTool = isExcludedTool(tool.Name)

		if not isFish and not isRod and (not isVIPTool or includeVIPTools) and not isRoleTool and not addedTools[tool.Name] then
			table.insert(genericTools, tool)
			addedTools[tool.Name] = true
		end
	end

	table.sort(genericTools, function(a, b)
		return a.Name < b.Name
	end)

	for _, tool in ipairs(genericTools) do
		local card = self.Templates.Item:Clone()
		card.Name = tool.Name
		card.Visible = true
		card:SetAttribute("HotbarType", "Tool")
		card:SetAttribute("HotbarId", tool.Name)

		local itemImage = card:FindFirstChild("ItemImage")
		local itemIcon = itemImage and itemImage:FindFirstChild("ItemIcon")
		local itemName = card:FindFirstChild("ItemName")
		local itemInfo = card:FindFirstChild("ItemInfo")
		local itemRarity = card:FindFirstChild("ItemRarity")
		local favoriteButton = card:FindFirstChild("FavoriteButton")
		local clickArea = card:FindFirstChild("ClickArea")
		local badge = card:FindFirstChild("Badge")

		if not itemImage or not itemIcon or not itemName or not itemInfo or not clickArea then
			card:Destroy()
			continue
		end

		if itemRarity then itemRarity.Visible = false end
		if favoriteButton then favoriteButton.Visible = false end
		if badge then badge.Visible = false end

		itemName.Text = tool.Name
		itemInfo.Text = "Tool"
		local itemViewport = itemImage:FindFirstChild("ItemViewport")
		if not itemViewport then
			itemViewport = Instance.new("ViewportFrame")
			itemViewport.Name = "ItemViewport"
			itemViewport.Size = UDim2.new(1, 0, 1, 0)
			itemViewport.Position = UDim2.new(0, 0, 0, 0)
			itemViewport.BackgroundTransparency = 1
			itemViewport.BorderSizePixel = 0
			itemViewport.Active = false
			itemViewport.ZIndex = itemImage.ZIndex + 1
			itemViewport.Parent = itemImage
		end

		local icon = ""
		if tool:IsA("Tool") and tool.TextureId ~= "" then
			icon = tool.TextureId
		end

		if icon and icon ~= "" then
			if not icon:match("rbxassetid") and not icon:match("http") then
				icon = "rbxassetid://" .. icon
			end
			itemIcon.Image = icon
			itemIcon.ImageTransparency = 0
			itemIcon.Visible = true
			itemViewport.Visible = false
		else
			itemIcon.Image = ""
			itemIcon.Visible = false
			itemViewport.Visible = true
			self:SetupToolViewport(itemViewport, tool.Name)
		end

		clickArea.MouseButton1Click:Connect(function()
			self:OnAnyToolSelected(tool.Name)
		end)

		card.Parent = self.Inventory.ToolContent
	end

	self:UpdateEmptyState()
	self:RefreshCardHighlights()
end

-- ===================================================================
-- ADMIN / ROLE TOOLS POPULATION
-- ===================================================================
function Controller:PopulateAdminToolGrid()
	if not self.isAdmin then return end
	if not self.Inventory.AdminContent then return end
	if not self.Templates.Item then
		warn("[CustomInventory] ItemTemplate not found in CustomInventoryGui.Templates")
		return
	end

	for _, child in ipairs(self.Inventory.AdminContent:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	local vipTools = {}
	local addedTools = {}

	local ok, res = self.NetworkGateway:Request("GET", "/inventory/vip-tools"):await()
	local success = ok and type(res) == "table" and res.Success
	local vipToolsList = (success and type(res.Data) == "table" and res.Data) or {}

	if success and vipToolsList then
		for _, toolData in ipairs(vipToolsList) do
			if not addedTools[toolData.Name] then
				table.insert(vipTools, {
					Name = toolData.Name,
					TextureId = toolData.TextureId
				})
				addedTools[toolData.Name] = true
			end
		end
	end

	local backpack = self.player:WaitForChild("Backpack")
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and (self.CollectionService:HasTag(tool, "VIPTool") or self.RoleConfig.IsOwner(self.player) or self.RoleConfig.IsAdmin(self.player)) then
			if not addedTools[tool.Name] then
				table.insert(vipTools, {
					Name = tool.Name,
					TextureId = tool.TextureId
				})
				addedTools[tool.Name] = true
			end
		end
	end

	local char = self.player.Character
	if char then
		for _, tool in ipairs(char:GetChildren()) do
			if tool:IsA("Tool") and (self.CollectionService:HasTag(tool, "VIPTool") or self.RoleConfig.IsOwner(self.player) or self.RoleConfig.IsAdmin(self.player)) then
				if not addedTools[tool.Name] then
					table.insert(vipTools, {
						Name = tool.Name,
						TextureId = tool.TextureId
					})
					addedTools[tool.Name] = true
				end
			end
		end
	end

	table.sort(vipTools, function(a, b)
		return a.Name < b.Name
	end)

	for _, toolData in ipairs(vipTools) do
		local card = self.Templates.Item:Clone()
		card.Name = toolData.Name
		card.Visible = true
		local hotbarType = self:IsRodName(toolData.Name) and "Rod" or "Tool"
		card:SetAttribute("HotbarType", hotbarType)
		card:SetAttribute("HotbarId", toolData.Name)

		local itemImage = card:FindFirstChild("ItemImage")
		local itemIcon = itemImage and itemImage:FindFirstChild("ItemIcon")
		local itemName = card:FindFirstChild("ItemName")
		local itemInfo = card:FindFirstChild("ItemInfo")
		local itemRarity = card:FindFirstChild("ItemRarity")
		local favoriteButton = card:FindFirstChild("FavoriteButton")
		local clickArea = card:FindFirstChild("ClickArea")
		local badge = card:FindFirstChild("Badge")

		if not itemImage or not itemIcon or not itemName or not itemInfo or not clickArea then
			card:Destroy()
			continue
		end

		if itemRarity then itemRarity.Visible = false end
		if favoriteButton then favoriteButton.Visible = false end

		itemName.Text = toolData.Name
		itemInfo.Text = "Admin Tool"
		local itemViewport = itemImage:FindFirstChild("ItemViewport")
		if not itemViewport then
			itemViewport = Instance.new("ViewportFrame")
			itemViewport.Name = "ItemViewport"
			itemViewport.Size = UDim2.new(1, 0, 1, 0)
			itemViewport.Position = UDim2.new(0, 0, 0, 0)
			itemViewport.BackgroundTransparency = 1
			itemViewport.BorderSizePixel = 0
			itemViewport.Active = false
			itemViewport.ZIndex = itemImage.ZIndex + 1
			itemViewport.Parent = itemImage
		end

		local icon = toolData.TextureId or ""
		if icon and icon ~= "" then
			if not icon:match("rbxassetid") and not icon:match("http") then
				icon = "rbxassetid://" .. icon
			end
			itemIcon.Image = icon
			itemIcon.ImageTransparency = 0
			itemIcon.Visible = true
			itemViewport.Visible = false
		else
			itemIcon.Image = ""
			itemIcon.Visible = false
			itemViewport.Visible = true
			self:SetupToolViewport(itemViewport, toolData.Name)
		end

		if badge then
			badge.Visible = true
			if self.RoleConfig.IsOwner(self.player) then
				badge.Text = "OWNER"
				badge.TextColor3 = Color3.fromRGB(255, 215, 0)
			elseif self.RoleConfig.IsAdmin(self.player) then
				badge.Text = "ADMIN"
				badge.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				badge.Text = "VIP"
				badge.TextColor3 = Color3.fromRGB(255, 215, 0)
			end
		end

		clickArea.MouseButton1Click:Connect(function()
			self:OnAnyToolSelected(toolData.Name)
		end)

		card.Parent = self.Inventory.AdminContent
	end

	self:UpdateEmptyState()
	self:RefreshCardHighlights()
end
end

return Module
