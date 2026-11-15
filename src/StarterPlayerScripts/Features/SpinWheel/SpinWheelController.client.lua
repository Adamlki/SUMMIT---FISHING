--!nonstrict
-- SpinWheelController: state & network untuk wheel spin.
-- - Badge merah + Timer cooldown di RewadsButton (Studio).
-- - Tombol free/paid/beli, antrian spin 5x cepat + skip, popup RewardPopup.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))
local SpinConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("SpinConfig"))
local RewardPopup = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UI"):WaitForChild("RewardPopup"))
local SpinWheel = require(script.Parent.Modules.SpinWheel)

local player = Players.LocalPlayer

local state = {
	Spins = 0,
	FreeReadyAt = 0,
	HasFree = false,
	CooldownSeconds = SpinConfig.FreeSpin.CooldownSeconds,
	Products = {
		X2 = { ProductId = SpinConfig.Products.X2.ProductId, Price = SpinConfig.Products.X2.Price },
		X7 = { ProductId = SpinConfig.Products.X7.ProductId, Price = SpinConfig.Products.X7.Price },
	},
}

local rewadsButton
local badge
local timerLabel

local autoSpinCount = 0
local queued = 0
local pendingSpin = false
local lastHasFree = false

local function findButtonElements()
	local pg = player:WaitForChild("PlayerGui", 15)
	local buttons = pg and pg:FindFirstChild("GameUI") and pg.GameUI:FindFirstChild("Component") and pg.GameUI.Component:FindFirstChild("ButtonsNew")
	local rewards = buttons and buttons:FindFirstChild("Rewards")
	rewadsButton = rewards and rewards:FindFirstChild("RewadsButton")
	if rewadsButton then
		badge = rewadsButton:FindFirstChild("FreeBadge")
		timerLabel = rewadsButton:FindFirstChild("Timer")
	end
end

local function updateBadgeAndTimer()
	if not rewadsButton then
		return
	end
	-- Cooldown bisa habis sendiri tanpa push server: deteksi transisi di client.
	local hasFree = state.HasFree == true or os.time() >= (state.FreeReadyAt or 0)
	if hasFree ~= lastHasFree and not SpinWheel.isSpinning() then
		lastHasFree = hasFree
		state.HasFree = hasFree
		SpinWheel.setState(state)
	end

	if badge then
		badge.Visible = hasFree
	end
	if timerLabel then
		timerLabel.Visible = not hasFree
		if not hasFree then
			local remaining = math.max(0, state.FreeReadyAt - os.time())
			local mins = math.floor(remaining / 60)
			local secs = remaining % 60
			timerLabel.Text = string.format("%d:%02d", mins, secs)
		end
	end
end

local function applyState(data)
	if type(data) ~= "table" then
		return
	end
	local before = state.Spins
	state.Spins = type(data.Spins) == "number" and data.Spins or state.Spins
	state.FreeReadyAt = type(data.FreeReadyAt) == "number" and data.FreeReadyAt or state.FreeReadyAt
	state.HasFree = data.HasFree == true
	state.CooldownSeconds = data.CooldownSeconds or state.CooldownSeconds
	if data.Products then
		state.Products = data.Products
	end

	-- Pembelian spin baru (delta positif) otomatis memutar antrian cepat.
	local delta = state.Spins - before
	if delta > 0 then
		autoSpinCount = autoSpinCount + delta
		SpinWheel.setFast(true)
	end

	SpinWheel.setState(state)
	SpinWheel.updateCountdown(state)
	updateBadgeAndTimer()
	maybeAutoSpin()
end

local function showRewardPopup(result)
	if type(result) ~= "table" then
		return
	end
	local icon = result.Icon
	local title = "JACKPOT!"
	if result.Type == "Coins" then
		title = "COINS!"
	elseif result.Type == "Luck" then
		title = "LUCKY!"
	elseif result.Type == "Rod" then
		title = "NEW ROD!"
	end
	RewardPopup.show({
		Title = title,
		ItemName = result.Label or "Reward",
		Icon = icon,
	})
end

local function requestSpin(mode)
	if pendingSpin then
		return -- cegah klik dobel ngirim 2 request (suara jadi dobel)
	end
	pendingSpin = true

	local ok, res = NetworkGateway:Request("POST", "/spin/spin", { Mode = mode }):await()
	pendingSpin = false

	if not ok or type(res) ~= "table" then
		SpinWheel.showMessage("Gagal terhubung ke server.")
		return
	end
	if not res.Success then
		if res.ErrorCode == "FreeSpinNotReady" then
			SpinWheel.showMessage("Free spin belum siap.")
		elseif res.ErrorCode == "NoSpins" then
			SpinWheel.showMessage("Spin kamu habis. Beli dulu ya!")
		end
		if res.Data then
			applyState(res.Data)
		end
		return
	end

	local data = res.Data or {}
	queued = queued + 1
	SpinWheel.setBusy(true)
	SpinWheel.spinToSegment(data.SegmentIndex or 1, nil, function()
		queued = queued - 1
		SpinWheel.showMessage("")
		showRewardPopup(data.Result)
		applyState(data)
		if queued <= 0 then
			SpinWheel.setBusy(false)
			if autoSpinCount <= 0 then
				SpinWheel.setFast(false)
			end
		end
	end)
end

function maybeAutoSpin()
	if autoSpinCount <= 0 or queued > 0 or SpinWheel.isSpinning() then
		return
	end
	autoSpinCount = autoSpinCount - 1
	requestSpin("paid")
end

local function buyPack(pack)
	local ok, res = NetworkGateway:Request("POST", "/spin/buy", { Pack = pack }):await()
	if not ok or type(res) ~= "table" then
		SpinWheel.showMessage("Gagal terhubung ke server.")
		return
	end
	if not res.Success and res.ErrorCode == "NotConfigured" then
		SpinWheel.showMessage("Produk belum dikonfigurasi (ProductId belum diisi).")
	end
	-- Kalau pembelian sukses, spin bertambah lewat push Spin/State -> auto spin.
end

local function init()
	if not SpinWheel.init() then
		return
	end

	SpinWheel.setCallbacks({
		onSpin = function()
			if autoSpinCount > 0 then
				return
			end
			if state.HasFree then
				requestSpin("free")
			elseif (state.Spins or 0) > 0 then
				requestSpin("paid")
			else
				SpinWheel.showMessage("Spin habis. Beli spin dulu ya!")
			end
		end,
		onBuy = buyPack,
	})

	findButtonElements()

	if rewadsButton then
		rewadsButton.Activated:Connect(function()
			if autoSpinCount <= 0 then
				SpinWheel.toggle()
			end
		end)
	end

	NetworkGateway:On("Spin/State", applyState)

	-- Muat state awal + sync berkala (antisipasi push terlewat).
	local ok, res = NetworkGateway:Request("GET", "/spin/state"):await()
	if ok and type(res) == "table" and type(res.Data) == "table" then
		applyState(res.Data)
	end

	-- Cooldown ticker untuk badge & timer.
	task.spawn(function()
		while true do
			updateBadgeAndTimer()
			SpinWheel.updateCountdown(state)
			task.wait(1)
		end
	end)
end

init()
