--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)

local ResetMenuBinder = {}

local function connectButton(janitor, btn, callback)
	if not btn then return end
	btn.Active = true
	local debounce = false
	local function trigger()
		if debounce then return end
		debounce = true
		task.delay(0.05, function()
			debounce = false
		end)
		callback()
	end

	if btn:IsA("GuiButton") then
		janitor:Add(btn.Activated:Connect(trigger), "Disconnect")
	else
		janitor:Add(btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				trigger()
			end
		end), "Disconnect")
	end
end

function ResetMenuBinder.bind(refs, onToggle, onClose, onConfirm)
	local janitor = Janitor.new()
	connectButton(janitor, refs.toggleBtn, onToggle)
	connectButton(janitor, refs.noBtn, onClose)
	connectButton(janitor, refs.yesBtn, onConfirm)
	return janitor
end

return ResetMenuBinder
