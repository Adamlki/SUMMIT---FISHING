local RoleConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("RoleConfig"))
--!strict
-- ShopFeatureController: Master Store Controller
-- Sourced directly from ShopMasterConfig for Zero-Maintenance Code-Based Updates.
-- Features:
-- 1. 3D ViewportFrames for all Rods (Real 3D models with camera & lighting, like Fish Index)
-- 2. Rods Ownership: Once purchased, status becomes permanent 'OWNED' (rods managed via backpack)
-- 3. VIP Rod: Free/Owned with VIP Pack, or 'VIP ONLY' button linking to VIP Gamepass
-- 4. Trails: Dual toggle 'EQUIP' / 'EQUIPPED' with real WalkSpeed stacking & torso welding
-- 5. Smooth Animated ButtonHeader Selection (BackgroundTransparency 0 vs 1 via TweenService)
-- 6. Universal Tactile Button Animations (Hover Scale 1.04 + Click Squash/Bounce with Sound)
-- 7. Exclusive Server Luck Stacking & Auto-Reset
-- 8. Player Gifting Modal

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local MarketplaceService = game:GetService("MarketplaceService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Configurations
local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem", 15)
local TrailSystem = ReplicatedStorage:WaitForChild("TrailSystem", 15)
local rodAssets = FishingSystem:WaitForChild("Assets"):WaitForChild("Rod")

local MasterConfig = require(FishingSystem:WaitForChild("ShopMasterConfig"))
local TrailShopConfig = require(TrailSystem:WaitForChild("TrailShopConfig"))

-- Remotes
local RodShopEvents = FishingSystem:WaitForChild("RodShopEvents")
local rfGetShopData = RodShopEvents:WaitForChild("GetShopData") :: RemoteFunction
local reRequestPurchase = RodShopEvents:WaitForChild("RequestPurchase") :: RemoteEvent
local rePurchaseSuccess = RodShopEvents:WaitForChild("PurchaseSuccess") :: RemoteEvent
local rfEquipRod = RodShopEvents:WaitForChild("EquipRod") :: RemoteFunction
local rfBuyServerLuck = RodShopEvents:WaitForChild("BuyServerLuck") :: RemoteFunction
local rfBuyCoinPack = RodShopEvents:WaitForChild("BuyCoinPack") :: RemoteFunction
local rfRequestGift = RodShopEvents:WaitForChild("RequestGift") :: RemoteFunction

local TrailRemotes = TrailSystem:WaitForChild("Remotes")
local GetTrailDataRF = TrailRemotes:WaitForChild("GetTrailData") :: RemoteFunction
local BuyTrailWithCoinsRF = TrailRemotes:WaitForChild("BuyTrailWithCoins") :: RemoteFunction
local BuyTrailWithRobuxRF = TrailRemotes:WaitForChild("BuyTrailWithRobux") :: RemoteFunction
local EquipTrailRF = TrailRemotes:WaitForChild("EquipTrail") :: RemoteFunction
local UnequipTrailRF = TrailRemotes:WaitForChild("UnequipTrail") :: RemoteFunction
local TrailUpdatedRE = TrailRemotes:WaitForChild("TrailUpdated") :: RemoteEvent

-- Values for Live Server Luck
local ServerLuckPurchases = FishingSystem:WaitForChild("ServerLuckPurchases") :: IntValue
local LuckBoostTimer = FishingSystem:WaitForChild("LuckBoostTimer") :: IntValue
local GlobalLuckMultiplier = FishingSystem:WaitForChild("GlobalLuckMultiplier") :: NumberValue

-- ===================================================================
-- SOUND ENGINE
-- ===================================================================
local SOUNDS = {
	Click = "rbxassetid://340910329",
	Hover = "rbxassetid://5852311399",
	Purchase = "rbxassetid://4525871712",
	Equip = "rbxassetid://6895079853",
}

local function playSound(soundId: string, volume: number?)
	task.spawn(function()
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = volume or 0.35
		sound.Parent = SoundService
		sound:Play()
		sound.Ended:Connect(function() sound:Destroy() end)
	end)
end

-- ===================================================================
-- RESOLVE UI REFERENCES
-- ===================================================================
local gameUI = playerGui:WaitForChild("GameUI", 30)
if not gameUI then return end

local menus = gameUI:WaitForChild("Menus", 20)
local shopFeature = menus:WaitForChild("ShopFeature", 20) :: Frame
if not shopFeature then return end

local closeBtn = shopFeature:WaitForChild("CloseButton") :: ImageButton
local btnHeader = shopFeature:WaitForChild("ButtonHeader") :: Frame

local rodsTabBtn = (btnHeader:FindFirstChild("RodsButoon") or btnHeader:FindFirstChild("RodsButton")) :: ImageButton
local exclusiveTabBtn = (btnHeader:FindFirstChild("ExclusiveButoon") or btnHeader:FindFirstChild("ExclusiveButton")) :: ImageButton
local trailsTabBtn = (btnHeader:FindFirstChild("TrailsButoon") or btnHeader:FindFirstChild("TrailsButton")) :: ImageButton

local exclusiveTab = shopFeature:WaitForChild("Exclusive") :: ScrollingFrame
local rodsTab = shopFeature:WaitForChild("Rods") :: ScrollingFrame
local trailsTab = shopFeature:WaitForChild("Trails") :: ScrollingFrame
local rodTemplate = rodsTab:WaitForChild("Template") :: Frame
rodTemplate.Visible = false

local modal = shopFeature:WaitForChild("PlayerSelectionModal") :: Frame
local modalHeader = modal:WaitForChild("Header") :: Frame
local modalTitle = modalHeader:WaitForChild("Title") :: TextLabel
local modalSubtitle = modalHeader:WaitForChild("Subtitle") :: TextLabel
local modalCloseBtn = modalHeader:WaitForChild("CloseButton") :: TextButton
local modalContainer = modal:WaitForChild("Container") :: ScrollingFrame
local modalTemplate = modalContainer:WaitForChild("Template") :: Frame
modalTemplate.Visible = false

local buttonsFolder = gameUI:WaitForChild("Component"):WaitForChild("Buttons")
local leftHolder = buttonsFolder:WaitForChild("LeftHolder")
local shopToolbarBtn = leftHolder:FindFirstChild("Shop") :: GuiButton?

-- ===================================================================
-- UNIVERSAL TACTILE BUTTON ANIMATOR
-- ===================================================================
local TWEEN_HOVER = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SQUASH = TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_BOUNCE = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local boundButtons: { [GuiButton]: boolean } = {}

local function attachTactileEffect(btn: GuiButton)
	if boundButtons[btn] then return end
	boundButtons[btn] = true

	local scale = btn:FindFirstChild("ButtonScale") :: UIScale?
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "ButtonScale"
		scale.Parent = btn
	end

	btn.MouseEnter:Connect(function()
		TweenService:Create(scale, TWEEN_HOVER, { Scale = 1.04 }):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(scale, TWEEN_HOVER, { Scale = 1.0 }):Play()
	end)

	btn.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TWEEN_SQUASH, { Scale = 0.93 }):Play()
	end)

	btn.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TWEEN_BOUNCE, { Scale = 1.0 }):Play()
	end)
