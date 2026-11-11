--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DonationsRenderer = {}

local function getDonationProducts()
    local ok, config = pcall(function()
        local mod = ReplicatedStorage:FindFirstChild("DonationConfig")
            or (ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Config") and ReplicatedStorage.Shared.Config:FindFirstChild("DonationsConfig"))
        return mod and require(mod)
    end)
    if ok and config and config.Products then
        return config.Products
    end
    return nil
end

function DonationsRenderer.applyProducts(state, view, ignoreSet)
    if not view then
        return
    end

    local products = getDonationProducts()
    if products and #products > 0 then
        view:setProducts(products)
        return
    end

    -- Fallback jika config belum dimuat
    local filteredProducts = {}
    for _, product in ipairs(state and state.products or {}) do
        table.insert(filteredProducts, product)
    end
    view:setProducts(filteredProducts)
end

function DonationsRenderer.ensureProducts(state, view, ignoreSet)
    DonationsRenderer.applyProducts(state, view, ignoreSet)
end

return DonationsRenderer
