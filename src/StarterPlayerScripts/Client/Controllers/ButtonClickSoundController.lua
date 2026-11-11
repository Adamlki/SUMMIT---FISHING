--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)

local ButtonClickSound = require(script.Parent.Parent.Modules.ButtonClickSound)

local Controller = Knit.CreateController({ Name = "ButtonClickSoundController" })

function Controller:KnitStart()
	self._runtime = ButtonClickSound.init()
end

function Controller:KnitStop()
	ButtonClickSound.destroy()
	self._runtime = nil
end

return Controller
