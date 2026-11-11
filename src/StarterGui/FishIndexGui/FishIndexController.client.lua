local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))

local player = Players.LocalPlayer
local gui = script.Parent
local mainFrame = gui:WaitForChild("MainFrame")
local header = mainFrame:WaitForChild("Header")
local subtitle = header:WaitForChild("Subtitle")
local progressBarFill = header:WaitForChild("ProgressBarBg"):WaitForChild("Fill")
local closeBtn = header:WaitForChild("CloseBtn")

local contentArea = mainFrame:WaitForChild("ContentArea")
local filterColumn = contentArea:WaitForChild("FilterColumn")
local gridContainer = contentArea:WaitForChild("GridContainer")
local fishGrid = gridContainer:WaitForChild("FishGrid")
local detailsPanel = contentArea:WaitForChild("DetailsPanel")

local dpName = detailsPanel:WaitForChild("DetailName")
local dpRarityBadge = detailsPanel:WaitForChild("DetailRarityBadge")
local previewBox = detailsPanel:WaitForChild("PreviewBox")
local previewImage = previewBox:WaitForChild("PreviewImage")
local previewChance = previewBox:WaitForChild("PreviewChance")
local statsList = detailsPanel:WaitForChild("StatsList")
local weightLabel = statsList:WaitForChild("WeightLabel")
local caughtStatus = statsList:WaitForChild("CaughtStatus")
local caughtTimes = statsList:WaitForChild("CaughtTimes")

local templates = gui:WaitForChild("Templates")
local cardTemplate = templates:WaitForChild("CardTemplate")

local fishingSystem = ReplicatedStorage:WaitForChild("FishingSystem", 15)
local fishingConfig = fishingSystem and require(fishingSystem:WaitForChild("FishingConfig", 15))

-- Ensure GridContainer symmetry
gridContainer.Position = UDim2.new(0, 131, 0, 0)
gridContainer.Size = UDim2.new(0, 380, 1, 0)

-- Ensure UIPadding inside FishGrid
local gridPadding = fishGrid:FindFirstChildOfClass("UIPadding")
if not gridPadding then
	gridPadding = Instance.new("UIPadding")
	gridPadding.Name = "UIPadding"
	gridPadding.Parent = fishGrid
end
gridPadding.PaddingTop = UDim.new(0, 10)
gridPadding.PaddingBottom = UDim.new(0, 14)
gridPadding.PaddingLeft = UDim.new(0, 10)
gridPadding.PaddingRight = UDim.new(0, 12)

local gridLayout = fishGrid:FindFirstChildOfClass("UIGridLayout")
if gridLayout then
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	gridLayout.CellSize = UDim2.new(0, 80, 0, 80)
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
end

-- Resilient Asset Resolver
local cachedFishFolder = nil
local function getFishAssetsFolder()
	if cachedFishFolder and cachedFishFolder.Parent then return cachedFishFolder end
	local fs = ReplicatedStorage:WaitForChild("FishingSystem", 15)
	if not fs then return nil end
	local assets = fs:WaitForChild("Assets", 15)
	if not assets then return nil end
	cachedFishFolder = assets:WaitForChild("Fish", 15)
	return cachedFishFolder
end

-- 3D Preview Viewport in Details Panel
local previewViewport = previewBox:FindFirstChild("PreviewViewport")
if not previewViewport then
	previewViewport = Instance.new("ViewportFrame")
	previewViewport.Name = "PreviewViewport"
	previewViewport.Size = UDim2.new(1, -12, 1, -26)
	previewViewport.Position = UDim2.new(0.5, 0, 0.44, 0)
	previewViewport.AnchorPoint = Vector2.new(0.5, 0.5)
	previewViewport.BackgroundTransparency = 1
	previewViewport.Parent = previewBox
end
previewImage.Visible = false

-- Rarity Colors mapping
local RARITY_COLORS = {
	Common = Color3.fromRGB(180, 190, 205),
	Uncommon = Color3.fromRGB(70, 215, 95),
	Rare = Color3.fromRGB(65, 150, 255),
	Epic = Color3.fromRGB(195, 85, 255),
	Legendary = Color3.fromRGB(255, 175, 40),
	Secret = Color3.fromRGB(255, 145, 0),
	Mitos = Color3.fromRGB(255, 65, 75),
	Forgotten = Color3.fromRGB(255, 65, 75),
}

