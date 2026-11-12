--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)
local Helpers = script.Parent:WaitForChild("Helpers")
local RealtimeServiceSync = require(Helpers:WaitForChild("RealtimeServiceSync"))
local MonetizationConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("MonetizationConfig"))

local RealtimeEntry = {}
RealtimeEntry.__index = RealtimeEntry

local VIP_GAMEPASS_ID = MonetizationConfig.VIP.LegacyGamePassId

local function formatNumber(n)
	local str = tostring(math.floor(tonumber(n) or 0))
	return string.reverse(string.gsub(string.reverse(str), "(%d%d%d)", "%1,")):gsub("^,", "")
end

local function makeThumbnail(player, imageLabel)
	if not imageLabel or not player then return end
	task.spawn(function()
		local success, thumb = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId,
				Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)
		end)
		if success and thumb and imageLabel then
			imageLabel.Image = thumb
		end
	end)
end

local function updateEntry(entry)
	local p = entry.player
	local frame = entry.frame
	if not p or not frame then return end

	-- Update Subtitle / Tag
	local subtitle = frame:FindFirstChild("Subtitle")
	if subtitle then
		if p.UserId == 8978185974 or p.Name == "GUARD_ZVxJekybix" or p.UserId == game.CreatorId then
			subtitle.Text = "👑 Developer / Creator"
			subtitle.TextColor3 = Color3.fromRGB(255, 215, 0)
		elseif p:GetAttribute("HasRemoteSell") == true then
			subtitle.Text = "💎 Master Pemancing"
			subtitle.TextColor3 = Color3.fromRGB(0, 210, 255)
		else
			subtitle.Text = "Adventurer & Angler"
			subtitle.TextColor3 = Color3.fromRGB(140, 175, 220)
		end
	end

	local data = frame:FindFirstChild("Data")
	if data then
		local posisiLbl = data:FindFirstChild("Posisi")
		local puncakLbl = data:FindFirstChild("Puncak")
		local bestTimeLbl = data:FindFirstChild("BestTime")
		local coinsLbl = data:FindFirstChild("Coins")
		local tangkapanLbl = data:FindFirstChild("Tangkapan")
		local luckLbl = data:FindFirstChild("Luck")

		local leaderstats = p:FindFirstChild("leaderstats")
		if leaderstats then
			if posisiLbl and leaderstats:FindFirstChild("Posisi") then
				posisiLbl.Text = "📍 " .. tostring(leaderstats.Posisi.Value)
			end
			if puncakLbl and leaderstats:FindFirstChild("Summit") then
				puncakLbl.Text = "🏔️ " .. tostring(leaderstats.Summit.Value)
			end
			if bestTimeLbl then
				local best = leaderstats:FindFirstChild("BestTime")
				bestTimeLbl.Text = "⏱️ " .. tostring(best and best.Value or "00:00")
			end
			if coinsLbl and leaderstats:FindFirstChild("Coins") then
				coinsLbl.Text = "💰 " .. formatNumber(leaderstats.Coins.Value)
			end
			if tangkapanLbl and leaderstats:FindFirstChild("Tangkapan") then
				tangkapanLbl.Text = "🐟 " .. formatNumber(leaderstats.Tangkapan.Value)
			end
		end

		-- Real-time Luck Multiplier Badge
		if luckLbl then
			local fishingSystem = ReplicatedStorage:FindFirstChild("FishingSystem")
			local globalLuck = fishingSystem and fishingSystem:FindFirstChild("GlobalLuckMultiplier")
			local lVal = globalLuck and globalLuck.Value or 1.0
			luckLbl.Text = string.format("🍀 %.1fx", lVal)
			if lVal > 1.0 then
				luckLbl.TextColor3 = Color3.fromRGB(0, 255, 140)
			else
				luckLbl.TextColor3 = Color3.fromRGB(220, 230, 245)
			end
		end
	end
end

