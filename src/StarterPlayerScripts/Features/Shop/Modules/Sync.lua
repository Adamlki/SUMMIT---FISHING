local Module = {}

function Module.Install(Controller)
-- ===================================================================
-- DATA SYNC ENGINE
-- ===================================================================
function Controller:RefreshTrailData()
	local ok, res = self.NetworkGateway:Request("GET", "/trail/data"):await()
	if not ok or type(res) ~= "table" or not res.Success then return end
	local trailData = res.Data or {}
	self.ownedTrails = trailData.Owned or trailData.owned or {}
	self.equippedTrail = trailData.Equipped or trailData.equipped or ""
	self:RenderTrailsCatalog()
end

function Controller:RefreshData()
	task.spawn(function()
		local okShop, resShop = self.NetworkGateway:Request("GET", "/shop/rods"):await()
		local shopData = (okShop and type(resShop) == "table" and resShop.Success and resShop.Data) or nil
		if shopData then
			self.ownedRods = shopData.OwnedRods or {}
			self.equippedRod = shopData.EquippedRod or "Basic Rod"
			self.playerCoins = shopData.Coins or 0
			self:RenderRodsCatalogImmediate()
		end

		self:RefreshTrailData()
		self:ApplyExclusiveMasterConfig()
	end)
end

function Controller:ConnectSyncEvents()
	self.NetworkGateway:On("Trail/Updated", function(data)
		if type(data) == "table" and type(data.TrailId) == "string" then
			self.equippedTrail = data.TrailId
			self:RenderTrailsCatalog()
		end
		task.spawn(function()
			self:RefreshTrailData()
		end)
	end)

	self.rePurchaseSuccess.OnClientEvent:Connect(function()
		self:PlaySound(self.SOUNDS.Purchase, 0.45)
		self:RefreshData()
	end)

	self.TrailUpdatedRE.OnClientEvent:Connect(function(data)
		if data.owned then self.ownedTrails = data.owned end
		if data.equipped ~= nil then self.equippedTrail = data.equipped end
		self:RenderTrailsCatalog()
	end)
end

function Controller:WireNpcPrompt()
	task.spawn(function()
		local npc = workspace:WaitForChild("RodShop", 25)
		if npc then
			local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				prompt.Triggered:Connect(function()
					self:OpenShop("Rods")
				end)
			end
		end
	end)
end

function Controller:WirePurchaseRefresh()
	self.MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
		if player == self.localPlayer and wasPurchased then
			task.wait(0.5)
			self:RefreshData()
		end
	end)

	self.MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, prodId, wasPurchased)
		if userId == self.localPlayer.UserId and wasPurchased then
			task.wait(0.5)
			self:RefreshData()
		end
	end)
end
end

return Module
