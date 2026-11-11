local Module = {}

function Module.Install(Controller)
-- ===================================================================
-- 3D VIEWPORT FRAME ENGINE (Real 3D models with camera & lighting)
-- ===================================================================
function Controller:SetupFishViewport(viewport, fishName)
	if not viewport then return end
	viewport:ClearAllChildren()
	if not fishName or fishName == "" then return end

	local template = self.fishAssetFolder:FindFirstChild(fishName)
	if not template then
		local fishModelFolder = self.FishingSystem:WaitForChild("Assets"):FindFirstChild("FishModel")
		template = fishModelFolder and fishModelFolder:FindFirstChild(fishName)
	end
	if not template then return end

	local cam = Instance.new("Camera")
	cam.FieldOfView = 70
	cam.Parent = viewport
	viewport.CurrentCamera = cam

	viewport.Ambient = Color3.fromRGB(215, 215, 230)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -1)

	local model = Instance.new("Model")
	model.Name = "FishModel"

	for _, desc in ipairs(template:GetDescendants()) do
		if desc:IsA("BasePart") then
			local isSpecialMesh = desc:FindFirstChildOfClass("SpecialMesh") ~= nil
			local isMeshPart = desc:IsA("MeshPart")
			local isGhostly = desc.Transparency >= 0.9
			local isInvisibleGripHandle = (desc.Name == "Handle" and isGhostly and not isMeshPart and not isSpecialMesh)

			if not isInvisibleGripHandle and (desc.Transparency < 0.9 or isMeshPart or isSpecialMesh) then
				local p = desc:Clone()
				p.Anchored = true
				p.CanCollide = false
				p.CanTouch = false
				p.CanQuery = false
				p.Parent = model
			end
		end
	end
	model.Parent = viewport

	local preCF, _ = model:GetBoundingBox()
	local rx, _, _ = preCF:ToEulerAnglesXYZ()
	if math.abs(math.deg(rx)) > 50 then
		local unpitchCF = CFrame.Angles(-rx, 0, 0)
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") then
				p.CFrame = unpitchCF * p.CFrame
			end
		end
	end

	local cf, size = model:GetBoundingBox()
	local center = cf.Position

	local axes = {
		{vec = cf.RightVector, dim = size.X},
		{vec = cf.UpVector,    dim = size.Y},
		{vec = cf.LookVector,  dim = size.Z},
	}
	table.sort(axes, function(a, b) return math.abs(a.vec.Y) > math.abs(b.vec.Y) end)

	local vertAxis = axes[1]
	local vertVec = (vertAxis.vec.Y >= 0) and vertAxis.vec or -vertAxis.vec
	local vertHeight = vertAxis.dim

	local horizA = axes[2]
	local horizB = axes[3]
	local lengthAxis = (horizA.dim >= horizB.dim) and horizA or horizB
	local thickAxis  = (horizA.dim >= horizB.dim) and horizB or horizA

	local lengthVec = lengthAxis.vec
	local lengthVal = lengthAxis.dim
	local sideVec   = thickAxis.vec

	local vFovRad = math.rad(70)
	local tanHalfV = math.tan(vFovRad / 2)
	local vpAspect = 1
	local tanHalfH = tanHalfV * vpAspect

	local distH = (lengthVal / 2) / tanHalfH
	local distV = (vertHeight / 2) / tanHalfV
	local dist = math.max(distH, distV) * 1.30
	if dist < 0.9 then dist = 0.9 end

	local camPos = center + sideVec * (dist * 0.96) + vertVec * (dist * 0.12) + lengthVec * (dist * 0.22)
	cam.CFrame = CFrame.lookAt(camPos, center, vertVec)
end

