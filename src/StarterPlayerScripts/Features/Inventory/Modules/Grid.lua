local Module = {}

function Module.Install(Controller)
-- ===================================================================
-- LOGIC FUNCTIONS
-- ===================================================================

function Controller:PopulateFishGrid()
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
		local card = self.Templates.Fish:Clone()
		card.Name = fishData.uniqueId
		card.Visible = true

		local fishImage = card:FindFirstChild("FishImage")
		local fishName = card:FindFirstChild("FishName")
		local fishWeight = card:FindFirstChild("FishWeight")
		local fishRarity = card:FindFirstChild("FishRarity")
		local favoriteButton = card:FindFirstChild("FavoriteButton")
		local uiStroke = card:FindFirstChildOfClass("UIStroke") or (fishImage and fishImage:FindFirstChildOfClass("UIStroke"))

		if not fishImage or not fishName or not fishWeight or not fishRarity or not favoriteButton then
			card:Destroy()
			continue
		end

		local fishViewport = fishImage:FindFirstChild("FishViewport")
		if not fishViewport then
			fishViewport = Instance.new("ViewportFrame")
			fishViewport.Name = "FishViewport"
			fishViewport.Size = UDim2.new(1, 0, 1, 0)
			fishViewport.Position = UDim2.new(0, 0, 0, 0)
			fishViewport.BackgroundTransparency = 1
			fishViewport.BorderSizePixel = 0
			fishViewport.ZIndex = fishImage.ZIndex + 1
			fishViewport.Parent = fishImage
		end

		fishImage.Image = ""
		fishViewport.Visible = true
		self:SetupFishViewport(fishViewport, fishData.name)

		local rarityColor = self:GetRarityColor(fishData.rarity)
		if uiStroke then uiStroke.Color = rarityColor end

		fishName.Text = fishData.name
		fishWeight.Text = string.format("%.1fkg", fishData.weight)
		fishRarity.Text = fishData.rarity
		fishRarity.TextColor3 = rarityColor

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
		fishImage.MouseButton1Click:Connect(function()
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
end

function Controller:PopulateRodGrid()
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
		local card = self.Templates.Rod:Clone()
		card.Name = rodName
		card.Visible = true

		local rodNameLabel = card:FindFirstChild("RodName")
		local rodImage = card:FindFirstChild("RodImage")
		local statsLabel = card:FindFirstChild("StatsLabel")
		local equipButton = card:FindFirstChild("EquipButton")

		if not rodNameLabel or not rodImage or not statsLabel or not equipButton then
			card:Destroy()
			continue
		end

		local cachedData = self.rodToolStats[rodName]
		local stats = cachedData and cachedData.Stats or self.FishingConfig.GetRodConfig(rodName)
		local textureId = cachedData and cachedData.TextureId or ""

		if textureId ~= "" and not textureId:match("rbxassetid") then
			textureId = "rbxassetid://" .. textureId
		end

		rodNameLabel.Text = rodName
		rodImage.Image = ""
		local rodViewport = rodImage:FindFirstChild("RodViewport")
		if not rodViewport then
			rodViewport = Instance.new("ViewportFrame")
			rodViewport.Name = "RodViewport"
			rodViewport.Size = UDim2.new(1, 0, 1, 0)
			rodViewport.Position = UDim2.new(0, 0, 0, 0)
			rodViewport.BackgroundTransparency = 1
			rodViewport.BorderSizePixel = 0
			rodViewport.Active = false
			rodViewport.ZIndex = rodImage.ZIndex + 1
			rodViewport.Parent = rodImage
		end
		self:SetupRodViewport(rodViewport, rodName)

		local baseLuck = stats.baseLuck or 1.0
		local finalLuck = baseLuck * currentMultiplier
		local roundedLuck = math.round(finalLuck)
		local weight = stats.maxWeight or 0
		local luckPercentage = roundedLuck * 100

		if currentMultiplier > 1 then
			statsLabel.RichText = true
			statsLabel.Text = string.format("Luck: <font color='#00FF00'><b>%d%%</b></font>\nWeight: %dkg", luckPercentage, weight)
		else
			statsLabel.RichText = false
			statsLabel.Text = string.format("Luck: %d%%\nWeight: %dkg", luckPercentage, weight)
		end

		equipButton.MouseButton1Click:Connect(function()
			self:PlayClickSound()
			self.lastEquippedRodName = rodName
			self:SaveHotbarState()
			self:UpdateRodVisual(rodName)
			self.NetworkGateway:Request("PUT", "/inventory/equip-rod", { RodName = rodName })
		end)

		card.Parent = self.Inventory.RodContent
	end
end

function Controller:PopulateToolGrid()
	for _, child in ipairs(self.Inventory.ToolContent:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	local genericTools = {}
	local addedTools = {}

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

		if not isFish and not isRod and not isVIPTool and not isRoleTool and not addedTools[tool.Name] then
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

		if not isFish and not isRod and not isVIPTool and not isRoleTool and not addedTools[tool.Name] then
			table.insert(genericTools, tool)
			addedTools[tool.Name] = true
		end
	end

	table.sort(genericTools, function(a, b)
		return a.Name < b.Name
	end)

	for _, tool in ipairs(genericTools) do
		local card = self.Templates.Tool:Clone()
		card.Name = tool.Name
		card.Visible = true

		local toolImage = card:FindFirstChild("ToolImage")
		local toolNameLabel = card:FindFirstChild("ToolName")

		if not toolImage or not toolNameLabel then
			card:Destroy()
			continue
		end

		toolNameLabel.Text = tool.Name
		local toolViewport = toolImage:FindFirstChild("ToolViewport")
		if not toolViewport then
			toolViewport = Instance.new("ViewportFrame")
			toolViewport.Name = "ToolViewport"
			toolViewport.Size = UDim2.new(1, 0, 1, 0)
			toolViewport.Position = UDim2.new(0, 0, 0, 0)
			toolViewport.BackgroundTransparency = 1
			toolViewport.BorderSizePixel = 0
			toolViewport.Active = false
			toolViewport.ZIndex = toolImage.ZIndex + 1
			toolViewport.Parent = toolImage
		end

		local icon = ""
		if tool:IsA("Tool") and tool.TextureId ~= "" then
			icon = tool.TextureId
		end

		if icon and icon ~= "" then
			if not icon:match("rbxassetid") and not icon:match("http") then
				icon = "rbxassetid://" .. icon
			end
			toolImage.Image = icon
			toolImage.ImageTransparency = 0
			toolViewport.Visible = false
		else
			toolImage.Image = ""
			toolViewport.Visible = true
			self:SetupToolViewport(toolViewport, tool.Name)
		end

		toolImage.MouseButton1Click:Connect(function()
			self:OnAnyToolSelected(tool.Name)
		end)

		card.Parent = self.Inventory.ToolContent
	end
end

-- ===================================================================
-- VIP TOOLS POPULATION
-- ===================================================================
function Controller:PopulateVIPToolGrid()
	if not self.isVIP then return end
	if not self.Inventory.VIPContent then return end
	if not self.Templates.VIPTool then
		warn("[CustomInventory] VIPToolTemplate not found!")
		return
	end

	for _, child in ipairs(self.Inventory.VIPContent:GetChildren()) do
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
		local card = self.Templates.VIPTool:Clone()
		card.Name = toolData.Name
		card.Visible = true

		local toolImage = card:FindFirstChild("ToolImage")
		local toolNameLabel = card:FindFirstChild("ToolName")
		local vipBadge = card:FindFirstChild("VIPBadge")

		if not toolImage or not toolNameLabel then
			card:Destroy()
			continue
		end

		toolNameLabel.Text = toolData.Name
		local toolViewport = toolImage:FindFirstChild("ToolViewport")
		if not toolViewport then
			toolViewport = Instance.new("ViewportFrame")
			toolViewport.Name = "ToolViewport"
			toolViewport.Size = UDim2.new(1, 0, 1, 0)
			toolViewport.Position = UDim2.new(0, 0, 0, 0)
			toolViewport.BackgroundTransparency = 1
			toolViewport.BorderSizePixel = 0
			toolViewport.Active = false
			toolViewport.ZIndex = toolImage.ZIndex + 1
			toolViewport.Parent = toolImage
		end

		local icon = toolData.TextureId or ""
		if icon and icon ~= "" then
			if not icon:match("rbxassetid") and not icon:match("http") then
				icon = "rbxassetid://" .. icon
			end
			toolImage.Image = icon
			toolImage.ImageTransparency = 0
			toolViewport.Visible = false
		else
			toolImage.Image = ""
			toolViewport.Visible = true
			self:SetupToolViewport(toolViewport, toolData.Name)
		end

		if vipBadge then
			if self.RoleConfig.IsOwner(self.player) then
				vipBadge.Text = "👑 OWNER"
				vipBadge.TextColor3 = Color3.fromRGB(255, 215, 0)
			elseif self.RoleConfig.IsAdmin(self.player) then
				vipBadge.Text = "🛡️ ADMIN"
				vipBadge.TextColor3 = Color3.fromRGB(255, 80, 80)
			else
				vipBadge.Text = "⭐ VIP"
				vipBadge.TextColor3 = Color3.fromRGB(255, 215, 0)
			end
		end

		toolImage.MouseButton1Click:Connect(function()
			self:OnAnyToolSelected(toolData.Name)
		end)

		card.Parent = self.Inventory.VIPContent
	end
end
end

return Module
