--!nonstrict
local StarterGui = game:GetService("StarterGui")

local DanceContextMenu = {}

local bindableRef = nil
local optionRef = nil
local currentLabel = "Sync"

local function setCore(method, value)
	return pcall(function()
		StarterGui:SetCore(method, value)
	end)
end

local function enableContextMenu()
	local ok = setCore("AvatarContextMenuEnabled", true)
	return ok
end

local function normalizeLabel(mode)
	return mode == "Unsync" and "Unsync" or "Sync"
end

local function addOption(label, bindable)
	return setCore("AddAvatarContextMenuOption", {label, bindable})
end

local function removeOption(option)
	if not option then
		return true
	end

	local ok = setCore("RemoveAvatarContextMenuOption", option)
	return ok
end

function DanceContextMenu.getMode()
	return currentLabel
end

function DanceContextMenu.init(onSelect)
	if bindableRef then
		return true, bindableRef
	end

	enableContextMenu()

	local bindable = Instance.new("BindableEvent")
	bindable.Event:Connect(function(player)
		if onSelect and player then
			onSelect(player)
		end
	end)

	local ok, err = addOption(currentLabel, bindable)
	if not ok then
		bindable:Destroy()
		return false, "Failed to add dance context menu option: " .. tostring(err)
	end

	bindableRef = bindable
	optionRef = {currentLabel, bindable}
	return true, bindable
end

function DanceContextMenu.setMode(mode)
	local nextLabel = normalizeLabel(mode)
	if not bindableRef or currentLabel == nextLabel then
		currentLabel = nextLabel
		return
	end

	local oldOptionRef = optionRef
	local newOptionRef = {nextLabel, bindableRef}

	removeOption(oldOptionRef)

	local ok = addOption(nextLabel, bindableRef)
	if ok then
		optionRef = newOptionRef
		currentLabel = nextLabel
	end
end

function DanceContextMenu.destroy()
	removeOption(optionRef)
	if bindableRef then
		bindableRef:Destroy()
	end
	bindableRef = nil
	optionRef = nil
	currentLabel = "Sync"
end

return DanceContextMenu