-- Muted border stroke colors for unselected cards
local function getStrokeColor(rarityColor)
	return Color3.new(
		math.clamp(rarityColor.R * 0.55, 0.15, 1),
		math.clamp(rarityColor.G * 0.55, 0.15, 1),
		math.clamp(rarityColor.B * 0.55, 0.15, 1)
	)
end

-- Caught fish state: { [fishName] = count }
local caughtData = {}
local activeFilter = "All"
local allCards = {}
local selectedCard = nil
local activeFishName = ""
local activePreviewThread = nil
local refreshGrid: (() -> ())? = nil
local renderedState = {}

-- Helper to setup 3D fish model into a ViewportFrame with universal side-profile framing
local function setupFishViewport(viewport, template, isCaught, enableRotation, fishNameRef, isDetailPreview)
	viewport:ClearAllChildren()
	local cam = Instance.new("Camera")
	cam.FieldOfView = 70
	cam.Parent = viewport
	viewport.CurrentCamera = cam

	if isCaught then
		viewport.Ambient = Color3.fromRGB(205, 205, 220)
		viewport.LightColor = Color3.fromRGB(255, 255, 255)
		viewport.LightDirection = Vector3.new(-1, -1, -1)
	else
		-- Solid pitch-black silhouette mode for uncaught fish
		viewport.Ambient = Color3.fromRGB(0, 0, 0)
		viewport.LightColor = Color3.fromRGB(0, 0, 0)
		viewport.LightDirection = Vector3.new(0, -1, 0)
	end

	local model = Instance.new("Model")
	model.Name = "FishModel"

	for _, desc in ipairs(template:GetDescendants()) do
		if desc:IsA("BasePart") then
			local isSpecialMesh = desc:FindFirstChildOfClass("SpecialMesh") ~= nil
			local isMeshPart = desc:IsA("MeshPart")
			local isGhostly = desc.Transparency >= 0.9
			local isInvisibleGripHandle = (desc.Name == "Handle" and isGhostly and not isMeshPart and not isSpecialMesh)

			if not isInvisibleGripHandle and (desc.Transparency < 0.9 or isMeshPart or isSpecialMesh) then
				local p = desc:Clone()
				p.Anchored = true
				p.CanCollide = false
				if not isCaught then
					-- Strip all textures, decals, and surface materials for true black silhouette
					p.Color = Color3.fromRGB(0, 0, 0)
					p.Material = Enum.Material.SmoothPlastic
					p.Reflectance = 0
					if p:IsA("MeshPart") then
						p.TextureID = ""
					end
					local sm = p:FindFirstChildOfClass("SpecialMesh")
					if sm then
						sm.TextureId = ""
					end
					for _, ch in ipairs(p:GetChildren()) do
						if ch:IsA("Decal") or ch:IsA("Texture") or ch:IsA("SurfaceAppearance") then
							ch:Destroy()
						end
					end
				end
				p.Parent = model
			end
		end
	end
	model.Parent = viewport

	-- Auto unpitch if model was saved rotated > 50 degrees around X (e.g. Nila Fish, Rock Fish)
	local preCF, _ = model:GetBoundingBox()
	local rx, _, _ = preCF:ToEulerAnglesXYZ()
	if math.abs(math.deg(rx)) > 50 then
		local unpitchCF = CFrame.Angles(-rx, 0, 0)
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") then
				p.CFrame = unpitchCF * p.CFrame
			end
		end
	end

	local cf, size = model:GetBoundingBox()
	local center = cf.Position

	-- Dynamically detect vertical axis (closest to World Y)
	local axes = {
		{vec = cf.RightVector, dim = size.X},
		{vec = cf.UpVector,    dim = size.Y},
		{vec = cf.LookVector,  dim = size.Z},
	}

	table.sort(axes, function(a, b)
		return math.abs(a.vec.Y) > math.abs(b.vec.Y)
	end)

	local vertAxis = axes[1]
	local vertVec = (vertAxis.vec.Y >= 0) and vertAxis.vec or -vertAxis.vec
	local vertHeight = vertAxis.dim

	-- Out of remaining two axes, the longer one is length, shorter is thickness
	local horizA = axes[2]
	local horizB = axes[3]
	local lengthAxis = (horizA.dim >= horizB.dim) and horizA or horizB
	local thickAxis  = (horizA.dim >= horizB.dim) and horizB or horizA

	local lengthVec = lengthAxis.vec
	local lengthVal = lengthAxis.dim
	local sideVec   = thickAxis.vec
	local thickVal  = thickAxis.dim

	-- FOV framing calculation with generous 30% margin (never clips edges!)
	local vFovRad = math.rad(70)
	local tanHalfV = math.tan(vFovRad / 2)
	local vpAspect = isDetailPreview and (216 / 134) or (72 / 58)
	local tanHalfH = tanHalfV * vpAspect

	local distH = (lengthVal / 2) / tanHalfH
	local distV = (vertHeight / 2) / tanHalfV
	local dist = math.max(distH, distV) * 1.30
	if dist < 0.9 then dist = 0.9 end

	-- Position camera at true lateral side with subtle 10-degree 3/4 perspective
	local camPos = center + sideVec * (dist * 0.96) + vertVec * (dist * 0.12) + lengthVec * (dist * 0.22)
	cam.CFrame = CFrame.lookAt(camPos, center, vertVec)

	-- Smooth rotation for caught fish in Details Panel
	if enableRotation and isCaught then
		local angle = 0
		activePreviewThread = task.spawn(function()
			while viewport.Parent and (activeFishName == fishNameRef) do
				angle = (angle + 1) % 360
				local rotCF = CFrame.fromAxisAngle(vertVec, math.rad(angle))
				local baseOffset = sideVec * (dist * 0.96) + vertVec * (dist * 0.12) + lengthVec * (dist * 0.22)
				local offset = rotCF * baseOffset
				cam.CFrame = CFrame.lookAt(center + offset, center, vertVec)
				task.wait(0.03)
			end
		end)
	end

	return model
