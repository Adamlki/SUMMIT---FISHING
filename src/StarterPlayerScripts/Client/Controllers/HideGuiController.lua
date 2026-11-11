--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)
local Janitor = require(Packages.Janitor)

local HideGuiResolver = require(script.Parent.Parent.Modules.HideGui.HideGuiResolver)
local HideGuiRuntime = require(script.Parent.Parent.Modules.HideGui.HideGuiRuntime)
local Logger = require(script.Parent.Parent.Modules.Logger)

local Controller = Knit.CreateController({ Name = "HideGuiController" })

local log = Logger.new("HideGuiController", false)

function Controller:KnitStart()
	local ok, refsOrErr
	for _ = 1, 5 do
		ok, refsOrErr = HideGuiResolver.resolve()
		if ok then
			break
		end
		task.wait(2)
	end

	if not ok then
		log:warn("HideGuiResolver failed: " .. tostring(refsOrErr))
		return
	end

	self._janitor = Janitor.new()
	self._runtime = HideGuiRuntime.new(refsOrErr)
	self._runtime:Bind()
	self._janitor:Add(self._runtime, "Destroy")
end

function Controller:KnitStop()
	if self._janitor then
		self._janitor:Destroy()
		self._janitor = nil
	end
	self._runtime = nil
end

return Controller
