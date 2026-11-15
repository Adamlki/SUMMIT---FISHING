--!strict
-- UnifiedPurchaseGateway: Single Authoritative MarketplaceService.ProcessReceipt Pipeline
-- Routes all Developer Products in the game through ONE single channel:
-- 1. Server Luck Boost (Fishing System, stacking multiplier & accumulating duration)
-- 2. VIP Gifting (SummitKit VipService)
-- 3. Shop Tool Purchases & Gifting (SummitKit ShopService)
-- 4. Robux Donations (SummitKit DonationsService)

local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreConfig = require(ServerScriptService:WaitForChild("Configs"):WaitForChild("DataStoreConfig"))

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local StoreConfig = require(FishingSystem:WaitForChild("ExclusiveStoreConfig"))
local ServerLuckManager = require(ServerScriptService:WaitForChild("FishingServerScripts"):WaitForChild("ServerLuckManager"))

local TrailSystem = ReplicatedStorage:WaitForChild("TrailSystem", 10)
local TrailShopConfig = nil
pcall(function()
	if TrailSystem then
		TrailShopConfig = require(TrailSystem:WaitForChild("TrailShopConfig", 5))
	end
end)
local GameProfileService = require(ServerScriptService:WaitForChild("Data"):WaitForChild("PetCore"):WaitForChild("FishData"))

local Knit = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Knit"))

local receiptStore = nil
pcall(function()
	receiptStore = DataStoreService:GetDataStore(DataStoreConfig.Stores.PurchaseReceiptLog)
end)

local receiptCache = {}
local RECEIPT_RETENTION_SECONDS = 60 * 60 * 24 * 90

local function getReceiptLog(userId)
	if receiptCache[userId] then return receiptCache[userId] end
	if not receiptStore then return nil end

	local attempts = DataStoreConfig.Retry and DataStoreConfig.Retry.MaxAttempts or 3
	local backoff = DataStoreConfig.Retry and DataStoreConfig.Retry.BackoffSeconds or 0.5

	for attempt = 1, attempts do
		local ok, res = pcall(function()
			return receiptStore:GetAsync("Receipts_" .. tostring(userId))
		end)
		if ok then
			local log = (type(res) == "table") and res or {}
			receiptCache[userId] = log
			return log
		end
		if attempt < attempts then
			task.wait(backoff * attempt)
		end
	end

	warn("[UnifiedPurchaseGateway] Failed to load receipt log for " .. tostring(userId))
	return nil
end

local function saveReceiptLog(userId, log)
	if not receiptStore then return false end
	local snapshot = {}
	for id, ts in pairs(log) do snapshot[id] = ts end
	local attempts = DataStoreConfig.Retry and DataStoreConfig.Retry.MaxAttempts or 3
	local backoff = DataStoreConfig.Retry and DataStoreConfig.Retry.BackoffSeconds or 0.5

	for attempt = 1, attempts do
		local ok = pcall(function()
			receiptStore:UpdateAsync("Receipts_" .. tostring(userId), function(old)
				old = (type(old) == "table") and old or {}
				for id, ts in pairs(snapshot) do old[id] = ts end
				return old
			end)
		end)
		if ok then return true end
		if attempt < attempts then
			task.wait(backoff * attempt)
		end
	end

	warn("[UnifiedPurchaseGateway] Failed to save receipt log for " .. tostring(userId))
	return false
end

local function recordReceipt(userId, purchaseId)
	local log = getReceiptLog(userId)
	if not log then return false end
	log[tostring(purchaseId)] = os.time()
	local now = os.time()
	local kept = 0
	for id, ts in pairs(log) do
		if type(ts) ~= "number" or (now - ts) > RECEIPT_RETENTION_SECONDS then
			log[id] = nil
		else
			kept = kept + 1
		end
	end
	if kept > 1000 then
		local oldestId, oldestTs = nil, nil
		for id, ts in pairs(log) do
			if not oldestTs or ts < oldestTs then oldestId, oldestTs = id, ts end
		end
		if oldestId then log[oldestId] = nil end
	end
	return saveReceiptLog(userId, log)
end

Players.PlayerRemoving:Connect(function(player)
	receiptCache[player.UserId] = nil
end)

