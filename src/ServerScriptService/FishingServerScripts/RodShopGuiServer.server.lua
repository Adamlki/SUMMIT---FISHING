local RoleConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("RoleConfig"))
--!strict
-- RodShopGuiServer: Authoritative Rod Purchases, Equipping, Catalog & Store Handlers (REST + DUAL-STACK)
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local rodAssetsFolder = FishingSystem:WaitForChild("Assets"):WaitForChild("Rod")
local RodShopConfig = require(FishingSystem:WaitForChild("RodShopConfig"))
local FishingConfig = require(FishingSystem:WaitForChild("FishingConfig"))
local StoreConfig = require(FishingSystem:WaitForChild("ExclusiveStoreConfig"))
local GameProfileService = require(ServerScriptService.Data.PetCore:WaitForChild("FishData"))

local ShopEvents = FishingSystem:WaitForChild("RodShopEvents")
local rfGetShopData = ShopEvents:WaitForChild("GetShopData") :: RemoteFunction
local reRequestPurchase = ShopEvents:WaitForChild("RequestPurchase") :: RemoteEvent
local rePurchaseSuccess = ShopEvents:WaitForChild("PurchaseSuccess") :: RemoteEvent
local rfEquipRod = ShopEvents:WaitForChild("EquipRod") :: RemoteFunction
local rfBuyServerLuck = ShopEvents:WaitForChild("BuyServerLuck") :: RemoteFunction
local rfBuyCoinPack = ShopEvents:WaitForChild("BuyCoinPack") :: RemoteFunction
local rfRequestGift = ShopEvents:WaitForChild("RequestGift") :: RemoteFunction

local showNotificationEvent = FishingSystem:FindFirstChild("ShowNotification")
local function notify(player: Player, message: string, color: Color3?)
	if showNotificationEvent and showNotificationEvent:IsA("RemoteEvent") then
		showNotificationEvent:FireClient(player, message, 3.5, color or Color3.fromRGB(255, 255, 255))
	end
end

-- ===================================================================
-- GIVE ROD & EQUIP ROD
-- ===================================================================
local function giveRod(player: Player, rodName: string)
	if not player or not rodName then return end
	GameProfileService:AddRod(player, rodName)

	local rodTool = rodAssetsFolder:FindFirstChild(rodName)
	local backpack = player:FindFirstChild("Backpack")
	if rodTool and backpack then
		if not backpack:FindFirstChild(rodName) and not (player.Character and player.Character:FindFirstChild(rodName)) then
			local cloned = rodTool:Clone()
			cloned.Parent = backpack
		end
	end
	notify(player, "🎉 Sukses! Joran '" .. rodName .. "' telah ditambahkan ke tas.", Color3.fromRGB(100, 255, 140))
end

local function equipRodToCharacter(player: Player, rodName: string): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	if not GameProfileService:HasRod(player, rodName) then
		notify(player, "Kamu belum memiliki joran ini!", Color3.fromRGB(255, 100, 100))
		return false
	end

	humanoid:UnequipTools()

	local backpack = player:WaitForChild("Backpack", 5)
	if not backpack then return false end

	local tool = backpack:FindFirstChild(rodName)
	if not tool then
		local rodTemplate = rodAssetsFolder:FindFirstChild(rodName)
		if rodTemplate then
			tool = rodTemplate:Clone()
			tool.Parent = backpack
		end
	end

	if tool and tool:IsA("Tool") then
		humanoid:EquipTool(tool)
		GameProfileService:SetLastEquippedRod(player, rodName)
		notify(player, "🎣 Joran '" .. rodName .. "' berhasil dipakai!", Color3.fromRGB(100, 255, 140))
		return true
	end

	return false
end

