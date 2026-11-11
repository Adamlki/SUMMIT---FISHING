-- Custom Inventory Manager with 6-Slot Hotbar Architecture & Dynamic Fish Slot Visibility
-- Slot 1: RodSlot (1)
-- Slot 2: ToolSlot1 (2)
-- Slot 3: ToolSlot2 (3)
-- Slot 4: BagButton (4)
-- Slot 5: FishSlot1 (5) [Hidden when empty]
-- Slot 6: FishSlot2 (6) [Hidden when empty]

local StarterGui = game:GetService("StarterGui")
task.spawn(function()
	local attempts = 0
	while attempts < 30 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		if ok then break end
		attempts = attempts + 1
		task.wait(0.1)
	end
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoleConfig = require(ReplicatedStorage:WaitForChild("RoleConfig"))
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local StarterPack = game:GetService("StarterPack")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===================================================================
-- SOUND SETTINGS (Handled universally by UniversalButtonEffects)
-- ===================================================================
local function playClickSound()
	-- No-op: Handled universally by UniversalButtonEffects to prevent double sounds
end

-- ===================================================================
-- MODULES & EVENTS
-- ===================================================================
local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local FishingConfig = require(FishingSystem:WaitForChild("FishingConfig"))
local RarityColors = FishingConfig.RarityColors

local InventoryEvents = FishingSystem:WaitForChild("InventoryEvents")
local rfGetData = InventoryEvents:WaitForChild("Inventory_GetData")
local rfToggleFavorite = InventoryEvents:WaitForChild("Inventory_ToggleFavorite")
local rfSellAll = InventoryEvents:WaitForChild("Inventory_SellAll")
local reEquipRod = InventoryEvents:WaitForChild("Inventory_EquipRod")
local reEquipFish = InventoryEvents:WaitForChild("Inventory_EquipFish")
local reUnequipAll = InventoryEvents:WaitForChild("Inventory_UnequipAll")
local reEquipTool = InventoryEvents:WaitForChild("Inventory_EquipTool")
local reEquipVIPTool = InventoryEvents:WaitForChild("Inventory_EquipVIPTool")
local rfGetVIPTools = InventoryEvents:WaitForChild("Inventory_GetVIPTools")
local GlobalLuckVal = FishingSystem:WaitForChild("GlobalLuckMultiplier")

local fishAssetFolder = FishingSystem:WaitForChild("Assets"):WaitForChild("Fish")
local rodAssetFolder = FishingSystem:WaitForChild("Assets"):WaitForChild("Rod")




-- ===================================================================
-- VIP CONFIGURATION
-- ===================================================================
local VIP_GAMEPASS_ID = 1590939529
local isVIP = false

-- ===================================================================
-- GUI REFERENCE + ORIGINAL COLORS
-- ===================================================================
local gui = nil
local Hotbar = {}
local Inventory = {}
local Templates = {}

local OriginalColors = {
	RodSlot = {},
	ToolSlot1 = {},
	ToolSlot2 = {},
	FishSlot1 = {},
	FishSlot2 = {}
}

local function updateGUIReferences()
	local attempts = 0
	while attempts < 50 do
		gui = playerGui:FindFirstChild("CustomInventoryGui")
		if gui then break end
		attempts = attempts + 1
		task.wait(0.1)
	end

	if not gui then
		warn("[CustomInventory] Failed to find CustomInventoryGui!")
		return false
	end

	Hotbar.Frame = gui:FindFirstChild("HotbarFrame")
	if not Hotbar.Frame then
		warn("[CustomInventory] HotbarFrame not found!")
		return false
	end

	-- Slot 1: Rod
	Hotbar.RodSlot = Hotbar.Frame:FindFirstChild("RodSlot")
	Hotbar.RodImage = Hotbar.RodSlot and Hotbar.RodSlot:FindFirstChild("RodImage")
	Hotbar.RodName = Hotbar.RodSlot and Hotbar.RodSlot:FindFirstChild("RodName")
	Hotbar.RodViewport = Hotbar.RodSlot and Hotbar.RodSlot:FindFirstChild("RodViewport")

	-- Slot 2: Tool 1
	Hotbar.ToolSlot1 = Hotbar.Frame:FindFirstChild("ToolSlot1")
	Hotbar.ToolImage1 = Hotbar.ToolSlot1 and Hotbar.ToolSlot1:FindFirstChild("ToolImage1")
	Hotbar.ToolName1 = Hotbar.ToolSlot1 and Hotbar.ToolSlot1:FindFirstChild("ToolName1")
	Hotbar.ToolViewport1 = Hotbar.ToolSlot1 and Hotbar.ToolSlot1:FindFirstChild("ToolViewport1")

	-- Slot 3: Tool 2
	Hotbar.ToolSlot2 = Hotbar.Frame:FindFirstChild("ToolSlot2")
	Hotbar.ToolImage2 = Hotbar.ToolSlot2 and Hotbar.ToolSlot2:FindFirstChild("ToolImage2")
	Hotbar.ToolName2 = Hotbar.ToolSlot2 and Hotbar.ToolSlot2:FindFirstChild("ToolName2")
	Hotbar.ToolViewport2 = Hotbar.ToolSlot2 and Hotbar.ToolSlot2:FindFirstChild("ToolViewport2")

	-- Slot 4: Bag
	Hotbar.BagButton = Hotbar.Frame:FindFirstChild("BagButton")

	-- Slot 5: Fish 1
	Hotbar.FishSlot1 = Hotbar.Frame:FindFirstChild("FishSlot1")
	Hotbar.FishImage1 = Hotbar.FishSlot1 and Hotbar.FishSlot1:FindFirstChild("FishImage1")
	Hotbar.FishName1 = Hotbar.FishSlot1 and Hotbar.FishSlot1:FindFirstChild("FishName1")
	Hotbar.FishViewport1 = Hotbar.FishSlot1 and Hotbar.FishSlot1:FindFirstChild("FishViewport1")

	-- Slot 6: Fish 2
	Hotbar.FishSlot2 = Hotbar.Frame:FindFirstChild("FishSlot2")
	Hotbar.FishImage2 = Hotbar.FishSlot2 and Hotbar.FishSlot2:FindFirstChild("FishImage2")
	Hotbar.FishName2 = Hotbar.FishSlot2 and Hotbar.FishSlot2:FindFirstChild("FishName2")
	Hotbar.FishViewport2 = Hotbar.FishSlot2 and Hotbar.FishSlot2:FindFirstChild("FishViewport2")

	if Hotbar.RodSlot then
		OriginalColors.RodSlot.Background = Hotbar.RodSlot.BackgroundColor3
		OriginalColors.RodSlot.Transparency = Hotbar.RodSlot.BackgroundTransparency
		OriginalColors.RodSlot.ImageTransparency = Hotbar.RodImage and Hotbar.RodImage.ImageTransparency or 0
		OriginalColors.RodSlot.TextTransparency = Hotbar.RodName and Hotbar.RodName.TextTransparency or 0
		OriginalColors.RodSlot.TextColor = Hotbar.RodName and Hotbar.RodName.TextColor3 or Color3.fromRGB(255, 255, 255)
	end

	if Hotbar.ToolSlot1 then
		OriginalColors.ToolSlot1.Background = Hotbar.ToolSlot1.BackgroundColor3
		OriginalColors.ToolSlot1.Transparency = Hotbar.ToolSlot1.BackgroundTransparency
		OriginalColors.ToolSlot1.ImageTransparency = Hotbar.ToolImage1 and Hotbar.ToolImage1.ImageTransparency or 0
		OriginalColors.ToolSlot1.TextTransparency = Hotbar.ToolName1 and Hotbar.ToolName1.TextTransparency or 0
		OriginalColors.ToolSlot1.TextColor = Hotbar.ToolName1 and Hotbar.ToolName1.TextColor3 or Color3.fromRGB(255, 255, 255)
	end

	if Hotbar.ToolSlot2 then
		OriginalColors.ToolSlot2.Background = Hotbar.ToolSlot2.BackgroundColor3
		OriginalColors.ToolSlot2.Transparency = Hotbar.ToolSlot2.BackgroundTransparency
		OriginalColors.ToolSlot2.ImageTransparency = Hotbar.ToolImage2 and Hotbar.ToolImage2.ImageTransparency or 0
		OriginalColors.ToolSlot2.TextTransparency = Hotbar.ToolName2 and Hotbar.ToolName2.TextTransparency or 0
		OriginalColors.ToolSlot2.TextColor = Hotbar.ToolName2 and Hotbar.ToolName2.TextColor3 or Color3.fromRGB(255, 255, 255)
	end

	if Hotbar.FishSlot1 then
		OriginalColors.FishSlot1.Background = Hotbar.FishSlot1.BackgroundColor3
		OriginalColors.FishSlot1.Transparency = Hotbar.FishSlot1.BackgroundTransparency
		OriginalColors.FishSlot1.ImageTransparency = Hotbar.FishImage1 and Hotbar.FishImage1.ImageTransparency or 0
		OriginalColors.FishSlot1.TextTransparency = Hotbar.FishName1 and Hotbar.FishName1.TextTransparency or 0
		OriginalColors.FishSlot1.TextColor = Hotbar.FishName1 and Hotbar.FishName1.TextColor3 or Color3.fromRGB(255, 255, 255)
	end

	if Hotbar.FishSlot2 then
		OriginalColors.FishSlot2.Background = Hotbar.FishSlot2.BackgroundColor3
		OriginalColors.FishSlot2.Transparency = Hotbar.FishSlot2.BackgroundTransparency
		OriginalColors.FishSlot2.ImageTransparency = Hotbar.FishImage2 and Hotbar.FishImage2.ImageTransparency or 0
		OriginalColors.FishSlot2.TextTransparency = Hotbar.FishName2 and Hotbar.FishName2.TextTransparency or 0
		OriginalColors.FishSlot2.TextColor = Hotbar.FishName2 and Hotbar.FishName2.TextColor3 or Color3.fromRGB(255, 255, 255)
	end

	local mainFrame = gui:FindFirstChild("MainInventoryFrame")
	if not mainFrame then
		warn("[CustomInventory] MainInventoryFrame not found!")
		return false
	end

	Inventory.Frame = mainFrame

	local headerFrame = mainFrame:FindFirstChild("Header")
	Inventory.CloseButton = headerFrame and headerFrame:FindFirstChild("CloseButton")

	local tabsFrame = mainFrame:FindFirstChild("TabsFrame")
	Inventory.FishTabButton = tabsFrame and tabsFrame:FindFirstChild("FishTabButton")
	Inventory.RodTabButton = tabsFrame and tabsFrame:FindFirstChild("RodTabButton")
	Inventory.ToolTabButton = tabsFrame and tabsFrame:FindFirstChild("ToolTabButton")
	Inventory.VIPTabButton = tabsFrame and tabsFrame:FindFirstChild("VIPTabButton")

	local contentFrame = mainFrame:FindFirstChild("ContentFrame")
	Inventory.FishContent = contentFrame and contentFrame:FindFirstChild("FishContent")
	Inventory.RodContent = contentFrame and contentFrame:FindFirstChild("RodContent")
	Inventory.ToolContent = contentFrame and contentFrame:FindFirstChild("ToolContent")
	Inventory.VIPContent = contentFrame and contentFrame:FindFirstChild("VIPContent")

	local footerFrame = mainFrame:FindFirstChild("Footer")
	Inventory.SellAllButton = footerFrame and footerFrame:FindFirstChild("SellAllButton")
	Inventory.FishCountLabel = footerFrame and footerFrame:FindFirstChild("FishCountLabel")

	local templatesFolder = gui:FindFirstChild("Templates")
	if templatesFolder then
		Templates.Fish = templatesFolder:FindFirstChild("FishTemplate")
		Templates.Tool = templatesFolder:FindFirstChild("ToolTemplate")
		Templates.Rod = templatesFolder:FindFirstChild("RodTemplate")
		Templates.VIPTool = templatesFolder:FindFirstChild("VIPToolTemplate")
	end

	Hotbar.Frame.Visible = true
	return true
end

updateGUIReferences()

-- ===================================================================
-- STATE VARIABLES
-- ===================================================================
local isInventoryOpen = false
local currentTab = "Fish"
local lastOpenedTab = "Fish"
local allFishData = {}
local allRodData = {}
local rodToolStats = {}

local lastEquippedRodName = nil
local lastEquippedToolName1 = nil
local lastEquippedToolName2 = nil
local lastEquippedFishId1 = nil
local lastEquippedFishId2 = nil

local connections = {}

-- ===================================================================
-- HOTBAR STATE PERSISTENCE
-- ===================================================================
local HotbarState = {
	rod = nil,
	tool1 = nil,
	tool2 = nil,
	fish1 = nil,
	fish2 = nil
}

local function saveHotbarState()
	HotbarState.rod = lastEquippedRodName
	HotbarState.tool1 = lastEquippedToolName1
	HotbarState.tool2 = lastEquippedToolName2
	HotbarState.fish1 = lastEquippedFishId1
	HotbarState.fish2 = lastEquippedFishId2
end

-- ===================================================================
-- HELPER FUNCTIONS
-- ===================================================================

local function updateFishCount()
	if Inventory.FishCountLabel then
		local fishCount = #allFishData
		local maxFish = FishingConfig.InventoryLimitSettings.maxFishInventory or 500
		Inventory.FishCountLabel.Text = string.format("%d/%d", fishCount, maxFish)
	end
end

local function getRarityColor(rarity)
	return RarityColors[rarity] or Color3.fromRGB(255, 255, 255)
end

-- ===================================================================
-- AUTHORITATIVE ROD VALIDATOR (Guarantees Slot 1 = Rod only, Slot 2/3 = Tools only)
-- ===================================================================
local function isRodName(name)
	if not name or name == "" then return false end
	if table.find(allRodData, name) then return true end
	if rodAssetFolder and rodAssetFolder:FindFirstChild(name) then return true end
	local bp = player:FindFirstChild("Backpack")
	local ch = player.Character
	local t = (bp and bp:FindFirstChild(name)) or (ch and ch:FindFirstChild(name))
	if t and CollectionService:HasTag(t, "Rod") then return true end
	return false
end

-- ===================================================================
-- 3D VIEWPORT FRAME ENGINE (Real 3D models with camera & lighting)
-- ===================================================================
local function setupFishViewport(viewport, fishName)
	if not viewport then return end
	viewport:ClearAllChildren()
	if not fishName or fishName == "" then return end

	local template = fishAssetFolder:FindFirstChild(fishName)
	if not template then
		local fishModelFolder = FishingSystem:WaitForChild("Assets"):FindFirstChild("FishModel")
		template = fishModelFolder and fishModelFolder:FindFirstChild(fishName)
	end
	if not template then return end

	local cam = Instance.new("Camera")
	cam.FieldOfView = 70
	cam.Parent = viewport
	viewport.CurrentCamera = cam

	viewport.Ambient = Color3.fromRGB(215, 215, 230)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -1)

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
				p.CanTouch = false
				p.CanQuery = false
				p.Parent = model
			end
		end
	end
	model.Parent = viewport

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

	local axes = {
		{vec = cf.RightVector, dim = size.X},
		{vec = cf.UpVector,    dim = size.Y},
		{vec = cf.LookVector,  dim = size.Z},
	}
	table.sort(axes, function(a, b) return math.abs(a.vec.Y) > math.abs(b.vec.Y) end)

	local vertAxis = axes[1]
	local vertVec = (vertAxis.vec.Y >= 0) and vertAxis.vec or -vertAxis.vec
	local vertHeight = vertAxis.dim

	local horizA = axes[2]
	local horizB = axes[3]
	local lengthAxis = (horizA.dim >= horizB.dim) and horizA or horizB
	local thickAxis  = (horizA.dim >= horizB.dim) and horizB or horizA

	local lengthVec = lengthAxis.vec
	local lengthVal = lengthAxis.dim
	local sideVec   = thickAxis.vec

	local vFovRad = math.rad(70)
	local tanHalfV = math.tan(vFovRad / 2)
	local vpAspect = 1
	local tanHalfH = tanHalfV * vpAspect

	local distH = (lengthVal / 2) / tanHalfH
	local distV = (vertHeight / 2) / tanHalfV
	local dist = math.max(distH, distV) * 1.30
	if dist < 0.9 then dist = 0.9 end

	local camPos = center + sideVec * (dist * 0.96) + vertVec * (dist * 0.12) + lengthVec * (dist * 0.22)
	cam.CFrame = CFrame.lookAt(camPos, center, vertVec)
