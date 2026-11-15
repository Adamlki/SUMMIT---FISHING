--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UI = Shared:WaitForChild("UI")
local RewardPopup = require(UI:WaitForChild("RewardPopup"))
local NetworkGateway = require(Shared:WaitForChild("Network"):WaitForChild("NetworkGateway"))

-- Scaling is owned by RewardPopupGui.AutoResize, which drives PopupRoot.PopupScale.
RewardPopup.init()

NetworkGateway:On("Reward/Granted", function(data)
	if type(data) == "table" then
		RewardPopup.show(data)
	end
end)
