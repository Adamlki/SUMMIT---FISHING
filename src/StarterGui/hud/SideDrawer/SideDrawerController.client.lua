--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SocialService = game:GetService("SocialService")
local MarketplaceService = game:GetService("MarketplaceService")
local MonetizationConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("MonetizationConfig"))

local player = Players.LocalPlayer
local drawer = script.Parent :: Frame
local content = drawer:WaitForChild("DrawerContent") :: Frame
local toggleBtn = drawer:WaitForChild("ToggleSlideBtn") :: TextButton
local arrow = toggleBtn:WaitForChild("Arrow") :: TextLabel

local adminCard = content:WaitForChild("AdminEventsCard") :: Frame
local cardBox = adminCard:WaitForChild("CardBox") :: Frame
local statsFrame = cardBox:WaitForChild("StatsFrame") :: Frame
local eventNameLbl = statsFrame:WaitForChild("EventName") :: TextLabel
local statLuck = statsFrame:WaitForChild("StatLuck") :: TextLabel
local statBonusLuck = statsFrame:WaitForChild("StatBonusLuck") :: TextLabel
local statMutation = statsFrame:WaitForChild("StatMutation") :: TextLabel
local timerPill = adminCard:WaitForChild("TimerPill") :: Frame
local timerLabel = timerPill:WaitForChild("TimerLabel") :: TextLabel

local luckContainer = content:WaitForChild("LuckContainer") :: Frame
local serverLuckFrame = luckContainer:WaitForChild("ServerLuckFrame") :: Frame
local serverLuckLabel = serverLuckFrame:WaitForChild("ServerLuckLabel") :: TextLabel
local friendLuckFrame = luckContainer:WaitForChild("FriendLuckFrame") :: Frame
local friendLuckLabel = friendLuckFrame:WaitForChild("FriendLuckLabel") :: TextLabel
local inviteBtn = friendLuckFrame:WaitForChild("InviteBtn") :: TextButton

local coinFrame = luckContainer:WaitForChild("CoinFrame") :: Frame
local coinLabel = coinFrame:WaitForChild("CoinLabel") :: TextLabel

local labelFrame = luckContainer:WaitForChild("LabelFrame") :: Frame
local edvancedIcon = labelFrame:FindFirstChild("EdvancedLuckIcon") :: ImageLabel?
local extraIcon = labelFrame:FindFirstChild("ExtraLuckIcon") :: ImageLabel?
local smallIcon = labelFrame:FindFirstChild("SmallLuckIcon") :: ImageLabel?
local mutationIcon = labelFrame:FindFirstChild("MoreMutationsIcon") :: ImageLabel?
local vipIcon = labelFrame:FindFirstChild("VipPackIcon") :: ImageLabel?

local fishingSystem = ReplicatedStorage:WaitForChild("FishingSystem", 10)
local luckValue = fishingSystem and fishingSystem:WaitForChild("GlobalLuckMultiplier", 10) :: NumberValue?
local timerValue = fishingSystem and fishingSystem:WaitForChild("LuckBoostTimer", 10) :: IntValue?
local mutValue = fishingSystem and fishingSystem:WaitForChild("GlobalMutationMultiplier", 10) :: NumberValue?
local eventNameValue = fishingSystem and fishingSystem:WaitForChild("ActiveEventName", 10) :: StringValue?

-- Bottom-Left Slide Coordinates with comfortable margin (24px padding)
drawer.AnchorPoint = Vector2.new(0, 1)
local POS_DRAWER_OPEN = UDim2.new(0, 24, 1, -24)
local POS_DRAWER_CLOSED = UDim2.new(0, -240, 1, -24)

-- Ensure local positions inside drawer are static and locked
content.Position = UDim2.new(0, 0, 0, 0)
toggleBtn.Position = UDim2.new(0, 244, 0.5, -15)

-- State
local isOpen = true
local isTweening = false
local tweenSlide = TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local tweenFast = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function setDrawerOpen(open: boolean)
	if isTweening then return end
	isOpen = open
	isTweening = true

	local targetPos = isOpen and POS_DRAWER_OPEN or POS_DRAWER_CLOSED
	local targetArrow = isOpen and "◀" or "▶"

	arrow.Text = targetArrow
	local tw = TweenService:Create(drawer, tweenSlide, { Position = targetPos })
	tw:Play()

	tw.Completed:Connect(function()
		isTweening = false
	end)
end

toggleBtn.MouseButton1Click:Connect(function()
	setDrawerOpen(not isOpen)
end)

