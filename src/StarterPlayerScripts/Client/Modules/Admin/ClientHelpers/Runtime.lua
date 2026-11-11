--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)
local Promise = require(Packages.Promise)

local AdminInput = require(script.Parent.Input)
local AdminAnimator = require(script.Parent.Animator)
local Util = require(script.Parent.Parent.RuntimeHelpers.Util)
local SelectState = require(script.Parent.Parent.RuntimeHelpers.Actions.SelectState)
local Tabs = require(script.Parent.Parent.RuntimeHelpers.Tabs)
local Announce = require(script.Parent.Parent.RuntimeHelpers.Announce)
local Event = require(script.Parent.Parent.RuntimeHelpers.Event)
local Manager = require(script.Parent.Parent.RuntimeHelpers.Manager)
local PlayersPage = require(script.Parent.Parent.RuntimeHelpers.Players)
local Roles = require(script.Parent.Parent.RuntimeHelpers.Roles)
local Teleport = require(script.Parent.Parent.RuntimeHelpers.Teleport)
local Tools = require(script.Parent.Parent.RuntimeHelpers.Tools)
local Logs = require(script.Parent.Parent.RuntimeHelpers.Logs)
local ServerPage = require(script.Parent.Parent.RuntimeHelpers.Server)
local RuntimeHelpers = script.Parent:WaitForChild("RuntimeHelpers")
local ServiceBinder = require(RuntimeHelpers:WaitForChild("ServiceBinder"))
local TextBoxBinder = require(RuntimeHelpers:WaitForChild("TextBoxBinder"))
local MenuState = require(RuntimeHelpers:WaitForChild("MenuState"))
local PageLoader = require(RuntimeHelpers:WaitForChild("PageLoader"))

local AdminRuntime = {}
AdminRuntime.__index = AdminRuntime


function AdminRuntime.new(refs, service)
	local self = setmetatable({}, AdminRuntime)
	self._refs = refs
	self._service = service
	self._janitor = Janitor.new()
	self._animator = AdminAnimator.new(refs.Root)
	self._visible = false
	self._announceScope = "Server"
	self._bootstrap = nil
	self._promise = Promise
	self._logMax = 100
	self._logEntries = {}
	self._logCounter = 0

	self._selected = SelectState.new()

	self:_bindUI()
	self:_bindUptime()
	self:_bindAnnouncements()
	self:_bindNotices()
	self:_loadBootstrap()

	return self
end

function AdminRuntime:_bindAnnouncements()
	ServiceBinder.bindAnnouncements(self)
end

function AdminRuntime:_bindNotices()
	ServiceBinder.bindNotices(self)
end

function AdminRuntime:_bindUI()
	local refs = self._refs
	if refs.Menu then
		refs.Menu.Visible = false
	end
	refs.Root.Visible = false

	AdminInput.bindToggle(self._janitor, refs.Toggle, function()
		self:Toggle()
	end)
	AdminInput.bindButton(self._janitor, refs.Close, function()
		if self._visible then
			self:Toggle()
		end
	end)
	AdminInput.bindTabToggle(self._janitor, function()
		self:Toggle()
	end)

	self:_bindLeftTabs()
	self:_bindAnnounce()
	self:_bindEvent()
	self:_bindManager()
	self:_bindPlayers()
	self:_bindRoles()
	self:_bindLogs()
	self:_bindServer()
	self:_bindTeleport()
	self:_bindTools()
	self:_bindTextBoxes()
end

function AdminRuntime:_bindTextBox(box)
	TextBoxBinder.bindTextBox(self, box)
end

function AdminRuntime:_bindTextBoxes()
	TextBoxBinder.bindAll(self)
end

function AdminRuntime:_bindLeftTabs()
	Tabs.bind(self)
end

function AdminRuntime:_hideAllPages()
	MenuState.hideAllPages(self)
end

function AdminRuntime:_applyTabVisual(activePage)
	MenuState.applyTabVisual(self, activePage)
end

function AdminRuntime:_applySelectVisual(button, selected)
	Util.applySelectVisual(button, selected)
end

function AdminRuntime:_makeSingleSelect()
	return Util.makeSingleSelect(function(button, selected)
		self:_applySelectVisual(button, selected)
	end)
end

function AdminRuntime:_showPage(name)
	MenuState.showPage(self, name)
end

function AdminRuntime:_loadBootstrap()
	PageLoader.load(self)
end

function AdminRuntime:_applyBootstrap()
	PageLoader.apply(self)
end

function AdminRuntime:_bindUptime()
	ServiceBinder.bindUptime(self)
end

function AdminRuntime:_updateAnnounceCounter()
	local page = self._refs.Pages.Announce
	if not page or not page.Title then return end
	local maxLen = (self._bootstrap and self._bootstrap.maxAnnounce) or 100
	local text = ""
	if page.InputText and page.InputText:IsA("TextBox") then
		text = page.InputText.Text or ""
	elseif page.Input and page.Input:IsA("TextLabel") then
		text = page.Input.Text or ""
	end
	page.Title.Text = string.format("%d/%d", #text, maxLen)
end

function AdminRuntime:_bindAnnounce()
	Announce.bind(self)
end

function AdminRuntime:_sendAnnounce()
	Announce.send(self)
end

function AdminRuntime:_bindEvent()
	Event.bind(self)
end

function AdminRuntime:_sendEvent()
	Event.send(self)
end

function AdminRuntime:_setLogs(entries)
	Logs.set(self, entries)
end

function AdminRuntime:_pushLog(entry)
	Logs.push(self, entry)
end

function AdminRuntime:_bindLogs()
	Logs.bind(self)
end

function AdminRuntime:_bindServer()
	ServerPage.bind(self)
end

function AdminRuntime:_buildPlayerList(list, template, onSelect, onRemove)
	return Util.buildPlayerList({
		janitor = self._janitor,
		list = list,
		template = template,
		onSelect = onSelect,
		onRemove = onRemove,
		applySelect = function(button, selected)
			self:_applySelectVisual(button, selected)
		end,
	})
end

function AdminRuntime:_getAmountFromInput(page)
	if not page then return 0 end
	if page.ValueText and page.ValueText:IsA("TextBox") then
		return tonumber(page.ValueText.Text) or 0
	end
	local input = page.InputText
	if input and input:IsA("TextBox") then
		return tonumber(input.Text) or 0
	end
	if page.Input and page.Input:IsA("TextLabel") then
		return tonumber(page.Input.Text) or 0
	end
	return 0
end

function AdminRuntime:_bindManager()
	Manager.bind(self)
end

function AdminRuntime:_bindPlayers()
	PlayersPage.bind(self)
end

function AdminRuntime:_buildRoleButtons(roles)
	Roles.buildButtons(self, roles)
end

function AdminRuntime:_bindRoles()
	Roles.bind(self)
end

function AdminRuntime:_buildTeleportButtons(destinations)
	Teleport.buildButtons(self, destinations)
end

function AdminRuntime:_bindTeleport()
	Teleport.bind(self)
end

function AdminRuntime:_buildToolButtons(tools)
	Tools.buildButtons(self, tools)
end

function AdminRuntime:_bindTools()
	Tools.bind(self)
end

function AdminRuntime:Toggle()
	MenuState.toggle(self)
end

function AdminRuntime:Destroy()
	if self._janitor then
		self._janitor:Destroy()
		self._janitor = nil
	end
end

return AdminRuntime
