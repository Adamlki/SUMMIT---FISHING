--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Promise = require(Packages.Promise)
local TableUtil = require(Packages.TableUtil)

local DonationsFetcher = {}

function DonationsFetcher.fetchAll(onComplete, ignoreSet)
    local function fetchPageAccum()
        local products = {}
        local ok, pages = pcall(function()
            return MarketplaceService:GetDeveloperProductsAsync()
        end)
        if not ok or not pages then
            return products
        end
        local function appendPage(page)
            for _, info in ipairs(page:GetCurrentPage()) do
                local rawId = info.ProductId
                local productId = tonumber(rawId) or rawId
                local name = info.Name or ("Product " .. tostring(productId))
                local price = info.PriceInRobux

                local okDetail, detail = pcall(function()
                    return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
                end)
                if okDetail and detail then
                    name = detail.Name or name
                    price = detail.PriceInRobux or price
                end
                local lowerName = string.lower(tostring(name))
                local isGiftName = lowerName:find("gift vip", 1, true) ~= nil
                if (ignoreSet and (ignoreSet[productId] or ignoreSet[tostring(productId)])) or isGiftName then
                    continue
                end

                table.insert(products, {
                    ProductId = productId,
                    Name = name,
                    Price = price,
                })
            end
        end

        appendPage(pages)
        while pages.IsFinished == false do
            pages:AdvanceToNextPageAsync()
            appendPage(pages)
        end
        return products
    end

    return Promise.new(function(resolve)
        resolve(fetchPageAccum())
    end):andThen(function(products)
        if onComplete then
            onComplete(TableUtil.Copy(products))
        end
        return products
    end)
end

return DonationsFetcher