-- ===================================================================
-- PLAYER ADDED & VIP AUTO-GRANT
-- ===================================================================
local function handlePlayerVipSync(player: Player)
	local isOwner = RoleConfig.IsOwner(player)
	local isVIP = isOwner or (player:GetAttribute("VIP") == true) or (player:GetAttribute("IsVIP") == true)
	if not isVIP then
		for _, passId in ipairs({ 1874479701, 1590939529 }) do
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
			end)
			if ok and owns then
				isVIP = true
				break
			end
		end
	end

	if isVIP then
		player:SetAttribute("VIP", true)
		player:SetAttribute("IsVIP", true)
				GameProfileService:AddRod(player, "Gold Rod")
		GameProfileService:AddTrail(player, "GreenTrail")

		if isOwner then
			print("👑 [RodShopGuiServer] Auto-granting all catalog rods to Owner: " .. player.Name)
			local MasterConfig = require(ReplicatedStorage.FishingSystem.ShopMasterConfig)
			for _, r in ipairs(MasterConfig.Rods) do
				GameProfileService:AddRod(player, r.Name)
			end
		end

		local function giveBackpackGoldRod()
			local rodTool = rodAssetsFolder:FindFirstChild("Gold Rod")
			local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 5)
			if rodTool and backpack and not backpack:FindFirstChild("Gold Rod") then
				local clone = rodTool:Clone()
				clone.Parent = backpack
			end
		end

		giveBackpackGoldRod()
		player.CharacterAdded:Connect(function()
			task.wait(0.2)
			giveBackpackGoldRod()
		end)
	end
end

Players.PlayerAdded:Connect(handlePlayerVipSync)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(handlePlayerVipSync, p)
end

-- ===================================================================
-- CORE SHOP LOGIC (REUSABLE BY REST & LEGACY)
-- ===================================================================

local function getShopData(player: Player)
	local isOwner = RoleConfig.IsOwner(player)
	if isOwner then
		local MasterConfig = require(ReplicatedStorage.FishingSystem.ShopMasterConfig)
		for _, r in ipairs(MasterConfig.Rods) do
			GameProfileService:AddRod(player, r.Name)
		end
	end
	local ownedRods = GameProfileService:GetOwnedRods(player)
	-- Pastikan Basic Rod selalu owned secara default
	if not table.find(ownedRods, "Basic Rod") then
		GameProfileService:AddRod(player, "Basic Rod")
		ownedRods = GameProfileService:GetOwnedRods(player)
	end

	-- Pastikan pemain VIP otomatis memiliki Gold Rod dan GreenTrail
	local isVIP = (player:GetAttribute("VIP") == true) or (player:GetAttribute("IsVIP") == true)
	if not isVIP then
		for _, passId in ipairs({ 1874479701, 1590939529 }) do
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
			end)
			if ok and owns then
				player:SetAttribute("VIP", true)
				player:SetAttribute("IsVIP", true)
				isVIP = true
				break
			end
		end
	end

	if isVIP and not table.find(ownedRods, "Gold Rod") then
		GameProfileService:AddRod(player, "Gold Rod")
		GameProfileService:AddTrail(player, "GreenTrail")
		ownedRods = GameProfileService:GetOwnedRods(player)
	end

	local equippedRod = GameProfileService:GetLastEquippedRod(player) or "Basic Rod"
	local coins = GameProfileService:GetCoins(player)

	local catalog = {}
	for rodName, cfg in pairs(RodShopConfig) do
		-- Hanya tampilkan joran yang BUKAN tipe Staff (Staff Rods disembunyikan sesuai grill-me)
		if cfg.Type ~= "Staff" and cfg.Type ~= "None" then
			local stats = FishingConfig.GetRodConfig(rodName)
			local tool = rodAssetsFolder:FindFirstChild(rodName)
			local textureId = ""
			if tool and tool:IsA("Tool") then
				local tex = tostring(tool.TextureId)
				if tex ~= "" then
					textureId = tex:match("rbxassetid://") and tex or ("rbxassetid://" .. tex)
				end
			end

			catalog[rodName] = {
				Type = cfg.Type,
				CoinPrice = cfg.CoinPrice or 0,
				RobuxPrice = cfg.RobuxPrice or 0,
				GamePassId = cfg.GamePassId or 0,
				ProductId = cfg.ProductId or 0,
				Stats = stats,
				TextureId = textureId,
			}
		end
	end

	return {
		OwnedRods = ownedRods,
		EquippedRod = equippedRod,
		Coins = coins,
		Catalog = catalog,
	}
end

