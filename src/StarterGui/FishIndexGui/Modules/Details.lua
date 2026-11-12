local Module = {}

function Module.Install(Controller)
-- Muted border stroke colors for unselected cards
function Controller:GetStrokeColor(rarityColor)
	return Color3.new(
		math.clamp(rarityColor.R * 0.55, 0.15, 1),
		math.clamp(rarityColor.G * 0.55, 0.15, 1),
		math.clamp(rarityColor.B * 0.55, 0.15, 1)
	)
end

-- Calculate Base Chance String
function Controller:GetChanceString(prob)
	if not prob or prob <= 0 then return "1 in 100" end
	local oneIn = math.round(100 / prob)
	return string.format("1 in %d", math.max(1, oneIn))
end

-- Update Details Panel
function Controller:SelectFish(fishInfo, isCaught, count)
	local rarity = fishInfo.rarity or "Common"
	local rarityColor = self.RARITY_COLORS[rarity] or Color3.fromRGB(180, 190, 205)
	self.activeFishName = fishInfo.name

	if self.activePreviewThread then
		pcall(task.cancel, self.activePreviewThread)
		self.activePreviewThread = nil
	end

	-- Always display the accurate weight range
	local minW = fishInfo.minKg or 0.5
	local maxW = fishInfo.maxKg or 45
	self.weightLabel.Text = string.format("Weight: %.1f kg - %.1f kg", minW, maxW)

	if isCaught then
		self.dpName.Text = fishInfo.name
		self.dpName.TextColor3 = rarityColor
		self.caughtStatus.Text = "Discovered"
		self.caughtStatus.TextColor3 = Color3.fromRGB(80, 220, 120)
		self.caughtTimes.Text = string.format("Caught %d times", count or 1)
		self.caughtTimes.Visible = true
	else
		self.dpName.Text = "???"
		self.dpName.TextColor3 = rarityColor
		self.caughtStatus.Text = "Not caught yet"
		self.caughtStatus.TextColor3 = Color3.fromRGB(160, 170, 185)
		self.caughtTimes.Text = "Caught 0 times"
		self.caughtTimes.Visible = true
	end

	-- Render 3D model / silhouette in preview box
	local fishFolder = self:GetFishAssetsFolder()
	local template = fishFolder and fishFolder:FindFirstChild(fishInfo.name)
	if template then
		self:SetupFishViewport(self.previewViewport, template, isCaught, true, fishInfo.name, true)
	else
		self.previewViewport:ClearAllChildren()
	end

	self.dpRarityBadge.Text = string.upper(rarity)
	self.dpRarityBadge.BackgroundColor3 = rarityColor
	self.previewChance.Text = self:GetChanceString(fishInfo.probability or 30)
end
end

return Module
