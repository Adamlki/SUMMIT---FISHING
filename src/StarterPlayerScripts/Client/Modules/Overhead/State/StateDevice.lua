--!nonstrict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local StateDevice = {}

function StateDevice.getDevice(player, config)
    local device = player:GetAttribute(config.DeviceAttribute)
    if device then
        return device
    end
    if player == Players.LocalPlayer then
        if UserInputService.TouchEnabled then
            return "Mobile"
        end
        return "Desktop"
    end
    return nil
end

return StateDevice
