local Module = {}
local RoleConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Configs"):WaitForChild("RoleConfig"))
local HudVisibility = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("UI"):WaitForChild("HudVisibility"))

function Module.Install(Controller)
function Controller:PlayClickSound()
	-- No-op: Handled universally by UniversalButtonEffects to prevent double sounds
end

function Controller:UpdateGUIReferences()
	local attempts = 0
	while attempts < 50 do
		self.gui = self.playerGui:FindFirstChild("CustomInventoryGui")
		if self.gui then break end
		attempts = attempts + 1
		task.wait(0.1)
	end

	if not self.gui then
		warn("[CustomInventory] Failed to find CustomInventoryGui!")
		return false
	end

	self.Hotbar.Frame = self.gui:FindFirstChild("HotbarFrame")
	if not self.Hotbar.Frame then
		warn("[CustomInventory] HotbarFrame not found!")
		return false
	end

	-- Slot 1: Rod
	self.Hotbar.RodSlot = self.Hotbar.Frame:FindFirstChild("RodSlot")
	self.Hotbar.RodImage = self.Hotbar.RodSlot and self.Hotbar.RodSlot:FindFirstChild("RodImage")
	self.Hotbar.RodName = self.Hotbar.RodSlot and self.Hotbar.RodSlot:FindFirstChild("RodName")
	self.Hotbar.RodViewport = self.Hotbar.RodSlot and self.Hotbar.RodSlot:FindFirstChild("RodViewport")

	-- Slot 2: Tool 1
	self.Hotbar.ToolSlot1 = self.Hotbar.Frame:FindFirstChild("ToolSlot1")
	self.Hotbar.ToolImage1 = self.Hotbar.ToolSlot1 and self.Hotbar.ToolSlot1:FindFirstChild("ToolImage1")
	self.Hotbar.ToolName1 = self.Hotbar.ToolSlot1 and self.Hotbar.ToolSlot1:FindFirstChild("ToolName1")
	self.Hotbar.ToolViewport1 = self.Hotbar.ToolSlot1 and self.Hotbar.ToolSlot1:FindFirstChild("ToolViewport1")

	-- Slot 3: Tool 2
	self.Hotbar.ToolSlot2 = self.Hotbar.Frame:FindFirstChild("ToolSlot2")
	self.Hotbar.ToolImage2 = self.Hotbar.ToolSlot2 and self.Hotbar.ToolSlot2:FindFirstChild("ToolImage2")
	self.Hotbar.ToolName2 = self.Hotbar.ToolSlot2 and self.Hotbar.ToolSlot2:FindFirstChild("ToolName2")
	self.Hotbar.ToolViewport2 = self.Hotbar.ToolSlot2 and self.Hotbar.ToolSlot2:FindFirstChild("ToolViewport2")

	-- Slot 4: Bag
	self.Hotbar.BagButton = self.Hotbar.Frame:FindFirstChild("BagButton")

	-- Slot 5: Fish 1
	self.Hotbar.FishSlot1 = self.Hotbar.Frame:FindFirstChild("FishSlot1")
	self.Hotbar.FishImage1 = self.Hotbar.FishSlot1 and self.Hotbar.FishSlot1:FindFirstChild("FishImage1")
	self.Hotbar.FishName1 = self.Hotbar.FishSlot1 and self.Hotbar.FishSlot1:FindFirstChild("FishName1")
	self.Hotbar.FishViewport1 = self.Hotbar.FishSlot1 and self.Hotbar.FishSlot1:FindFirstChild("FishViewport1")

	-- Slot 6: Fish 2
	self.Hotbar.FishSlot2 = self.Hotbar.Frame:FindFirstChild("FishSlot2")
	self.Hotbar.FishImage2 = self.Hotbar.FishSlot2 and self.Hotbar.FishSlot2:FindFirstChild("FishImage2")
	self.Hotbar.FishName2 = self.Hotbar.FishSlot2 and self.Hotbar.FishSlot2:FindFirstChild("FishName2")
	self.Hotbar.FishViewport2 = self.Hotbar.FishSlot2 and self.Hotbar.FishSlot2:FindFirstChild("FishViewport2")

	if self.Hotbar.RodSlot then
		self.OriginalColors.RodSlot.Background = self.Hotbar.RodSlot.BackgroundColor3
		self.OriginalColors.RodSlot.Transparency = self.Hotbar.RodSlot.BackgroundTransparency
		self.OriginalColors.RodSlot.ImageTransparency = self.Hotbar.RodImage and self.Hotbar.RodImage.ImageTransparency or 0
		self.OriginalColors.RodSlot.TextTransparency = self.Hotbar.RodName and self.Hotbar.RodName.TextTransparency or 0
		self.OriginalColors.RodSlot.TextColor = self.Hotbar.RodName and self.Hotbar.RodName.TextColor3 or Color3.fromRGB(255, 255, 255)
	end

	if self.Hotbar.ToolSlot1 then
		self.OriginalColors.ToolSlot1.Background = self.Hotbar.ToolSlot1.BackgroundColor3
		self.OriginalColors.ToolSlot1.Transparency = self.Hotbar.ToolSlot1.BackgroundTransparency
		self.OriginalColors.ToolSlot1.ImageTransparency = self.Hotbar.ToolImage1 and self.Hotbar.ToolImage1.ImageTransparency or 0
		self.OriginalColors.ToolSlot1.TextTransparency = self.Hotbar.ToolName1 and self.Hotbar.ToolName1.TextTransparency or 0
		self.OriginalColors.ToolSlot1.TextColor = self.Hotbar.ToolName1 and self.Hotbar.ToolName1.TextColor3 or Color3.fromRGB(255, 255, 255)
	end

	if self.Hotbar.ToolSlot2 then
		self.OriginalColors.ToolSlot2.Background = self.Hotbar.ToolSlot2.BackgroundColor3
		self.OriginalColors.ToolSlot2.Transparency = self.Hotbar.ToolSlot2.BackgroundTransparency
		self.OriginalColors.ToolSlot2.ImageTransparency = self.Hotbar.ToolImage2 and self.Hotbar.ToolImage2.ImageTransparency or 0
		self.OriginalColors.ToolSlot2.TextTransparency = self.Hotbar.ToolName2 and self.Hotbar.ToolName2.TextTransparency or 0
		self.OriginalColors.ToolSlot2.TextColor = self.Hotbar.ToolName2 and self.Hotbar.ToolName2.TextColor3 or Color3.fromRGB(255, 255, 255)
	end

	if self.Hotbar.FishSlot1 then
		self.OriginalColors.FishSlot1.Background = self.Hotbar.FishSlot1.BackgroundColor3
		self.OriginalColors.FishSlot1.Transparency = self.Hotbar.FishSlot1.BackgroundTransparency
		self.OriginalColors.FishSlot1.ImageTransparency = self.Hotbar.FishImage1 and self.Hotbar.FishImage1.ImageTransparency or 0
		self.OriginalColors.FishSlot1.TextTransparency = self.Hotbar.FishName1 and self.Hotbar.FishName1.TextTransparency or 0
		self.OriginalColors.FishSlot1.TextColor = self.Hotbar.FishName1 and self.Hotbar.FishName1.TextColor3 or Color3.fromRGB(255, 255, 255)
	end

	if self.Hotbar.FishSlot2 then
		self.OriginalColors.FishSlot2.Background = self.Hotbar.FishSlot2.BackgroundColor3
		self.OriginalColors.FishSlot2.Transparency = self.Hotbar.FishSlot2.BackgroundTransparency
		self.OriginalColors.FishSlot2.ImageTransparency = self.Hotbar.FishImage2 and self.Hotbar.FishImage2.ImageTransparency or 0
		self.OriginalColors.FishSlot2.TextTransparency = self.Hotbar.FishName2 and self.Hotbar.FishName2.TextTransparency or 0
		self.OriginalColors.FishSlot2.TextColor = self.Hotbar.FishName2 and self.Hotbar.FishName2.TextColor3 or Color3.fromRGB(255, 255, 255)
	end

	local mainFrame = self.gui:FindFirstChild("MainInventoryFrame")
	if not mainFrame then
		warn("[CustomInventory] MainInventoryFrame not found!")
		return false
	end

	self.Inventory.Frame = mainFrame

	-- Buka/tutup lewat backdrop (Panel.closeAll) juga harus menyelaraskan state.
	mainFrame:GetAttributeChangedSignal("IsOpen"):Connect(function()
		self.isInventoryOpen = mainFrame:GetAttribute("IsOpen") == true
	end)

	local headerFrame = mainFrame:FindFirstChild("Header")
	self.Inventory.CloseButton = headerFrame and headerFrame:FindFirstChild("CloseButton")

	local tabsFrame = mainFrame:FindFirstChild("TabsFrame")
	self.Inventory.FishTabButton = tabsFrame and tabsFrame:FindFirstChild("FishTabButton")
	self.Inventory.RodTabButton = tabsFrame and tabsFrame:FindFirstChild("RodTabButton")
	self.Inventory.ToolTabButton = tabsFrame and tabsFrame:FindFirstChild("ToolTabButton")
	self.Inventory.AdminTabButton = tabsFrame and tabsFrame:FindFirstChild("AdminTabButton")

	local contentFrame = mainFrame:FindFirstChild("ContentFrame")
	self.Inventory.FishContent = contentFrame and contentFrame:FindFirstChild("FishContent")
	self.Inventory.RodContent = contentFrame and contentFrame:FindFirstChild("RodContent")
	self.Inventory.ToolContent = contentFrame and contentFrame:FindFirstChild("ToolContent")
	self.Inventory.AdminContent = contentFrame and contentFrame:FindFirstChild("AdminContent")
	self.Inventory.EmptyState = contentFrame and contentFrame:FindFirstChild("EmptyState")

	local footerFrame = mainFrame:FindFirstChild("Footer")
	self.Inventory.SellAllButton = footerFrame and footerFrame:FindFirstChild("SellAllButton")
	self.Inventory.FishCountLabel = footerFrame and footerFrame:FindFirstChild("FishCountLabel")

	local templatesFolder = self.gui:FindFirstChild("Templates")
	if templatesFolder then
		self.Templates.Item = templatesFolder:FindFirstChild("ItemTemplate")
	end

	local highlightOutline = self.Templates.Item and self.Templates.Item:FindFirstChild("HotbarOutline")
	local highlightStroke = highlightOutline and highlightOutline:FindFirstChildOfClass("UIStroke")
	self.HotbarHighlightColor = highlightStroke and highlightStroke.Color or Color3.fromRGB(57, 255, 20)

	HudVisibility:SetHotbarDesired(true)
	return true