end

-- ===================================================================
-- Synchronized Open/Close Logic (Top-to-Bottom Smooth Easing)
-- ===================================================================
local INDEX_SHOWN_POS = UDim2.new(0.5, 0, 0.5, 0)
local INDEX_HIDDEN_POS = UDim2.new(0.5, 0, -0.6, 0)
local indexTween: Tween? = nil
local indexTweenId = 0

local function setIndexVisible(visible: boolean)
	indexTweenId += 1
	local curId = indexTweenId
	if indexTween then
		indexTween:Cancel()
		indexTween = nil
	end

	mainFrame:SetAttribute("IsOpen", visible)
	gui:SetAttribute("IsOpen", visible)

	if visible then
		gui.Enabled = true
		mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		mainFrame.Position = INDEX_HIDDEN_POS
		mainFrame.Visible = true

		if refreshGrid then
			task.spawn(refreshGrid)
		end

		indexTween = TweenService:Create(
			mainFrame,
			TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = INDEX_SHOWN_POS }
		)
		indexTween.Completed:Connect(function()
			if curId == indexTweenId then
				indexTween = nil
			end
		end)
		indexTween:Play()
	else
		indexTween = TweenService:Create(
			mainFrame,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = INDEX_HIDDEN_POS }
		)
		indexTween.Completed:Connect(function()
			if curId == indexTweenId then
				mainFrame.Visible = false
				gui.Enabled = false
				indexTween = nil
			end
		end)
		indexTween:Play()
	end
end

closeBtn.MouseButton1Click:Connect(function()
	setIndexVisible(false)
end)

mainFrame:GetAttributeChangedSignal("IsOpen"):Connect(function()
	local isOpen = mainFrame:GetAttribute("IsOpen") == true
	if not isOpen and (mainFrame.Visible or gui.Enabled) and (not indexTween or mainFrame.Position == INDEX_SHOWN_POS) then
		setIndexVisible(false)
	end
end)

local lastToggleTime = 0
local function toggleIndex()
	local now = os.clock()
	if now - lastToggleTime < 0.25 then return end
	lastToggleTime = now

	local isOpen = mainFrame:GetAttribute("IsOpen") == true
	setIndexVisible(not isOpen)
end

