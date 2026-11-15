--!nonstrict
-- SpinService: wheel spin rewards. Server-side roll + grant (anti-exploit),
-- free-spin cooldown + paid spins persisted via DataStore, Developer Product
-- receipt handling di-integrasikan ke UnifiedPurchaseGateway.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))
local SpinConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("SpinConfig"))
local DataStoreConfig = require(ServerScriptService:WaitForChild("Configs"):WaitForChild("DataStoreConfig"))
local GameProfileService = require(ServerScriptService:WaitForChild("Data"):WaitForChild("PetCore"):WaitForChild("FishData"))

local SpinService = {}

local store = DataStoreService:GetDataStore(DataStoreConfig.Stores.SpinData)
local cache = {} -- [userId] = { Spins = number, FreeReadyAt = number }
local version = {} -- [userId] = number (dirty counter biar save lama tidak menimpa save baru)

local function defaultData()
	return { Spins = 0, FreeReadyAt = os.time() }
end

local function getData(userId)
	local data = cache[userId]
	if data then
		return data
	end

	local ok, loaded = DataStoreConfig.RetryCall(function()
		return store:GetAsync("Spin_" .. tostring(userId))
	end, "SpinLoad")
	data = (ok and type(loaded) == "table") and loaded or defaultData()
	if type(data.Spins) ~= "number" then
		data.Spins = 0
	end
	if type(data.FreeReadyAt) ~= "number" then
		data.FreeReadyAt = os.time()
	end
	version[userId] = (type(loaded) == "table" and type(loaded.V) == "number" and loaded.V) or 0
	cache[userId] = data
	return data
end

local function markDirty(userId)
	version[userId] = (version[userId] or 0) + 1
end

local function saveData(userId)
	local data = cache[userId]
	if not data then
		return
	end
	local v = version[userId] or 0
	local snapshot = { Spins = data.Spins, FreeReadyAt = data.FreeReadyAt, V = v }
	DataStoreConfig.RetryCall(function()
		store:UpdateAsync("Spin_" .. tostring(userId), function(old)
			local oldV = (type(old) == "table" and type(old.V) == "number" and old.V) or 0
			if oldV > v then
				return nil -- ada save lebih baru; jangan timpa
			end
			return snapshot
		end)
	end, "SpinSave")
end

local function stateFor(userId)
	local data = getData(userId)
	return {
		Spins = data.Spins,
		FreeReadyAt = data.FreeReadyAt,
		HasFree = os.time() >= data.FreeReadyAt,
		CooldownSeconds = SpinConfig.FreeSpin.CooldownSeconds,
		Products = {
			X2 = { ProductId = SpinConfig.Products.X2.ProductId, Price = SpinConfig.Products.X2.Price },
			X7 = { ProductId = SpinConfig.Products.X7.ProductId, Price = SpinConfig.Products.X7.Price },
		},
	}
end

local function pushState(player)
	if player and player.Parent then
		NetworkGateway:Broadcast("Spin/State", stateFor(player.UserId), player)
	end
end

