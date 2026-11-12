local Module = {}
local MonetizationConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Configs"):WaitForChild("MonetizationConfig"))

function Module.Install(Controller)
-- ===================================================================
-- SERVER LUCK & GAMEPASS OWNERSHIP
-- ===================================================================
function Controller:UpdateServerLuckFrame()
	local exclusiveTab = self.exclusiveTab
	local slFrame = exclusiveTab:FindFirstChild("ServerLuckFrame")
	if not slFrame then return end

	local count = self.ServerLuckPurchases.Value
	local cfg = self.MasterConfig.Exclusive.ServerLuck
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
		if self.LuckBoostTimer.Value > 0 then
			local mins = math.floor(self.LuckBoostTimer.Value / 60)
			local secs = self.LuckBoostTimer.Value % 60
			descLabel.Text = string.format("Boost Aktif! Sisa Waktu: %02d:%02d", mins, secs)
		else
			descLabel.Text = "Tingkatkan Luck memancing untuk semua pemain di server!"
		end
	end
end

function Controller:WireLuckSignals()
	self.ServerLuckPurchases.Changed:Connect(function()
		self:UpdateServerLuckFrame()
	end)
	self.LuckBoostTimer.Changed:Connect(function()
		self:UpdateServerLuckFrame()
	end)
end

function Controller:CheckPlayerOwnsPass(passId: number, attrName: string): boolean
	local localPlayer = self.localPlayer
	if self.RoleConfig.IsOwner(localPlayer) then return true end
	if localPlayer:GetAttribute(attrName) == true then return true end
	if passId > 0 then
		local ok, owns = pcall(function()
			return self.MarketplaceService:UserOwnsGamePassAsync(localPlayer.UserId, passId)
		end)
		if ok and owns then
			localPlayer:SetAttribute(attrName, true)
			return true
		end
	end
	return false
end

function Controller:ApplyExclusiveMasterConfig()
	local exclusiveTab = self.exclusiveTab
	local MasterConfig = self.MasterConfig
	local localPlayer = self.localPlayer

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

				local owns = self:CheckPlayerOwnsPass(info.PassId, key)
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

		local owns = self:CheckPlayerOwnsPass(cfg.PassId, "HasRemoteSell") or (localPlayer:GetAttribute("RemoteSell") == true)
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
				self:SetupViewportForRod(existingVP, "Gold Rod")
			end
		end

		local owns = self:CheckPlayerOwnsPass(cfg.PassId, "VIP") or self:CheckPlayerOwnsPass(MonetizationConfig.VIP.LegacyGamePassId, "VIP") or (localPlayer:GetAttribute("IsVIP") == true)
		if owns then
			if rIcon then rIcon.Visible = false end
			if vLabel then vLabel.Text = "OWNED" end
		else
			if rIcon then rIcon.Visible = true end
			if vLabel then vLabel.Text = tostring(cfg.RobuxPrice) end
		end
	end

	self:UpdateServerLuckFrame()
end
end

return Module