-- Hook up with LeftHolder Index button in GameUI
task.spawn(function()
	local playerGui = player:WaitForChild("PlayerGui")
	local gameUI = playerGui:WaitForChild("GameUI", 15)
	if gameUI then
		local component = gameUI:WaitForChild("Component", 15)
		local buttons = component and component:WaitForChild("Buttons", 15)
		local leftHolder = buttons and buttons:WaitForChild("LeftHolder", 15)
		local indexBtn = leftHolder and leftHolder:WaitForChild("Index", 15)
		if indexBtn then
			indexBtn.MouseButton1Click:Connect(toggleIndex)
		end
	end
end)

-- Calculate Base Chance String
local function getChanceString(prob)
	if not prob or prob <= 0 then return "1 in 100" end
	local oneIn = math.round(100 / prob)
	return string.format("1 in %d", math.max(1, oneIn))
end

-- Update Details Panel
local function selectFish(fishInfo, isCaught, count)
	local rarity = fishInfo.rarity or "Common"
	local rarityColor = RARITY_COLORS[rarity] or Color3.fromRGB(180, 190, 205)
	activeFishName = fishInfo.name

	if activePreviewThread then
		pcall(task.cancel, activePreviewThread)
		activePreviewThread = nil
	end

	-- Always display the accurate weight range
	local minW = fishInfo.minKg or 0.5
	local maxW = fishInfo.maxKg or 45
	weightLabel.Text = string.format("Weight: %.1f kg - %.1f kg", minW, maxW)

	if isCaught then
		dpName.Text = fishInfo.name
		dpName.TextColor3 = rarityColor
		caughtStatus.Text = "Discovered"
		caughtStatus.TextColor3 = Color3.fromRGB(80, 220, 120)
		caughtTimes.Text = string.format("Caught %d times", count or 1)
		caughtTimes.Visible = true
	else
		dpName.Text = "???"
		dpName.TextColor3 = rarityColor
		caughtStatus.Text = "Not caught yet"
		caughtStatus.TextColor3 = Color3.fromRGB(160, 170, 185)
		caughtTimes.Text = "Caught 0 times"
		caughtTimes.Visible = true
	end

	-- Render 3D model / silhouette in preview box
	local fishFolder = getFishAssetsFolder()
	local template = fishFolder and fishFolder:FindFirstChild(fishInfo.name)
	if template then
		setupFishViewport(previewViewport, template, isCaught, true, fishInfo.name, true)
	else
		previewViewport:ClearAllChildren()
	end

	dpRarityBadge.Text = string.upper(rarity)
	dpRarityBadge.BackgroundColor3 = rarityColor
	previewChance.Text = getChanceString(fishInfo.probability or 30)
end

-- Filter visibility helper (instantaneous, 0ms)
local function updateFilterVisibility()
	for fishName, card in pairs(allCards) do
		local matchesFilter = false
		local rarity = card:GetAttribute("Rarity") or "Common"
		if activeFilter == "All" then
			matchesFilter = true
		elseif activeFilter == "Secret" and (rarity == "Secret" or rarity == "Legendary") then
			matchesFilter = true
		elseif activeFilter == "Forgotten" and (rarity == "Forgotten" or rarity == "Mitos") then
			matchesFilter = true
		elseif activeFilter == rarity then
			matchesFilter = true
		end
		card.Visible = matchesFilter
	end
end