end

local function setupRodViewport(viewport, rodName)
	if not viewport then return end
	viewport:ClearAllChildren()
	if not rodName or rodName == "" then return end

	local targetName = rodName
	if targetName == "Vip Rod" or targetName == "Royal Rod" then
		targetName = "Dragon Spine"
	end

	local tool = rodAssetFolder and rodAssetFolder:FindFirstChild(targetName)
	if not tool then
		local bp = player:FindFirstChild("Backpack")
		local ch = player.Character
		tool = (bp and bp:FindFirstChild(targetName)) or (ch and ch:FindFirstChild(targetName))
	end
	if not tool then return end

	local model = Instance.new("Model")
	model.Name = "RodModel"

	for _, desc in ipairs(tool:GetDescendants()) do
		if desc:IsA("BasePart") then
			local isMeshPart = desc:IsA("MeshPart")
			local hasSpecialMesh = desc:FindFirstChildOfClass("SpecialMesh") ~= nil
			local isInvisibleGrip = (desc.Transparency >= 0.9 and not isMeshPart and not hasSpecialMesh)

			if not isInvisibleGrip and (desc.Transparency < 0.9 or isMeshPart or hasSpecialMesh) then
				local p = desc:Clone()
				p.Anchored = true
				p.CanCollide = false
				p.CanTouch = false
				p.CanQuery = false
				p.Parent = model
			end
		end
	end
	model.Parent = viewport

	local cam = Instance.new("Camera")
	cam.FieldOfView = 50
	cam.Parent = viewport
	viewport.CurrentCamera = cam

	viewport.Ambient = Color3.fromRGB(220, 220, 235)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -1)

	local cf, size = model:GetBoundingBox()
	local maxDim = math.max(size.X, size.Y, size.Z)
	local dist = (maxDim / 2) / math.tan(math.rad(cam.FieldOfView / 2)) * 1.15
	if dist < 1 then dist = 1 end

	local camPos = cf.Position + Vector3.new(dist * 0.42, dist * 0.18, dist * 0.9)
	cam.CFrame = CFrame.lookAt(camPos, cf.Position)
