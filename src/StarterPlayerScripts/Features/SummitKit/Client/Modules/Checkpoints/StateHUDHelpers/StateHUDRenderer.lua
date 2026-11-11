--!nonstrict
local StateHUDRenderer = {}

function StateHUDRenderer.hideAll(frames)
	if not frames then
		return
	end
	for _, f in pairs(frames) do
		if f then
			f.Visible = false
		end
	end
end

function StateHUDRenderer.render(frames, _state)
	if not frames then
		return
	end
	if frames.CheckpointCount then
		frames.CheckpointCount.Visible = false
	end
end

return StateHUDRenderer
