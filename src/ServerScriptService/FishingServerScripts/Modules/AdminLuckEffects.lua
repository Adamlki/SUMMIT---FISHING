-- Visual effects (lucky model, sky, sound) for the luck boost intro.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Effects = {}

local function anchorModel(model, isAnchored)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("UnionOperation") then
			part.Anchored = isAnchored
		end
	end
end

local function toggleVisualEffects(model, isEnabled)
	for _, child in model:GetDescendants() do
		if child:IsA("ParticleEmitter") or child:IsA("Beam") or child:IsA("Trail") then
			child.Enabled = isEnabled
		end
	end
end

-- 🌟 EFEK INTRO HANYA 5.5 DETIK, LALU OTOMATIS NORMAL KEMBALI
function Effects.playIntro()
	task.spawn(function()
		-- 1. Lucky Model
		local luckyModel = ReplicatedStorage:FindFirstChild("lucky")
		if luckyModel then
			anchorModel(luckyModel, true)
			luckyModel.Parent = Workspace
			toggleVisualEffects(luckyModel, true)
		end

		-- 2. Sky Lucky
		local skyLucky = ReplicatedStorage:FindFirstChild("SkyLucky")
		local activeSkyLucky = nil
		if skyLucky then
			local oldSky = Lighting:FindFirstChild("EventSkyLucky")
			if oldSky then oldSky:Destroy() end
			activeSkyLucky = skyLucky:Clone()
			activeSkyLucky.Name = "EventSkyLucky"
			activeSkyLucky.Parent = Lighting
		end

		-- 3. Sound Lucky
		local luckysound = ReplicatedStorage:FindFirstChild("luckysound")
		local activeLuckySound = nil
		if luckysound then
			local oldSnd = Lighting:FindFirstChild("ActiveLuckySound")
			if oldSnd then oldSnd:Destroy() end
			activeLuckySound = luckysound:Clone()
			activeLuckySound.Name = "ActiveLuckySound"
			activeLuckySound.Parent = Lighting
			activeLuckySound.Looped = false
			activeLuckySound:Play()
		end

		-- ⏱️ TUNGGU 5.5 DETIK PAS INTRO SELESAI, KEMBALI KE BIASA!
		task.wait(5.5)

		if luckyModel and luckyModel.Parent == Workspace then
			toggleVisualEffects(luckyModel, false)
			luckyModel.Parent = ReplicatedStorage
			anchorModel(luckyModel, false)
		end

		if activeSkyLucky and activeSkyLucky.Parent == Lighting then
			activeSkyLucky:Destroy()
		end

		if activeLuckySound and activeLuckySound.Parent == Lighting then
			activeLuckySound:Stop()
			activeLuckySound:Destroy()
		end
	end)
end

-- Sky and sound clones staged under Lighting.
function Effects.clearSkyAndSound()
	local activeSky = Lighting:FindFirstChild("EventSkyLucky")
	if activeSky then activeSky:Destroy() end

	local activeSound = Lighting:FindFirstChild("ActiveLuckySound")
	if activeSound then activeSound:Destroy() end
end

-- Restore the lucky model when it is located through ReplicatedStorage (/unluck path).
function Effects.restoreLuckyFromStorage()
	local luckyModel = ReplicatedStorage:FindFirstChild("lucky")
	if luckyModel and luckyModel.Parent == Workspace then
		toggleVisualEffects(luckyModel, false)
		luckyModel.Parent = ReplicatedStorage
		anchorModel(luckyModel, false)
	end
end

-- Restore the lucky model when it is located through Workspace (remote STOP path).
function Effects.restoreLuckyInWorkspace()
	local luckyModel = Workspace:FindFirstChild("lucky")
	if luckyModel then
		toggleVisualEffects(luckyModel, false)
		luckyModel.Parent = ReplicatedStorage
		anchorModel(luckyModel, false)
	end
end

return Effects