end

local function setupToolViewport(viewport, toolRef)
	if not viewport then return end
	viewport:ClearAllChildren()
	if not toolRef then return end

	local tool = nil
	if typeof(toolRef) == "Instance" then
		tool = toolRef
	elseif type(toolRef) == "string" and toolRef ~= "" then
		local bp = player:FindFirstChild("Backpack")
		local ch = player.Character
		local gear = player:FindFirstChild("StarterGear")
		tool = (bp and bp:FindFirstChild(toolRef))
			or (ch and ch:FindFirstChild(toolRef))
			or (gear and gear:FindFirstChild(toolRef))
			or StarterPack:FindFirstChild(toolRef)
	end
	if not tool or not tool:IsA("Tool") then return end

local model = Instance.new("Model")
	model.Name = "ToolModel"

	for _, desc in ipairs(tool:GetDescendants()) do
		if desc:IsA("BasePart") then
			local isMeshPart = desc:IsA("MeshPart")
			local hasSpecialMesh = desc:FindFirstChildOfClass("SpecialMesh") ~= nil
			local isInvisibleGrip = (desc.Transparency >= 0.9 and not isMeshPart and not hasSpecialMesh)

			if not isInvisibleGrip and (desc.Transparency < 0.9 or isMeshPart or hasSpecialMesh) then
				local p = desc:Clone()
				p.Anchored = true
				p.CanCollide = false
				p.CanTouch = false
				p.CanQuery = false
				p.Parent = model
			end
		end
	end
	model.Parent = viewport

	local cam = Instance.new("Camera")
	cam.FieldOfView = 55
	cam.Parent = viewport
	viewport.CurrentCamera = cam

	viewport.Ambient = Color3.fromRGB(220, 220, 235)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -1)

	local cf, size = model:GetBoundingBox()
	local maxDim = math.max(size.X, size.Y, size.Z)
	local dist = (maxDim / 2) / math.tan(math.rad(cam.FieldOfView / 2)) * 1.2
	if dist < 1 then dist = 1 end

	local camPos = cf.Position + Vector3.new(dist * 0.4, dist * 0.2, dist * 0.9)
	cam.CFrame = CFrame.lookAt(camPos, cf.Position)
end

-- Visual for Slot 1: Rod (STRICTLY RODS ONLY)
local function updateRodVisual(rodName)
	if not rodName or rodName == "" then
		if Hotbar.RodViewport then Hotbar.RodViewport:ClearAllChildren(); Hotbar.RodViewport.Visible = false end
		if Hotbar.RodImage then Hotbar.RodImage.Image = "" end
		if Hotbar.RodName then
			Hotbar.RodName.Text = "ROD"
			Hotbar.RodName.TextColor3 = Color3.fromRGB(255, 255, 255)
			Hotbar.RodName.TextTransparency = 0
		end
		if Hotbar.RodSlot then
			Hotbar.RodSlot.ImageColor3 = Color3.fromRGB(255, 255, 255)
			Hotbar.RodSlot.BackgroundTransparency = 1
		end
		return
	end

	if Hotbar.RodViewport then
		Hotbar.RodViewport.ZIndex = 3
		Hotbar.RodViewport.Visible = true
		setupRodViewport(Hotbar.RodViewport, rodName)
	end
	if Hotbar.RodImage then Hotbar.RodImage.Image = "" end
	if Hotbar.RodName then
		Hotbar.RodName.Text = rodName
		Hotbar.RodName.TextColor3 = Color3.fromRGB(255, 255, 255)
		Hotbar.RodName.TextTransparency = 0
	end

	local char = player.Character
	local isHolding = char and char:FindFirstChild(rodName)

	if Hotbar.RodSlot then
		Hotbar.RodSlot.BackgroundTransparency = 1
		if isHolding then
			Hotbar.RodSlot.ImageColor3 = Color3.fromRGB(255, 230, 160)
		else
			Hotbar.RodSlot.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

-- Visual for Slot 2: Tool 1 (STRICTLY NON-ROD TOOLS ONLY)
local function updateToolVisual1(toolName)
	if not toolName or toolName == "" or isRodName(toolName) then
		if Hotbar.ToolViewport1 then Hotbar.ToolViewport1:ClearAllChildren(); Hotbar.ToolViewport1.Visible = false end
		if Hotbar.ToolImage1 then Hotbar.ToolImage1.Image = "" end
		if Hotbar.ToolName1 then
			Hotbar.ToolName1.Text = "TOOLS"
			Hotbar.ToolName1.TextColor3 = Color3.fromRGB(255, 255, 255)
			Hotbar.ToolName1.TextTransparency = 0
		end
		if Hotbar.ToolSlot1 then
			Hotbar.ToolSlot1.ImageColor3 = Color3.fromRGB(255, 255, 255)
			Hotbar.ToolSlot1.BackgroundTransparency = 1
		end
		return
	end

	local icon = ""
	local tool = player.Backpack:FindFirstChild(toolName) or (player.Character and player.Character:FindFirstChild(toolName))
	if tool and tool:IsA("Tool") and tool.TextureId ~= "" then
		icon = tool.TextureId
	end

	if icon and icon ~= "" then
		if not icon:match("rbxassetid") and not icon:match("http") then
			icon = "rbxassetid://" .. icon
		end
		if Hotbar.ToolImage1 then
			Hotbar.ToolImage1.Image = icon
			Hotbar.ToolImage1.ImageTransparency = 0
			Hotbar.ToolImage1.Visible = true
		end
		if Hotbar.ToolViewport1 then Hotbar.ToolViewport1.Visible = false end
	else
		if Hotbar.ToolImage1 then Hotbar.ToolImage1.Image = "" end
		if Hotbar.ToolViewport1 then
			Hotbar.ToolViewport1.ZIndex = 3
			Hotbar.ToolViewport1.Visible = true
			setupToolViewport(Hotbar.ToolViewport1, toolName)
		end
	end

	if Hotbar.ToolName1 then
		Hotbar.ToolName1.Text = toolName
		Hotbar.ToolName1.TextColor3 = Color3.fromRGB(255, 255, 255)
		Hotbar.ToolName1.TextTransparency = 0
	end

	local char = player.Character
	local isHolding = char and char:FindFirstChild(toolName)

	if Hotbar.ToolSlot1 then
		Hotbar.ToolSlot1.BackgroundTransparency = 1
		if isHolding then
			Hotbar.ToolSlot1.ImageColor3 = Color3.fromRGB(255, 230, 160)
		else
			Hotbar.ToolSlot1.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