end

local function applyTactileEffectsToContainer(container: Instance)
	for _, desc in ipairs(container:GetDescendants()) do
		if desc:IsA("GuiButton") then
			attachTactileEffect(desc)
		end
	end
	container.DescendantAdded:Connect(function(desc)
		if desc:IsA("GuiButton") then
			attachTactileEffect(desc)
		end
	end)
end

applyTactileEffectsToContainer(shopFeature)
applyTactileEffectsToContainer(modal)

-- ===================================================================
-- STATE MANAGEMENT & NUMBER FORMATTING
-- ===================================================================
local currentTab = "Exclusive"
local ownedRods: { string } = {}
local equippedRod: string = "Basic Rod"
local playerCoins: number = 0

local ownedTrails: { string } = {}
local equippedTrail: string = ""

local rodCardInstances: { [string]: Frame } = {}

local function formatK(num: number): string
	if num >= 1000000 then
		local m = num / 1000000
		return string.format(m % 1 == 0 and "%.0fM" or "%.1fM", m)
	elseif num >= 1000 then
		local k = num / 1000
		return string.format(k % 1 == 0 and "%.0fK" or "%.1fK", k)
	else
		return tostring(math.floor(num))
	end
end

-- ===================================================================
-- 3D ROD VIEWPORT FRAME ENGINE (Real 3D Models like Fish Index)
-- ===================================================================
local function setupViewportForRod(vp: ViewportFrame, rodName: string)
	vp:ClearAllChildren()
	local targetName = rodName
	if targetName == "Vip Rod" or targetName == "Royal Rod" then
		targetName = "Dragon Spine"
	end
	local tool = rodAssets:FindFirstChild(targetName)
	if not tool then
		warn("[ShopFeatureController] Rod asset not found for 3D Viewport: " .. tostring(rodName))
		return
	end

	local model = Instance.new("Model")
	model.Name = "RodDisplayModel"

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

	model.Parent = vp

	local cam = Instance.new("Camera")
	cam.FieldOfView = 50
	cam.Parent = vp
	vp.CurrentCamera = cam

	vp.Ambient = Color3.fromRGB(220, 220, 235)
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	vp.LightDirection = Vector3.new(-1, -1, -1)

	local cf, size = model:GetBoundingBox()
	local maxDim = math.max(size.X, size.Y, size.Z)
	local dist = (maxDim / 2) / math.tan(math.rad(cam.FieldOfView / 2)) * 1.15

	-- Dynamic diagonal angle displaying handle and tip cleanly
	local camPos = cf.Position + Vector3.new(dist * 0.42, dist * 0.18, dist * 0.9)
	cam.CFrame = CFrame.lookAt(camPos, cf.Position)
end

