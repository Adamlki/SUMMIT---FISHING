--!nonstrict
-- ============================================================
-- Title/Modules/Runtime (ModuleScript)
-- Late-bound Knit OverheadService access (profile source).
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Knit = require(Shared:WaitForChild("Packages"):WaitForChild("Knit"))

local Runtime = {}

local OverheadService = nil

-- Tunggu OverheadService aktif melalui Knit
function Runtime.Start()
	task.spawn(function()
		Knit.OnStart():await()
		OverheadService = Knit.GetService("OverheadService")
	end)
end

function Runtime.getOverheadService()
	return OverheadService
end

function Runtime.getProfile(player)
	if not OverheadService or not OverheadService.profiles then
		return nil
	end
	return OverheadService.profiles[player]
end

return Runtime
