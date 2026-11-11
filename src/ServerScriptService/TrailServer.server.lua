--!strict
-- ServerScriptService/TrailServer
-- Handles Trail Purchases (Coins & Robux), Equipping, Character AssetTrails Attachment, and Speed Bonuses.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))

local TrailSystem = ReplicatedStorage:WaitForChild("TrailSystem", 15)
local TrailShopConfig = require(TrailSystem:WaitForChild("TrailShopConfig"))
local Remotes = TrailSystem:WaitForChild("Remotes")
local AssetTrails = TrailSystem:WaitForChild("AssetTrails")

local GetTrailDataRF = Remotes:WaitForChild("GetTrailData") :: RemoteFunction
local BuyTrailWithCoinsRF = Remotes:WaitForChild("BuyTrailWithCoins") :: RemoteFunction
local BuyTrailWithRobuxRF = Remotes:WaitForChild("BuyTrailWithRobux") :: RemoteFunction
local EquipTrailRF = Remotes:WaitForChild("EquipTrail") :: RemoteFunction
local UnequipTrailRF = Remotes:WaitForChild("UnequipTrail") :: RemoteFunction

local GameProfileService = require(ServerScriptService.Data.PetCore:WaitForChild("FishData"))

local lastTrailAction = {}
Players.PlayerRemoving:Connect(function(player)
	lastTrailAction[player] = nil
end)

-- ===================================================================
-- RESPONSE + BROADCAST HELPERS
-- ===================================================================

local function respondSuccess(data: any, message: string?)
	return {
		Success = true,
		StatusCode = 200,
		Data = data,
		Message = message or "OK",
	}
end

local function respondFailure(statusCode: number, errorCode: string, message: string)
	return {
		Success = false,
		StatusCode = statusCode,
		ErrorCode = errorCode,
		Message = message,
	}
end

local function broadcastTrailUpdated(player: Player, trailId: string)
	NetworkGateway:Broadcast("Trail/Updated", { TrailId = trailId }, player)
end

-- ===================================================================
-- VISUAL ASSETTRAILS ATTACHMENT & SPEED ENGINE
-- ===================================================================

local function removePlayerTrail(char: Model?)
	if not char then return end
	for _, child in ipairs(char:GetChildren()) do
		if child.Name == "EquippedTrailPart" or child:GetAttribute("IsTrailPart") == true then
			child:Destroy()
		end
	end
end

local function applyPlayerTrail(player: Player, char: Model?, trailId: string?)
	if not char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")

	if not trailId or trailId == "" then
		removePlayerTrail(char)
		player:SetAttribute("EquippedTrail", "")
		player:SetAttribute("TrailSpeedBonus", 0)
		if humanoid then
			local coilBonus = player:GetAttribute("CoilSpeedBonus") or 0
			humanoid.WalkSpeed = 16 + coilBonus
		end
		return
	end

	local trailConfig = TrailShopConfig.Registry[trailId]
	if not trailConfig then
		removePlayerTrail(char)
		player:SetAttribute("EquippedTrail", "")
		player:SetAttribute("TrailSpeedBonus", 0)
		return
	end

	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
	if not torso or not torso:IsA("BasePart") then return end

	-- Hapus trail lama jika ada
	removePlayerTrail(char)

	-- Ambil template dari AssetTrails
	local templatePart = AssetTrails:FindFirstChild(trailConfig.PartName)
	if templatePart and templatePart:IsA("BasePart") then
		local trailPart = templatePart:Clone()
		trailPart.Name = "EquippedTrailPart"
		trailPart:SetAttribute("IsTrailPart", true)
		trailPart.CanCollide = false
		trailPart.CanTouch = false
		trailPart.CanQuery = false
		trailPart.Massless = true
		trailPart.Anchored = false
		trailPart.CFrame = torso.CFrame
		trailPart.Parent = char

		local weld = trailPart:FindFirstChildOfClass("WeldConstraint")
		if not weld then
			weld = Instance.new("WeldConstraint")
			weld.Name = "MainPartTrailWeldConstraint"
			weld.Parent = trailPart
		end
		weld.Part0 = trailPart
		weld.Part1 = torso
	end

	-- Update State & WalkSpeed (16 + CoilBonus + TrailSpeedBonus)
	player:SetAttribute("EquippedTrail", trailId)
	player:SetAttribute("TrailSpeedBonus", trailConfig.SpeedBonus)
	if humanoid then
		local coilBonus = player:GetAttribute("CoilSpeedBonus") or 0
		humanoid.WalkSpeed = 16 + coilBonus + trailConfig.SpeedBonus
	end
end

-- ===================================================================
-- LIFECYCLE & RESPAWN HANDLING
-- ===================================================================

