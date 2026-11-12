local Module = {}

function Module.Install(Controller)
-- Resilient Asset Resolver
function Controller:GetFishAssetsFolder()
	if self.cachedFishFolder and self.cachedFishFolder.Parent then return self.cachedFishFolder end
	local fs = self.ReplicatedStorage:WaitForChild("FishingSystem", 15)
	if not fs then return nil end
	local assets = fs:WaitForChild("Assets", 15)
	if not assets then return nil end
	self.cachedFishFolder = assets:WaitForChild("Fish", 15)
	return self.cachedFishFolder
end

function Controller:SetupFishViewport(viewport, template, isCaught, enableRotation, fishNameRef, isDetailPreview)
	viewport:ClearAllChildren()
	local cam = Instance.new("Camera")
	cam.FieldOfView = 70
	cam.Parent = viewport
	viewport.CurrentCamera = cam

	if isCaught then
		viewport.Ambient = Color3.fromRGB(205, 205, 220)
		viewport.LightColor = Color3.fromRGB(255, 255, 255)
		viewport.LightDirection = Vector3.new(-1, -1, -1)
	else
		-- Solid pitch-black silhouette mode for uncaught fish
		viewport.Ambient = Color3.fromRGB(0, 0, 0)
		viewport.LightColor = Color3.fromRGB(0, 0, 0)
		viewport.LightDirection = Vector3.new(0, -1, 0)
	end

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
				if not isCaught then
					-- Strip all textures, decals, and surface materials for true black silhouette
					p.Color = Color3.fromRGB(0, 0, 0)
					p.Material = Enum.Material.SmoothPlastic
					p.Reflectance = 0
					if p:IsA("MeshPart") then
						p.TextureID = ""
					end
					local sm = p:FindFirstChildOfClass("SpecialMesh")
					if sm then
						sm.TextureId = ""
					end
					for _, ch in ipairs(p:GetChildren()) do
						if ch:IsA("Decal") or ch:IsA("Texture") or ch:IsA("SurfaceAppearance") then
							ch:Destroy()
						end
					end
				end
				p.Parent = model
			end
		end
	end
	model.Parent = viewport

	-- Auto unpitch if model was saved rotated > 50 degrees around X (e.g. Nila Fish, Rock Fish)
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

	-- Dynamically detect vertical axis (closest to World Y)
	local axes = {
		{vec = cf.RightVector, dim = size.X},
		{vec = cf.UpVector,    dim = size.Y},
		{vec = cf.LookVector,  dim = size.Z},
	}

	table.sort(axes, function(a, b)
		return math.abs(a.vec.Y) > math.abs(b.vec.Y)
	end)

	local vertAxis = axes[1]
	local vertVec = (vertAxis.vec.Y >= 0) and vertAxis.vec or -vertAxis.vec
	local vertHeight = vertAxis.dim

	-- Out of remaining two axes, the longer one is length, shorter is thickness
	local horizA = axes[2]
	local horizB = axes[3]
	local lengthAxis = (horizA.dim >= horizB.dim) and horizA or horizB
	local thickAxis  = (horizA.dim >= horizB.dim) and horizB or horizA

	local lengthVec = lengthAxis.vec
	local lengthVal = lengthAxis.dim
	local sideVec   = thickAxis.vec
	local thickVal  = thickAxis.dim

	-- FOV framing calculation with generous 30% margin (never clips edges!)
	local vFovRad = math.rad(70)
	local tanHalfV = math.tan(vFovRad / 2)
	local vpAspect = isDetailPreview and (216 / 134) or (72 / 58)
	local tanHalfH = tanHalfV * vpAspect

	local distH = (lengthVal / 2) / tanHalfH
	local distV = (vertHeight / 2) / tanHalfV
	local dist = math.max(distH, distV) * 1.30
	if dist < 0.9 then dist = 0.9 end

	-- Position camera at true lateral side with subtle 10-degree 3/4 perspective
	local camPos = center + sideVec * (dist * 0.96) + vertVec * (dist * 0.12) + lengthVec * (dist * 0.22)
	cam.CFrame = CFrame.lookAt(camPos, center, vertVec)

	-- Smooth rotation for caught fish in Details Panel
	if enableRotation and isCaught then
		local angle = 0
		self.activePreviewThread = task.spawn(function()
			while viewport.Parent and (self.activeFishName == fishNameRef) do
				angle = (angle + 1) % 360
				local rotCF = CFrame.fromAxisAngle(vertVec, math.rad(angle))
				local baseOffset = sideVec * (dist * 0.96) + vertVec * (dist * 0.12) + lengthVec * (dist * 0.22)
				local offset = rotCF * baseOffset
				cam.CFrame = CFrame.lookAt(center + offset, center, vertVec)
				task.wait(0.03)
			end
		end)
	end

	return model
end
end

return Module