-- ===================================================================
-- BUTTONHEADER SMOOTH ANIMATED SELECTION
-- BackgroundTransparency = 0 (Selected) vs 1 (Unselected)
-- ===================================================================
local TWEEN_HEADER_TRANS = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function updateHeaderButtonVisuals(activeTabName: string)
	local tabs = {
		{ Btn = exclusiveTabBtn, Name = "Exclusive" },
		{ Btn = rodsTabBtn, Name = "Rods" },
		{ Btn = trailsTabBtn, Name = "Trails" },
	}

	for _, t in ipairs(tabs) do
		if t.Btn then
			local isSelected = (t.Name == activeTabName)
			local targetTrans = isSelected and 0 or 1
			TweenService:Create(t.Btn, TWEEN_HEADER_TRANS, {
				BackgroundTransparency = targetTrans
			}):Play()
		end
	end
end

-- ===================================================================
-- 1. EXCLUSIVE TAB ENGINE
-- ===================================================================
local function updateServerLuckFrame()
	local slFrame = exclusiveTab:FindFirstChild("ServerLuckFrame")
	if not slFrame then return end

	local count = ServerLuckPurchases.Value
	local cfg = MasterConfig.Exclusive.ServerLuck
	local maxCount = cfg.MaxPurchases or 5
	local isMax = count >= maxCount

	local frameSub = slFrame:FindFirstChild("Frame")
	local valueLabel = frameSub and frameSub:FindFirstChild("ValueLabel") :: TextLabel?
	local descLabel = frameSub and frameSub:FindFirstChild("DescLabel") :: TextLabel?

	local buyBtn = slFrame:FindFirstChild("BuyButton") :: ImageButton?
	local btnInner = buyBtn and buyBtn:FindFirstChild("Frame")
	local robuxIcon = btnInner and btnInner:FindFirstChildOfClass("ImageLabel")
	local btnValLabel = btnInner and btnInner:FindFirstChild("ValueLabel") :: TextLabel?

	if isMax then
		if valueLabel then valueLabel.Text = "X960 (MAX)" end
		if btnValLabel then btnValLabel.Text = "MAX" end
		if robuxIcon then robuxIcon.Visible = false end
	else
		local nextTier = cfg.Tiers[count + 1] or cfg.Tiers[1]

		if valueLabel then valueLabel.Text = nextTier.Display or "X30 > X60" end
		if btnValLabel then btnValLabel.Text = tostring(nextTier.RobuxPrice or 50) end
		if robuxIcon then robuxIcon.Visible = true end
	end

	if descLabel then
		if LuckBoostTimer.Value > 0 then
			local mins = math.floor(LuckBoostTimer.Value / 60)
			local secs = LuckBoostTimer.Value % 60
			descLabel.Text = string.format("Boost Aktif! Sisa Waktu: %02d:%02d", mins, secs)
		else
			descLabel.Text = "Tingkatkan Luck memancing untuk semua pemain di server!"
		end
	end
end

ServerLuckPurchases.Changed:Connect(updateServerLuckFrame)
LuckBoostTimer.Changed:Connect(updateServerLuckFrame)

local function checkPlayerOwnsPass(passId: number, attrName: string): boolean
	if RoleConfig.IsOwner(localPlayer) then return true end
	if localPlayer:GetAttribute(attrName) == true then return true end
	if passId > 0 then
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(localPlayer.UserId, passId)
		end)
		if ok and owns then
			localPlayer:SetAttribute(attrName, true)
			return true
		end
	end
	return false
end

