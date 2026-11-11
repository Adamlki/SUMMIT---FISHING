--!nonstrict
local DanceMenuBinder = {}

function DanceMenuBinder.bind(runtime)
	local refs = runtime._refs
	refs.Menu.Visible = false
	runtime._defaultAnchor = refs.Menu.AnchorPoint
	runtime._defaultPos = refs.Menu.Position

	if refs.ToggleBtn then
		if refs.ToggleBtn:IsA("GuiButton") then
			runtime._janitor:Add(refs.ToggleBtn.Activated:Connect(function()
				runtime:_toggleMenu()
			end), "Disconnect")
		else
			refs.ToggleBtn.Active = true
			runtime._janitor:Add(refs.ToggleBtn.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					runtime:_toggleMenu()
				end
			end), "Disconnect")
		end
	else
		runtime._log:warn("Toggle button not found")
	end

	if refs.DanceTab then
		runtime._janitor:Add(refs.DanceTab.Activated:Connect(function()
			runtime:_switchTab("Dance")
		end), "Disconnect")
	end
	if refs.PoseTab then
		runtime._janitor:Add(refs.PoseTab.Activated:Connect(function()
			runtime:_switchTab("Pose")
		end), "Disconnect")
	end
end

return DanceMenuBinder
