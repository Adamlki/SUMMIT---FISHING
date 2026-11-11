--!strict
-- ExclusiveStoreServer: Handles Gamepass verification and player attributes
-- Note: Developer Product receipts are routed through the central PurchaseRouter via ServerLuckManager
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local StoreConfig = require(FishingSystem:WaitForChild("ExclusiveStoreConfig"))
local ServerLuckManager = require(ServerScriptService.FishingServerScripts.ServerLuckManager)

-- Initialize Server Luck countdown timer if active
ServerLuckManager.Init()

-- Apply Gamepass Perks to a Player
local function applyGamepassPerks(player: Player, gpId: string)
    if gpId == "VIP" then
        player:SetAttribute("VIP", true)
        player:SetAttribute("IsVIP", true)
        player:SetAttribute("VIPLuckBoost", 5.0) -- +500% permanent luck boost
    elseif gpId == "SellAnywhere" then
        player:SetAttribute("CanSellAnywhere", true)
        player:SetAttribute("HasRemoteSell", true)
        task.spawn(function()
            local GameProfileService = nil
            pcall(function()
                GameProfileService = require(ServerScriptService:WaitForChild("Data"):WaitForChild("PetCore"):WaitForChild("FishData"))
            end)
            if GameProfileService then
                GameProfileService:SetRemoteSell(player, true)
            end
        end)
    elseif gpId == "Mutations" then
        player:SetAttribute("HasMutationsPass", true)
    elseif gpId == "SmallLuck" then
        player:SetAttribute("SmallLuckBoost", 3.0) -- +300% permanent luck boost
    elseif gpId == "AdvancedLuck" then
        player:SetAttribute("AdvancedLuckBoost", 10.0) -- +1000% permanent luck boost
    elseif gpId == "ExtraLuck" then
        player:SetAttribute("ExtraLuckBoost", 15.0) -- +1500% permanent luck boost
    end
end

-- Handle Gamepass Purchase Finished
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, gamePassId: number, wasPurchased: boolean)
    if not wasPurchased then return end

    if StoreConfig and StoreConfig.Gamepasses then
        for _, gp in ipairs(StoreConfig.Gamepasses) do
            if gp.GamePassId == gamePassId then
                applyGamepassPerks(player, gp.Id)

                local showNotif = FishingSystem:FindFirstChild("ShowNotification")
                if showNotif then
                    showNotif:FireClient(player, "🎉 Selamat! Kamu telah memiliki " .. gp.Title .. "!", 4, Color3.fromRGB(100, 255, 140))
                end
                break
            end
        end
    end
end)

-- Check owned passes and Owner privileges when player joins
local RoleConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("RoleConfig"))

local function applyOwnerAllPerks(player: Player)
    if not RoleConfig.IsOwner(player) then return end
    print("👑 [ExclusiveStoreServer] Granting ALL Shop & Gamepass Perks to Owner: " .. player.Name)
    applyGamepassPerks(player, "VIP")
    applyGamepassPerks(player, "SellAnywhere")
    task.spawn(function()
        local GameProfileService = nil
        pcall(function()
            GameProfileService = require(ServerScriptService:WaitForChild("Data"):WaitForChild("PetCore"):WaitForChild("FishData"))
        end)
        if GameProfileService then
            GameProfileService:SetRemoteSell(player, true)
        end
    end)
    applyGamepassPerks(player, "Mutations")
    applyGamepassPerks(player, "SmallLuck")
    applyGamepassPerks(player, "ExtraLuck")
    applyGamepassPerks(player, "AdvancedLuck")
    player:SetAttribute("VIP", true)
    player:SetAttribute("IsVIP", true)
    player:SetAttribute("SmallLuck", true)
    player:SetAttribute("ExtraLuck", true)
    player:SetAttribute("EdvancedLuck", true)
    player:SetAttribute("MoreMutations", true)
    player:SetAttribute("HasMutationsPass", true)
    player:SetAttribute("RemoteSell", true)
    player:SetAttribute("HasRemoteSell", true)
    player:SetAttribute("CanSellAnywhere", true)
end

Players.PlayerAdded:Connect(function(player: Player)
    applyOwnerAllPerks(player)
    if StoreConfig and StoreConfig.Gamepasses then
        for _, gp in ipairs(StoreConfig.Gamepasses) do
            if gp.GamePassId and gp.GamePassId > 0 then
                task.spawn(function()
                    local ok, owns = pcall(function()
                        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gp.GamePassId)
                    end)
                    if ok and owns then
                        applyGamepassPerks(player, gp.Id)
                    end
                end)
            end
        end
    end
end)

for _, p in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        applyOwnerAllPerks(p)
    end)
end
