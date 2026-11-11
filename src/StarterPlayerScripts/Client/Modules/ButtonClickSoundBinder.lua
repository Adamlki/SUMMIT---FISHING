--!nonstrict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)
local ButtonClickSoundConfig = require(Shared.Config.UI.ButtonClickSoundConfig)

local ButtonClickSoundBinder = {}

local function isSupportedButton(instance)
	return instance and (instance:IsA("TextButton") or instance:IsA("ImageButton"))
end

local function getExtraSoundKinds()
	local kinds = {}
	for kind in pairs(ButtonClickSoundConfig) do
		if kind ~= "ButtonClick" and kind ~= "ButtonHover" then
			table.insert(kinds, kind)
		end
	end
	table.sort(kinds)
	return kinds
end

local function hasCustomTaggedSound(button, kinds)
	for _, kind in ipairs(kinds) do
		if CollectionService:HasTag(button, kind) then
			return true
		end
	end
	return false
end

local function bindButton(state, button, tagName)
	if not isSupportedButton(button) then
		return
	end
	if tagName == "ButtonOpen" and button.Name == "Open" then
		return
	end
	if tagName == "ButtonClick" and hasCustomTaggedSound(button, state.extraKinds) then
		return
	end
	local bucket = state.bound[tagName]
	if bucket[button] then
		return
	end

	local buttonJanitor = Janitor.new()
	bucket[button] = buttonJanitor

	if tagName == "ButtonClick" then
		buttonJanitor:Add(button.Activated:Connect(function()
			state.onTriggered(tagName, button)
		end), "Disconnect")
	elseif tagName == "ButtonHover" then
		buttonJanitor:Add(button.MouseEnter:Connect(function()
			state.onTriggered(tagName, button)
		end), "Disconnect")
	end

	buttonJanitor:Add(button.Destroying:Connect(function()
		local current = bucket[button]
		if current then
			current:Destroy()
			bucket[button] = nil
		end
	end), "Disconnect")
end

local function bindTagged(state, tagName)
	for _, instance in ipairs(CollectionService:GetTagged(tagName)) do
		bindButton(state, instance, tagName)
	end

	state.janitor:Add(CollectionService:GetInstanceAddedSignal(tagName):Connect(function(instance)
		bindButton(state, instance, tagName)
	end), "Disconnect")

	state.janitor:Add(CollectionService:GetInstanceRemovedSignal(tagName):Connect(function(instance)
		local buttonJanitor = state.bound[tagName][instance]
		if buttonJanitor then
			buttonJanitor:Destroy()
			state.bound[tagName][instance] = nil
		end
	end), "Disconnect")
end

function ButtonClickSoundBinder.start(onTriggered)
	local extraKinds = getExtraSoundKinds()
	local state = {
		janitor = Janitor.new(),
		bound = {
			ButtonClick = {},
			ButtonHover = {},
		},
		extraKinds = extraKinds,
		onTriggered = onTriggered,
	}

	for _, kind in ipairs(extraKinds) do
		state.bound[kind] = {}
	end

	bindTagged(state, "ButtonClick")
	bindTagged(state, "ButtonHover")
	for _, kind in ipairs(extraKinds) do
		bindTagged(state, kind)
	end

	function state:Destroy()
		for _, bucket in pairs(self.bound) do
			for button, buttonJanitor in pairs(bucket) do
				buttonJanitor:Destroy()
				bucket[button] = nil
			end
		end
		self.janitor:Destroy()
	end

	return state
end

return ButtonClickSoundBinder
