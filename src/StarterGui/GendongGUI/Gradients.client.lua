--[[
	UI STROKE ANIMATOR ADVANCED (OPTIMIZED CACHED COLLECTION)
	Location: StarterGui > GendongGUI > Gradients
	
	Features:
	✅ Smooth gradient rotation
	✅ Pulsing effect
	✅ High-performance Cached Collection (0 frame allocations, 0 tree traversals per frame)
]]

local ScreenGui = script.Parent
local RunService = game:GetService("RunService")

-- ✅ SETTINGS - BISA DIUBAH
local rotationSpeed = 1 -- Kecepatan putar gradient
local pulseEnabled = true -- Pulse effect ON/OFF
local pulseSpeed = 2 -- Kecepatan pulse
local pulseMin = 0 -- Transparency minimal
local pulseMax = 0 -- Transparency maksimal

-- Cached collection of targets: { stroke = UIStroke, gradient = UIGradient }
local cachedTargets = {}

local function registerDescendant(descendant)
	if descendant:IsA("UIStroke") then
		local uiGradient = descendant:FindFirstChildOfClass("UIGradient")
		table.insert(cachedTargets, { stroke = descendant, gradient = uiGradient })
	elseif descendant:IsA("UIGradient") and descendant.Parent and descendant.Parent:IsA("UIStroke") then
		for _, entry in ipairs(cachedTargets) do
			if entry.stroke == descendant.Parent then
				entry.gradient = descendant
				return
			end
		end
		table.insert(cachedTargets, { stroke = descendant.Parent, gradient = descendant })
	end
end

local function unregisterDescendant(descendant)
	for i = #cachedTargets, 1, -1 do
		local entry = cachedTargets[i]
		if entry.stroke == descendant or entry.gradient == descendant then
			table.remove(cachedTargets, i)
		end
	end
end

for _, desc in ipairs(ScreenGui:GetDescendants()) do
	registerDescendant(desc)
end

ScreenGui.DescendantAdded:Connect(registerDescendant)
ScreenGui.DescendantRemoving:Connect(unregisterDescendant)

-- High performance animation loop
RunService.RenderStepped:Connect(function()
	local timePulse
	if pulseEnabled then
		timePulse = os.clock() * pulseSpeed
	end

	for i = 1, #cachedTargets do
		local entry = cachedTargets[i]
		local uiStroke = entry.stroke
		if uiStroke and uiStroke.Parent then
			local uiGradient = entry.gradient
			if uiGradient and uiGradient.Parent == uiStroke then
				uiGradient.Rotation = uiGradient.Rotation + rotationSpeed
			end

			if pulseEnabled then
				local pulse = (math.sin(timePulse) + 1) * 0.5
				uiStroke.Transparency = pulseMin + (pulse * (pulseMax - pulseMin))
			end
		end
	end
end)
