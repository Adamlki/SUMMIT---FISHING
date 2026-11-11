--!strict
-- Server-Private config aggregator.
local Configs = {}

Configs.AdminPrivateConfig = require(script:WaitForChild("AdminPrivateConfig"))
Configs.AntiCheatConfig = require(script:WaitForChild("AntiCheatConfig"))
Configs.DataStoreConfig = require(script:WaitForChild("DataStoreConfig"))

return Configs
