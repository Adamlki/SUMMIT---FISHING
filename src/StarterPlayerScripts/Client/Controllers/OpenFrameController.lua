local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)
local Janitor = require(Packages.Janitor)
local LeftHolderMenu = require(script.Parent.Parent.Modules.OpenFrame.LeftHolderMenu)
local FrameTracker = require(script.Parent.Parent.Modules.OpenFrame.FrameTracker)

local Controller = Knit.CreateController({ Name = "OpenFrameController" })

local LocalPlayer = Players.LocalPlayer

function Controller:KnitStart()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui", 60)
	if not playerGui then
		return
	end

	local gameUI = playerGui:FindFirstChild("GameUI") or playerGui:WaitForChild("GameUI", 60)
	if not gameUI then
		return
	end

	self._janitor = Janitor.new()
	self._leftHolderMenu = LeftHolderMenu.setup(gameUI, self._janitor)
	self._frameTracker = FrameTracker.setup(gameUI, self._janitor)
end

function Controller:KnitStop()
	if self._janitor then
		self._janitor:Destroy()
		self._janitor = nil
	end
end

return Controller
