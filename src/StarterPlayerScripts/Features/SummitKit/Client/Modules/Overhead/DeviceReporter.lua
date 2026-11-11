--!nonstrict
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)

local DeviceReporter = {}

local function detectDevice()
    if UserInputService.TouchEnabled then
        return "Mobile"
    end
    return "Desktop"
end

function DeviceReporter.start(overheadService)
    if not overheadService then
        return Janitor.new()
    end
    local janitor = Janitor.new()

    local current = detectDevice()
    task.defer(function()
        pcall(function()
            overheadService:SetDevice(current)
        end)
    end)

    janitor:Add(UserInputService.LastInputTypeChanged:Connect(function(_)
        local newDevice = detectDevice()
        if newDevice ~= current then
            current = newDevice
            pcall(function()
                overheadService:SetDevice(current)
            end)
        end
    end), "Disconnect")

    return janitor
end

return DeviceReporter
