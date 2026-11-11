--!nonstrict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local SettingsBinder = {}

function SettingsBinder.bind(janitor, applySettings, ensureRefs, promiseLibrary)
	local function hookPlayer(player)
		janitor:Add(player.CharacterAdded:Connect(function(character)
			applySettings()
			if character then
				janitor:Add(character.ChildAdded:Connect(function(child)
					if child:IsA("BillboardGui") then
						applySettings()
					end
				end), "Disconnect")
			end
			promiseLibrary.delay(0.2):andThen(applySettings)
			promiseLibrary.delay(0.6):andThen(applySettings)
		end), "Disconnect")
		if player.Character then
			applySettings()
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		hookPlayer(player)
	end
	janitor:Add(Players.PlayerAdded:Connect(hookPlayer), "Disconnect")
	janitor:Add(Players.PlayerRemoving:Connect(function()
		applySettings()
	end), "Disconnect")
	janitor:Add(RunService.Heartbeat:Connect(function()
		ensureRefs()
	end), "Disconnect")
end

return SettingsBinder