local function weightedPick(list, weightFn)	local total = 0
	for _, item in ipairs(list) do
		total = total + weightFn(item)
	end
	local roll = math.random() * total
	for _, item in ipairs(list) do
		roll = roll - weightFn(item)
		if roll <= 0 then
			return item
		end
	end
	return list[#list]
end

-- Personal luck: cuma untuk player yang menang, tidak menular ke server.
-- Nilai dibaca FishingConfig.CalculateTotalLuck lewat attribute PersonalLuckMultiplier.
local spinLuck = {} -- [Player] = { multiplier, expiresAt, task }

local function clearSpinLuck(player, boost)
	if not player.Parent then
		return
	end
	local current = player:GetAttribute("PersonalLuckMultiplier") or 1
	if math.abs(current - boost.multiplier) < 0.001 then
		player:SetAttribute("PersonalLuckMultiplier", nil)
	end
end

local function grantPersonalLuck(player, multiplier, seconds)
	local boost = spinLuck[player]
	if not boost then
		boost = { multiplier = 1, expiresAt = 0 }
		spinLuck[player] = boost
	end

	boost.multiplier = math.max(boost.multiplier, multiplier)
	boost.expiresAt = os.clock() + seconds
	player:SetAttribute("PersonalLuckMultiplier", boost.multiplier)

	if not boost.task then
		boost.task = task.spawn(function()
			while true do
				local remaining = boost.expiresAt - os.clock()
				if remaining <= 0 then
					break
				end
				task.wait(math.min(remaining, 1))
			end
			if spinLuck[player] == boost then
				spinLuck[player] = nil
			end
			clearSpinLuck(player, boost)
		end)
	end

	local showNotif = ReplicatedStorage.FishingSystem:FindFirstChild("ShowNotification")
	if showNotif and showNotif:IsA("RemoteEvent") then
		pcall(function()
			showNotif:FireClient(player, string.format("🍀 Luck %sx aktif untukmu selama %d detik!", string.format("%.1f", boost.multiplier), seconds))
		end)
	end
end

local function grantReward(player, segment)
	if segment.Type == "Coins" then
		GameProfileService:AddCoins(player, segment.Amount)
		return {
			Type = "Coins",
			Amount = segment.Amount,
			Label = "+" .. tostring(segment.Amount) .. " Coins",
			Icon = SpinConfig.CoinIcon,
		}

	elseif segment.Type == "Luck" then
		grantPersonalLuck(player, segment.Multiplier, segment.Seconds)
		return {
			Type = "Luck",
			Multiplier = segment.Multiplier,
			Seconds = segment.Seconds,
			Label = "Luck " .. string.format("%.1fx", segment.Multiplier) .. " (" .. segment.Seconds .. " dtk)",
			Icon = SpinConfig.LuckIcon,
		}

	elseif segment.Type == "Rod" then
		local rodName = segment.RodName
		if not rodName then
			local entries = {}
			for name, weight in pairs(segment.RodPool or {}) do
				table.insert(entries, { Name = name, Weight = weight })
			end
			local picked = weightedPick(entries, function(e)
				return e.Weight
			end)
			rodName = picked and picked.Name or "Lucky Rod"
		end

		if GameProfileService:HasRod(player, rodName) then
			-- Duplikat: konversi jadi coins, tetap terasa berhadiah.
			GameProfileService:AddCoins(player, segment.DupeCoins or 200)
			return {
				Type = "Coins",
				Amount = segment.DupeCoins or 200,
				Label = "+" .. tostring(segment.DupeCoins or 200) .. " Coins (sudah punya " .. rodName .. ")",
				Icon = SpinConfig.CoinIcon,
			}
		end

		GameProfileService:AddRod(player, rodName)
		return {
			Type = "Rod",
			RodName = rodName,
			Label = rodName,
			Icon = nil,
		}
	end

	return { Type = "Coins", Amount = 0, Label = "Coba lagi", Icon = SpinConfig.CoinIcon }
end

function SpinService.ProcessReceipt(receiptInfo)
	local productId = receiptInfo.ProductId
	for _, key in ipairs({ "X2", "X7" }) do
		local cfg = SpinConfig.Products[key]
		if cfg.ProductId and cfg.ProductId > 0 and cfg.ProductId == productId then
			local data = getData(receiptInfo.PlayerId)
			data.Spins = (data.Spins or 0) + cfg.Spins
			markDirty(receiptInfo.PlayerId)
			saveData(receiptInfo.PlayerId)
			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			pushState(player)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function SpinService.Init()
	NetworkGateway:RegisterRoute("GET", "/spin/state", function(player)
		return { Success = true, StatusCode = 200, Data = stateFor(player.UserId) }
	end)

	NetworkGateway:RegisterRoute("POST", "/spin/spin", function(player, payload)
		local userId = player.UserId
		local data = getData(userId)
		local mode = (type(payload) == "table" and payload.Mode) or "paid"
		local now = os.time()

		if mode == "free" then
			if now < data.FreeReadyAt then
				return { Success = false, StatusCode = 400, ErrorCode = "FreeSpinNotReady", Data = stateFor(userId) }
			end
			data.FreeReadyAt = now + SpinConfig.FreeSpin.CooldownSeconds
		else
			if (data.Spins or 0) < 1 then
				return { Success = false, StatusCode = 400, ErrorCode = "NoSpins", Data = stateFor(userId) }
			end
			data.Spins = data.Spins - 1
		end

		markDirty(userId)
		saveData(userId)

		local segment = weightedPick(SpinConfig.Segments, function(s)
			return s.Weight
		end)
		local result = grantReward(player, segment)

		local state = stateFor(userId)
		pushState(player)
		return {
			Success = true,
			StatusCode = 200,
			Data = {
				Result = result,
				SegmentIndex = table.find(SpinConfig.Segments, segment),
				Spins = state.Spins,
				FreeReadyAt = state.FreeReadyAt,
				HasFree = state.HasFree,
			},
		}
	end, { rateLimitSeconds = 0.5 })

	NetworkGateway:RegisterRoute("POST", "/spin/buy", function(player, payload)
		local pack = (type(payload) == "table" and payload.Pack) or nil
		local cfg = pack and SpinConfig.Products[pack]
		if not cfg then
			return { Success = false, StatusCode = 400, ErrorCode = "InvalidPack" }
		end
		if not cfg.ProductId or cfg.ProductId < 1 then
			return { Success = false, StatusCode = 400, ErrorCode = "NotConfigured" }
		end
		MarketplaceService:PromptProductPurchase(player, cfg.ProductId)
		return { Success = true, StatusCode = 200, Data = { Prompted = true } }
	end, { rateLimitSeconds = 2 })

	Players.PlayerAdded:Connect(function(player)
		getData(player.UserId)
		task.spawn(function()
			pushState(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		saveData(player.UserId)
		cache[player.UserId] = nil
		version[player.UserId] = nil
		local boost = spinLuck[player]
		if boost then
			boost.expiresAt = 0 -- hentikan timer personal luck
			spinLuck[player] = nil
		end
	end)

	-- Helper test khusus Studio (tidak terdaftar di server produksi).
	if RunService:IsStudio() then
		NetworkGateway:RegisterRoute("POST", "/spin/debug-grant", function(player, payload)
			local n = (type(payload) == "table" and tonumber(payload.Amount)) or 5
			local data = getData(player.UserId)
			data.Spins = data.Spins + n
			markDirty(player.UserId)
			saveData(player.UserId)
			pushState(player)
			return { Success = true, StatusCode = 200, Data = stateFor(player.UserId) }
		end)

		NetworkGateway:RegisterRoute("POST", "/spin/debug-free", function(player)
			local data = getData(player.UserId)
			data.FreeReadyAt = os.time() - 100
			markDirty(player.UserId)
			saveData(player.UserId)
			pushState(player)
			return { Success = true, StatusCode = 200 }
		end)

		-- Simulasi distribusi hadiah (tanpa grant) buat verifikasi persentase.
		NetworkGateway:RegisterRoute("POST", "/spin/debug-simulate", function(player, payload)
			local rolls = math.clamp(tonumber(payload and payload.Rolls) or 1000, 1, 50000)
			local counts = {}
			for i = 1, rolls do
				local seg = weightedPick(SpinConfig.Segments, function(s)
					return s.Weight
				end)
				local key = tostring(seg.Type) .. ":" .. tostring(seg.Amount or seg.RodName or seg.Multiplier or "?")
				counts[key] = (counts[key] or 0) + 1
			end
			return { Success = true, StatusCode = 200, Data = { Rolls = rolls, Counts = counts } }
		end)
	end

	print("[SpinService] Initialized.")
end

return SpinService
