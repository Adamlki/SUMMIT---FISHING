--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local TableUtil = require(Packages.TableUtil)

local VipConfig = require(script.Parent.VipConfig)
local ToolsConfig = require(script.Parent.ToolsConfig)

local ignoredProductIds = TableUtil.Copy({
    VipConfig.GiftProductId,
})

for _, tool in ipairs(ToolsConfig.Tools or {}) do
    local giftProductId = tonumber(tool.GiftProductId)
    if giftProductId and giftProductId > 0 then
        table.insert(ignoredProductIds, giftProductId)
    end
end

local DonationsConfig = {
	DataStoreName = "DonationsLeaderboard_V1",
    MaxRows = 20,
    FetchLimit = 100,
    MinValue = 1,
    UpdateInterval = 120,
    Podium = {
        RankColor1 = Color3.fromRGB(255, 215, 0),
        RankColor2 = Color3.fromRGB(192, 192, 192),
        RankColor3 = Color3.fromRGB(205, 127, 50),
        Animations = {
            [1] = {
                R15 = "rbxassetid://115134008219873",
                R6 = "rbxassetid://182436935",
            },
            [2] = {
                R15 = "rbxassetid://507777268",
                R6 = "rbxassetid://182436935",
            },
            [3] = {
                R15 = "rbxassetid://507777268",
                R6 = "rbxassetid://182436935",
            },
        },
    },
    IgnoredProductIds = ignoredProductIds,
}

return DonationsConfig
