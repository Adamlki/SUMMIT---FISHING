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

-- Apply Gamepass Perks to a Player. Accept both config keys and legacy perk names.
local function applyGamepassPerks(player: Player, passKey: string)
    if passKey == "VIP" then
        player:SetAttribute("VIP", true)
        player:SetAttribute("IsVIP", true)
        player:SetAttribute("VIPLuckBoost", 5.0) -- +500% permanent luck boost
    elseif passKey == "RemoteSell" or passKey == "SellAnywhere" then
        player:SetAttribute("RemoteSell", true)
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
    elseif passKey == "MoreMutations" or passKey == "Mutations" then
        player:SetAttribute("MoreMutations", true)
        player:SetAttribute("HasMutationsPass", true)
    elseif passKey == "SmallLuck" then
        player:SetAttribute("SmallLuck", true)
    elseif passKey == "ExtraLuck" then
        player:SetAttribute("ExtraLuck", true)
    elseif passKey == "EdvancedLuck" or passKey == "AdvancedLuck" then
        player:SetAttribute("EdvancedLuck", true)
    end
end

-- Handle Gamepass Purchase Finished
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, gamePassId: number, wasPurchased: boolean)
    if not wasPurchased then return end

    if StoreConfig and StoreConfig.Gamepasses then
        for passKey, gp in pairs(StoreConfig.Gamepasses) do
            if type(gp) == "table" and gp.PassId == gamePassId then
                applyGamepassPerks(player, passKey)

                local showNotif = FishingSystem:FindFirstChild("ShowNotification")
                if showNotif then
                    showNotif:FireClient(player, "🎉 Selamat! Kamu telah memiliki " .. (gp.Title or passKey) .. "!", 4, Color3.fromRGB(100, 255, 140))
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
    for _, passKey in ipairs({ "VIP", "RemoteSell", "MoreMutations", "SmallLuck", "ExtraLuck", "EdvancedLuck" }) do
        applyGamepassPerks(player, passKey)
    end
end

Players.PlayerAdded:Connect(function(player: Player)
    applyOwnerAllPerks(player)
    if StoreConfig and StoreConfig.Gamepasses then
        for passKey, gp in pairs(StoreConfig.Gamepasses) do
            if type(gp) == "table" and type(gp.PassId) == "number" and gp.PassId > 0 then
                local passId = gp.PassId
                local perkKey = passKey
                task.spawn(function()
                    local ok, owns = pcall(function()
                        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
                    end)
                    if ok and owns and player.Parent then
                        applyGamepassPerks(player, perkKey)
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
