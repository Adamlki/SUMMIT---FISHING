--!strict
-- ServerScriptService/Server (Clean Bootstrap)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

Players.CharacterAutoLoads = false

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = Shared:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))
local Janitor = require(Packages:WaitForChild("Janitor"))

local Core = ServerScriptService:WaitForChild("Server"):WaitForChild("Core")
local CoreModule = require(Core)

-- Inisialisasi Core
CoreModule:Init()

-- Setup player collision & character loading
local janitor = Janitor.new()
if CoreModule.Modules and CoreModule.Modules.Physics and CoreModule.Modules.Physics.NoPlayerCollision then
	CoreModule.Modules.Physics.NoPlayerCollision.enable(janitor)
end

janitor:Add(Players.PlayerAdded:Connect(function(player)
	player:LoadCharacter()
end), "Disconnect")

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		player:LoadCharacter()
	end)
end

Knit.Start():catch(function(err)
	warn("[Server] Knit gagal dimulai:", err)
	error(err, 0)
end)

game:BindToClose(function()
	janitor:Destroy()
end)
