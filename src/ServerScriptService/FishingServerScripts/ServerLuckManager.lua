--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local StoreConfig = require(FishingSystem:WaitForChild("ExclusiveStoreConfig"))
local GlobalLuck = FishingSystem:WaitForChild("GlobalLuckMultiplier") :: NumberValue
local LuckTimer = FishingSystem:WaitForChild("LuckBoostTimer") :: NumberValue
local ServerLuckPurchases = FishingSystem:WaitForChild("ServerLuckPurchases") :: IntValue

local ServerLuckManager = {}
local activeTimerTask: thread? = nil

local function ensureTimerRunning()
    if activeTimerTask ~= nil then return end

    activeTimerTask = task.spawn(function()
        while LuckTimer.Value > 0 do
            task.wait(1)
            LuckTimer.Value = math.max(0, LuckTimer.Value - 1)
        end
        -- Reset to normal luck and 0 purchases once timer expires
        GlobalLuck.Value = 1
        ServerLuckPurchases.Value = 0
        activeTimerTask = nil
    end)
end

function ServerLuckManager.ProcessReceipt(receiptInfo: { PlayerId: number, ProductId: number }): Enum.ProductPurchaseDecision
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    local cfg = StoreConfig.ServerLuckBoost
    local addSeconds = cfg.DurationSeconds or 1800

    -- At max tier: still extend the duration with the top tier (the player paid, must receive value)
    local maxPurchases = cfg.MaxPurchases or 5
    local nextCount = math.min(ServerLuckPurchases.Value + 1, maxPurchases)
    ServerLuckPurchases.Value = nextCount
    local tier = StoreConfig.GetLuckTierByCount(nextCount)
    
    GlobalLuck.Value = tier.Multiplier
    LuckTimer.Value = LuckTimer.Value + addSeconds
    ensureTimerRunning()

    local pName = player and player.DisplayName or "Seorang pemain"
    local msg = string.format("🎉 %s telah mengaktifkan Server Luck Boost! (Sekarang %s, +30 Menit)!", pName, tier.Display)

    if RunService:IsServer() and not RunService:IsEdit() then
        local showNotif = FishingSystem:FindFirstChild("ShowNotification")
        if showNotif and showNotif:IsA("RemoteEvent") then
            pcall(function() showNotif:FireAllClients(msg) end)
        end

        local sendChat = FishingSystem:FindFirstChild("SendChatMessage")
        if sendChat and sendChat:IsA("RemoteEvent") then
            pcall(function() sendChat:FireAllClients(msg, Color3.fromRGB(80, 240, 120)) end)
        end
    end

    return Enum.ProductPurchaseDecision.PurchaseGranted
end

function ServerLuckManager.Init()
    if LuckTimer.Value > 0 then
        ensureTimerRunning()
    else
        GlobalLuck.Value = 1
        ServerLuckPurchases.Value = 0
    end
end

return ServerLuckManager