local function buyRodWithCoins(player: Player, rodName: string)
	local cfg = RodShopConfig[rodName]
	if not cfg or cfg.Type == "Staff" then
		return { success = false, message = "Joran tidak tersedia untuk dibeli." }
	end

	if GameProfileService:HasRod(player, rodName) then
		notify(player, "Kamu sudah memiliki joran ini!", Color3.fromRGB(255, 200, 100))
		return { success = false, message = "Kamu sudah memiliki joran ini!" }
	end

	if cfg.Type == "VIP" then
		local hasVip = (player:GetAttribute("VIP") == true) or (player:FindFirstChild("VIP") ~= nil)
		if not hasVip then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, 1874479701)
			end)
			if ok and owns then
				player:SetAttribute("VIP", true)
				hasVip = true
			end
		end
		if not hasVip then
			notify(player, "Joran ini khusus untuk pemilik VIP Pack!", Color3.fromRGB(255, 200, 40))
			return { success = false, message = "Joran ini khusus untuk pemilik VIP Pack!" }
		end
	end

	if cfg.Type == "Gamepass" then
		notify(player, "Joran ini hanya dapat diperoleh melalui Gamepass!", Color3.fromRGB(255, 200, 40))
		return { success = false, message = "Joran ini hanya dapat diperoleh melalui Gamepass!" }
	end

	local price = cfg.CoinPrice or 0
	if price > 0 then
		local success, remaining = GameProfileService:TryPurchase(player, price)
		if success then
			giveRod(player, rodName)
			rePurchaseSuccess:FireClient(player)
			return { success = true, rodName = rodName, remainingCoins = remaining }
		else
			notify(player, "Koin kamu tidak cukup! Butuh " .. tostring(price) .. " Koin.", Color3.fromRGB(255, 100, 100))
			return { success = false, message = "Koin kamu tidak cukup!" }
		end
	else
		giveRod(player, rodName)
		rePurchaseSuccess:FireClient(player)
		return { success = true, rodName = rodName }
	end
end

local function buyCoinPack(player: Player, packName: string)
	local pack = StoreConfig.CoinPacks and StoreConfig.CoinPacks[packName]
	if not pack then return { success = false, message = "Paket koin tidak ditemukan" } end

	if pack.ProductId and pack.ProductId > 0 then
		MarketplaceService:PromptProductPurchase(player, pack.ProductId)
		return { success = true, prompted = true }
	end

	-- H-03 Fix: ProductId 0 atau belum dikonfigurasi tidak boleh memberikan koin gratis
	return { success = false, message = "Paket koin belum dikonfigurasi di Roblox Dashboard (ProductId belum di-assign)." }
end

local function buyServerLuck(player: Player)
	local ServerLuckManager = require(ServerScriptService.FishingServerScripts.ServerLuckManager)
	local ServerLuckPurchases = FishingSystem:WaitForChild("ServerLuckPurchases") :: IntValue
	local cfg = StoreConfig.ServerLuckBoost

	if ServerLuckPurchases.Value >= (cfg.MaxPurchases or 5) then
		return { success = false, message = "Server Luck Boost sudah mencapai batas maksimal (MAX)!" }
	end

	local nextTier = StoreConfig.GetLuckTierByCount(ServerLuckPurchases.Value + 1)
	if nextTier.ProductId and nextTier.ProductId > 0 then
		MarketplaceService:PromptProductPurchase(player, nextTier.ProductId)
		return { success = true, prompted = true }
	end

	-- H-03 Fix: ProductId 0 atau belum dikonfigurasi tidak boleh memberikan boost gratis
	return { success = false, message = "Server Luck Boost tier ini belum dikonfigurasi di Roblox Dashboard (ProductId belum di-assign)." }
end

-- ===================================================================
-- REST ROUTES (NETWORK GATEWAY)
-- ===================================================================

NetworkGateway:RegisterRoute("GET", "/shop/rods", function(player)
	return {
		Success = true,
		StatusCode = 200,
		Data = getShopData(player)
	}
end, { rateLimitSeconds = 0.5 })

NetworkGateway:RegisterRoute("PUT", "/shop/equip-rod", function(player, payload)
	if type(payload) ~= "table" or type(payload.RodName) ~= "string" then
		return { Success = false, StatusCode = 400, ErrorCode = "INVALID_PAYLOAD", Message = "RodName is required." }
	end
	local ok = equipRodToCharacter(player, payload.RodName)
	return {
		Success = ok,
		StatusCode = if ok then 200 else 400,
		Message = if ok then "Joran berhasil dipakai" else "Gagal memakai joran"
	}
end, { rateLimitSeconds = 0.5 })

