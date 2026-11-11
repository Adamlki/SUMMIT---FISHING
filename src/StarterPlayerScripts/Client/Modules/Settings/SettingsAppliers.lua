--!nonstrict

local SettingsAppliers = {}
local ApplyHelpers = script.Parent:WaitForChild("ApplyHelpers")
local LayoutApplier = require(ApplyHelpers:WaitForChild("LayoutApplier"))
local WorldApplier = require(ApplyHelpers:WaitForChild("WorldApplier"))

function SettingsAppliers.cacheDefaults(refs)
    LayoutApplier.cacheDefaults(refs)
end

function SettingsAppliers.setOverheadVisibility(enabledTitle)
    WorldApplier.setOverheadVisibility(enabledTitle)
end

function SettingsAppliers.setPlayersVisibility(showPlayers)
    WorldApplier.setPlayersVisibility(showPlayers)
end

function SettingsAppliers.applyEffectsFlags(values)
    WorldApplier.applyEffectsFlags(values)
end

function SettingsAppliers.applyJumpSettings(refs, values)
    LayoutApplier.applyJumpSettings(refs, values)
end

function SettingsAppliers.applyShiftlockSettings(refs, values)
    LayoutApplier.applyShiftlockSettings(refs, values)
end

return SettingsAppliers
