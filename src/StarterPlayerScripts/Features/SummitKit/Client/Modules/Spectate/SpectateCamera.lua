--!nonstrict
local Camera = {}

function Camera.applyToPlayer(player)
	local cam = workspace.CurrentCamera
	local hum = player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		cam.CameraType = Enum.CameraType.Custom
		cam.CameraSubject = hum
	end
end

return Camera