-- Visual for Slot 3: Tool 2 (STRICTLY NON-ROD TOOLS ONLY)
local function updateToolVisual2(toolName)
	if not toolName or toolName == "" or isRodName(toolName) then
		if Hotbar.ToolViewport2 then Hotbar.ToolViewport2:ClearAllChildren(); Hotbar.ToolViewport2.Visible = false end
		if Hotbar.ToolImage2 then Hotbar.ToolImage2.Image = "" end
		if Hotbar.ToolName2 then
			Hotbar.ToolName2.Text = "TOOLS"
			Hotbar.ToolName2.TextColor3 = Color3.fromRGB(255, 255, 255)
			Hotbar.ToolName2.TextTransparency = 0
		end
		if Hotbar.ToolSlot2 then
			Hotbar.ToolSlot2.ImageColor3 = Color3.fromRGB(255, 255, 255)
			Hotbar.ToolSlot2.BackgroundTransparency = 1
		end
		return
	end

	local icon = ""
	local tool = player.Backpack:FindFirstChild(toolName) or (player.Character and player.Character:FindFirstChild(toolName))
	if tool and tool:IsA("Tool") and tool.TextureId ~= "" then
		icon = tool.TextureId
	end

	if icon and icon ~= "" then
		if not icon:match("rbxassetid") and not icon:match("http") then
			icon = "rbxassetid://" .. icon
		end
		if Hotbar.ToolImage2 then
			Hotbar.ToolImage2.Image = icon
			Hotbar.ToolImage2.ImageTransparency = 0
			Hotbar.ToolImage2.Visible = true
		end
		if Hotbar.ToolViewport2 then Hotbar.ToolViewport2.Visible = false end
	else
		if Hotbar.ToolImage2 then Hotbar.ToolImage2.Image = "" end
		if Hotbar.ToolViewport2 then
			Hotbar.ToolViewport2.ZIndex = 3
			Hotbar.ToolViewport2.Visible = true
			setupToolViewport(Hotbar.ToolViewport2, toolName)
		end
	end

	if Hotbar.ToolName2 then
		Hotbar.ToolName2.Text = toolName
		Hotbar.ToolName2.TextColor3 = Color3.fromRGB(255, 255, 255)
		Hotbar.ToolName2.TextTransparency = 0
	end

	local char = player.Character
	local isHolding = char and char:FindFirstChild(toolName)

	if Hotbar.ToolSlot2 then
		Hotbar.ToolSlot2.BackgroundTransparency = 1
		if isHolding then
			Hotbar.ToolSlot2.ImageColor3 = Color3.fromRGB(255, 230, 160)
		else
			Hotbar.ToolSlot2.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

-- Visual for Slot 4: Fish 1
local function updateFishVisual1(fishId)
	if not fishId then
		if Hotbar.FishViewport1 then Hotbar.FishViewport1:ClearAllChildren(); Hotbar.FishViewport1.Visible = false end
		if Hotbar.FishImage1 then Hotbar.FishImage1.Image = "" end
		if Hotbar.FishName1 then Hotbar.FishName1.Text = "FISH" end
		if Hotbar.FishSlot1 then
			Hotbar.FishSlot1.Visible = true
			Hotbar.FishSlot1.ImageColor3 = Color3.fromRGB(255, 255, 255)
			Hotbar.FishSlot1.BackgroundTransparency = 1
		end
		return
	end

	local fishData = nil
	for _, f in ipairs(allFishData) do
		if f.uniqueId == fishId then
			fishData = f
			break
		end
	end

	if fishData then
		local fishTemplate = fishAssetFolder:FindFirstChild(fishData.name)
		local textureId = ""

		if fishTemplate and fishTemplate:IsA("Tool") and fishTemplate.TextureId ~= "" then
			local textureIdString = tostring(fishTemplate.TextureId)
			textureId = textureIdString
			if not textureId:match("rbxassetid") then
				textureId = "rbxassetid://" .. textureId
			end
		end

		if Hotbar.FishViewport1 then
			setupFishViewport(Hotbar.FishViewport1, fishData.name)
			Hotbar.FishViewport1.Visible = true
		end
		if Hotbar.FishImage1 then Hotbar.FishImage1.Image = "" end
		if Hotbar.FishName1 then Hotbar.FishName1.Text = fishData.name end
		if Hotbar.FishSlot1 then
			Hotbar.FishSlot1.Visible = true
			Hotbar.FishSlot1.BackgroundTransparency = 1
		end
	else
		if Hotbar.FishImage1 then Hotbar.FishImage1.Image = "" end
		if Hotbar.FishName1 then Hotbar.FishName1.Text = "FISH" end
		if Hotbar.FishSlot1 then
			Hotbar.FishSlot1.Visible = true
			Hotbar.FishSlot1.BackgroundTransparency = 1
		end
		return
	end

	local char = player.Character
	local currentTool = char and char:FindFirstChildOfClass("Tool")
	local isHoldingThisFish = (currentTool and currentTool:FindFirstChild("FishId") and currentTool.FishId.Value == fishId)

	if Hotbar.FishSlot1 then
		Hotbar.FishSlot1.BackgroundTransparency = 1
		if isHoldingThisFish then
			Hotbar.FishSlot1.ImageColor3 = Color3.fromRGB(255, 230, 160)
		else
			Hotbar.FishSlot1.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

-- Visual for Slot 5: Fish 2
local function updateFishVisual2(fishId)
	if not fishId then
		if Hotbar.FishViewport2 then Hotbar.FishViewport2:ClearAllChildren(); Hotbar.FishViewport2.Visible = false end
		if Hotbar.FishImage2 then Hotbar.FishImage2.Image = "" end
		if Hotbar.FishName2 then Hotbar.FishName2.Text = "FISH" end
		if Hotbar.FishSlot2 then
			Hotbar.FishSlot2.Visible = true
			Hotbar.FishSlot2.ImageColor3 = Color3.fromRGB(255, 255, 255)
			Hotbar.FishSlot2.BackgroundTransparency = 1
		end
		return
	end

	local fishData = nil
	for _, f in ipairs(allFishData) do
		if f.uniqueId == fishId then
			fishData = f
			break
		end
	end

	if fishData then
		local fishTemplate = fishAssetFolder:FindFirstChild(fishData.name)
		local textureId = ""

		if fishTemplate and fishTemplate:IsA("Tool") and fishTemplate.TextureId ~= "" then
			local textureIdString = tostring(fishTemplate.TextureId)
			textureId = textureIdString
			if not textureId:match("rbxassetid") then
				textureId = "rbxassetid://" .. textureId
			end
		end

		if Hotbar.FishViewport2 then
			setupFishViewport(Hotbar.FishViewport2, fishData.name)
			Hotbar.FishViewport2.Visible = true
		end
		if Hotbar.FishImage2 then Hotbar.FishImage2.Image = "" end
		if Hotbar.FishName2 then Hotbar.FishName2.Text = fishData.name end
		if Hotbar.FishSlot2 then
			Hotbar.FishSlot2.Visible = true
			Hotbar.FishSlot2.BackgroundTransparency = 1
		end
	else
		if Hotbar.FishImage2 then Hotbar.FishImage2.Image = "" end
		if Hotbar.FishName2 then Hotbar.FishName2.Text = "FISH" end
		if Hotbar.FishSlot2 then
			Hotbar.FishSlot2.Visible = true
			Hotbar.FishSlot2.BackgroundTransparency = 1
		end
		return
	end

	local char = player.Character
	local currentTool = char and char:FindFirstChildOfClass("Tool")
	local isHoldingThisFish = (currentTool and currentTool:FindFirstChild("FishId") and currentTool.FishId.Value == fishId)

	if Hotbar.FishSlot2 then
		Hotbar.FishSlot2.BackgroundTransparency = 1
		if isHoldingThisFish then
			Hotbar.FishSlot2.ImageColor3 = Color3.fromRGB(255, 230, 160)
		else
			Hotbar.FishSlot2.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

-- ===================================================================
-- STATE MANAGEMENT FUNCTIONS
-- ===================================================================

local function restoreHotbarState()
	lastEquippedRodName = HotbarState.rod
	lastEquippedToolName1 = HotbarState.tool1
	lastEquippedToolName2 = HotbarState.tool2
	lastEquippedFishId1 = HotbarState.fish1
	lastEquippedFishId2 = HotbarState.fish2

	updateRodVisual(lastEquippedRodName)
	updateToolVisual1(lastEquippedToolName1)
	updateToolVisual2(lastEquippedToolName2)
	updateFishVisual1(lastEquippedFishId1)
	updateFishVisual2(lastEquippedFishId2)
end

local function validateHotbarItems()
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end

	-- Validate Rod
	if lastEquippedRodName then
		local rodExists = backpack:FindFirstChild(lastEquippedRodName) or
			(player.Character and player.Character:FindFirstChild(lastEquippedRodName))
		if not rodExists then
			local hasRod = false
			for _, rodName in ipairs(allRodData) do
				if rodName == lastEquippedRodName then
					hasRod = true
					break
				end
			end
			if not hasRod then
				lastEquippedRodName = nil
				updateRodVisual(nil)
			end
		end
	end

	-- Validate Tool 1
	if lastEquippedToolName1 then
		local toolExists = backpack:FindFirstChild(lastEquippedToolName1) or
			(player.Character and player.Character:FindFirstChild(lastEquippedToolName1))
		if not toolExists then
			lastEquippedToolName1 = nil
			updateToolVisual1(nil)
			saveHotbarState()
		end
	end

	-- Validate Tool 2
	if lastEquippedToolName2 then
		local toolExists = backpack:FindFirstChild(lastEquippedToolName2) or
			(player.Character and player.Character:FindFirstChild(lastEquippedToolName2))
		if not toolExists then
			lastEquippedToolName2 = nil
			updateToolVisual2(nil)
			saveHotbarState()
		end
	end

	-- Validate Fish 1
	if lastEquippedFishId1 then
		local fishExists = false
		for _, fishData in ipairs(allFishData) do
			if fishData.uniqueId == lastEquippedFishId1 then
				fishExists = true
				break
			end
		end
		if not fishExists then
			lastEquippedFishId1 = nil
			updateFishVisual1(nil)
			saveHotbarState()
		end
	end

	-- Validate Fish 2
	if lastEquippedFishId2 then
		local fishExists = false
		for _, fishData in ipairs(allFishData) do
			if fishData.uniqueId == lastEquippedFishId2 then
				fishExists = true
				break
			end
		end
		if not fishExists then
			lastEquippedFishId2 = nil
			updateFishVisual2(nil)
			saveHotbarState()
		end
	end
