--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)
local Janitor = require(Packages.Janitor)

local DanceBootstrap = require(script.Parent.Parent.Modules.Dance.DanceBootstrap)
local DanceContextMenu = require(script.Parent.Parent.Modules.Dance.DanceContextMenu)
local DanceNotification = require(script.Parent.Parent.Modules.Notifications.DanceNotification)
local Logger = require(script.Parent.Parent.Modules.Logger)

local Controller = Knit.CreateController({Name = "DanceController"})

local LocalPlayer = Players.LocalPlayer
local log = Logger.new("DanceController", false)

function Controller:KnitStart()
	local janitor = Janitor.new()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui", 30)
	if not playerGui then
		log:error("PlayerGui not found")
		return
	end

	DanceBootstrap.start(playerGui, {
		DanceService = Knit.GetService("DanceService"),
		DanceNotification = DanceNotification,
		DanceContextMenu = DanceContextMenu,
		DanceStateCache = {},
	}):andThen(function(result)
		local runtime = result.Runtime
		local danceStateCache = result.StateCache
		local danceService = runtime._service
		janitor:Add(runtime, "Destroy")
		DanceContextMenu.setMode("Sync")

		local okMenu, menuErr = DanceContextMenu.init(function(targetPlayer)
			runtime:ToggleSyncTarget(targetPlayer)
		end)
		if not okMenu then
			log:warn(tostring(menuErr))
		end

		if danceService and danceService.StateChanged then
			janitor:Add(danceService.StateChanged:Connect(function(targetUserId, state)
				danceStateCache[targetUserId] = state
				runtime:SetCachedState(targetUserId, state)
				runtime:HandleFollowStateChanged(targetUserId, state)
			end), "Disconnect")
		end

		janitor:Add(LocalPlayer.CharacterAdded:Connect(function()
			runtime:OnCharacterAdded()
		end), "Disconnect")
	end):catch(function(err)
		log:warn("Init failed: " .. tostring(err))
	end)
end

return Controller