-- Invite Friends Button
inviteBtn.MouseButton1Click:Connect(function()
	local success, canInvite = pcall(function()
		return SocialService:CanSendGameInviteAsync(player)
	end)
	if success and canInvite then
		SocialService:PromptGameInvite(player)
	end
end)

-- ===================================================================
-- GAMEPASS ICONS INDICATOR ENGINE (LabelFrame)
-- ===================================================================
local function updateGamepassIcons()
	local hasEdvanced = player:GetAttribute("EdvancedLuck") == true
	local hasExtra = player:GetAttribute("ExtraLuck") == true
	local hasSmall = player:GetAttribute("SmallLuck") == true
	local hasMutation = player:GetAttribute("MoreMutations") == true
	local hasVIP = player:GetAttribute("VIP") == true

	if edvancedIcon then edvancedIcon.Visible = hasEdvanced end
	if extraIcon then extraIcon.Visible = hasExtra end
	if smallIcon then smallIcon.Visible = hasSmall end
	if mutationIcon then mutationIcon.Visible = hasMutation end
	if vipIcon then vipIcon.Visible = hasVIP end

	local anyActive = hasEdvanced or hasExtra or hasSmall or hasMutation or hasVIP
	labelFrame.Visible = anyActive
end

-- Connect attribute signals for real-time activation indicator
for _, attr in ipairs({"EdvancedLuck", "ExtraLuck", "SmallLuck", "MoreMutations", "VIP"}) do
	player:GetAttributeChangedSignal(attr):Connect(updateGamepassIcons)
end
updateGamepassIcons()

-- Verify Gamepass ownership on start
task.spawn(function()
	local passes = {
		{ Attr = "EdvancedLuck", Id = MonetizationConfig.LuckPasses.EdvancedLuck },
		{ Attr = "ExtraLuck", Id = MonetizationConfig.LuckPasses.ExtraLuck },
		{ Attr = "SmallLuck", Id = MonetizationConfig.LuckPasses.SmallLuck },
		{ Attr = "MoreMutations", Id = MonetizationConfig.LuckPasses.MoreMutations },
		{ Attr = "VIP", Id = MonetizationConfig.VIP.GamePassId },
	}
	for _, p in ipairs(passes) do
		if player:GetAttribute(p.Attr) ~= true then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, p.Id)
			end)
			if ok and owns then
				player:SetAttribute(p.Attr, true)
			end
		end
	end
	updateGamepassIcons()
end)

-- Live Coin Counter Sync
task.spawn(function()
	while true do
		local leaderstats = player:FindFirstChild("leaderstats")
		local coins = leaderstats and leaderstats:FindFirstChild("Coins") :: ValueBase?
		if coins then
			local num = tonumber(coins.Value) or 0
			coinLabel.Text = string.format("%d Coins", num)
		else
			coinLabel.Text = "0 Coins"
		end
		task.wait(1)
	end
end)

-- Live Friend Luck Sync
local function updateFriendLuck()
	local count = 0
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other:IsFriendsWith(player.UserId) then
			count += 1
		end
	end
	friendLuckLabel.Text = string.format("Friend Luck: +%d%%", count * 10)
end
Players.PlayerAdded:Connect(updateFriendLuck)
Players.PlayerRemoving:Connect(updateFriendLuck)
task.spawn(updateFriendLuck)

-- Live Server Luck Sync
local function updateServerLuck()
	local mult = luckValue and luckValue.Value or 1
	serverLuckLabel.Text = string.format("Server Luck: %.1fx", mult)
end
if luckValue then
	luckValue.Changed:Connect(updateServerLuck)
	updateServerLuck()
end

-- Live Admin Events Card
local function updateAdminEvent()
	local activeName = eventNameValue and eventNameValue.Value or ""
	if activeName ~= "" then
		adminCard.Visible = true
		eventNameLbl.Text = activeName
		local l = luckValue and luckValue.Value or 1
		local m = mutValue and mutValue.Value or 1
		statLuck.Text = string.format("Luck: %.1fx", l)
		statMutation.Text = string.format("Mutations: %.1fx", m)
	else
		adminCard.Visible = false
	end
end
if eventNameValue then
	eventNameValue.Changed:Connect(updateAdminEvent)
	updateAdminEvent()
end

-- Timer Pill
task.spawn(function()
	while true do
		if timerValue and timerValue.Value > 0 then
			timerPill.Visible = true
			local mins = math.floor(timerValue.Value / 60)
			local secs = timerValue.Value % 60
			timerLabel.Text = string.format("%02d:%02d", mins, secs)
		else
			timerPill.Visible = false
		end
		task.wait(1)
	end
end)

-- Initial Setup
drawer.Position = POS_DRAWER_OPEN
