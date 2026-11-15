local Module = {}
local MonetizationConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Configs"):WaitForChild("MonetizationConfig"))
local RewardPopup = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("UI"):WaitForChild("RewardPopup"))
local UIEffects = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("UI"):WaitForChild("UIEffects"))

function Module.Install(Controller)
function Controller:FormatK(num: number): string
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
function Controller:SetupViewportForRod(vp: ViewportFrame, rodName: string)
	vp:ClearAllChildren()
	local targetName = rodName
	if targetName == "Vip Rod" or targetName == "Royal Rod" then
		targetName = "Dragon Spine"
	end
	local tool = self.rodAssets:FindFirstChild(targetName)
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
-- 2. RODS TAB ENGINE (3D ViewportFrames & 'OWNED' Status)
-- ===================================================================
function Controller:RenderRodsCatalogImmediate()
	local MasterConfig = self.MasterConfig
	local rodsTab = self.rodsTab
	local localPlayer = self.localPlayer
	local isOwner = self.RoleConfig.IsOwner(localPlayer)
	local hasVIP = isOwner or (localPlayer:GetAttribute("VIP") == true) or (localPlayer:GetAttribute("IsVIP") == true) or self:CheckPlayerOwnsPass(MonetizationConfig.VIP.GamePassId, "VIP") or self:CheckPlayerOwnsPass(MonetizationConfig.VIP.LegacyGamePassId, "VIP")

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
		local card = self.rodCardInstances[rod.Name] or rodsTab:FindFirstChild("Rod_" .. rod.Name) :: Frame?

		if not card then
			card = self.rodTemplate:Clone()
			card.Name = "Rod_" .. rod.Name
			card.Parent = rodsTab
			self:AttachTactileEffect(card:FindFirstChild("Frame"):FindFirstChild("BuyCoinButton") :: GuiButton)
			self:AttachTactileEffect(card:FindFirstChild("Frame"):FindFirstChild("BuyRobuxButton") :: GuiButton)
		end
		card.Visible = true
		card.LayoutOrder = idx
		self.rodCardInstances[rod.Name] = card

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
			self:SetupViewportForRod(vp, rod.Name)
		elseif not vp:FindFirstChild("RodDisplayModel") then
			self:SetupViewportForRod(vp, rod.Name)
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
			if weight then weight.Text = "Weight: " .. self:FormatK(rod.MaxWeightKg) .. " kg" end
		end

		-- Set Button State: Once purchased, status is 'OWNED' (items used via backpack)
		local bf = card:FindFirstChild("Frame")
		if bf then
			local coinBtn = bf:FindFirstChild("BuyCoinButton") :: ImageButton?
			local robuxBtn = bf:FindFirstChild("BuyRobuxButton") :: ImageButton?
			local coinVal = coinBtn and coinBtn:FindFirstChild("ValueLabel") :: TextLabel?
			local robuxVal = robuxBtn and robuxBtn:FindFirstChild("Frame") and robuxBtn.Frame:FindFirstChild("ValueLabel") :: TextLabel?

			-- Check if owned in player profile or backpack or VIP
			local isOwned = isOwner or table.find(self.ownedRods, rod.Name) ~= nil or (rod.Type == "VIP" and hasVIP)

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
						if coinVal then coinVal.Text = rod.CoinPrice > 0 and self:FormatK(rod.CoinPrice) or "FREE" end
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
					local currentOwned = table.find(self.ownedRods, rod.Name) ~= nil or (rod.Type == "VIP" and hasVIP)
					if currentOwned then
						-- Already owned! Handled in backpack
						return
					end

					if rod.Type == "VIP" then
						-- Prompt VIP gamepass
						self.MarketplaceService:PromptGamePassPurchase(localPlayer, MonetizationConfig.VIP.GamePassId)
						return
					end

					self.NetworkGateway:Request("POST", "/shop/buy-rod", { RodName = rod.Name }):andThen(function(res)
						if res.Success then
							self:RefreshData()
						else
							UIEffects.warning(coinBtn, res.Message or "NOT ENOUGH COINS!")
						end
					end)
				end)
			end

			if robuxBtn and not robuxBtn:GetAttribute("BoundClick") then
				robuxBtn:SetAttribute("BoundClick", true)
				robuxBtn.MouseButton1Click:Connect(function()
					local currentOwned = table.find(self.ownedRods, rod.Name) ~= nil
					if currentOwned then return end

					if rod.Type == "Gamepass" and rod.GamePassId and rod.GamePassId > 0 then
						self.MarketplaceService:PromptGamePassPurchase(localPlayer, rod.GamePassId)
					elseif rod.ProductId and rod.ProductId > 0 then
						self.MarketplaceService:PromptProductPurchase(localPlayer, rod.ProductId)
					else
						self.NetworkGateway:Request("POST", "/shop/buy-rod", { RodName = rod.Name })
					end
				end)
			end
		end
	end
end

