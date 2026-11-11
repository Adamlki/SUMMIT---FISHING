--!nonstrict
local Playback = require(script.Parent.Playback)

local Populate = {}

local function clearButtons(scrollFrame)
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

function Populate.run(runtime)
	local template = runtime._assets.Template
	local danceAnims = runtime._assets.DanceAnimations

	clearButtons(runtime._refs.DanceScroll)
	clearButtons(runtime._refs.PoseScroll)

	for _, anim in ipairs(danceAnims:GetChildren()) do
		if not anim:IsA("Animation") then
			continue
		end
		local btn = template:Clone()
		btn.Name = anim.Name
		btn.Text = anim.Name
		btn.Visible = true
		btn.BackgroundColor3 = runtime._colors.Default
		btn.Parent = runtime._refs.DanceScroll

		runtime._janitor:Add(btn.Activated:Connect(function()
			Playback.playManual(runtime, anim, true, btn)
		end), "Disconnect")
		runtime._janitor:Add(btn, "Destroy")
	end

	for _, anim in ipairs(runtime._assets.PoseAnimations:GetChildren()) do
		if not anim:IsA("Animation") then
			continue
		end
		local btn = template:Clone()
		btn.Name = anim.Name
		btn.Text = anim.Name
		btn.Visible = true
		btn.BackgroundColor3 = runtime._colors.Default
		btn.Parent = runtime._refs.PoseScroll

		runtime._janitor:Add(btn.Activated:Connect(function()
			Playback.playManual(runtime, anim, true, btn)
		end), "Disconnect")
		runtime._janitor:Add(btn, "Destroy")
	end
end

return Populate
