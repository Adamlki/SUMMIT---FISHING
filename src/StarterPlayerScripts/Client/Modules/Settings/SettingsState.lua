--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local TableUtil = require(Packages.TableUtil)

local SettingsState = {}
SettingsState.__index = SettingsState

function SettingsState.new()
    local self = setmetatable({}, SettingsState)
    self.values = {
        Title = false,
        Players = false,
        Effect = false,
        Blur = false,
        Shadow = false,
        JumpSize = 0,
        JumpVertical = 0,
        JumpHorizontal = 0,
        ShiftlockSize = 0,
        ShiftlockVertical = 0,
        ShiftlockHorizontal = 0,
    }
    self.defaultValues = TableUtil.Copy(self.values)
    self.adjustKeys = TableUtil.Copy({
        "JumpSize",
        "JumpVertical",
        "JumpHorizontal",
        "ShiftlockSize",
        "ShiftlockVertical",
        "ShiftlockHorizontal",
    })
    return self
end

function SettingsState:syncFromAttributes()
    local lp = Players.LocalPlayer
    if not lp then return end
    local v = self.values
    v.Title = lp:GetAttribute("HideTitles") == true
    v.Players = lp:GetAttribute("HidePlayers") == true
    v.Effect = lp:GetAttribute("DisableEffects") == true
    v.Blur = lp:GetAttribute("DisableBlur") == true
    v.Shadow = lp:GetAttribute("DisableShadow") == true
    v.JumpSize = lp:GetAttribute("JumpSizeDelta") or 0
    v.JumpVertical = lp:GetAttribute("JumpVerticalDelta") or 0
    v.JumpHorizontal = lp:GetAttribute("JumpHorizontalDelta") or 0
    v.ShiftlockSize = lp:GetAttribute("ShiftlockSizeDelta") or 0
    v.ShiftlockVertical = lp:GetAttribute("ShiftlockVerticalDelta") or 0
    v.ShiftlockHorizontal = lp:GetAttribute("ShiftlockHorizontalDelta") or 0
end

function SettingsState:saveAttributes()
    local lp = Players.LocalPlayer
    if not lp then return end
    local v = self.values
    lp:SetAttribute("HideTitles", v.Title)
    lp:SetAttribute("HidePlayers", v.Players)
    lp:SetAttribute("DisableEffects", v.Effect)
    lp:SetAttribute("DisableBlur", v.Blur)
    lp:SetAttribute("DisableShadow", v.Shadow)
    lp:SetAttribute("JumpSizeDelta", v.JumpSize)
    lp:SetAttribute("JumpVerticalDelta", v.JumpVertical)
    lp:SetAttribute("JumpHorizontalDelta", v.JumpHorizontal)
    lp:SetAttribute("ShiftlockSizeDelta", v.ShiftlockSize)
    lp:SetAttribute("ShiftlockVerticalDelta", v.ShiftlockVertical)
    lp:SetAttribute("ShiftlockHorizontalDelta", v.ShiftlockHorizontal)
end

function SettingsState:resetAdjusters()
    for _, key in ipairs(self.adjustKeys) do
        self.values[key] = 0
    end
end

function SettingsState:resetToDefaults()
    self.values = TableUtil.Copy(self.defaultValues)
end

function SettingsState:changeAdjuster(name, delta, minValue, maxValue, step)
    if self.values[name] == nil then return end
    local stepValue = delta * step
    self.values[name] = math.clamp(self.values[name] + stepValue, minValue, maxValue)
end

return SettingsState