-- ===================================================================
-- 3. TRAILS TAB ENGINE (Retains 'EQUIP' / 'EQUIPPED' Swap System)
-- ===================================================================
function Controller:RenderTrailsCatalog()
	local trailsTab = self.trailsTab
	for _, trail in ipairs(self.MasterConfig.Trails) do
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

			local isOwned = table.find(self.ownedTrails, trail.Id) ~= nil
			local isEquipped = (self.equippedTrail == trail.Id)

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
					if coinVal then coinVal.Text = self:FormatK(trail.CoinPrice) end
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
					local currentOwned = table.find(self.ownedTrails, trail.Id) ~= nil
					local currentEquipped = (self.equippedTrail == trail.Id)

					if currentOwned then
						if currentEquipped then
							self.NetworkGateway:Request("DELETE", "/trail/unequip", {})
							self.equippedTrail = ""
							self:RenderTrailsCatalog()
						else
							self.NetworkGateway:Request("PUT", "/trail/equip", { TrailId = trail.Id })
							self.equippedTrail = trail.Id
							self:PlaySound(self.SOUNDS.Equip, 0.4)
							self:RenderTrailsCatalog()
						end
					else
						local ok, res = self.NetworkGateway:Request("POST", "/trail/buy-coins", { TrailId = trail.Id }):await()
						if ok and type(res) == "table" and res.Success then
							local data = res.Data
							if data and type(data.Owned) == "table" then
								self.ownedTrails = data.Owned
							elseif not table.find(self.ownedTrails, trail.Id) then
								table.insert(self.ownedTrails, trail.Id)
							end
							self.equippedTrail = (data and data.Equipped) or trail.Id
							self:PlaySound(self.SOUNDS.Purchase, 0.45)
							RewardPopup.show({ Title = "PURCHASED!", ItemName = trail.Name })
							self:RenderTrailsCatalog()
						else
							UIEffects.warning(coinBtn, type(res) == "table" and res.Message or "NOT ENOUGH COINS!")
						end
					end
				end)
			end

			if robuxBtn and not robuxBtn:GetAttribute("BoundClick") then
				robuxBtn:SetAttribute("BoundClick", true)
				robuxBtn.MouseButton1Click:Connect(function()
					local currentOwned = table.find(self.ownedTrails, trail.Id) ~= nil
					if currentOwned then return end
					local ok, response = self.NetworkGateway:Request("POST", "/trail/buy-robux", { TrailId = trail.Id }):await()
					local res = ok and type(response) == "table" and response.Data or nil
					if res and res.success then
						if not table.find(self.ownedTrails, trail.Id) then
							table.insert(self.ownedTrails, trail.Id)
						end
						self.equippedTrail = trail.Id
						self:PlaySound(self.SOUNDS.Purchase, 0.45)
						RewardPopup.show({ Title = "PURCHASED!", ItemName = trail.Name })
						self:RenderTrailsCatalog()
					end
				end)
			end
		end
	end
end

-- ===================================================================
-- EXCLUSIVE TAB BUTTON WIRING
-- ===================================================================
function Controller:HookExclusiveButtons()
	local exclusiveTab = self.exclusiveTab
	local MasterConfig = self.MasterConfig
	local localPlayer = self.localPlayer

	local slFrame = exclusiveTab:FindFirstChild("ServerLuckFrame")
	local slBuy = slFrame and slFrame:FindFirstChild("BuyButton") :: ImageButton?
	if slBuy then
		slBuy.MouseButton1Click:Connect(function()
			if self.ServerLuckPurchases.Value >= 5 then return end
			self.NetworkGateway:Request("POST", "/shop/buy-server-luck", {})
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
						if self:CheckPlayerOwnsPass(info.PassId, key) then return end
						self.MarketplaceService:PromptGamePassPurchase(localPlayer, info.PassId)
					end)
				end
				if gb then
					gb.MouseButton1Click:Connect(function()
						self:OpenPlayerModal("Gamepass", key, info.Title)
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
				if self:CheckPlayerOwnsPass(cfg.PassId, "HasRemoteSell") then return end
				self.MarketplaceService:PromptGamePassPurchase(localPlayer, cfg.PassId)
			end)
		end
		if gb then
			gb.MouseButton1Click:Connect(function()
				self:OpenPlayerModal("Gamepass", "RemoteSell", cfg.Title)
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
						self.NetworkGateway:Request("POST", "/shop/buy-coin-pack", { PackName = key })
					end)
				end
				if gb then
					gb.MouseButton1Click:Connect(function()
						self:OpenPlayerModal("Coin", key, info.Title)
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
				if self:CheckPlayerOwnsPass(cfg.PassId, "VIP") then return end
				self.MarketplaceService:PromptGamePassPurchase(localPlayer, cfg.PassId)
			end)
		end
		if gb then
			gb.MouseButton1Click:Connect(function()
				self:OpenPlayerModal("Gamepass", "VIP", cfg.Title)
			end)
		end
	end
end
end

return Module
