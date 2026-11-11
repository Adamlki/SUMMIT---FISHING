--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)

local SpectateResolver = require(script.Parent.Parent.Modules.Spectate.SpectateResolver)
local SpectateRuntime = require(script.Parent.Parent.Modules.Spectate.SpectateRuntime)

local Controller = Knit.CreateController({ Name = "SpectateController" })

local runtime

function Controller:KnitStart()
	for _ = 1, 5 do
		local ok, refsOrErr = SpectateResolver.resolve()
		if ok then
			runtime = SpectateRuntime.new(refsOrErr)
			runtime:bind()
			return
		end
		task.wait(2)
	end
end

function Controller:KnitShutdown()
	if runtime then
		runtime:destroy()
		runtime = nil
	end
end

return Controller
