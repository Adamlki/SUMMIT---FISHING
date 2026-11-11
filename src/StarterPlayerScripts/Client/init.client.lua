--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)

print("[ClientBootstrap] Starting Knit Client...")
local controllersFolder = script:WaitForChild("Controllers", 10)
if not controllersFolder then
	warn("[ClientBootstrap] Controllers folder not found!")
	return
end

for _, module in ipairs(controllersFolder:GetChildren()) do 
	if module:IsA("ModuleScript") then
		local ok, err = pcall(function()
			require(module)
		end)
		if not ok then 
			warn(string.format("[ClientBootstrap] Failed to require controller %s: %s", module.Name, tostring(err)))
		end
	end
end

Knit.Start():andThen(function()
	print("[ClientBootstrap] ✅ Knit started successfully!")
end):catch(function(err)
	warn("[ClientBootstrap] ❌ Knit start failed!:", err)
    error(err, 0)
end)
