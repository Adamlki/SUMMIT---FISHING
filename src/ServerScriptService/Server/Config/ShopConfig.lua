--!nonstrict
local DataStoreConfig = require(game:GetService("ServerScriptService"):WaitForChild("Configs"):WaitForChild("DataStoreConfig"))

return {
    ProfileKey = DataStoreConfig.Stores.ShopToolsData,
    ToolsFolderName = "ShopTools",
}
