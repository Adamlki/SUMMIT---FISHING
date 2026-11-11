--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)

local HideGuiState = require(script.Parent.HideGuiState)
local HideGuiVisibility = require(script.Parent.HideGuiVisibility)

local HideGuiRuntime = {}
HideGuiRuntime.__index = HideGuiRuntime

function HideGuiRuntime.new(refs)
	local self = setmetatable({}, HideGuiRuntime)
	self._refs = refs
	self._janitor = Janitor.new()
	self._hidden = false
	self._savedVisible = {}
	return self
end

function HideGuiRuntime:_setHiddenState(active)
	local button = self._refs.HideBtn
	if not button then
		return
	end

	button:SetAttribute("GuiHidden", active == true)
end

function HideGuiRuntime:_hideGui()
	table.clear(self._savedVisible)

	local protected = HideGuiVisibility.buildProtectedSet(self)
	for _, descendant in ipairs(self._refs.GameUI:GetDescendants()) do
		if descendant:IsA("GuiObject") and not protected[descendant] then
			self._savedVisible[descendant] = HideGuiState.closeOpenGui(self, descendant)
			descendant.Visible = false
		end
	end

	self._hidden = true
	self:_setHiddenState(true)
end

function HideGuiRuntime:_showGui()
	HideGuiState.restore(self._savedVisible)
	table.clear(self._savedVisible)
	self._hidden = false
	self:_setHiddenState(false)
end

function HideGuiRuntime:Toggle()
	if self._hidden then
		self:_showGui()
	else
		self:_hideGui()
	end
end

function HideGuiRuntime:Bind()
	self:_setHiddenState(false)
	self._janitor:Add(self._refs.HideBtn.Activated:Connect(function()
		self:Toggle()
	end), "Disconnect")
end

function HideGuiRuntime:Destroy()
	if self._hidden then
		self:_showGui()
	end
	self._janitor:Destroy()
end

return HideGuiRuntime
