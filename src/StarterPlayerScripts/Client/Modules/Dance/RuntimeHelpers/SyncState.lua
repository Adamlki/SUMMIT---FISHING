--!nonstrict
local Promise = require(game:GetService("ReplicatedStorage").Shared.Packages.Promise)
local Playback = require(script.Parent.Playback)

local SyncState = {}

function SyncState.publish(runtime, animationId, animationName, looped, speed)
	if not runtime._service or not runtime._service.UpdateState then
		return
	end

	local result = runtime._service:UpdateState({
		animationId = animationId,
		animationName = animationName,
		looped = looped == true,
		speed = tonumber(speed) or 1,
		startedAtServerTime = workspace:GetServerTimeNow(),
	})

	if Promise.is(result) then
		result:catch(function(err)
			runtime._log:warn("UpdateState failed: " .. tostring(err))
		end)
	end
end

function SyncState.clearPublished(runtime)
	if runtime._service and runtime._service.ClearState then
		local result = runtime._service:ClearState()
		if Promise.is(result) then
			result:catch(function(err)
				runtime._log:warn("ClearState failed: " .. tostring(err))
			end)
		end
	end
end

function SyncState.clearFollowTarget(runtime)
	runtime._followTargetUserId = nil
	if runtime._contextMenu and runtime._contextMenu.setMode then
		runtime._contextMenu.setMode("Sync")
	end
end

function SyncState.setFollowTarget(runtime, userId)
	runtime._followTargetUserId = userId
	if runtime._contextMenu and runtime._contextMenu.setMode then
		runtime._contextMenu.setMode(userId and "Unsync" or "Sync")
	end
end

function SyncState.setCachedState(runtime, userId, state)
	runtime._stateCache[userId] = state
end

function SyncState.handleFollowStateChanged(runtime, targetUserId, state)
	if not runtime._followTargetUserId or runtime._followTargetUserId ~= targetUserId then
		return
	end

	if typeof(state) ~= "table" then
		if runtime._currentTrack then
			runtime._currentTrack:Stop()
			runtime._currentTrack:Destroy()
			runtime._currentTrack = nil
		end
		Playback.resetButton(runtime)
		SyncState.clearPublished(runtime)
		return
	end

	local success, reason = Playback.playSynced(runtime, state)
	if not success then
		runtime._log:warn("Live sync update failed: " .. tostring(reason))
	end
end

function SyncState.unsync(runtime)
	SyncState.clearFollowTarget(runtime)
	if runtime._currentTrack then
		runtime._currentTrack:Stop()
		runtime._currentTrack:Destroy()
		runtime._currentTrack = nil
	end
	Playback.resetButton(runtime)
	SyncState.clearPublished(runtime)
	if runtime._notification then
		runtime._notification.success("Unsynced dance.")
	end
end

function SyncState.syncToPlayer(runtime, targetPlayer)
	if not targetPlayer or not runtime._service or not runtime._service.RequestSync then
		if runtime._notification then
			runtime._notification.error("Dance service is not ready.")
		end
		return
	end

	local cachedState = runtime._stateCache[targetPlayer.UserId]
	if typeof(cachedState) == "table" then
		SyncState.setFollowTarget(runtime, targetPlayer.UserId)
		local cachedOk = Playback.playSynced(runtime, cachedState)
		if not cachedOk then
			SyncState.clearFollowTarget(runtime)
		end
	end

	local result = runtime._service:RequestSync(targetPlayer.UserId)
	if not Promise.is(result) then
		return
	end

	result:andThen(function(ok, payloadOrReason)
		if ok ~= true then
			if runtime._notification then
				runtime._notification.error(runtime:_getSyncErrorMessage(payloadOrReason))
			end
			runtime._log:warn("Sync request failed: " .. tostring(payloadOrReason))
			return
		end

		local payload = payloadOrReason
		local state = payload and payload.state
		runtime._stateCache[targetPlayer.UserId] = state
		SyncState.setFollowTarget(runtime, payload and payload.targetUserId or targetPlayer.UserId)
		local success, reason = Playback.playSynced(runtime, state)
		if not success then
			SyncState.clearFollowTarget(runtime)
			if runtime._notification then
				runtime._notification.error(runtime:_getSyncErrorMessage(reason))
			end
			runtime._log:warn("Sync dance failed: " .. tostring(reason))
			return
		end

		if runtime._notification and typeof(cachedState) ~= "table" then
			runtime._notification.success("Synced with " .. tostring(payload.targetName or targetPlayer.Name))
		end
	end):catch(function(err)
		if runtime._notification then
			runtime._notification.error("Sync dance request error.")
		end
		runtime._log:warn("Sync request errored: " .. tostring(err))
	end)
end

function SyncState.toggleSyncTarget(runtime, targetPlayer)
	if not targetPlayer then
		return
	end

	if runtime._followTargetUserId and runtime._followTargetUserId == targetPlayer.UserId then
		SyncState.unsync(runtime)
		return
	end

	SyncState.syncToPlayer(runtime, targetPlayer)
end

return SyncState