local function onCharacterAdded(player: Player, char: Model)
	task.spawn(function()
		local maxWait = 50
		while maxWait > 0 do
			local profile = GameProfileService:GetProfile(player)
			if profile and profile:IsActive() then break end
			task.wait(0.1)
			maxWait -= 1
		end

		char:WaitForChild("HumanoidRootPart", 5)
		local humanoid = char:WaitForChild("Humanoid", 5) :: Humanoid?
		task.wait(0.3)

		local equipped = GameProfileService:GetEquippedTrail(player)
		if equipped and equipped ~= "" then
			applyPlayerTrail(player, char, equipped)
		else
			if humanoid then
				local coilBonus = player:GetAttribute("CoilSpeedBonus") or 0
				humanoid.WalkSpeed = 16 + coilBonus
			end
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end)

for _, p in ipairs(Players:GetPlayers()) do
	p.CharacterAdded:Connect(function(char)
		onCharacterAdded(p, char)
	end)
	if p.Character then
		onCharacterAdded(p, p.Character)
	end
end

-- ===================================================================
-- CORE TRAIL LOGIC (REUSABLE BY REST & LEGACY)
-- ===================================================================

local function getTrailData(player: Player)
	return {
		Owned = GameProfileService:GetOwnedTrails(player) or {},
		Equipped = GameProfileService:GetEquippedTrail(player) or "",
	}
end

local function buyTrailWithCoins(player: Player, trailId: string)
	if lastTrailAction[player] and os.clock() - lastTrailAction[player] < 0.5 then
		return { success = false, message = "Terlalu cepat, coba lagi sebentar." }
	end
	lastTrailAction[player] = os.clock()
	if type(trailId) ~= "string" or trailId == "" then
		return { success = false, message = "ID Trail tidak valid" }
	end

	local itemConfig = TrailShopConfig.Registry[trailId]
	if not itemConfig then
		return { success = false, message = "Skin trail tidak ditemukan di katalog" }
	end

	if GameProfileService:HasTrail(player, trailId) then
		return { success = false, message = "Kamu sudah memiliki skin trail ini!" }
	end

	local price = itemConfig.CoinPrice
	local success, remainingCoins = true, 0
	if price > 0 then
		success, remainingCoins = GameProfileService:TryPurchase(player, price)
		if not success then
			return { success = false, message = "Koin kamu tidak cukup untuk membeli trail ini!" }
		end
	else
		local profile = GameProfileService:GetProfile(player)
		remainingCoins = profile and profile.Data.Coins or 0
	end

	GameProfileService:AddTrail(player, trailId)
	GameProfileService:SetEquippedTrail(player, trailId)
	if player.Character then
		applyPlayerTrail(player, player.Character, trailId)
	end

	broadcastTrailUpdated(player, trailId)

	return {
		success = true,
		equipped = trailId,
		coins = remainingCoins,
		owned = GameProfileService:GetOwnedTrails(player),
		message = "Berhasil membeli dan memakai " .. itemConfig.Name .. "!",
	}
end

local function buyTrailWithRobux(player: Player, trailId: string)
	if lastTrailAction[player] and os.clock() - lastTrailAction[player] < 0.5 then
		return { success = false, message = "Terlalu cepat, coba lagi sebentar." }
	end
	lastTrailAction[player] = os.clock()
	if type(trailId) ~= "string" or trailId == "" then
		return { success = false, message = "ID Trail tidak valid" }
	end

	local itemConfig = TrailShopConfig.Registry[trailId]
	if not itemConfig then
		return { success = false, message = "Skin trail tidak ditemukan di katalog" }
	end

	if GameProfileService:HasTrail(player, trailId) then
		return { success = false, message = "Kamu sudah memiliki skin trail ini!" }
	end

	if itemConfig.ProductId and itemConfig.ProductId > 0 then
		MarketplaceService:PromptProductPurchase(player, itemConfig.ProductId)
		return { success = true, prompted = true }
	end

	-- Studio simulation / Fallback
	if not RunService:IsStudio() then
		return { success = false, message = "Pembelian Robux untuk trail ini belum tersedia saat ini." }
	end

	GameProfileService:AddTrail(player, trailId)
	GameProfileService:SetEquippedTrail(player, trailId)
	if player.Character then
		applyPlayerTrail(player, player.Character, trailId)
	end

	broadcastTrailUpdated(player, trailId)

	return {
		success = true,
		equipped = trailId,
		message = "Berhasil membeli dan memakai " .. itemConfig.Name .. "!",
	}
end

local function equipTrail(player: Player, trailId: string)
	if lastTrailAction[player] and os.clock() - lastTrailAction[player] < 0.5 then
		return { success = false, message = "Terlalu cepat, coba lagi sebentar." }
	end
	lastTrailAction[player] = os.clock()
	if type(trailId) ~= "string" or trailId == "" then
		return { success = false, message = "ID tidak valid" }
	end

	local itemConfig = TrailShopConfig.Registry[trailId]
	if not itemConfig then
		return { success = false, message = "Trail tidak ditemukan" }
	end

	if not GameProfileService:HasTrail(player, trailId) then
		return { success = false, message = "Kamu belum memiliki skin trail ini!" }
	end

	GameProfileService:SetEquippedTrail(player, trailId)
	if player.Character then
		applyPlayerTrail(player, player.Character, trailId)
	end

	broadcastTrailUpdated(player, trailId)

	return {
		success = true,
		equipped = trailId,
		message = "Trail " .. itemConfig.Name .. " berhasil dipakai!",
	}
