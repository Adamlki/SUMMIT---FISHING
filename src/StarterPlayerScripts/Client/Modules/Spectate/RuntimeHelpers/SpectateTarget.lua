--!nonstrict
local Players = game:GetService("Players")

local SpectateCamera = require(script.Parent.Parent.SpectateCamera)
local SpectateList = require(script.Parent.Parent.SpectateList)

local SpectateTarget = {}

function SpectateTarget.updateLabels(runtime, player)
	local refs = runtime._refs
	if player then
		if refs.NameLabel then
			refs.NameLabel.Text = player.DisplayName or player.Name
		end
		if refs.UsernameLabel then
			refs.UsernameLabel.Text = "@" .. player.Name
		end
	else
		if refs.NameLabel then
			refs.NameLabel.Text = "-"
		end
		if refs.UsernameLabel then
			refs.UsernameLabel.Text = "-"
		end
	end
end

function SpectateTarget.setTarget(runtime, player)
	runtime._targetJanitor:Cleanup()
	runtime._target = player
	SpectateTarget.updateLabels(runtime, player)
	SpectateCamera.applyToPlayer(player)

	if player ~= Players.LocalPlayer then
		runtime._freeze:freeze()
	else
		runtime._freeze:unfreeze()
		task.defer(function()
			runtime._freeze:unfreeze()
		end)
	end

	runtime._targetJanitor:Add(player.CharacterAdded:Connect(function()
		task.wait(0.1)
		if runtime._spectating and runtime._target == player then
			SpectateCamera.applyToPlayer(player)
			if player ~= Players.LocalPlayer then
				runtime._freeze:freeze()
			else
				runtime._freeze:unfreeze()
				task.defer(function()
					runtime._freeze:unfreeze()
				end)
			end
		end
	end), "Disconnect")
end

function SpectateTarget.refreshAfterChange(runtime, excludedRoles)
	if not runtime._spectating then
		return
	end
	local current = runtime._target
	runtime._list = SpectateList.build(Players.LocalPlayer, excludedRoles)
	if not current or SpectateList.isExcluded(current, excludedRoles) or not current.Parent then
		runtime._index = SpectateList.findIndex(runtime._list, Players.LocalPlayer)
		SpectateTarget.setTarget(runtime, runtime._list[runtime._index])
	else
		runtime._index = SpectateList.findIndex(runtime._list, current)
		SpectateTarget.setTarget(runtime, runtime._list[runtime._index])
	end
end

function SpectateTarget.stepTarget(runtime, delta)
	if not runtime._spectating then
		return
	end
	if #runtime._list <= 1 then
		return
	end
	runtime._index += delta
	if runtime._index < 1 then
		runtime._index = #runtime._list
	end
	if runtime._index > #runtime._list then
		runtime._index = 1
	end
	SpectateTarget.setTarget(runtime, runtime._list[runtime._index])
end

return SpectateTarget