end

local function autoFillHotbarSlots()
	validateHotbarItems()

	local backpack = player:FindFirstChild("Backpack")
	local char = player.Character

	-- Auto fill rod if slot 1 is empty
	if not lastEquippedRodName or lastEquippedRodName == "" then
		local foundRod = nil
		if table.find(allRodData, "Basic Rod") then
			foundRod = "Basic Rod"
		elseif backpack and backpack:FindFirstChild("Basic Rod") then
			foundRod = "Basic Rod"
		elseif char and char:FindFirstChild("Basic Rod") then
			foundRod = "Basic Rod"
		elseif #allRodData > 0 then
			foundRod = allRodData[1]
		else
			local function findRodIn(parent)
				if not parent then return end
				for _, item in ipairs(parent:GetChildren()) do
					if item:IsA("Tool") and CollectionService:HasTag(item, "Rod") then
						return item.Name
					end
				end
			end
			foundRod = findRodIn(backpack) or findRodIn(char)
		end

		if foundRod then
			lastEquippedRodName = foundRod
			updateRodVisual(lastEquippedRodName)
		end
	end

	-- Clean up if any rod accidentally leaked into tool slots
	if lastEquippedToolName1 and isRodName(lastEquippedToolName1) then
		lastEquippedToolName1 = nil
	end
	if lastEquippedToolName2 and isRodName(lastEquippedToolName2) then
		lastEquippedToolName2 = nil
	end

	-- Auto fill tools if slots are empty (STRICTLY NON-ROD TOOLS)
	local backpack = player:FindFirstChild("Backpack")
	local char = player.Character
	local availableTools = {}

	local function collectTools(parent)
		if not parent then return end
		for _, item in ipairs(parent:GetChildren()) do
			if item:IsA("Tool") and not isRodName(item.Name) and not CollectionService:HasTag(item, "Rod") and not item:FindFirstChild("FishId") then
				if not table.find(availableTools, item.Name) then
					table.insert(availableTools, item.Name)
				end
			end
		end
	end

	collectTools(char)
	collectTools(backpack)

	if not lastEquippedToolName1 and #availableTools > 0 then
		lastEquippedToolName1 = availableTools[1]
		updateToolVisual1(lastEquippedToolName1)
	end

	if not lastEquippedToolName2 and #availableTools > 1 then
		for _, tName in ipairs(availableTools) do
			if tName ~= lastEquippedToolName1 then
				lastEquippedToolName2 = tName
				updateToolVisual2(lastEquippedToolName2)
				break
			end
		end
	end

	saveHotbarState()
end

-- ===================================================================
-- VIP STATUS CHECK
-- ===================================================================
local function checkVIPStatus()
	local MarketplaceService = game:GetService("MarketplaceService")

	local success, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_GAMEPASS_ID)
	end)

	if success then
		isVIP = result
	else
		isVIP = false
	end

	if RoleConfig.IsOwner(player) or RoleConfig.IsAdmin(player) then
		isVIP = true
	end

	if Inventory.VIPTabButton then
		Inventory.VIPTabButton.Visible = isVIP
	end

	return isVIP
end

-- ===================================================================
-- REMOTE SELL (BAG SELLING) PERMISSIONS
-- ===================================================================
local function hasRemoteSellPermission()
	if isVIP then return true end
	if player:GetAttribute("HasRemoteSell") == true then return true end
	if game.CreatorType == Enum.CreatorType.User and (player.UserId == game.CreatorId or game.CreatorId == 0) then
		return true
	end
	local ADMIN_IDS = { 7319628066, 8978185974 }
	for _, id in ipairs(ADMIN_IDS) do
		if player.UserId == id then return true end
	end
	if player.Name == "GUARD_ZVxJekybix" then
		return true
	end
	return false
end

local function updateSellButtonVisual()
	if not Inventory.SellAllButton then return end
	if hasRemoteSellPermission() then
		Inventory.SellAllButton.Text = "Sell All Fish"
		Inventory.SellAllButton.BackgroundColor3 = Color3.fromRGB(255, 183, 0)
	else
		Inventory.SellAllButton.Text = "🔒 Sell (Perk)"
		Inventory.SellAllButton.BackgroundColor3 = Color3.fromRGB(80, 80, 85)
	end
end

-- ===================================================================
-- FORWARD DECLARATIONS
-- ===================================================================
local toggleInventory
local switchTab

-- Helper to equip / unequip tool locally or via server
local function toggleEquipToolByName(toolName, fallbackTab)
	if not toolName or toolName == "" then
		toggleInventory(true)
		if fallbackTab then switchTab(fallbackTab) end
		return
	end

	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local backpack = player:FindFirstChild("Backpack")

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

	if reEquipVIPTool then
		reEquipVIPTool:FireServer(toolName)
	elseif reEquipTool then
		reEquipTool:FireServer(toolName)
	end
end

-- Helper when a tool is selected from Inventory
local function onAnyToolSelected(selectedToolName)
	playClickSound()
	if not selectedToolName or selectedToolName == "" then return end

	-- Slot 1 is STRICTLY for Rods. If a rod is selected, it belongs ONLY in Slot 1
	if isRodName(selectedToolName) then
		lastEquippedRodName = selectedToolName
		saveHotbarState()
		updateRodVisual(selectedToolName)
		reEquipRod:FireServer(selectedToolName)
		return
	end

	-- Tool non-rod is STRICTLY for Slot 2 and Slot 3!
	if lastEquippedToolName1 == selectedToolName then
		toggleEquipToolByName(selectedToolName)
	elseif lastEquippedToolName2 == selectedToolName then
		toggleEquipToolByName(selectedToolName)
	else
		if not lastEquippedToolName1 or lastEquippedToolName1 == "" then
			lastEquippedToolName1 = selectedToolName
			updateToolVisual1(selectedToolName)
		elseif not lastEquippedToolName2 or lastEquippedToolName2 == "" then
			lastEquippedToolName2 = selectedToolName
			updateToolVisual2(selectedToolName)
		else
			lastEquippedToolName1 = selectedToolName
			updateToolVisual1(selectedToolName)
		end
		saveHotbarState()
		toggleEquipToolByName(selectedToolName)
	end
end

-- ===================================================================
-- LOGIC FUNCTIONS
-- ===================================================================

local function populateFishGrid()
	for _, child in ipairs(Inventory.FishContent:GetChildren()) do
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

	table.sort(allFishData, function(a, b)
		if a.isFavorited ~= b.isFavorited then return a.isFavorited end
		local rarityA = rarityOrder[a.rarity] or 0
		local rarityB = rarityOrder[b.rarity] or 0
		if rarityA ~= rarityB then return rarityA > rarityB end
		return a.weight > b.weight
	end)

	for _, fishData in ipairs(allFishData) do
		local card = Templates.Fish:Clone()
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
		setupFishViewport(fishViewport, fishData.name)

		local rarityColor = getRarityColor(fishData.rarity)
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
			playClickSound()
			local newStatus = rfToggleFavorite:InvokeServer(fishData.uniqueId)
			if newStatus ~= nil then
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
			playClickSound()
			local equippedFishId = fishData.uniqueId
			local targetFishId = nil

			if lastEquippedFishId1 == equippedFishId then
				targetFishId = equippedFishId
			elseif lastEquippedFishId2 == equippedFishId then
				targetFishId = equippedFishId
			else
				if not lastEquippedFishId1 then
					lastEquippedFishId1 = equippedFishId
					targetFishId = equippedFishId
					updateFishVisual1(equippedFishId)
				elseif not lastEquippedFishId2 then
					lastEquippedFishId2 = equippedFishId
					targetFishId = equippedFishId
					updateFishVisual2(equippedFishId)
				else
					lastEquippedFishId1 = equippedFishId
					targetFishId = equippedFishId
					updateFishVisual1(equippedFishId)
				end
				saveHotbarState()
			end

			if targetFishId then
				local char = player.Character
				local currentTool = char and char:FindFirstChildOfClass("Tool")
				if currentTool and currentTool:FindFirstChild("FishId") and currentTool.FishId.Value == targetFishId then
					reUnequipAll:FireServer()
				else
					reEquipFish:FireServer(targetFishId)
				end
			end
		end)

		card.Parent = Inventory.FishContent
	end

	updateFishCount()
