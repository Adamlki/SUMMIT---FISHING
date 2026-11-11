--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TitleModes = require(ReplicatedStorage.Shared.Config.CustomTitle.TitleModes)

local State = {}
State.__index = State

function State.new()
    local self = setmetatable({}, State)
    self.ColorModes = TitleModes.ColorModes
    self.Modes = TitleModes.EffectModes
    self.ColorModeIndex = 1
    self.ModeIndex = 1
    self.ColorMode = self.ColorModes[self.ColorModeIndex]
    self.Mode = self.Modes[self.ModeIndex]
    self.Slot = 1
    self.MaxSlot = 7
    self.Text = ""
    self.Colors = {nil, nil, nil, nil}
    self.SelectedPlayer = nil
    self.SelectedButton = nil
    self.Refs = nil
    self.Animator = nil
    self.Open = false
    return self
end

function State:setSelectedPlayer(player, btn)
    self.SelectedPlayer = player
    if self.SelectedButton and self.SelectedButton.Parent then
        self.SelectedButton.BorderSizePixel = 0
    end
    self.SelectedButton = btn
    if self.SelectedButton then
        self.SelectedButton.BorderSizePixel = 2
        self.SelectedButton.BorderColor3 = Color3.fromRGB(255, 200, 0)
    end
end

function State:cycleMode()
    self.ModeIndex = (self.ModeIndex % #self.Modes) + 1
    self.Mode = self.Modes[self.ModeIndex]
end

function State:cycleColorMode()
    self.ColorModeIndex = (self.ColorModeIndex % #self.ColorModes) + 1
    self.ColorMode = self.ColorModes[self.ColorModeIndex]
end

function State:cycleSlot()
    self.Slot = (self.Slot % self.MaxSlot) + 1
end

function State:setText(text)
    self.Text = text or ""
end

function State:setColor(index, color)
    if index < 1 or index > 4 then
        return
    end
    self.Colors[index] = color
end

function State:getActiveColors()
    local list = {}
    for i = 1, 4 do
        if self.Colors[i] then
            table.insert(list, self.Colors[i])
        end
    end
    if self.ColorMode == "Solid" then
        if list[1] then
            return {list[1]}
        end
        return {}
    end
    return list
end

function State:buildView()
    return {
        ColorMode = self.ColorMode,
        Mode = self.Mode,
        Slot = self.Slot,
        Text = self.Text,
        Colors = self:getActiveColors(),
    }
end

return State