function Controller:SetupRodViewport(viewport, rodName)
	if not viewport then return end
	viewport:ClearAllChildren()
	if not rodName or rodName == "" then return end

	local targetName = rodName
	if targetName == "Vip Rod" or targetName == "Royal Rod" then
		targetName = "Dragon Spine"
	end

	local tool = self.rodAssetFolder and self.rodAssetFolder:FindFirstChild(targetName)
	if not tool then
		local bp = self.player:FindFirstChild("Backpack")
		local ch = self.player.Character
		tool = (bp and bp:FindFirstChild(targetName)) or (ch and ch:FindFirstChild(targetName))
	end
	if not tool then return end

	local model = Instance.new("Model")
	model.Name = "RodModel"

	for _, desc in ipairs(tool:GetDescendants()) do
		if desc:IsA("BasePart") then
			local isMeshPart = desc:IsA("MeshPart")
			local hasSpecialMesh = desc:FindFirstChildOfClass("SpecialMesh") ~= nil
			local isInvisibleGrip = (desc.Transparency >= 0.9 and not isMeshPart and not hasSpecialMesh)

			if not isInvisibleGrip and (desc.Transparency < 0.9 or isMeshPart or hasSpecialMesh) then
				local p = desc:Clone()
				p.Anchored = true
				p.CanCollide = false
				p.CanTouch = false
				p.CanQuery = false
				p.Parent = model
			end
		end
	end
	model.Parent = viewport

	local cam = Instance.new("Camera")
	cam.FieldOfView = 50
	cam.Parent = viewport
	viewport.CurrentCamera = cam

	viewport.Ambient = Color3.fromRGB(220, 220, 235)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -1)

	local cf, size = model:GetBoundingBox()
	local maxDim = math.max(size.X, size.Y, size.Z)
	local dist = (maxDim / 2) / math.tan(math.rad(cam.FieldOfView / 2)) * 1.15
	if dist < 1 then dist = 1 end

	local camPos = cf.Position + Vector3.new(dist * 0.42, dist * 0.18, dist * 0.9)
	cam.CFrame = CFrame.lookAt(camPos, cf.Position)
end

function Controller:SetupToolViewport(viewport, toolRef)
	if not viewport then return end
	viewport:ClearAllChildren()
	if not toolRef then return end

	local tool = nil
	if typeof(toolRef) == "Instance" then
		tool = toolRef
	elseif type(toolRef) == "string" and toolRef ~= "" then
		local bp = self.player:FindFirstChild("Backpack")
		local ch = self.player.Character
		local gear = self.player:FindFirstChild("StarterGear")
		tool = (bp and bp:FindFirstChild(toolRef))
			or (ch and ch:FindFirstChild(toolRef))
			or (gear and gear:FindFirstChild(toolRef))
			or self.StarterPack:FindFirstChild(toolRef)
	end
	if not tool or not tool:IsA("Tool") then return end

local model = Instance.new("Model")
	model.Name = "ToolModel"

	for _, desc in ipairs(tool:GetDescendants()) do
		if desc:IsA("BasePart") then
			local isMeshPart = desc:IsA("MeshPart")
			local hasSpecialMesh = desc:FindFirstChildOfClass("SpecialMesh") ~= nil
			local isInvisibleGrip = (desc.Transparency >= 0.9 and not isMeshPart and not hasSpecialMesh)

			if not isInvisibleGrip and (desc.Transparency < 0.9 or isMeshPart or hasSpecialMesh) then
				local p = desc:Clone()
				p.Anchored = true
				p.CanCollide = false
				p.CanTouch = false
				p.CanQuery = false
				p.Parent = model
			end
		end
	end
	model.Parent = viewport

	local cam = Instance.new("Camera")
	cam.FieldOfView = 55
	cam.Parent = viewport
	viewport.CurrentCamera = cam

	viewport.Ambient = Color3.fromRGB(220, 220, 235)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -1)

	local cf, size = model:GetBoundingBox()
	local maxDim = math.max(size.X, size.Y, size.Z)
	local dist = (maxDim / 2) / math.tan(math.rad(cam.FieldOfView / 2)) * 1.2
	if dist < 1 then dist = 1 end

	local camPos = cf.Position + Vector3.new(dist * 0.4, dist * 0.2, dist * 0.9)
	cam.CFrame = CFrame.lookAt(camPos, cf.Position)
end
end

return Module