end

function Controller:SaveHotbarState()
	self.HotbarState.rod = self.lastEquippedRodName
	self.HotbarState.tool1 = self.lastEquippedToolName1
	self.HotbarState.tool2 = self.lastEquippedToolName2
	self.HotbarState.fish1 = self.lastEquippedFishId1
	self.HotbarState.fish2 = self.lastEquippedFishId2
end

function Controller:UpdateFishCount()
	if self.Inventory.FishCountLabel then
		local fishCount = #self.allFishData
		local maxFish = self.FishingConfig.InventoryLimitSettings.maxFishInventory or 500
		self.Inventory.FishCountLabel.Text = string.format("%d/%d", fishCount, maxFish)
	end
end

function Controller:UpdateEmptyState()
	local label = self.Inventory.EmptyState
	if not label then return end

	local content = nil
	if self.currentTab == "Fish" then
		content = self.Inventory.FishContent
	elseif self.currentTab == "Rods" then
		content = self.Inventory.RodContent
	elseif self.currentTab == "Tools" then
		content = self.Inventory.ToolContent
	elseif self.currentTab == "Admin" then
		content = self.Inventory.AdminContent
	end

	if not content or not content.Visible then
		label.Visible = false
		return
	end

	for _, child in ipairs(content:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ImageButton") then
			label.Visible = false
			return
		end
	end
	label.Visible = true
end

function Controller:SetCardHotbarHighlight(card, active)
	local outline = card and card:FindFirstChild("HotbarOutline")
	if outline then
		outline.Visible = active
	end
end

function Controller:RefreshCardHighlights()
	local fish1, fish2 = self.lastEquippedFishId1, self.lastEquippedFishId2
	local rodName = self.lastEquippedRodName
	local tool1, tool2 = self.lastEquippedToolName1, self.lastEquippedToolName2

	local function refreshContent(content)
		if not content then return end
		for _, card in ipairs(content:GetChildren()) do
			if card:IsA("Frame") then
				local kind = card:GetAttribute("HotbarType")
				local id = card:GetAttribute("HotbarId")
				local active = false
				if id ~= nil then
					if kind == "Fish" then
						active = (id == fish1 or id == fish2)
					elseif kind == "Rod" then
						active = (id == rodName)
					elseif kind == "Tool" then
						active = (id == tool1 or id == tool2)
					end
				end
				self:SetCardHotbarHighlight(card, active)
			end
		end
	end

	refreshContent(self.Inventory.FishContent)
	refreshContent(self.Inventory.RodContent)
	refreshContent(self.Inventory.ToolContent)
	refreshContent(self.Inventory.AdminContent)
end

function Controller:GetRarityColor(rarity)
	return self.RarityColors[rarity] or Color3.fromRGB(255, 255, 255)
end

function Controller:IsRodName(name)
	if not name or name == "" then return false end
	if table.find(self.allRodData, name) then return true end
	if self.rodAssetFolder and self.rodAssetFolder:FindFirstChild(name) then return true end
	local bp = self.player:FindFirstChild("Backpack")
	local ch = self.player.Character
	local t = (bp and bp:FindFirstChild(name)) or (ch and ch:FindFirstChild(name))
	if t and self.CollectionService:HasTag(t, "Rod") then return true end
	return false
end

function Controller:CheckVIPStatus()
	local MarketplaceService = game:GetService("MarketplaceService")

	local success, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(self.player.UserId, self.VIP_GAMEPASS_ID)
	end)

	if success then
		self.isVIP = result
	else
		self.isVIP = false
	end

	if self.RoleConfig.IsOwner(self.player) or self.RoleConfig.IsAdmin(self.player) then
		self.isAdmin = true
		self.isVIP = true
	else
		self.isAdmin = false
	end

	if self.Inventory.AdminTabButton then
		self.Inventory.AdminTabButton.Visible = self.isAdmin
	end

	return self.isVIP
end

function Controller:HasRemoteSellPermission()
	if self.isVIP then return true end
	if self.player:GetAttribute("HasRemoteSell") == true then return true end
	if game.CreatorType == Enum.CreatorType.User and (self.player.UserId == game.CreatorId or game.CreatorId == 0) then
		return true
	end
	if RoleConfig.IsAdmin(self.player) then return true end
	return false
end

function Controller:UpdateSellButtonVisual()
	if not self.Inventory.SellAllButton then return end
	if self:HasRemoteSellPermission() then
		self.Inventory.SellAllButton.Text = "Sell All"
		self.Inventory.SellAllButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
	else
		self.Inventory.SellAllButton.Text = "🔒 Sell (Perk)"
		self.Inventory.SellAllButton.BackgroundColor3 = Color3.fromRGB(80, 80, 85)
	end
end

function Controller:DisableTooltip(tool)
	if tool and tool:IsA("Tool") then
		tool.ToolTip = " "
	end
end
end

return Module