local handlerFunction = function(receiptInfo: { PlayerId: number, ProductId: number, PurchaseId: string }): Enum.ProductPurchaseDecision
	local userId = receiptInfo.PlayerId
	local purchaseKey = receiptInfo.PurchaseId and tostring(receiptInfo.PurchaseId)

	local log = getReceiptLog(userId)
	if not log then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if purchaseKey and log[purchaseKey] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local decision: Enum.ProductPurchaseDecision? = nil

	-- [JALUR 1]: Server Luck Boost (Consumable Multiplier & Stacking Duration)
	if StoreConfig.IsLuckBoostProductId ~= nil and StoreConfig.IsLuckBoostProductId(receiptInfo.ProductId) then
		decision = ServerLuckManager.ProcessReceipt(receiptInfo)
	end

	-- [JALUR 2]: Direct VipService Dispatch
	if not decision or decision == Enum.ProductPurchaseDecision.NotProcessedYet then
		local okVip, vipService = pcall(function() return Knit.GetService("VipService") end)
		if okVip and vipService and vipService._processReceipt then
			local okProc, dec = pcall(function() return vipService:_processReceipt(receiptInfo) end)
			if okProc and dec ~= nil and dec ~= Enum.ProductPurchaseDecision.NotProcessedYet then
				decision = dec
			end
		end
	end

	-- [JALUR 3]: Direct ShopService Dispatch
	if not decision or decision == Enum.ProductPurchaseDecision.NotProcessedYet then
		local okShop, shopService = pcall(function() return Knit.GetService("ShopService") end)
		if okShop and shopService and shopService.ProcessReceipt then
			local okProc, dec = pcall(function() return shopService:ProcessReceipt(receiptInfo) end)
			if okProc and dec ~= nil and dec ~= Enum.ProductPurchaseDecision.NotProcessedYet then
				decision = dec
			end
		end
	end

	-- [JALUR 4]: Direct DonationsService Dispatch
	if not decision or decision == Enum.ProductPurchaseDecision.NotProcessedYet then
		local okDon, donService = pcall(function() return Knit.GetService("DonationsService") end)
		if okDon and donService and donService.ProcessReceipt then
			local okProc, dec = pcall(function() return donService:ProcessReceipt(receiptInfo) end)
			if okProc and dec ~= nil and dec ~= Enum.ProductPurchaseDecision.NotProcessedYet then
				decision = dec
			end
		end
	end

	-- [JALUR 5]: Direct Trail Products Dispatch (TrailSystem)
	if not decision or decision == Enum.ProductPurchaseDecision.NotProcessedYet then
		local matchedTrailId = nil
		if TrailShopConfig and TrailShopConfig.Registry then
			for id, cfg in pairs(TrailShopConfig.Registry) do
				if cfg.ProductId and cfg.ProductId > 0 and cfg.ProductId == receiptInfo.ProductId then
					matchedTrailId = id
					break
				end
			end
		end

		if matchedTrailId then
			local player = Players:GetPlayerByUserId(userId)
			if player then
				local grantFn = TrailSystem and TrailSystem:FindFirstChild("GrantTrailProduct")
				local granted = false
				if grantFn and grantFn:IsA("BindableFunction") then
					local ok, res = pcall(function()
						return grantFn:Invoke(player, receiptInfo.ProductId)
					end)
					if ok and res == true then
						granted = true
					end
				end

				if not granted and GameProfileService then
					local okAdd = pcall(function()
						GameProfileService:AddTrail(player, matchedTrailId)
						GameProfileService:SetEquippedTrail(player, matchedTrailId)
					end)
					if okAdd then
						granted = true
					end
				end

				if granted then
					decision = Enum.ProductPurchaseDecision.PurchaseGranted
				else
					decision = Enum.ProductPurchaseDecision.NotProcessedYet
				end
			else
				-- Player is offline during purchase callback; return NotProcessedYet so Roblox retries on reconnect
				decision = Enum.ProductPurchaseDecision.NotProcessedYet
			end
		end
	end

	-- [JALUR 6]: Spin Wheel Products (SpinService)
	if not decision or decision == Enum.ProductPurchaseDecision.NotProcessedYet then
		local okSpin, spinService = pcall(function()
			return require(ServerScriptService:WaitForChild("SpinService"))
		end)
		if okSpin and spinService and spinService.ProcessReceipt then
			local okProc, dec = pcall(function()
				return spinService.ProcessReceipt(receiptInfo)
			end)
			if okProc and dec ~= nil and dec ~= Enum.ProductPurchaseDecision.NotProcessedYet then
				decision = dec
			end
		end
	end

	if not decision then
		decision = Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if purchaseKey and decision == Enum.ProductPurchaseDecision.PurchaseGranted then
		if not recordReceipt(userId, purchaseKey) then
			-- The grant already happened. Keep the in-memory marker so an immediate retry is not granted twice.
			warn("[UnifiedPurchaseGateway] Grant completed but receipt log was not saved for " .. tostring(userId))
		end
	end

	return decision
end

local function installProcessReceiptHandler()
	MarketplaceService.ProcessReceipt = handlerFunction
	print("[UnifiedPurchaseGateway] Single ProcessReceipt Pipeline successfully activated!")
end

-- Install authoritative handler immediately
installProcessReceiptHandler()

