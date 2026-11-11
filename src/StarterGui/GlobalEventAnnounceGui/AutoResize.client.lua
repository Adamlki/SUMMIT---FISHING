local player = game.Players.LocalPlayer
local screenGui = script.Parent

local uiScale = screenGui:FindFirstChildOfClass("UIScale")
if not uiScale then
	uiScale = Instance.new("UIScale")
	uiScale.Parent = screenGui
end

-- Resolusi referensi (desain dibuat di resolusi ini)
local baseX, baseY = 1366, 768

local function updateScale()
	local screenSize = workspace.CurrentCamera.ViewportSize
	if screenSize.X == 0 or screenSize.Y == 0 then return end

	local scaleX = screenSize.X / baseX
	local scaleY = screenSize.Y / baseY

	-- Pakai minimum agar semua UI tetap muat di layar apapun
	local baseScale = math.min(scaleX, scaleY)

	-- Clamp: min 0.35 (HP kecil) sampai max 1.5 (monitor besar)
	uiScale.Scale = math.clamp(baseScale, 0.35, 1.0)
end

updateScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
