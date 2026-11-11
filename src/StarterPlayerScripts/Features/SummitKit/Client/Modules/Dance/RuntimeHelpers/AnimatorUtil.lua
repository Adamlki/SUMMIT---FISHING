--!nonstrict
local Players = game:GetService("Players")

local AnimatorUtil = {}

function AnimatorUtil.getAnimator()
	local character = Players.LocalPlayer.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	return animator
end

return AnimatorUtil
