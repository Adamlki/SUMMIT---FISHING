--!nonstrict
-- Bootstrap SpinService: daftarkan route, load data, dan hook pemain.
local ServerScriptService = game:GetService("ServerScriptService")

local SpinService = require(ServerScriptService:WaitForChild("SpinService"))
SpinService.Init()