-- Refresh Index Grid (Smart Caching & Micro-Batching)
refreshGrid = function()
	if not fishingConfig or not fishingConfig.FishTable then return end

	local totalFish = #fishingConfig.FishTable
	local caughtCount = 0
	local fishFolder = getFishAssetsFolder()

	for i, fishInfo in ipairs(fishingConfig.FishTable) do
		local fishName = fishInfo.name
		local count = caughtData[fishName] or 0
		local isCaught = count > 0
		if isCaught then
			caughtCount = caughtCount + 1
		end

		local rarity = fishInfo.rarity or "Common"
		local rarityColor = RARITY_COLORS[rarity] or Color3.fromRGB(180, 190, 205)
		local defaultStrokeColor = getStrokeColor(rarityColor)

		local card = allCards[fishName]
		local isNewCard = false
		if not card then
			isNewCard = true
			card = cardTemplate:Clone()
			card.Name = "Card_" .. fishName
			card:SetAttribute("Rarity", rarity)
			card.Parent = fishGrid
			allCards[fishName] = card

			card.MouseButton1Click:Connect(function()
				if selectedCard and selectedCard:FindFirstChild("UIStroke") then
					local prevFishName = string.sub(selectedCard.Name, 6)
					local prevFishInfo = nil
					for _, fi in ipairs(fishingConfig.FishTable) do
						if fi.name == prevFishName then
							prevFishInfo = fi
							break
						end
					end
					local prevRarity = prevFishInfo and prevFishInfo.rarity or "Common"
					local prevRarityColor = RARITY_COLORS[prevRarity] or Color3.fromRGB(180, 190, 205)
					selectedCard.UIStroke.Color = getStrokeColor(prevRarityColor)
					selectedCard.UIStroke.Thickness = 1
				end

				selectedCard = card
				if card:FindFirstChild("UIStroke") then
					card.UIStroke.Color = Color3.fromRGB(255, 255, 255)
					card.UIStroke.Thickness = 2
				end
				selectFish(fishInfo, (caughtData[fishName] or 0) > 0, caughtData[fishName])
			end)
		end

		-- Set card stroke color based on rarity
		local cardStroke = card:FindFirstChild("UIStroke")
		if cardStroke then
			if card == selectedCard then
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
			local alreadyRendered = (renderedState[fishName] == isCaught) and (cardViewport:FindFirstChild("FishModel") ~= nil)
			if not alreadyRendered then
				setupFishViewport(cardViewport, template, isCaught, false, fishName, false)
				renderedState[fishName] = isCaught
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
		if i == 1 and not selectedCard then
			selectedCard = card
			if cardStroke then
				cardStroke.Color = Color3.fromRGB(255, 255, 255)
				cardStroke.Thickness = 2
			end
			selectFish(fishInfo, isCaught, count)
		end
	end

	-- Apply filter visibility
	updateFilterVisibility()

	-- Update Progress Header
	subtitle.Text = string.format("All Fish: %d/%d", caughtCount, totalFish)
	local pct = totalFish > 0 and (caughtCount / totalFish) or 0
	TweenService:Create(progressBarFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(pct, 0, 1, 0)
	}):Play()
end

-- Filter Buttons Setup
for _, child in ipairs(filterColumn:GetChildren()) do
	if child:IsA("TextButton") and string.sub(child.Name, 1, 7) == "Filter_" then
		local filterName = string.sub(child.Name, 8)
		child.MouseButton1Click:Connect(function()
			activeFilter = filterName

			for _, btn in ipairs(filterColumn:GetChildren()) do
				if btn:IsA("TextButton") then
					local stroke = btn:FindFirstChild("UIStroke")
					if stroke then
						stroke.Color = (btn == child) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
						stroke.Thickness = (btn == child) and 2 or 1
					end
				end
			end

			updateFilterVisibility()
		end)
	end
end

-- Load Initial Caught Data from Server
task.spawn(function()
	for _ = 1, 5 do
		local callOk, awaitedOk, response = pcall(function()
			return NetworkGateway:Request("GET", "/fishing/index"):await()
		end)
		if callOk and awaitedOk and type(response) == "table" and response.Success and type(response.Data) == "table" then
			caughtData = response.Data
			if refreshGrid then refreshGrid() end
			return
		end
		task.wait(1)
	end
end)

-- Realtime Gateway Listener
local function setupCatchListener()
	NetworkGateway:On("Fishing/CatchSuccess", function(event)
		if type(event) ~= "table" then return end
		local fishName = event.FishName
		if type(fishName) ~= "string" or fishName == "" then return end
		caughtData[fishName] = event.SpeciesCount or ((caughtData[fishName] or 0) + 1)
		if refreshGrid then refreshGrid() end
	end)
end

setupCatchListener()
task.spawn(function()
	task.wait(1)
	if refreshGrid then refreshGrid() end
end)

-- Initial setup: hidden offscreen above
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = INDEX_HIDDEN_POS
mainFrame.Visible = false
mainFrame:SetAttribute("IsOpen", false)
gui:SetAttribute("IsOpen", false)
gui.Enabled = false