end

local function populateRodGrid()
	for _, child in ipairs(Inventory.RodContent:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	local currentMultiplier = GlobalLuckVal and GlobalLuckVal.Value or 1

	table.sort(allRodData, function(a, b)
		local statsA = rodToolStats[a] and rodToolStats[a].Stats or FishingConfig.GetRodConfig(a)
		local statsB = rodToolStats[b] and rodToolStats[b].Stats or FishingConfig.GetRodConfig(b)
		local luckA = statsA.baseLuck or 0
		local luckB = statsB.baseLuck or 0
		return luckA > luckB
	end)

	for _, rodName in ipairs(allRodData) do
		local card = Templates.Rod:Clone()
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

		local cachedData = rodToolStats[rodName]
		local stats = cachedData and cachedData.Stats or FishingConfig.GetRodConfig(rodName)
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
		setupRodViewport(rodViewport, rodName)

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
			playClickSound()
			lastEquippedRodName = rodName
			saveHotbarState()
			updateRodVisual(rodName)
			reEquipRod:FireServer(rodName)
		end)

		card.Parent = Inventory.RodContent
	end
end

local function populateToolGrid()
	for _, child in ipairs(Inventory.ToolContent:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	local genericTools = {}
	local addedTools = {}

	local function isExcludedTool(toolName)
		for _, r in pairs(RoleConfig.Roles) do
			if r.AutoGrantTools and table.find(r.AutoGrantTools, toolName) then
				return true
			end
		end
		return false
	end

	local backpack = player:WaitForChild("Backpack")
	for _, tool in ipairs(backpack:GetChildren()) do
		if not tool:IsA("Tool") then continue end

		local isFish = tool:FindFirstChild("FishId")
		local isRod = CollectionService:HasTag(tool, "Rod")
		local isVIPTool = CollectionService:HasTag(tool, "VIPTool")
		local isRoleTool = isExcludedTool(tool.Name)

		if not isFish and not isRod and not isVIPTool and not isRoleTool and not addedTools[tool.Name] then
			table.insert(genericTools, tool)
			addedTools[tool.Name] = true
		end
	end

	for _, tool in ipairs(StarterPack:GetChildren()) do
		if not tool:IsA("Tool") then continue end

		local isFish = tool:FindFirstChild("FishId")
		local isRod = CollectionService:HasTag(tool, "Rod")
		local isVIPTool = CollectionService:HasTag(tool, "VIPTool")
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
		local card = Templates.Tool:Clone()
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
			setupToolViewport(toolViewport, tool.Name)
		end

		toolImage.MouseButton1Click:Connect(function()
			onAnyToolSelected(tool.Name)
		end)

		card.Parent = Inventory.ToolContent
	end
end

-- ===================================================================
-- VIP TOOLS POPULATION
-- ===================================================================
local function populateVIPToolGrid()
	if not isVIP then return end
	if not Inventory.VIPContent then return end
	if not Templates.VIPTool then
		warn("[CustomInventory] VIPToolTemplate not found!")
		return
	end

	for _, child in ipairs(Inventory.VIPContent:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	local vipTools = {}
	local addedTools = {}

	local success, vipToolsList = pcall(function()
		return rfGetVIPTools:InvokeServer()
	end)

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

	local backpack = player:WaitForChild("Backpack")
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and (CollectionService:HasTag(tool, "VIPTool") or RoleConfig.IsOwner(player) or RoleConfig.IsAdmin(player)) then
			if not addedTools[tool.Name] then
				table.insert(vipTools, {
					Name = tool.Name,
					TextureId = tool.TextureId
				})
				addedTools[tool.Name] = true
			end
		end
	end

	local char = player.Character
	if char then
		for _, tool in ipairs(char:GetChildren()) do
			if tool:IsA("Tool") and (CollectionService:HasTag(tool, "VIPTool") or RoleConfig.IsOwner(player) or RoleConfig.IsAdmin(player)) then
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
		local card = Templates.VIPTool:Clone()
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
			setupToolViewport(toolViewport, toolData.Name)
		end

		if vipBadge then
			if RoleConfig.IsOwner(player) then
				vipBadge.Text = "👑 OWNER"
				vipBadge.TextColor3 = Color3.fromRGB(255, 215, 0)
			elseif RoleConfig.IsAdmin(player) then
				vipBadge.Text = "🛡️ ADMIN"
				vipBadge.TextColor3 = Color3.fromRGB(255, 80, 80)
			else
				vipBadge.Text = "⭐ VIP"
				vipBadge.TextColor3 = Color3.fromRGB(255, 215, 0)
			end
		end

		toolImage.MouseButton1Click:Connect(function()
			onAnyToolSelected(toolData.Name)
		end)

		card.Parent = Inventory.VIPContent
	end
end

local isRefreshing = false

local function refreshAllData()
	if isRefreshing then return end
	isRefreshing = true

	local success, fullData = pcall(function()
		return rfGetData:InvokeServer()
	end)

	if not success or not fullData then
		isRefreshing = false
		return
	end

	allFishData = fullData.Fish or {}
	allRodData = fullData.Rods or {}

	if next(rodToolStats) == nil then
		local rodShopEvents = FishingSystem:FindFirstChild("RodShopEvents")
		if rodShopEvents then
			local rfGetShopData = rodShopEvents:FindFirstChild("GetShopData")
			if rfGetShopData then
				local success2, shopData = pcall(function()
					return rfGetShopData:InvokeServer()
				end)

				if success2 and shopData and shopData.AllRodData then
					for rodName, data in pairs(shopData.AllRodData) do
						rodToolStats[rodName] = {
							Stats = data.Stats,
							TextureId = data.TextureId
						}
					end
				end
			end
		end
	end

	validateHotbarItems()

	if currentTab == "Fish" then
		populateFishGrid()
	elseif currentTab == "Rods" then
		populateRodGrid()
	elseif currentTab == "Tools" then
		populateToolGrid()
	elseif currentTab == "VIP" and isVIP then
		populateVIPToolGrid()
	end

	updateFishCount()
	isRefreshing = false
end

switchTab = function(tabName)
	lastOpenedTab = tabName
	currentTab = tabName

	if Inventory.FishTabButton then Inventory.FishTabButton.BackgroundColor3 = Color3.fromRGB(49, 49, 49) end
	if Inventory.RodTabButton then Inventory.RodTabButton.BackgroundColor3 = Color3.fromRGB(49, 49, 49) end
	if Inventory.ToolTabButton then Inventory.ToolTabButton.BackgroundColor3 = Color3.fromRGB(49, 49, 49) end
	if Inventory.VIPTabButton then
		Inventory.VIPTabButton.BackgroundColor3 = Color3.fromRGB(49, 49, 49)
	end

	if Inventory.FishContent then Inventory.FishContent.Visible = false end
	if Inventory.RodContent then Inventory.RodContent.Visible = false end
	if Inventory.ToolContent then Inventory.ToolContent.Visible = false end
	if Inventory.VIPContent then
		Inventory.VIPContent.Visible = false
	end
	if Inventory.SellAllButton then Inventory.SellAllButton.Visible = false end

	if tabName == "Fish" and Inventory.FishTabButton and Inventory.FishContent then
		Inventory.FishTabButton.BackgroundColor3 = Color3.fromRGB(106, 106, 106)
		Inventory.FishContent.Visible = true
		if Inventory.SellAllButton then Inventory.SellAllButton.Visible = true end
		if Inventory.FishCountLabel then
			Inventory.FishCountLabel.Visible = true
		end
		populateFishGrid()
	elseif tabName == "Rods" and Inventory.RodTabButton and Inventory.RodContent then
		Inventory.RodTabButton.BackgroundColor3 = Color3.fromRGB(106, 106, 106)
		Inventory.RodContent.Visible = true
		if Inventory.FishCountLabel then
			Inventory.FishCountLabel.Visible = false
		end
		populateRodGrid()
	elseif tabName == "Tools" and Inventory.ToolTabButton and Inventory.ToolContent then
		Inventory.ToolTabButton.BackgroundColor3 = Color3.fromRGB(106, 106, 106)
		Inventory.ToolContent.Visible = true
		if Inventory.FishCountLabel then
			Inventory.FishCountLabel.Visible = false
		end
		populateToolGrid()
	elseif tabName == "VIP" and isVIP and Inventory.VIPTabButton and Inventory.VIPContent then
		Inventory.VIPTabButton.BackgroundColor3 = Color3.fromRGB(106, 106, 106)
		Inventory.VIPContent.Visible = true
		if Inventory.FishCountLabel then
			Inventory.FishCountLabel.Visible = false
		end
		populateVIPToolGrid()
	end
end

toggleInventory = function(visible)
	if visible == isInventoryOpen then return end

	isInventoryOpen = visible
	if Inventory.Frame then
		Inventory.Frame.Visible = visible
	end

	if visible then
		refreshAllData()
		switchTab(lastOpenedTab)
	end
end

local function onToolChanged(tool)
	if tool and tool:IsA("Tool") and (isRodName(tool.Name) or CollectionService:HasTag(tool, "Rod")) then
		lastEquippedRodName = tool.Name
		saveHotbarState()
		updateRodVisual(tool.Name)
		updateToolVisual1(lastEquippedToolName1)
		updateToolVisual2(lastEquippedToolName2)
		updateFishVisual1(lastEquippedFishId1)
		updateFishVisual2(lastEquippedFishId2)

	elseif tool and tool:IsA("Tool") and tool:FindFirstChild("FishId") then
		updateRodVisual(lastEquippedRodName)
		updateToolVisual1(lastEquippedToolName1)
		updateToolVisual2(lastEquippedToolName2)
		updateFishVisual1(lastEquippedFishId1)
		updateFishVisual2(lastEquippedFishId2)

	elseif tool and tool:IsA("Tool") then
		-- Strictly non-rod tool: NEVER put into slot 1!
		if lastEquippedToolName1 == tool.Name then
			-- already in slot 2
		elseif lastEquippedToolName2 == tool.Name then
			-- already in slot 3
		else
			if not lastEquippedToolName1 or lastEquippedToolName1 == "" then
				lastEquippedToolName1 = tool.Name
			elseif not lastEquippedToolName2 or lastEquippedToolName2 == "" then
				lastEquippedToolName2 = tool.Name
			else
				lastEquippedToolName1 = tool.Name
			end
		end
		saveHotbarState()
		updateRodVisual(lastEquippedRodName)
		updateToolVisual1(lastEquippedToolName1)
		updateToolVisual2(lastEquippedToolName2)
		updateFishVisual1(lastEquippedFishId1)
		updateFishVisual2(lastEquippedFishId2)

	else
		updateRodVisual(lastEquippedRodName)
		updateToolVisual1(lastEquippedToolName1)
		updateToolVisual2(lastEquippedToolName2)
		updateFishVisual1(lastEquippedFishId1)
		updateFishVisual2(lastEquippedFishId2)
	end
end

local function disableTooltip(tool)
	if tool and tool:IsA("Tool") then
		tool.ToolTip = " "
	end
end

-- ===================================================================
-- KEYBOARD SHORTCUTS (1-5 keys for hotbar, ~ / 4 for bag)
-- ===================================================================
local function handleKeyPress(input, gameProcessed)
	if gameProcessed then return end

	local keyCode = input.KeyCode

	-- Shortcut: Toggle Tas (Bag) via Backquote (~)
	if keyCode == Enum.KeyCode.Backquote or keyCode == Enum.KeyCode.Tilde then
		playClickSound()
		toggleInventory(not isInventoryOpen)
		return
	end

	if isInventoryOpen then return end

	-- Shortcut 1: Rod
	if keyCode == Enum.KeyCode.One then
		playClickSound()
		local char = player.Character
		local currentTool = char and char:FindFirstChildOfClass("Tool")

		if currentTool and CollectionService:HasTag(currentTool, "Rod") then
			reUnequipAll:FireServer()
		else
			if lastEquippedRodName then
				reEquipRod:FireServer(lastEquippedRodName)
			end
		end

	-- Shortcut 2: Tool 1 (biasa / admin)
	elseif keyCode == Enum.KeyCode.Two then
		if lastEquippedToolName1 and lastEquippedToolName1 ~= "" then
			playClickSound()
			toggleEquipToolByName(lastEquippedToolName1, isVIP and "VIP" or "Tools")
		end

	-- Shortcut 3: Tool 2 (biasa / admin)
	elseif keyCode == Enum.KeyCode.Three then
		if lastEquippedToolName2 and lastEquippedToolName2 ~= "" then
			playClickSound()
			toggleEquipToolByName(lastEquippedToolName2, isVIP and "VIP" or "Tools")
		end

	-- Shortcut 4: Fish 1 (Slot 4)
	elseif keyCode == Enum.KeyCode.Four then
		if lastEquippedFishId1 and Hotbar.FishSlot1 and Hotbar.FishSlot1.Visible then
			playClickSound()
			local char = player.Character
			local currentTool = char and char:FindFirstChildOfClass("Tool")

			if currentTool and currentTool:FindFirstChild("FishId") and currentTool.FishId.Value == lastEquippedFishId1 then
				reUnequipAll:FireServer()
			else
				reEquipFish:FireServer(lastEquippedFishId1)
			end
		end

	-- Shortcut 5: Fish 2 (Slot 5)
	elseif keyCode == Enum.KeyCode.Five then
		if lastEquippedFishId2 and Hotbar.FishSlot2 and Hotbar.FishSlot2.Visible then
			playClickSound()
			local char = player.Character
			local currentTool = char and char:FindFirstChildOfClass("Tool")

			if currentTool and currentTool:FindFirstChild("FishId") and currentTool.FishId.Value == lastEquippedFishId2 then
				reUnequipAll:FireServer()
			else
				reEquipFish:FireServer(lastEquippedFishId2)
			end
		end
	end
end

-- ===================================================================
-- BUTTON EVENT SETUP
-- ===================================================================

local buttonConnections = {}

local function setupButtonEvents()
	for _, conn in ipairs(buttonConnections) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(buttonConnections)

	-- Slot 4: BagButton
	if Hotbar.BagButton then
		table.insert(buttonConnections, Hotbar.BagButton.MouseButton1Click:Connect(function()
			playClickSound()
			toggleInventory(not isInventoryOpen)
		end))
	end

	-- Slot 1: RodSlot
	if Hotbar.RodSlot then
		table.insert(buttonConnections, Hotbar.RodSlot.MouseButton1Click:Connect(function()
			playClickSound()

			if isInventoryOpen then
				if lastEquippedRodName then
					reUnequipAll:FireServer()
					lastEquippedRodName = nil
					updateRodVisual(nil)
					saveHotbarState()
				end
				return
			end

			local char = player.Character
			local currentTool = char and char:FindFirstChildOfClass("Tool")

			if currentTool and CollectionService:HasTag(currentTool, "Rod") then
				reUnequipAll:FireServer()
			else
				if lastEquippedRodName then
					local hasRod = false
					for _, rodName in ipairs(allRodData) do
						if rodName == lastEquippedRodName then
							hasRod = true
							break
						end
					end

					if hasRod then
						reEquipRod:FireServer(lastEquippedRodName)
					else
						lastEquippedRodName = nil
						updateRodVisual(nil)
						saveHotbarState()
					end
				end
			end
		end))
	end

	-- Slot 2: ToolSlot1
	if Hotbar.ToolSlot1 then
		table.insert(buttonConnections, Hotbar.ToolSlot1.MouseButton1Click:Connect(function()
			playClickSound()
			toggleEquipToolByName(lastEquippedToolName1, isVIP and "VIP" or "Tools")
		end))
	end

	-- Slot 3: ToolSlot2
	if Hotbar.ToolSlot2 then
		table.insert(buttonConnections, Hotbar.ToolSlot2.MouseButton1Click:Connect(function()
			playClickSound()
			toggleEquipToolByName(lastEquippedToolName2, isVIP and "VIP" or "Tools")
		end))
	end

	-- Slot 4: FishSlot1
	if Hotbar.FishSlot1 then
		table.insert(buttonConnections, Hotbar.FishSlot1.MouseButton1Click:Connect(function()
			playClickSound()

			if isInventoryOpen then
				if lastEquippedFishId1 then
					reUnequipAll:FireServer()
					lastEquippedFishId1 = nil
					updateFishVisual1(nil)
					saveHotbarState()
				end
				return
			end

			local char = player.Character
			local currentTool = char and char:FindFirstChildOfClass("Tool")

			if currentTool and currentTool:FindFirstChild("FishId") and currentTool.FishId.Value == lastEquippedFishId1 then
				reUnequipAll:FireServer()
			else
				if lastEquippedFishId1 then
					reEquipFish:FireServer(lastEquippedFishId1)
				end
			end
		end))
	end

	-- Slot 5: FishSlot2
	if Hotbar.FishSlot2 then
		table.insert(buttonConnections, Hotbar.FishSlot2.MouseButton1Click:Connect(function()
			playClickSound()

			if isInventoryOpen then
				if lastEquippedFishId2 then
					reUnequipAll:FireServer()
					lastEquippedFishId2 = nil
					updateFishVisual2(nil)
					saveHotbarState()
				end
				return
			end

			local char = player.Character
			local currentTool = char and char:FindFirstChildOfClass("Tool")

			if currentTool and currentTool:FindFirstChild("FishId") and currentTool.FishId.Value == lastEquippedFishId2 then
				reUnequipAll:FireServer()
			else
				if lastEquippedFishId2 then
					reEquipFish:FireServer(lastEquippedFishId2)
				end
			end
		end))
	end

	-- Inventory Buttons
	if Inventory.CloseButton then
		local lastCloseClick = 0
		local function onCloseClick()
			if os.clock() - lastCloseClick < 0.2 then return end
			lastCloseClick = os.clock()
			playClickSound()
			toggleInventory(false)
		end
		table.insert(buttonConnections, Inventory.CloseButton.MouseButton1Click:Connect(onCloseClick))
		table.insert(buttonConnections, Inventory.CloseButton.Activated:Connect(onCloseClick))
	end

	if Inventory.FishTabButton then
		table.insert(buttonConnections, Inventory.FishTabButton.MouseButton1Click:Connect(function()
			playClickSound()
			switchTab("Fish")
		end))
	end

	if Inventory.RodTabButton then
		table.insert(buttonConnections, Inventory.RodTabButton.MouseButton1Click:Connect(function()
			playClickSound()
			switchTab("Rods")
		end))
	end

	if Inventory.ToolTabButton then
		table.insert(buttonConnections, Inventory.ToolTabButton.MouseButton1Click:Connect(function()
			playClickSound()
			switchTab("Tools")
		end))
	end

	if Inventory.VIPTabButton then
		local lastVipClick = 0
		local function onVipClick()
			if os.clock() - lastVipClick < 0.2 then return end
			lastVipClick = os.clock()
			playClickSound()
			switchTab("VIP")
		end
		table.insert(buttonConnections, Inventory.VIPTabButton.MouseButton1Click:Connect(onVipClick))
	end

	if Inventory.SellAllButton then
		table.insert(buttonConnections, Inventory.SellAllButton.MouseButton1Click:Connect(function()
			playClickSound()

			if not hasRemoteSellPermission() then
				local fishingSys = ReplicatedStorage:FindFirstChild("FishingSystem")
				local cn = fishingSys and fishingSys:FindFirstChild("ClientNotification")
				if cn and cn:IsA("BindableEvent") then
					cn:Fire("Perk required! Purchase Remote Sell in the Exclusive Shop.", 3.5, Color3.fromRGB(255, 100, 100))
				end
				return
			end

			local success, soldCount, earnedCoins = rfSellAll:InvokeServer()
			if success then
				lastEquippedFishId1 = nil
				lastEquippedFishId2 = nil
				updateFishVisual1(nil)
				updateFishVisual2(nil)
				saveHotbarState()

				refreshAllData()

				local fishingSys = ReplicatedStorage:FindFirstChild("FishingSystem")
				local cn = fishingSys and fishingSys:FindFirstChild("ClientNotification")
				if cn and cn:IsA("BindableEvent") then
					if (soldCount or 0) > 0 then
						cn:Fire(string.format("Successfully sold %d fish! +%d Coins", soldCount, earnedCoins or 0), 3.5, Color3.fromRGB(100, 255, 140))
					else
						cn:Fire("You have no fish to sell!", 3, Color3.fromRGB(255, 180, 50))
					end
				end
			end
		end))
	end
end

-- ===================================================================
-- CHARACTER SETUP
-- ===================================================================

local function setupCharacter(character)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

	local guiSuccess = updateGUIReferences()
	if not guiSuccess then
		task.wait(1)
		guiSuccess = updateGUIReferences()
		if not guiSuccess then
			return
		end
	end

	checkVIPStatus()
	setupButtonEvents()

	for _, conn in ipairs(connections) do
		if conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(connections)

	if Hotbar.Frame then
		Hotbar.Frame.Visible = true
	end

	if Hotbar.BagButton then Hotbar.BagButton.Active = true end
	if Hotbar.RodSlot then Hotbar.RodSlot.Active = true end
	if Hotbar.ToolSlot1 then Hotbar.ToolSlot1.Active = true end
	if Hotbar.ToolSlot2 then Hotbar.ToolSlot2.Active = true end
	if Hotbar.FishSlot1 then Hotbar.FishSlot1.Active = true end
	if Hotbar.FishSlot2 then Hotbar.FishSlot2.Active = true end

	local backpack = player:WaitForChild("Backpack")

	task.wait(0.5)

	task.spawn(function()
		local success, fullData = pcall(function()
			return rfGetData:InvokeServer()
		end)

		if success and fullData then
			allFishData = fullData.Fish or {}
			allRodData = fullData.Rods or {}

			local isFirstLoad = not HotbarState.rod and not HotbarState.tool1 and not HotbarState.tool2 and not HotbarState.fish1 and not HotbarState.fish2

			if not isFirstLoad then
				restoreHotbarState()
			else
				if fullData.LastRod then
					lastEquippedRodName = fullData.LastRod
					HotbarState.rod = fullData.LastRod
				elseif table.find(allRodData, "Basic Rod") or (backpack and backpack:FindFirstChild("Basic Rod")) then
					lastEquippedRodName = "Basic Rod"
					HotbarState.rod = "Basic Rod"
				elseif #allRodData > 0 then
					lastEquippedRodName = allRodData[1]
					HotbarState.rod = allRodData[1]
				end
			end

			autoFillHotbarSlots()

			updateRodVisual(lastEquippedRodName)
			updateToolVisual1(lastEquippedToolName1)
			updateToolVisual2(lastEquippedToolName2)
			updateFishVisual1(lastEquippedFishId1)
			updateFishVisual2(lastEquippedFishId2)

			saveHotbarState()
			updateFishCount()
		end
	end)

	table.insert(connections, backpack.ChildAdded:Connect(function(child)
		disableTooltip(child)
		if child:IsA("Tool") and not CollectionService:HasTag(child, "Rod") and not child:FindFirstChild("FishId") then
			if not lastEquippedToolName1 or not lastEquippedToolName2 then
				autoFillHotbarSlots()
			end
		end
	end))

	table.insert(connections, backpack.ChildRemoved:Connect(function(child)
		if not child:IsA("Tool") then return end

		task.wait(0.1)

		local isFish = child:FindFirstChild("FishId")
		local isRod = CollectionService:HasTag(child, "Rod")

		local stillExists = player.Backpack:FindFirstChild(child.Name) or
			(player.Character and player.Character:FindFirstChild(child.Name))

		if stillExists then
			return
		end

		if isRod and child.Name == lastEquippedRodName then
			local rodStillOwned = false
			for _, rodName in ipairs(allRodData) do
				if rodName == lastEquippedRodName then
					rodStillOwned = true
					break
				end
			end
			if not rodStillOwned then
				lastEquippedRodName = nil
				updateRodVisual(nil)
				saveHotbarState()
			end
		elseif child.Name == lastEquippedToolName1 then
			lastEquippedToolName1 = nil
			updateToolVisual1(nil)
			saveHotbarState()
		elseif child.Name == lastEquippedToolName2 then
			lastEquippedToolName2 = nil
			updateToolVisual2(nil)
			saveHotbarState()
		elseif isFish and child:FindFirstChild("FishId") and child.FishId.Value == lastEquippedFishId1 then
			local fishStillExists = false
			for _, fish in ipairs(allFishData) do
				if fish.uniqueId == lastEquippedFishId1 then
					fishStillExists = true
					break
				end
			end
			if not fishStillExists then
				lastEquippedFishId1 = nil
				updateFishVisual1(nil)
				saveHotbarState()
			end
		elseif isFish and child:FindFirstChild("FishId") and child.FishId.Value == lastEquippedFishId2 then
			local fishStillExists = false
			for _, fish in ipairs(allFishData) do
				if fish.uniqueId == lastEquippedFishId2 then
					fishStillExists = true
					break
				end
			end
			if not fishStillExists then
				lastEquippedFishId2 = nil
				updateFishVisual2(nil)
				saveHotbarState()
			end
		end
	end))

	table.insert(connections, character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			disableTooltip(child)
			onToolChanged(child)
		end
	end))

	table.insert(connections, character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			onToolChanged(nil)
		end
	end))
end

-- ===================================================================
-- INITIALIZATION
-- ===================================================================

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

task.spawn(function()
	while true do
		task.wait(1)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end
end)

UserInputService.InputBegan:Connect(handleKeyPress)

if player.Character then
	setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)

if GlobalLuckVal then
	GlobalLuckVal.Changed:Connect(function()
		if isInventoryOpen and currentTab == "Rods" then
			populateRodGrid()
		end
	end)
end

local function connectReplicationEvents()
	local eventsFolder = ReplicatedStorage:WaitForChild("FishingEvents", 5)
	if eventsFolder then
		local onFishCaught = eventsFolder:FindFirstChild("FishCaught")
		if onFishCaught then
			onFishCaught.OnClientEvent:Connect(function(fishData)
				refreshAllData()
			end)
		end
	end
end

task.spawn(connectReplicationEvents)
