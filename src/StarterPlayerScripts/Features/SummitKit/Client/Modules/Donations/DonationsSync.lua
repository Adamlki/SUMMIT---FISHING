--!nonstrict
local Knit = nil

local DonationsSync = {}

local function ensureKnit()
    if Knit then
        return Knit
    end

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Shared = ReplicatedStorage.Shared
    local Packages = Shared.Packages
    Knit = require(Packages.Knit)
    return Knit
end

local function refreshProducts(state, view, renderer)
    state:RefreshIgnoreSet()
    renderer.applyProducts(state, view, state.ignoreSet)
    renderer.ensureProducts(state, view, state.ignoreSet)
end

function DonationsSync.bind(janitor, state, view, renderer)
    local knit = ensureKnit()

    local okVip, vipService = pcall(function()
        return knit.GetService("VipService")
    end)
    if okVip and vipService and vipService.Config then
        if vipService.Config.Get then
            state:ApplyVipConfig(vipService.Config:Get())
        end

        janitor:Add(vipService.Config:Observe(function(cfg)
            state:ApplyVipConfig(cfg)
            refreshProducts(state, view, renderer)
        end), "Disconnect")
    end

    local okShop, shopService = pcall(function()
        return knit.GetService("ShopService")
    end)
    if okShop and shopService and shopService.Catalog then
        if shopService.Catalog.Get then
            state:ApplyShopCatalog(shopService.Catalog:Get())
        end

        janitor:Add(shopService.Catalog:Observe(function(catalog)
            state:ApplyShopCatalog(catalog)
            refreshProducts(state, view, renderer)
        end), "Disconnect")
    end

    refreshProducts(state, view, renderer)
end

return DonationsSync
