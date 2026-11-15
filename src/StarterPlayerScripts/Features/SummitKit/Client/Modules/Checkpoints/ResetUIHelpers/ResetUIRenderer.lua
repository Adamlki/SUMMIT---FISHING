--!nonstrict
local Panel = require(script.Parent.Parent.Parent.UI.Panel)

local ResetUIRenderer = {}

function ResetUIRenderer.initHidden(refs)
	if not refs or not refs.menuFrame then return end
	local menuFrame = refs.menuFrame
	menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	menuFrame.Position = UDim2.fromScale(0.5, 0.5)
	menuFrame.Visible = false
end

function ResetUIRenderer.setVisible(refs, state: boolean, instant: boolean?)
	if not refs or not refs.menuFrame then return end
	if state then
		if instant then
			refs.menuFrame.Visible = true
		else
			Panel.open(refs.menuFrame)
		end
	elseif instant then
		-- Tetap lewat Panel supaya backdrop & HUD focus ikut ditutup.
		Panel.hideNow(refs.menuFrame)
	else
		Panel.close(refs.menuFrame)
	end
end

function ResetUIRenderer.toggle(refs)
	if not refs or not refs.menuFrame then return end
	Panel.toggle(refs.menuFrame)
end

return ResetUIRenderer
