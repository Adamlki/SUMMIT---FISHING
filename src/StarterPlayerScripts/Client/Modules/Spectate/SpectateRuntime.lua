--!nonstrict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)

local SpectateInput = require(script.Parent.SpectateInput)
local SpectateFreeze = require(script.Parent.SpectateFreeze)
local SpectateList = require(script.Parent.SpectateList)
local RuntimeHelpers = script.Parent:WaitForChild("RuntimeHelpers")
local SpectateTarget = require(RuntimeHelpers:WaitForChild("SpectateTarget"))

local SpectateRuntime = {}
SpectateRuntime.__index = SpectateRuntime

local EXCLUDED_ROLES = {
	Developer = true,
	Admin = true,
}

function SpectateRuntime.new(refs)
	local self = setmetatable({}, SpectateRuntime)
	self._refs = refs
	self._janitor = Janitor.new()
	self._targetJanitor = Janitor.new()
	self._spectating = false
	self._target = nil
	self._list = {}
	self._index = 1
	self._freeze = SpectateFreeze.new()
	return self
end

function SpectateRuntime:_updateLabels(p)
	SpectateTarget.updateLabels(self, p)
end

function SpectateRuntime:_setTarget(p)
	SpectateTarget.setTarget(self, p)
end

function SpectateRuntime:_rebuildList()
	self._list = SpectateList.build(Players.LocalPlayer, EXCLUDED_ROLES)
end

function SpectateRuntime:_refreshAfterChange()
	SpectateTarget.refreshAfterChange(self, EXCLUDED_ROLES)
end

function SpectateRuntime:_nextTarget(delta)
	SpectateTarget.stepTarget(self, delta)
end

function SpectateRuntime:_start()
	if self._spectating then
		return
	end
	self:_rebuildList()
	self._spectating = true
	self._refs.Root.Visible = true
	self._index = SpectateList.findIndex(self._list, Players.LocalPlayer)
	self:_setTarget(self._list[self._index])

	self._janitor:Add(Players.LocalPlayer.CharacterAdded:Connect(function()
		task.wait(0.1)
		if self._spectating then
			if self._target and self._target ~= Players.LocalPlayer then
				self._freeze:freeze()
			else
				self._freeze:unfreeze()
			end
		else
			self._freeze:unfreeze()
		end
	end), "Disconnect", "MyCharConn")
end

function SpectateRuntime:_stop()
	if not self._spectating then
		return
	end
	self._spectating = false
	self._refs.Root.Visible = false

	self._targetJanitor:Cleanup()
	self._janitor:Remove("MyCharConn")

	self._target = nil
	self:_updateLabels(nil)

	local cam = workspace.CurrentCamera
	local myHum = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if myHum then
		cam.CameraType = Enum.CameraType.Custom
		cam.CameraSubject = myHum
	end

	self._freeze:unfreeze()
	task.defer(function()
		self._freeze:unfreeze()
	end)
end

function SpectateRuntime:bind()
	SpectateInput.bindButton(self._janitor, self._refs.ToggleBtn, function()
		if self._spectating then
			self:_stop()
		else
			self:_start()
		end
	end)
	SpectateInput.bindButton(self._janitor, self._refs.NextBtn, function()
		self:_nextTarget(1)
	end)
	SpectateInput.bindButton(self._janitor, self._refs.PrevBtn, function()
		self:_nextTarget(-1)
	end)

	self._janitor:Add(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.P then
			if self._spectating then
				self:_stop()
			else
				self:_start()
			end
		end
	end), "Disconnect")

	self._janitor:Add(Players.PlayerAdded:Connect(function(p)
		self._janitor:Add(p:GetAttributeChangedSignal("RoleTitle"):Connect(function()
			self:_refreshAfterChange()
		end), "Disconnect")
		self:_refreshAfterChange()
	end), "Disconnect")

	self._janitor:Add(Players.PlayerRemoving:Connect(function()
		self:_refreshAfterChange()
	end), "Disconnect")

	for _, p in ipairs(Players:GetPlayers()) do
		self._janitor:Add(p:GetAttributeChangedSignal("RoleTitle"):Connect(function()
			self:_refreshAfterChange()
		end), "Disconnect")
	end

	self._refs.Root.Visible = false
	self:_updateLabels(nil)
	self._freeze:unfreeze()
end

function SpectateRuntime:destroy()
	self:_stop()
	self._janitor:Destroy()
	self._targetJanitor:Destroy()
end

return SpectateRuntime