local function applyExclusiveMasterConfig()
	local listLuck = exclusiveTab:FindFirstChild("ListLuckFrame")
	if listLuck then
		for key, info in pairs(MasterConfig.Exclusive.LuckPasses) do
			local f = listLuck:FindFirstChild(info.FrameName)
			if f then
				local textLabels = {}
				for _, ch in ipairs(f:GetChildren()) do
					if ch:IsA("TextLabel") then table.insert(textLabels, ch) end
				end
				if textLabels[1] then textLabels[1].Text = info.Title end
				if textLabels[2] then textLabels[2].Text = info.Subtitle end

				local bb = f:FindFirstChild("BuyButton") :: ImageButton?
				local bInner = bb and bb:FindFirstChild("Frame")
				local rIcon = bInner and bInner:FindFirstChildOfClass("ImageLabel")
				local vLabel = bInner and bInner:FindFirstChild("ValueLabel") :: TextLabel?

				local owns = checkPlayerOwnsPass(info.PassId, key)
				if owns then
					if rIcon then rIcon.Visible = false end
					if vLabel then vLabel.Text = "OWNED" end
				else
					if rIcon then rIcon.Visible = true end
					if vLabel then vLabel.Text = tostring(info.RobuxPrice) end
				end
			end
		end
	end

	-- RemoteSellFrame
	local rsf = exclusiveTab:FindFirstChild("RemoteSellFrame")
	if rsf then
		local cfg = MasterConfig.Exclusive.RemoteSell
		local bb = rsf:FindFirstChild("BuyButton") :: ImageButton?
		local bInner = bb and bb:FindFirstChild("Frame")
		local rIcon = bInner and bInner:FindFirstChildOfClass("ImageLabel")
		local vLabel = bInner and bInner:FindFirstChild("ValueLabel") :: TextLabel?

		local owns = checkPlayerOwnsPass(cfg.PassId, "HasRemoteSell") or (localPlayer:GetAttribute("RemoteSell") == true)
		if owns then
			if rIcon then rIcon.Visible = false end
			if vLabel then vLabel.Text = "OWNED" end
		else
			if rIcon then rIcon.Visible = true end
			if vLabel then vLabel.Text = tostring(cfg.RobuxPrice) end
		end
	end

	-- ListCoinFrame
	local listCoin = exclusiveTab:FindFirstChild("ListCoinFrame")
	if listCoin then
		for _, info in pairs(MasterConfig.Exclusive.CoinPacks) do
			local f = listCoin:FindFirstChild(info.FrameName)
			if f then
				local tc = f:FindFirstChild("TotalCoin") :: TextLabel?
				local bb = f:FindFirstChild("BuyButton") :: ImageButton?
				local bInner = bb and bb:FindFirstChild("Frame")
				local vl = bInner and bInner:FindFirstChild("ValueLabel") :: TextLabel?

				if tc then tc.Text = info.Display end
				if vl then vl.Text = tostring(info.RobuxPrice) end
			end
		end
	end

	-- VIPPackFrame
	local vipFrame = exclusiveTab:FindFirstChild("VIPPackFrame")
	if vipFrame then
		local cfg = MasterConfig.Exclusive.VIP
		local bb = vipFrame:FindFirstChild("BuyButton") :: ImageButton?
		local bInner = bb and bb:FindFirstChild("Frame")
		local rIcon = bInner and bInner:FindFirstChildOfClass("ImageLabel")
		local vLabel = bInner and bInner:FindFirstChild("ValueLabel") :: TextLabel?

		-- Update text label to Gold Rod
		for _, ch in ipairs(vipFrame:GetChildren()) do
			if ch:IsA("TextLabel") and (ch.Text == "Rod" or ch.Text == "Gold Rod") then
				ch.Text = "Gold Rod"
				ch.Size = UDim2.new(0, 65, 0, 18)
				ch.Position = UDim2.new(0.02, 0, 0.342166, 0)
				ch.TextXAlignment = Enum.TextXAlignment.Center
				break
			end
		end

		local rewardRodImg = vipFrame:FindFirstChild("RewardRodImage") :: ImageLabel?
		if rewardRodImg then
			rewardRodImg.Image = ""
			local existingVP = rewardRodImg:FindFirstChild("GoldRod3DViewport") :: ViewportFrame?
			if not existingVP then
				existingVP = Instance.new("ViewportFrame")
				existingVP.Name = "GoldRod3DViewport"
				existingVP.Size = UDim2.new(1, 0, 1, 0)
				existingVP.BackgroundTransparency = 1
				existingVP.ZIndex = rewardRodImg.ZIndex + 1
				existingVP.Parent = rewardRodImg
				setupViewportForRod(existingVP, "Gold Rod")
			end
		end

		local owns = checkPlayerOwnsPass(cfg.PassId, "VIP") or checkPlayerOwnsPass(1590939529, "VIP") or (localPlayer:GetAttribute("IsVIP") == true)
		if owns then
			if rIcon then rIcon.Visible = false end
			if vLabel then vLabel.Text = "OWNED" end
		else
			if rIcon then rIcon.Visible = true end
			if vLabel then vLabel.Text = tostring(cfg.RobuxPrice) end
		end
	end

	updateServerLuckFrame()
end

-- ===================================================================
-- MODAL GIFTING LOGIC
-- ===================================================================
local currentGiftCategory = ""
local currentGiftId = ""

local function openPlayerModal(category: string, itemId: string, itemTitle: string)
	currentGiftCategory = category
	currentGiftId = itemId

	modalTitle.Text = "KIRIM HADIAH"
	modalSubtitle.Text = "Pilih pemain di server untuk menerima: " .. itemTitle
	modal.Visible = true

	for _, child in ipairs(modalContainer:GetChildren()) do
		if child:IsA("Frame") and child ~= modalTemplate then
			child:Destroy()
		end
	end

	local serverPlayers = Players:GetPlayers()
	local count = 0

	for _, p in ipairs(serverPlayers) do
		if p ~= localPlayer then
			count += 1
			local item = modalTemplate:Clone()
			item.Name = "Player_" .. tostring(p.UserId)
			item.Visible = true
			item.Parent = modalContainer

			local dn = item:FindFirstChild("DisplayName") :: TextLabel?
			local un = item:FindFirstChild("Username") :: TextLabel?
			local av = item:FindFirstChild("Avatar") :: ImageLabel?
			local giftBtn = item:FindFirstChild("GiftActionBtn") :: TextButton?

			if dn then dn.Text = p.DisplayName end
			if un then un.Text = "@" .. p.Name end

			if av then
				task.spawn(function()
					local thumb, isReady = Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
					if av and av.Parent then av.Image = thumb end
				end)
			end

			if giftBtn then
				giftBtn.MouseButton1Click:Connect(function()
					modal.Visible = false
					rfRequestGift:InvokeServer(currentGiftCategory, currentGiftId, p.UserId)
				end)
			end
		end
	end

	if count == 0 then
		local notice = Instance.new("TextLabel")
		notice.Name = "EmptyNotice"
		notice.Size = UDim2.new(1, 0, 0, 50)
		notice.BackgroundTransparency = 1
		notice.Font = Enum.Font.FredokaOne
		notice.TextSize = 14
		notice.TextColor3 = Color3.fromRGB(180, 190, 210)
		notice.Text = "Tidak ada pemain lain di server saat ini."
		notice.Parent = modalContainer
	end
