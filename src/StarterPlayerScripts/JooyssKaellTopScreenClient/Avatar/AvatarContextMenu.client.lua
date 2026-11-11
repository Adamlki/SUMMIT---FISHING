-- ============================================================
-- AvatarContextMenu (LocalScript)
-- Lokasi: StarterPlayer > StarterPlayerScripts > JooyssKaellTopScreenClient > AvatarContextMenu
-- SUMMITKIT PREMIUM V1 BY JOOYSSKAELL
-- © 2025 JooyssKaell - All Rights Reserved
-- ============================================================

local StarterGui        = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local NetworkGateway    = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))

local player = Players.LocalPlayer

repeat task.wait(1) until player.Character and player.CharacterAppearanceLoaded

local function waitForCoreScript()
	local attempts = 0
	repeat
		attempts += 1
		local success = pcall(function() StarterGui:SetCore("AvatarContextMenuEnabled", true) end)
		if success then return true end
		task.wait(1)
	until attempts >= 30
	return false
end

if not waitForCoreScript() then
	warn("[AvatarContextMenu] CoreScript failed to load") return
end

StarterGui:SetCore("RemoveAvatarContextMenuOption", Enum.AvatarContextMenuOption.Emote)
StarterGui:SetCore("AvatarContextMenuTheme", {
	BackgroundImage         = "",
	BackgroundTransparency  = 0.3,
	BackgroundColor         = Color3.fromRGB(40, 37, 37),
	NameTagColor            = Color3.fromRGB(40, 37, 37),
	NameUnderlineColor      = Color3.fromRGB(40, 37, 37),
	ButtonFrameColor        = Color3.fromRGB(40, 37, 37),
	ButtonFrameTransparency = 0.3,
	ButtonUnderlineColor    = Color3.fromRGB(40, 37, 37),
	Font                    = Enum.Font.Jura
})

local syncBind      = Instance.new("BindableEvent")
local unsyncBind    = Instance.new("BindableEvent")
local carryBind     = Instance.new("BindableEvent")
local stopCarryBind = Instance.new("BindableEvent")

local syncingFolder = ReplicatedStorage:WaitForChild("Syncing",     15)

if not syncingFolder then warn("[AvatarContextMenu] Syncing folder tidak ditemukan!") return end

local function sync(targetPlayer)
	local e = syncingFolder:FindFirstChild("Sync")
	if e then e:FireServer(targetPlayer) end
end

local function unsync()
	local e = syncingFolder:FindFirstChild("UnSync")
	if e then e:FireServer() end
end

local function carry(targetPlayer)
	if not targetPlayer or not targetPlayer:IsA("Player") then return end
	NetworkGateway:Request("POST", "/carry/request", { TargetId = targetPlayer.UserId }):andThen(function(res)
		if res and res.Success then
			StarterGui:SetCore("SendNotification", {
				Title = "Carry Request Sent",
				Text  = "You sent a carry request to " .. targetPlayer.DisplayName,
				Duration = 3
			})
		else
			local msg = (res and res.Message) or "Failed to send carry request."
			StarterGui:SetCore("SendNotification", {
				Title = "Carry Notice",
				Text  = msg,
				Duration = 3
			})
		end
	end)
end

local function stopCarry()
	NetworkGateway:Request("DELETE", "/carry/stop", {}):andThen(function(res)
		local ok = res and res.Success
		StarterGui:SetCore("SendNotification", {
			Title = ok and "Carry Stopped" or "Carry Notice",
			Text = ok and "You stopped carrying." or ((res and res.Message) or "Failed to stop carry."),
			Duration = 2
		})
	end)
end

syncBind.Event:Connect(sync)
unsyncBind.Event:Connect(unsync)
carryBind.Event:Connect(carry)
stopCarryBind.Event:Connect(stopCarry)

StarterGui:SetCore("AddAvatarContextMenuOption", {"Carry",             carryBind})
StarterGui:SetCore("AddAvatarContextMenuOption", {"Stop Carry",        stopCarryBind})
StarterGui:SetCore("AddAvatarContextMenuOption", {"Sync Current Dance", syncBind})
StarterGui:SetCore("AddAvatarContextMenuOption", {"Unsync Dance",       unsyncBind})

print("✅ [AvatarContextMenu] SUMMITKIT PREMIUM V1 Loaded")