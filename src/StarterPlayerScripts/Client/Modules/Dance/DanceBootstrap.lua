--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Promise = require(Packages.Promise)

local DanceResolver = require(script.Parent.DanceResolver)
local DanceRuntime = require(script.Parent.DanceRuntime)

local DanceBootstrap = {}

local function resolveRefs(playerGui)
	return Promise.new(function(resolve, reject)
		local refs
		for _ = 1, 5 do
			local ok, result = DanceResolver.Resolve(playerGui)
			if ok then
				refs = result
				break
			end
			task.wait(2)
		end

		if not refs then
			reject("DanceResolver failed after retries")
			return
		end

		resolve(refs)
	end)
end

local function resolveAssets(dependencies)
	local danceAssets = Shared:FindFirstChild("Assets")
	danceAssets = danceAssets and danceAssets:FindFirstChild("Dance")
	if not danceAssets then
		return nil, "Assets/Dance not found in ReplicatedStorage.Shared"
	end

	local animations = danceAssets:FindFirstChild("Animations")
	local template = danceAssets:FindFirstChild("Template")
	if not animations or not template then
		return nil, "Dance Assets missing Animations/Template"
	end

	return {
		Template = template,
		DanceAnimations = animations:FindFirstChild("Dance") or Instance.new("Folder"),
		PoseAnimations = animations:FindFirstChild("Pose") or Instance.new("Folder"),
		DanceService = dependencies.DanceService,
		DanceNotification = dependencies.DanceNotification,
		DanceContextMenu = dependencies.DanceContextMenu,
		DanceStateCache = dependencies.DanceStateCache or {},
	}
end

function DanceBootstrap.start(playerGui, dependencies)
	return resolveRefs(playerGui):andThen(function(refs)
		local assets, assetErr = resolveAssets(dependencies)
		if not assets then
			return Promise.reject(assetErr)
		end

		local runtime = DanceRuntime.new(refs, assets)
		return {
			Runtime = runtime,
			StateCache = assets.DanceStateCache,
		}
	end)
end

return DanceBootstrap
