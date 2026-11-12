--!strict
-- Server-private config index. Feature configs stay under Server/Config; this is the
-- single require point for DataStore, admin, and anti-cheat/network settings.
local SharedConfigs = game:GetService("ReplicatedStorage"):WaitForChild("Configs")

local Config = {
	DataStore = require(script.Parent:WaitForChild("DataStoreConfig")),
	Admin = require(script.Parent:WaitForChild("AdminPrivateConfig")),
	AntiCheat = require(script.Parent:WaitForChild("AntiCheatConfig")),
	Monetization = require(SharedConfigs:WaitForChild("MonetizationConfig")),
	FeatureFlags = require(SharedConfigs:WaitForChild("FeatureFlags")),
}

return Config