end

modalCloseBtn.MouseButton1Click:Connect(function()
	modal.Visible = false
end)

local function hookExclusiveButtons()
	local slFrame = exclusiveTab:FindFirstChild("ServerLuckFrame")
	local slBuy = slFrame and slFrame:FindFirstChild("BuyButton") :: ImageButton?
	if slBuy then
		slBuy.MouseButton1Click:Connect(function()
			if ServerLuckPurchases.Value >= 5 then return end
			rfBuyServerLuck:InvokeServer()
		end)
	end

	local listLuck = exclusiveTab:FindFirstChild("ListLuckFrame")
	if listLuck then
		for key, info in pairs(MasterConfig.Exclusive.LuckPasses) do
			local f = listLuck:FindFirstChild(info.FrameName)
			if f then
				local bb = f:FindFirstChild("BuyButton") :: ImageButton?
				local gb = f:FindFirstChild("GiftButton") :: ImageButton?
				if bb then
					bb.MouseButton1Click:Connect(function()
						if checkPlayerOwnsPass(info.PassId, key) then return end
						MarketplaceService:PromptGamePassPurchase(localPlayer, info.PassId)
					end)
				end
				if gb then
					gb.MouseButton1Click:Connect(function()
						openPlayerModal("Gamepass", key, info.Title)
					end)
				end
			end
		end
	end

	local rsf = exclusiveTab:FindFirstChild("RemoteSellFrame")
	if rsf then
		local cfg = MasterConfig.Exclusive.RemoteSell
		local bb = rsf:FindFirstChild("BuyButton") :: ImageButton?
		local gb = rsf:FindFirstChild("GiftButton") :: ImageButton?
		if bb then
			bb.MouseButton1Click:Connect(function()
				if checkPlayerOwnsPass(cfg.PassId, "HasRemoteSell") then return end
				MarketplaceService:PromptGamePassPurchase(localPlayer, cfg.PassId)
			end)
		end
		if gb then
			gb.MouseButton1Click:Connect(function()
				openPlayerModal("Gamepass", "RemoteSell", cfg.Title)
			end)
		end
	end

	local listCoin = exclusiveTab:FindFirstChild("ListCoinFrame")
	if listCoin then
		for key, info in pairs(MasterConfig.Exclusive.CoinPacks) do
			local f = listCoin:FindFirstChild(info.FrameName)
			if f then
				local bb = f:FindFirstChild("BuyButton") :: ImageButton?
				local gb = f:FindFirstChild("GiftButton") :: ImageButton?
				if bb then
					bb.MouseButton1Click:Connect(function()
						rfBuyCoinPack:InvokeServer(key)
					end)
				end
				if gb then
					gb.MouseButton1Click:Connect(function()
						openPlayerModal("Coin", key, info.Title)
					end)
				end
			end
		end
	end

	local vipFrame = exclusiveTab:FindFirstChild("VIPPackFrame")
	if vipFrame then
		local cfg = MasterConfig.Exclusive.VIP
		local bb = vipFrame:FindFirstChild("BuyButton") :: ImageButton?
		local gb = vipFrame:FindFirstChild("GiftButton") :: ImageButton?
		if bb then
			bb.MouseButton1Click:Connect(function()
				if checkPlayerOwnsPass(cfg.PassId, "VIP") then return end
				MarketplaceService:PromptGamePassPurchase(localPlayer, cfg.PassId)
			end)
		end
		if gb then
			gb.MouseButton1Click:Connect(function()
				openPlayerModal("Gamepass", "VIP", cfg.Title)
			end)
		end
	end
end

