--!nonstrict
local Players = game:GetService("Players")

local ShopResolver = {}

function ShopResolver.resolve()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui", 60)
    local gameUI = playerGui and playerGui:WaitForChild("GameUI", 60)

    local component = gameUI:FindFirstChild("Component")
    local buttons = component and component:FindFirstChild("Buttons")
    local leftHolder = buttons and buttons:FindFirstChild("LeftHolder")
    local toggleBtn = leftHolder and leftHolder:FindFirstChild("Shop")

    local menus = gameUI:FindFirstChild("Menus")
    local shopFeature = menus and menus:FindFirstChild("ShopFeature")
    local playerSelections = shopFeature and shopFeature:FindFirstChild("PlayerSelections")
    local shopFrame = shopFeature and shopFeature:FindFirstChild("Shop")

    local psHeader = playerSelections and playerSelections:FindFirstChild("Header")
    local psClose = psHeader and psHeader:FindFirstChild("Close")
    local psContainer = playerSelections and playerSelections:FindFirstChild("Container")
    local psList = psContainer and psContainer:FindFirstChild("List")
    local psTemplate = psList and psList:FindFirstChild("Template")

    local shopBg = shopFrame and shopFrame:FindFirstChild("Background")
    local shopHeader = shopBg and shopBg:FindFirstChild("Header")
    local shopClose = shopHeader and shopHeader:FindFirstChild("Close")
    local shopContainer = shopBg and shopBg:FindFirstChild("Container")
    local shopList = shopContainer and shopContainer:FindFirstChild("List")
    local vipItem = shopList and shopList:FindFirstChild("VIP")
    local vipActions = vipItem and vipItem:FindFirstChild("Actions")
    local vipGift = (vipActions and vipActions:FindFirstChild("Gift")) or (vipItem and vipItem:FindFirstChild("Gift"))
    local vipBuy = (vipActions and vipActions:FindFirstChild("Buy")) or (vipItem and vipItem:FindFirstChild("Buy"))
    local toolsFrame = shopList and shopList:FindFirstChild("Tools")
    local toolTemplate = toolsFrame and toolsFrame:FindFirstChild("Template")

    if not gameUI or not menus or not shopFeature or not playerSelections or not shopFrame then
        return false, "Shop UI structure tidak lengkap"
    end

    return true, {
        gameUI = gameUI,
        toggleBtn = toggleBtn,
        shopFeature = shopFeature,
        playerSelections = playerSelections,
        playerSelectionsClose = psClose,
        playerList = psList,
        playerTemplate = psTemplate,
        shopFrame = shopFrame,
        shopClose = shopClose,
        vipGift = vipGift,
        vipBuy = vipBuy,
        shopList = shopList,
        toolsFrame = toolsFrame,
        toolTemplate = toolTemplate,
    }
end

return ShopResolver
