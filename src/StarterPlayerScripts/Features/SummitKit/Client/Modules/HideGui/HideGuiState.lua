--!nonstrict
local HideGuiState = {}

function HideGuiState.closeOpenGui(runtime, gui)
	local shouldRestoreVisible = gui.Visible
	if gui:GetAttribute("IsOpen") == true then
		shouldRestoreVisible = false
		gui:SetAttribute("IsOpen", false)
	end
	return shouldRestoreVisible
end

function HideGuiState.restore(savedVisible)
	for gui, visible in pairs(savedVisible) do
		if gui and gui.Parent then
			gui.Visible = visible
		end
	end
end

return HideGuiState