-- ===================================================================
-- 2. RODS TAB ENGINE (3D ViewportFrames & 'OWNED' Status)
-- ===================================================================
local function renderRodsCatalogImmediate()
	local isOwner = RoleConfig.IsOwner(localPlayer)
	local hasVIP = isOwner or (localPlayer:GetAttribute("VIP") == true) or (localPlayer:GetAttribute("IsVIP") == true) or checkPlayerOwnsPass(1874479701, "VIP") or checkPlayerOwnsPass(1590939529, "VIP")

	-- Destroy any stale or orphan rod frames that are not in MasterConfig.Rods (e.g. obsolete Rod_Vip Rod)
	local validRodNames = {}
	for _, rod in ipairs(MasterConfig.Rods) do
		validRodNames[rod.Name] = true
	end
	for _, child in ipairs(rodsTab:GetChildren()) do
		if child:IsA("GuiObject") and string.sub(child.Name, 1, 4) == "Rod_" then
			local rName = string.sub(child.Name, 5)
			if not validRodNames[rName] then
				child:Destroy()
			end
		end
	end

	for idx, rod in ipairs(MasterConfig.Rods) do
		local card = rodCardInstances[rod.Name] or rodsTab:FindFirstChild("Rod_" .. rod.Name) :: Frame?

		if not card then
			card = rodTemplate:Clone()
			card.Name = "Rod_" .. rod.Name
			card.Parent = rodsTab
			attachTactileEffect(card:FindFirstChild("Frame"):FindFirstChild("BuyCoinButton") :: GuiButton)
			attachTactileEffect(card:FindFirstChild("Frame"):FindFirstChild("BuyRobuxButton") :: GuiButton)
		end
		card.Visible = true
		card.LayoutOrder = idx
		rodCardInstances[rod.Name] = card

		-- Setup 3D ViewportFrame
		local oldImg = card:FindFirstChild("RodImage")
		if oldImg then oldImg.Visible = false end

		local vp = card:FindFirstChild("RodViewport") :: ViewportFrame?
		if not vp then
			vp = Instance.new("ViewportFrame")
			vp.Name = "RodViewport"
			vp.Size = UDim2.new(0, 155, 0, 300)
			vp.Position = UDim2.new(0.0411764719, 0, 0.0934343413, 0)
			vp.BackgroundTransparency = 1
			vp.ZIndex = 2
			vp.Parent = card
			setupViewportForRod(vp, rod.Name)
		elseif not vp:FindFirstChild("RodDisplayModel") then
			setupViewportForRod(vp, rod.Name)
		end

		-- Set InfoTopFrame (Name & Tier)
		local top = card:FindFirstChild("InfoTopFrame")
		if top then
			local nl = top:FindFirstChild("NameLabel") :: TextLabel?
			local tl = top:FindFirstChild("TierLabel") :: TextLabel?
			if nl then nl.Text = rod.Name end
			if tl then
				tl.Text = rod.Tier
				tl.BackgroundColor3 = rod.TierColor
			end
		end

		-- Set InfoBottomFrame (Stats)
		local btm = card:FindFirstChild("InfoBottomFrame")
		if btm then
			local luck = btm:FindFirstChild("LuckLabel") :: TextLabel?
			local speed = btm:FindFirstChild("SpeedLabel") :: TextLabel?
			local weight = btm:FindFirstChild("WeightLabel") :: TextLabel?
			if luck then luck.Text = "Luck: " .. tostring(rod.LuckPercent) .. "%" end
			if speed then speed.Text = "Speed: " .. tostring(rod.SpeedPercent) .. "%" end
			if weight then weight.Text = "Weight: " .. formatK(rod.MaxWeightKg) .. " kg" end
		end

		-- Set Button State: Once purchased, status is 'OWNED' (items used via backpack)
		local bf = card:FindFirstChild("Frame")
		if bf then
			local coinBtn = bf:FindFirstChild("BuyCoinButton") :: ImageButton?
			local robuxBtn = bf:FindFirstChild("BuyRobuxButton") :: ImageButton?
			local coinVal = coinBtn and coinBtn:FindFirstChild("ValueLabel") :: TextLabel?
			local robuxVal = robuxBtn and robuxBtn:FindFirstChild("Frame") and robuxBtn.Frame:FindFirstChild("ValueLabel") :: TextLabel?

			-- Check if owned in player profile or backpack or VIP
			local isOwned = isOwner or table.find(ownedRods, rod.Name) ~= nil or (rod.Type == "VIP" and hasVIP)

			if isOwned then
				if robuxBtn then robuxBtn.Visible = false end
				if coinBtn then
					coinBtn.Visible = true
					if coinVal then coinVal.Text = "OWNED" end
					coinBtn.BackgroundColor3 = Color3.fromRGB(75, 80, 90)
				end
			else
				if rod.Type == "VIP" then
					-- VIP exclusive rod
					if robuxBtn then robuxBtn.Visible = false end
					if coinBtn then
						coinBtn.Visible = true
						if coinVal then coinVal.Text = "VIP ONLY" end
						coinBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 40)
					end
				else
					if coinBtn then
						coinBtn.Visible = true
						if coinVal then coinVal.Text = rod.CoinPrice > 0 and formatK(rod.CoinPrice) or "FREE" end
						coinBtn.BackgroundColor3 = Color3.fromRGB(240, 150, 40)
					end
					if robuxBtn then
						robuxBtn.Visible = (rod.RobuxPrice and rod.RobuxPrice > 0)
						if robuxVal then robuxVal.Text = tostring(rod.RobuxPrice or 0) end
					end
				end
			end

			-- Bind Click Actions
			if coinBtn and not coinBtn:GetAttribute("BoundClick") then
				coinBtn:SetAttribute("BoundClick", true)
				coinBtn.MouseButton1Click:Connect(function()
					local currentOwned = table.find(ownedRods, rod.Name) ~= nil or (rod.Type == "VIP" and hasVIP)
					if currentOwned then
						-- Already owned! Handled in backpack
						return
					end

					if rod.Type == "VIP" then
						-- Prompt VIP gamepass
						MarketplaceService:PromptGamePassPurchase(localPlayer, 1874479701)
						return
					end

					reRequestPurchase:FireServer(rod.Name)
				end)
			end

			if robuxBtn and not robuxBtn:GetAttribute("BoundClick") then
				robuxBtn:SetAttribute("BoundClick", true)
				robuxBtn.MouseButton1Click:Connect(function()
					local currentOwned = table.find(ownedRods, rod.Name) ~= nil
					if currentOwned then return end

					if rod.Type == "Gamepass" and rod.GamePassId and rod.GamePassId > 0 then
						MarketplaceService:PromptGamePassPurchase(localPlayer, rod.GamePassId)
					elseif rod.ProductId and rod.ProductId > 0 then
						MarketplaceService:PromptProductPurchase(localPlayer, rod.ProductId)
					else
						reRequestPurchase:FireServer(rod.Name)
					end
				end)
			end
		end
	end
