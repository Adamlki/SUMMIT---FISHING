--!nonstrict

local ShopRenderer = {}
local ShopHelpers = script.Parent:WaitForChild("ShopHelpers")
local PlayerListRenderer = require(ShopHelpers:WaitForChild("PlayerListRenderer"))
local ToolListRenderer = require(ShopHelpers:WaitForChild("ToolListRenderer"))

function ShopRenderer.setVisible(refs, showFeature, showSelection, showShop)
    if refs.shopFeature then
        refs.shopFeature.Visible = showFeature == true
    end
    if refs.playerSelections then
        refs.playerSelections.Visible = showSelection == true
    end
    if refs.shopFrame then
        refs.shopFrame.Visible = showShop == true
    end
end

function ShopRenderer.clearPlayerList(listFrame)
    PlayerListRenderer.clear(listFrame)
end

function ShopRenderer.renderPlayers(refs, _state, onSelect)
    PlayerListRenderer.render(refs, onSelect)
end

function ShopRenderer.renderTools(refs, state, _onBuy, _onGift)
    return ToolListRenderer.render(refs, state)
end

return ShopRenderer
