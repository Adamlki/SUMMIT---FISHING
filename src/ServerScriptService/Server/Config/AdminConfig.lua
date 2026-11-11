--!nonstrict
-- Compatibility proxy: canonical config lives in ServerScriptService.Configs.
return require(game:GetService("ServerScriptService"):WaitForChild("Configs"):WaitForChild("AdminPrivateConfig"))
