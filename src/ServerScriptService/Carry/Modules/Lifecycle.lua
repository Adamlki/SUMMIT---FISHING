-- ============================================================
-- Carry/Modules/Lifecycle (ModuleScript)
-- Player join/leave/respawn cleanup bindings.
-- ============================================================

local Players = game:GetService("Players")
local State = require(script.Parent.State)
local Visuals = require(script.Parent.Visuals)
local CharacterUtil = require(script.Parent.CharacterUtil)
local CarryCore = require(script.Parent.CarryCore)

local Lifecycle = {}

local function onCharacterAdded(p, char)
	CarryCore.safeDetachIfAny(p, "respawn")
	Visuals.removeCarrierGoldenTrail(p)
	task.defer(function()
		task.wait(0.5)
		CharacterUtil.clearCarryWeldsForChar(char)
		Visuals.removeAuraCarry(char)
		Visuals.restoreCarriedScale(p, char)
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Sit = false hum.AutoRotate = true hum.WalkSpeed = 16
			hum.PlatformStand = false hum.Jump = false
			if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
			hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			task.spawn(function()
				for phase = 1, 4 do
					task.wait(0.1 * phase)
					if not hum or not hum.Parent then break end
					hum.Sit = false hum.PlatformStand = false hum.AutoRotate = true
					hum.WalkSpeed = math.max(hum.WalkSpeed, 16)
					for i = 1, 8 do hum.Sit = false hum:ChangeState(Enum.HumanoidStateType.Running) task.wait(0.02) end
				end
			end)
		end
		State.savedProps[p.UserId] = nil State.savedHum[p.UserId] = nil
		CharacterUtil.giveSelfOwnership(p)
	end)
end

function Lifecycle.Start()
	Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function(char) onCharacterAdded(p, char) end)
	end)

	Players.PlayerRemoving:Connect(function(p)
		State.pending[p.UserId] = nil
		CarryCore.detachIfAny(p, "left")
		Visuals.removeCarrierGoldenTrail(p)
		State.lockMap[p.UserId] = nil
		State.detachGuard[p.UserId] = nil
		State.savedProps[p.UserId] = nil
		State.savedHum[p.UserId] = nil
		State.savedScales[p.UserId] = nil
		State.carryingByCarrier[p.UserId] = nil
		State.carriedByTarget[p.UserId] = nil
		State.slotByCarrier[p.UserId] = nil
	end)
end

return Lifecycle
