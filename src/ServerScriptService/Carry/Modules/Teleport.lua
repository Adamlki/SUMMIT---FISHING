-- ============================================================
-- Carry/Modules/Teleport (ModuleScript)
-- Moves the standalone carry group when checkpoint/admin teleports.
-- Returns false when the player is not part of a carry group.
-- ============================================================

local State = require(script.Parent.State)

local Teleport = {}

local function getCharHRP(player)
	local char = player.Character
	return char, char and char:FindFirstChild("HumanoidRootPart")
end

function Teleport.TeleportCarryGroup(player, targetPart)
	if not player or not targetPart then return false end

	local carrier = State.carriedByTarget[player.UserId] or player
	local carried = State.carryingByCarrier[carrier.UserId]
	if not carried or not next(carried) then return false end

	local cChar, cHRP = getCharHRP(carrier)
	if not (cChar and cHRP) then return false end

	cHRP.AssemblyLinearVelocity = Vector3.zero
	cHRP.AssemblyAngularVelocity = Vector3.zero
	cChar:PivotTo(targetPart.CFrame + Vector3.new(0, 3, 0))

	local CarryCore = require(script.Parent.CarryCore)
	CarryCore.reindexSlots(carrier)
	return true
end

return Teleport