end

-- ===================================================================
-- 3. TRAILS TAB ENGINE (Retains 'EQUIP' / 'EQUIPPED' Swap System)
-- ===================================================================
local function renderTrailsCatalog()
	for _, trail in ipairs(MasterConfig.Trails) do
		local f = trailsTab:FindFirstChild(trail.FrameName)
		if f then
			local sf = f:FindFirstChild("SpeedFrame")
			local sl = sf and sf:FindFirstChildOfClass("TextLabel")
			if sl then sl.Text = string.format("Speed +%.1f%%", trail.SpeedBonus) end

			local top = f:FindFirstChild("InfoTopFrame")
			local nl = top and top:FindFirstChild("NameLabel") :: TextLabel?
			local tl = top and top:FindFirstChild("TierLabel") :: TextLabel?
			if nl then nl.Text = trail.Name end
			if tl then
				tl.Text = trail.Tier
				tl.BackgroundColor3 = trail.TierColor
			end

			local isOwned = table.find(ownedTrails, trail.Id) ~= nil
			local isEquipped = (equippedTrail == trail.Id)

			local btnFrame = f:FindFirstChild("Frame")
			local coinBtn = btnFrame and btnFrame:FindFirstChild("BuyCoinButton") :: ImageButton?
			local robuxBtn = btnFrame and btnFrame:FindFirstChild("BuyRobuxButton") :: ImageButton?
			local coinVal = coinBtn and coinBtn:FindFirstChild("ValueLabel") :: TextLabel?
			local robuxVal = robuxBtn and robuxBtn:FindFirstChild("Frame") and robuxBtn.Frame:FindFirstChild("ValueLabel") :: TextLabel?

			if isOwned then
				if robuxBtn then robuxBtn.Visible = false end
				if coinBtn then
					coinBtn.Visible = true
					if isEquipped then
						if coinVal then coinVal.Text = "EQUIPPED" end
						coinBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
					else
						if coinVal then coinVal.Text = "EQUIP" end
						coinBtn.BackgroundColor3 = Color3.fromRGB(45, 140, 255)
					end
				end
			else
				if coinBtn then
					coinBtn.Visible = true
					if coinVal then coinVal.Text = formatK(trail.CoinPrice) end
					coinBtn.BackgroundColor3 = Color3.fromRGB(240, 150, 40)
				end
				if robuxBtn then
					robuxBtn.Visible = true
					if robuxVal then robuxVal.Text = tostring(trail.RobuxPrice) end
				end
			end

			-- Bind Trail Click Actions
			if coinBtn and not coinBtn:GetAttribute("BoundClick") then
				coinBtn:SetAttribute("BoundClick", true)
				coinBtn.MouseButton1Click:Connect(function()
					local currentOwned = table.find(ownedTrails, trail.Id) ~= nil
					local currentEquipped = (equippedTrail == trail.Id)

					if currentOwned then
						if currentEquipped then
							UnequipTrailRF:InvokeServer()
							equippedTrail = ""
							renderTrailsCatalog()
						else
							EquipTrailRF:InvokeServer(trail.Id)
							equippedTrail = trail.Id
							playSound(SOUNDS.Equip, 0.4)
							renderTrailsCatalog()
						end
					else
						local res = BuyTrailWithCoinsRF:InvokeServer(trail.Id)
						if res and res.success then
							table.insert(ownedTrails, trail.Id)
							equippedTrail = trail.Id
							playSound(SOUNDS.Purchase, 0.45)
							renderTrailsCatalog()
						end
					end
				end)
			end

			if robuxBtn and not robuxBtn:GetAttribute("BoundClick") then
				robuxBtn:SetAttribute("BoundClick", true)
				robuxBtn.MouseButton1Click:Connect(function()
					local currentOwned = table.find(ownedTrails, trail.Id) ~= nil
					if currentOwned then return end
					local res = BuyTrailWithRobuxRF:InvokeServer(trail.Id)
					if res and res.success then
						table.insert(ownedTrails, trail.Id)
						equippedTrail = trail.Id
						playSound(SOUNDS.Purchase, 0.45)
						renderTrailsCatalog()
					end
				end)
			end
		end
	end
end

-- ===================================================================
-- DATA SYNC ENGINE
-- ===================================================================
local function refreshData()
	task.spawn(function()
		local shopData = rfGetShopData:InvokeServer()
		if shopData then
			ownedRods = shopData.OwnedRods or {}
			equippedRod = shopData.EquippedRod or "Basic Rod"
			playerCoins = shopData.Coins or 0
			renderRodsCatalogImmediate()
		end

		local trailData = GetTrailDataRF:InvokeServer()
		if trailData then
			ownedTrails = trailData.owned or {}
			equippedTrail = trailData.equipped or ""
			renderTrailsCatalog()
		end

		applyExclusiveMasterConfig()
	end)
