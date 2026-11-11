--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)

local ShopResolver = require(script.Parent.ShopResolver)
local ShopBinder = require(script.Parent.ShopBinder)
local ShopState = require(script.Parent.ShopState)

local ShopUI = {}

local janitor = Janitor.new()
local state = ShopState.new()
local initialized = false

function ShopUI.init(vipService, shopService)
    if initialized then
        return true
    end
    local ok, refsOrErr = ShopResolver.resolve()
    if not ok then
        warn("[ShopUI] " .. tostring(refsOrErr))
        return false
    end

    if vipService and vipService.Config then
        if vipService.Config.Get then
            state:setConfig(vipService.Config:Get())
        end
        if vipService.Config.Observe then 
            janitor:Add(vipService.Config:Observe(function(cfg)
                state:setConfig(cfg)
            end), "Disconnect")
        end
    end

    if shopService and shopService.Catalog then
        if shopService.Catalog.Get then
            state:setCatalog(shopService.Catalog:Get())
        end
        if shopService.Catalog.Observe then
            janitor:Add(shopService.Catalog:Observe(function(catalog)
                state:setCatalog(catalog)
            end), "Disconnect")
        end
    end

    if shopService and shopService.OwnedTools then
        if shopService.OwnedTools.Get then
            state:setOwnedTools(shopService.OwnedTools:Get())
        end
        if shopService.OwnedTools.Observe then
            janitor:Add(shopService.OwnedTools:Observe(function(ownedTools)
                state:setOwnedTools(ownedTools)
            end), "Disconnect")
        end
    end

    janitor:Add(ShopBinder.bind(refsOrErr, state, vipService, shopService), "Destroy")
    initialized = true
    return true
end

function ShopUI.destroy()
    janitor:Destroy()
    initialized = false
end

return ShopUI
