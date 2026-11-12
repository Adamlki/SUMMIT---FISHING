-- ServerScriptService/FishingServerScripts/AdminLuckManager
local FeatureFlags = require(game:GetService("ReplicatedStorage"):WaitForChild("Configs"):WaitForChild("FeatureFlags"))
if not FeatureFlags.AdminLuck then return end

print("🔒 [AdminLuck] Security System Active.")

local Config = require(script.Parent.Modules.AdminLuckConfig)
print("[AdminLuck] Server ID:", Config.SERVER_ID)

local Commands = require(script.Parent.Modules.AdminLuckCommands)
local Remotes = require(script.Parent.Modules.AdminLuckRemotes)
local PlayerActions = require(script.Parent.Modules.AdminLuckPlayerActions)

Commands.Start()
Remotes.Start()
PlayerActions.Start()