end

rePurchaseSuccess.OnClientEvent:Connect(function()
	playSound(SOUNDS.Purchase, 0.45)
	refreshData()
end)

TrailUpdatedRE.OnClientEvent:Connect(function(data)
	if data.owned then ownedTrails = data.owned end
	if data.equipped ~= nil then equippedTrail = data.equipped end
	renderTrailsCatalog()
end)

-- ===================================================================
-- TAB NAVIGATION ENGINE
-- ===================================================================
local function switchTab(tabName: string)
	currentTab = tabName
	updateHeaderButtonVisuals(tabName)

	exclusiveTab.Visible = (tabName == "Exclusive")
	rodsTab.Visible = (tabName == "Rods")
	trailsTab.Visible = (tabName == "Trails")

	if tabName == "Exclusive" then
		applyExclusiveMasterConfig()
	elseif tabName == "Rods" then
		renderRodsCatalogImmediate()
	elseif tabName == "Trails" then
		renderTrailsCatalog()
	end
end

if rodsTabBtn then
	rodsTabBtn.MouseButton1Click:Connect(function() switchTab("Rods") end)
end
if exclusiveTabBtn then
	exclusiveTabBtn.MouseButton1Click:Connect(function() switchTab("Exclusive") end)
end
if trailsTabBtn then
	trailsTabBtn.MouseButton1Click:Connect(function() switchTab("Trails") end)
end

-- ===================================================================
-- WINDOW VISIBILITY & ANIMATION CONTROLS (Top-to-Bottom Smooth Easing)
-- ===================================================================
local SHOP_SHOWN_POS = UDim2.new(0.5, 0, 0.5, 0)
local SHOP_HIDDEN_POS = UDim2.new(0.5, 0, -0.6, 0)
local shopTween: Tween? = nil
local shopTweenId = 0

local function openShop(initialTab: string?)
	shopTweenId += 1
	local curId = shopTweenId
	if shopTween then
		shopTween:Cancel()
		shopTween = nil
	end

	shopFeature.AnchorPoint = Vector2.new(0.5, 0.5)
	shopFeature.Position = SHOP_HIDDEN_POS
	shopFeature.Visible = true
	shopFeature:SetAttribute("IsOpen", true)
	modal.Visible = false
	switchTab(initialTab or currentTab or "Exclusive")
	refreshData()

	shopTween = TweenService:Create(
		shopFeature,
		TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = SHOP_SHOWN_POS }
	)
	shopTween.Completed:Connect(function()
		if curId == shopTweenId then
			shopTween = nil
		end
	end)
	shopTween:Play()
end

local function closeShop()
	shopTweenId += 1
	local curId = shopTweenId
	if shopTween then
		shopTween:Cancel()
		shopTween = nil
	end

	shopFeature:SetAttribute("IsOpen", false)
	modal.Visible = false

	shopTween = TweenService:Create(
		shopFeature,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = SHOP_HIDDEN_POS }
	)
	shopTween.Completed:Connect(function()
		if curId == shopTweenId then
			shopFeature.Visible = false
			shopTween = nil
		end
	end)
	shopTween:Play()
end

closeBtn.MouseButton1Click:Connect(closeShop)

shopFeature:GetAttributeChangedSignal("IsOpen"):Connect(function()
	local isOpen = shopFeature:GetAttribute("IsOpen") == true
	if not isOpen and shopFeature.Visible and (not shopTween or shopFeature.Position == SHOP_SHOWN_POS) then
		closeShop()
	end
end)

if shopToolbarBtn then
	shopToolbarBtn.MouseButton1Click:Connect(function()
		if shopFeature:GetAttribute("IsOpen") == true then
			closeShop()
		else
			openShop("Exclusive")
		end
	end)
end

-- Connect Workspace NPC ProximityPrompt
task.spawn(function()
	local npc = workspace:WaitForChild("RodShop", 25)
	if npc then
		local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt then
			prompt.Triggered:Connect(function()
				openShop("Rods")
			end)
		end
	end
end)

-- Auto-refresh on purchases
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if player == localPlayer and wasPurchased then
		task.wait(0.5)
		refreshData()
	end
end)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, prodId, wasPurchased)
	if userId == localPlayer.UserId and wasPurchased then
		task.wait(0.5)
		refreshData()
	end
end)

-- Initial Startup & Pre-render
hookExclusiveButtons()
applyExclusiveMasterConfig()
renderRodsCatalogImmediate()
renderTrailsCatalog()
switchTab("Exclusive")
refreshData()
shopFeature.AnchorPoint = Vector2.new(0.5, 0.5)
shopFeature.Position = SHOP_HIDDEN_POS
shopFeature.Visible = false
shopFeature:SetAttribute("IsOpen", false)

print("✅ [ShopFeatureController] 3D Rod Viewports, Backpack Rod Ownership, and VIP Rod integration active!")