NetworkGateway:RegisterRoute("POST", "/shop/buy-rod", function(player, payload)
	if type(payload) ~= "table" or type(payload.RodName) ~= "string" then
		return { Success = false, StatusCode = 400, ErrorCode = "INVALID_PAYLOAD", Message = "RodName is required." }
	end
	local res = buyRodWithCoins(player, payload.RodName)
	return {
		Success = res.success,
		StatusCode = if res.success then 200 else 400,
		Data = res,
		Message = res.message
	}
end, { rateLimitSeconds = 0.5 })

NetworkGateway:RegisterRoute("POST", "/shop/buy-coin-pack", function(player, payload)
	if type(payload) ~= "table" or type(payload.PackName) ~= "string" then
		return { Success = false, StatusCode = 400, ErrorCode = "INVALID_PAYLOAD", Message = "PackName is required." }
	end
	local res = buyCoinPack(player, payload.PackName)
	return {
		Success = res.success,
		StatusCode = if res.success then 200 else 400,
		Data = res,
		Message = res.message
	}
end, { rateLimitSeconds = 0.5 })

NetworkGateway:RegisterRoute("POST", "/shop/buy-server-luck", function(player)
	local res = buyServerLuck(player)
	return {
		Success = res.success,
		StatusCode = if res.success then 200 else 400,
		Data = res,
		Message = res.message
	}
end, { rateLimitSeconds = 0.5 })

NetworkGateway:RegisterRoute("POST", "/shop/gift", function(player, payload)
	return {
		Success = false,
		StatusCode = 403,
		ErrorCode = "FEATURE_DISABLED",
		Message = "Fitur gift saat ini belum tersedia dan memerlukan konfigurasi Developer Product resmi pada Roblox Dashboard."
	}
end, { rateLimitSeconds = 1 })

-- ===================================================================
-- DUAL-STACK LEGACY HANDLERS
-- ===================================================================

rfGetShopData.OnServerInvoke = function(player: Player)
	return getShopData(player)
end

rfEquipRod.OnServerInvoke = function(player: Player, rodName: string)
	if type(rodName) ~= "string" then return false end
	return equipRodToCharacter(player, rodName)
end

reRequestPurchase.OnServerEvent:Connect(function(player: Player, rodName: string)
	if type(rodName) ~= "string" then return end
	buyRodWithCoins(player, rodName)
end)

rfBuyCoinPack.OnServerInvoke = function(player: Player, packName: string)
	return buyCoinPack(player, packName)
end

rfBuyServerLuck.OnServerInvoke = function(player: Player)
	return buyServerLuck(player)
end

rfRequestGift.OnServerInvoke = function(player: Player, itemCategory: string, itemId: string, targetUserId: number)
	return {
		success = false,
		message = "Fitur gift saat ini belum tersedia dan memerlukan konfigurasi Developer Product resmi pada Roblox Dashboard."
	}
end

-- ===================================================================
-- PROMPT GAMEPASS FINISHED
-- ===================================================================
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, purchasedGamepassId: number, wasPurchased: boolean)
	if not wasPurchased then return end

	-- Check VIP Gamepass
	if purchasedGamepassId == 1874479701 or purchasedGamepassId == 1590939529 then
		player:SetAttribute("VIP", true)
		GameProfileService:AddRod(player, "Gold Rod")
		GameProfileService:AddTrail(player, "GreenTrail")
		local rodTool = rodAssetsFolder:FindFirstChild("Gold Rod")
		if rodTool and player.Backpack and not player.Backpack:FindFirstChild("Gold Rod") then
			rodTool:Clone().Parent = player.Backpack
		end
		notify(player, "👑 Selamat! Kamu mendapatkan VIP Chat Tag, Green Trail, dan Gold Rod!", Color3.fromRGB(255, 215, 0))
		rePurchaseSuccess:FireClient(player)
		return
	end

	-- Check Rod Gamepasses
	for rodName, config in pairs(RodShopConfig) do
		if config.Type == "Gamepass" and config.GamePassId == purchasedGamepassId then
			task.wait(0.5)
			giveRod(player, rodName)
			rePurchaseSuccess:FireClient(player)
			break
		end
	end
end)

return true