function RealtimeEntry.new(player, template, container)
	if not (player and template and container) then return nil end
	local useTemplate = template:GetAttribute("UseAsInstance") == true
	local frame
	if useTemplate then
		frame = template
		frame.Visible = true
	else
		frame = template:Clone()
		frame.Name = "Player_" .. player.UserId
		frame.Visible = true
		frame.Parent = container
	end

	local icon = frame:FindFirstChild("Icon", true)
	if icon and icon:IsA("ImageLabel") then
		makeThumbnail(player, icon)
	end

	local playersLbl = frame:FindFirstChild("PlayerName") or (frame:FindFirstChild("Data") and frame.Data:FindFirstChild("Players"))
	if playersLbl and playersLbl:IsA("TextLabel") then
		playersLbl.Text = player.DisplayName
	end

	local entryJanitor = Janitor.new()
	local self = setmetatable({
		player = player,
		frame = frame,
		janitor = entryJanitor,
	}, RealtimeEntry)

	if not useTemplate then
		entryJanitor:Add(frame, "Destroy")
	end

	entryJanitor:Add(player:GetPropertyChangedSignal("DisplayName"):Connect(function()
		local lbl = frame:FindFirstChild("PlayerName") or (frame:FindFirstChild("Data") and frame.Data:FindFirstChild("Players"))
		if lbl then
			lbl.Text = player.DisplayName
		end
	end), "Disconnect")

	local function onLeaderstatsChanged()
		updateEntry(self)
	end

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		if ls:FindFirstChild("Posisi") then
			entryJanitor:Add(ls.Posisi.Changed:Connect(onLeaderstatsChanged), "Disconnect")
		end
		if ls:FindFirstChild("Summit") then
			entryJanitor:Add(ls.Summit.Changed:Connect(onLeaderstatsChanged), "Disconnect")
		end
		if ls:FindFirstChild("BestTime") then
			entryJanitor:Add(ls.BestTime.Changed:Connect(onLeaderstatsChanged), "Disconnect")
		end
		if ls:FindFirstChild("Coins") then
			entryJanitor:Add(ls.Coins.Changed:Connect(onLeaderstatsChanged), "Disconnect")
		end
		if ls:FindFirstChild("Tangkapan") then
			entryJanitor:Add(ls.Tangkapan.Changed:Connect(onLeaderstatsChanged), "Disconnect")
		end
	end

	entryJanitor:Add(player.ChildAdded:Connect(function(child)
		if child.Name == "leaderstats" then
			onLeaderstatsChanged()
			local posisi = child:FindFirstChild("Posisi")
			local summit = child:FindFirstChild("Summit")
			local bestTime = child:FindFirstChild("BestTime")
			local coins = child:FindFirstChild("Coins")
			local tangkapan = child:FindFirstChild("Tangkapan")
			if posisi then
				entryJanitor:Add(posisi.Changed:Connect(onLeaderstatsChanged), "Disconnect")
			end
			if summit then
				entryJanitor:Add(summit.Changed:Connect(onLeaderstatsChanged), "Disconnect")
			end
			if bestTime then
				entryJanitor:Add(bestTime.Changed:Connect(onLeaderstatsChanged), "Disconnect")
			end
			if coins then
				entryJanitor:Add(coins.Changed:Connect(onLeaderstatsChanged), "Disconnect")
			end
			if tangkapan then
				entryJanitor:Add(tangkapan.Changed:Connect(onLeaderstatsChanged), "Disconnect")
			end
		end
	end), "Disconnect")

	-- Listen for GlobalLuckMultiplier changes
	local fishingSystem = ReplicatedStorage:FindFirstChild("FishingSystem")
	local globalLuck = fishingSystem and fishingSystem:FindFirstChild("GlobalLuckMultiplier")
	if globalLuck then
		entryJanitor:Add(globalLuck.Changed:Connect(function()
			updateEntry(self)
		end), "Disconnect")
	end

	-- Listen for HasRemoteSell / VIP attribute
	entryJanitor:Add(player:GetAttributeChangedSignal("HasRemoteSell"):Connect(function()
		updateEntry(self)
	end), "Disconnect")

	local svc = RealtimeServiceSync.getService()
	RealtimeServiceSync.bindStatsUpdated(self, entryJanitor, svc)
	RealtimeServiceSync.applySnapshot(self, svc)

	entryJanitor:Add(player.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:destroy()
		end
	end), "Disconnect")

	updateEntry(self)
	return self
end

function RealtimeEntry:refresh()
	updateEntry(self)
end

function RealtimeEntry:destroy()
	if self.janitor then
		self.janitor:Destroy()
	end
end

return RealtimeEntry
