local Module = {}

function Module.Install(Controller)
-- Filter visibility helper (instantaneous, 0ms)
function Controller:UpdateFilterVisibility()
	for fishName, card in pairs(self.allCards) do
		local matchesFilter = false
		local rarity = card:GetAttribute("Rarity") or "Common"
		if self.activeFilter == "All" then
			matchesFilter = true
		elseif self.activeFilter == "Secret" and (rarity == "Secret" or rarity == "Legendary") then
			matchesFilter = true
		elseif self.activeFilter == "Forgotten" and (rarity == "Forgotten" or rarity == "Mitos") then
			matchesFilter = true
		elseif self.activeFilter == rarity then
			matchesFilter = true
		end
		card.Visible = matchesFilter
	end
end

-- Refresh Index Grid (Smart Caching & Micro-Batching)
function Controller:RefreshGrid()
	if not self.fishingConfig or not self.fishingConfig.FishTable then return end

	local totalFish = #self.fishingConfig.FishTable
	local caughtCount = 0
	local fishFolder = self:GetFishAssetsFolder()

	for i, fishInfo in ipairs(self.fishingConfig.FishTable) do
		local fishName = fishInfo.name
		local count = self.caughtData[fishName] or 0
		local isCaught = count > 0
		if isCaught then
			caughtCount = caughtCount + 1
		end

		local rarity = fishInfo.rarity or "Common"
		local rarityColor = self.RARITY_COLORS[rarity] or Color3.fromRGB(180, 190, 205)
		local defaultStrokeColor = self:GetStrokeColor(rarityColor)

		local card = self.allCards[fishName]
		local isNewCard = false
		if not card then
			isNewCard = true
			card = self.cardTemplate:Clone()
			card.Name = "Card_" .. fishName
			card:SetAttribute("Rarity", rarity)
			card.Parent = self.fishGrid
			self.allCards[fishName] = card

			card.MouseButton1Click:Connect(function()
				if self.selectedCard and self.selectedCard:FindFirstChild("UIStroke") then
					local prevFishName = string.sub(self.selectedCard.Name, 6)
					local prevFishInfo = nil
					for _, fi in ipairs(self.fishingConfig.FishTable) do
						if fi.name == prevFishName then
							prevFishInfo = fi
							break
						end
					end
					local prevRarity = prevFishInfo and prevFishInfo.rarity or "Common"
					local prevRarityColor = self.RARITY_COLORS[prevRarity] or Color3.fromRGB(180, 190, 205)
					self.selectedCard.UIStroke.Color = self:GetStrokeColor(prevRarityColor)
					self.selectedCard.UIStroke.Thickness = 1
				end

				self.selectedCard = card
				if card:FindFirstChild("UIStroke") then
					card.UIStroke.Color = Color3.fromRGB(255, 255, 255)
					card.UIStroke.Thickness = 2
				end
				self:SelectFish(fishInfo, (self.caughtData[fishName] or 0) > 0, self.caughtData[fishName])
			end)
		end

		-- Set card stroke color based on rarity
		local cardStroke = card:FindFirstChild("UIStroke")
		if cardStroke then
			if card == self.selectedCard then
				cardStroke.Color = Color3.fromRGB(255, 255, 255)
				cardStroke.Thickness = 2
			else
				cardStroke.Color = defaultStrokeColor
				cardStroke.Thickness = 1
			end
		end

		-- Render unique 3D model with SMART CACHING (only render once per state!)
		local fishIcon = card:FindFirstChild("FishIcon")
		local fishNameLbl = card:FindFirstChild("FishName")
		local cardViewport = card:FindFirstChild("CardViewport")
		local template = fishFolder and fishFolder:FindFirstChild(fishName)

		if fishIcon then
			fishIcon.Visible = false
		end

		if template then
			if not cardViewport then
				cardViewport = Instance.new("ViewportFrame")
				cardViewport.Name = "CardViewport"
				cardViewport.BackgroundTransparency = 1
				cardViewport.Size = UDim2.new(1, -8, 0, 58)
				cardViewport.Position = UDim2.new(0.5, 0, 0, 4)
				cardViewport.AnchorPoint = Vector2.new(0.5, 0)
				cardViewport.Parent = card
			end
			cardViewport.Visible = true

			-- Caching check: ONLY setup viewport if not rendered yet or if caught state changed!
			local alreadyRendered = (self.renderedState[fishName] == isCaught) and (cardViewport:FindFirstChild("FishModel") ~= nil)
			if not alreadyRendered then
				self:SetupFishViewport(cardViewport, template, isCaught, false, fishName, false)
				self.renderedState[fishName] = isCaught
				if isNewCard and (i % 3 == 0) then
					task.wait()
				end
			end
		end

		if fishNameLbl then
			fishNameLbl.Size = UDim2.new(1, -6, 0, 15)
			fishNameLbl.Position = UDim2.new(0.5, 0, 1, -17)
			fishNameLbl.AnchorPoint = Vector2.new(0.5, 0)
			fishNameLbl.TextScaled = true
			fishNameLbl.TextColor3 = rarityColor
			if isCaught then
				fishNameLbl.Text = fishName
			else
				fishNameLbl.Text = "???"
			end
		end

		-- Select first card if none selected
		if i == 1 and not self.selectedCard then
			self.selectedCard = card
			if cardStroke then
				cardStroke.Color = Color3.fromRGB(255, 255, 255)
				cardStroke.Thickness = 2
			end
			self:SelectFish(fishInfo, isCaught, count)
		end
	end

	-- Apply filter visibility
	self:UpdateFilterVisibility()

	-- Update Progress Header
	self.subtitle.Text = string.format("All Fish: %d/%d", caughtCount, totalFish)
	local pct = totalFish > 0 and (caughtCount / totalFish) or 0
	self.TweenService:Create(self.progressBarFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(pct, 0, 1, 0)
	}):Play()
end

function Controller:SetupFilterButtons()
	for _, child in ipairs(self.filterColumn:GetChildren()) do
		if child:IsA("TextButton") and string.sub(child.Name, 1, 7) == "Filter_" then
			local filterName = string.sub(child.Name, 8)
			child.MouseButton1Click:Connect(function()
				self.activeFilter = filterName

				for _, btn in ipairs(self.filterColumn:GetChildren()) do
					if btn:IsA("TextButton") then
						local stroke = btn:FindFirstChild("UIStroke")
						if stroke then
							stroke.Color = (btn == child) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
							stroke.Thickness = (btn == child) and 2 or 1
						end
					end
				end

				self:UpdateFilterVisibility()
			end)
		end
	end
end

end

return Module