end

local function unequipTrail(player: Player)
	if lastTrailAction[player] and os.clock() - lastTrailAction[player] < 0.5 then
		return { success = false, message = "Terlalu cepat, coba lagi sebentar." }
	end
	lastTrailAction[player] = os.clock()

	GameProfileService:SetEquippedTrail(player, "")
	if player.Character then
		applyPlayerTrail(player, player.Character, "")
	end

	broadcastTrailUpdated(player, "")

	return {
		success = true,
		equipped = "",
		message = "Trail berhasil dilepas!",
	}
end

-- ===================================================================
-- REST ROUTES (NETWORK GATEWAY)
-- ===================================================================

NetworkGateway:RegisterRoute("GET", "/trail/data", function(player)
	return respondSuccess(getTrailData(player), "Trail data loaded.")
end, { rateLimitSeconds = 0.5 })

NetworkGateway:RegisterRoute("POST", "/trail/buy-coins", function(player, payload)
	if type(payload) ~= "table" or type(payload.TrailId) ~= "string" or payload.TrailId == "" then
		return respondFailure(400, "INVALID_PAYLOAD", "TrailId is required.")
	end

	local res = buyTrailWithCoins(player, payload.TrailId)
	if not res.success then
		return respondFailure(400, "TRAIL_PURCHASE_FAILED", res.message or "Trail purchase failed.")
	end

	return respondSuccess({
		Owned = res.owned,
		Equipped = res.equipped,
		Coins = res.coins,
	}, res.message)
end, { rateLimitSeconds = 0.5 })

NetworkGateway:RegisterRoute("PUT", "/trail/equip", function(player, payload)
	if type(payload) ~= "table" or type(payload.TrailId) ~= "string" or payload.TrailId == "" then
		return respondFailure(400, "INVALID_PAYLOAD", "TrailId is required.")
	end

	local res = equipTrail(player, payload.TrailId)
	if not res.success then
		return respondFailure(400, "TRAIL_EQUIP_FAILED", res.message or "Trail equip failed.")
	end

	return respondSuccess({
		Owned = GameProfileService:GetOwnedTrails(player) or {},
		Equipped = res.equipped,
	}, res.message)
end, { rateLimitSeconds = 0.5 })

NetworkGateway:RegisterRoute("DELETE", "/trail/unequip", function(player)
	local res = unequipTrail(player)
	if not res.success then
		return respondFailure(400, "TRAIL_UNEQUIP_FAILED", res.message or "Trail unequip failed.")
	end

	return respondSuccess({
		Owned = GameProfileService:GetOwnedTrails(player) or {},
		Equipped = "",
	}, res.message)
end, { rateLimitSeconds = 0.5 })

-- ===================================================================
-- DUAL-STACK LEGACY HANDLERS
-- ===================================================================

GetTrailDataRF.OnServerInvoke = function(player: Player)
	local data = getTrailData(player)
	return {
		owned = data.Owned,
		equipped = data.Equipped,
	}
end

BuyTrailWithCoinsRF.OnServerInvoke = function(player: Player, trailId: string)
	return buyTrailWithCoins(player, trailId)
end

BuyTrailWithRobuxRF.OnServerInvoke = function(player: Player, trailId: string)
	return buyTrailWithRobux(player, trailId)
end

EquipTrailRF.OnServerInvoke = function(player: Player, trailId: string)
	return equipTrail(player, trailId)
end

UnequipTrailRF.OnServerInvoke = function(player: Player)
	return unequipTrail(player)
end

-- ===================================================================
-- ROBUX DEVELOPER PRODUCT PURCHASE HANDLING (DISPATCH FOR UNIFIEDPURCHASEGATEWAY)
-- ===================================================================

-- [ARCHITECTURAL UPGRADE]: MarketplaceService.PromptProductPurchaseFinished
-- has been migrated to ServerScriptService.UnifiedPurchaseGateway (JALUR 5).
-- This BindableFunction is called by UnifiedPurchaseGateway upon verified ProcessReceipt.
local grantTrailBindable = TrailSystem:FindFirstChild("GrantTrailProduct") :: BindableFunction?
if not grantTrailBindable then
	grantTrailBindable = Instance.new("BindableFunction")
	grantTrailBindable.Name = "GrantTrailProduct"
	grantTrailBindable.Parent = TrailSystem
end

grantTrailBindable.OnInvoke = function(player: Player, productId: number): boolean
	for id, cfg in pairs(TrailShopConfig.Registry) do
		if cfg.ProductId and cfg.ProductId > 0 and cfg.ProductId == productId then
			GameProfileService:AddTrail(player, id)
			GameProfileService:SetEquippedTrail(player, id)
			if player.Character then
				applyPlayerTrail(player, player.Character, id)
			end
			broadcastTrailUpdated(player, id)
			return true
		end
	end
	return false
end

-- Deprecated PromptProductPurchaseFinished removed to guarantee at-least-once delivery,
-- persistent receipt deduplication, and zero transaction drops via ProcessReceipt.

return true
