-- ============================================================
-- CarrySystemSupport (ModuleScript)
-- Lokasi: ServerScriptService > JooyssKaellModules > Core > CarrySystemSupport
-- SUMMITKIT PREMIUM V1 BY JOOYSSKAELL
-- © 2025 JooyssKaell - All Rights Reserved
-- ============================================================

local Players = game:GetService("Players")
local CarrySystemSupport = {}

local function GetCarriedPlayers(carrier)
	local character = carrier.Character
	if not character then return {} end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return {} end
	local carried = {}
	for _, descendant in ipairs(humanoidRootPart:GetDescendants()) do
		if descendant:IsA("WeldConstraint") or descendant:IsA("Weld") then
			local otherPart = (descendant.Part0 == humanoidRootPart) and descendant.Part1 or descendant.Part0
			if otherPart and otherPart.Parent then
				local carriedChar = otherPart.Parent
				local carriedPlayer = Players:GetPlayerFromCharacter(carriedChar)
				if carriedPlayer and carriedPlayer ~= carrier then
					table.insert(carried, {
						Player = carriedPlayer,
						Character = carriedChar,
						HumanoidRootPart = otherPart,
						RelativeCFrame = humanoidRootPart.CFrame:ToObjectSpace(otherPart.CFrame)
					})
				end
			end
		end
	end
	return carried
end

function CarrySystemSupport.TeleportWithCarried(carrier, targetPosition)
	local character = carrier.Character
	if not character then return end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	local carriedPlayers = GetCarriedPlayers(carrier)
	local targetCFrame = CFrame.new(targetPosition)
	if character.PrimaryPart then character:PivotTo(targetCFrame)
	else humanoidRootPart.CFrame = targetCFrame end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end
	if #carriedPlayers > 0 then
		for _, data in ipairs(carriedPlayers) do
			local char = data.Character
			local hrp = data.HumanoidRootPart
			if char and hrp and hrp.Parent then
				local newCFrame = targetCFrame:ToWorldSpace(data.RelativeCFrame)
				if char.PrimaryPart then char:PivotTo(newCFrame)
				else hrp.CFrame = newCFrame end
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.AssemblyLinearVelocity = Vector3.zero
						part.AssemblyAngularVelocity = Vector3.zero
					end
				end
			end
		end
	end
end

return CarrySystemSupport