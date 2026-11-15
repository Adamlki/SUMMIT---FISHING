--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Players = game:GetService("Players")

local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)
local Promise = require(Packages.Promise)

local SettingResolver = require(script.Parent.SettingResolver)
local SettingBindings = require(script.Parent.SettingBindings)
local SettingsState = require(script.Parent.SettingsState)
local SettingsUI = require(script.Parent.SettingsUI)
local SettingsAppliers = require(script.Parent.SettingsAppliers)
local SettingHelpers = script.Parent:WaitForChild("SettingHelpers")
local SettingsBinder = require(SettingHelpers:WaitForChild("SettingsBinder"))
local Panel = require(script.Parent.Parent.UI.Panel)

local SettingMenu = {}

local janitor = Janitor.new()

local VALUE_MIN = -200
local VALUE_MAX = 200
local VALUE_STEP = 5

local refs

local state = SettingsState.new()

local function applySettings()
    SettingsAppliers.cacheDefaults(refs)
    local v = state.values
    local hideTitle = v.Title
    local hidePlayers = v.Players
    SettingsAppliers.setOverheadVisibility(not hideTitle)
    SettingsAppliers.setPlayersVisibility(not hidePlayers)
    SettingsAppliers.applyEffectsFlags(v)
    SettingsAppliers.applyJumpSettings(refs, v)
    SettingsAppliers.applyShiftlockSettings(refs, v)
    SettingsUI.applyAdjustValues(refs, v)
    state:saveAttributes()
end

local function tweenMenu(visible)
    if not refs or not refs.Menu then
        return
    end
    if visible then
        Panel.open(refs.Menu)
    else
        Panel.close(refs.Menu)
    end
end

local function flip(name)
    if state.values[name] == nil then
        return
    end
    state.values[name] = not state.values[name]
    SettingsUI.toggleIndicator(janitor, refs.Toggles[name], state.values[name])
    applySettings()
end

local function changeAdjuster(name, delta)
    if state.values[name] == nil then
        return
    end
    state:changeAdjuster(name, delta, VALUE_MIN, VALUE_MAX, VALUE_STEP)
    SettingsUI.applyAdjustValues(refs, state.values)
    applySettings()
end

local function resetToDefaults()
    state:resetToDefaults()
    SettingsUI.applyAdjustValues(refs, state.values)
    SettingsUI.applyAllIndicators(janitor, refs, state.values)
    applySettings()
end

local function bindAll()
    if not refs then
        return
    end
    SettingBindings.BindMenu(janitor, refs, function()
        tweenMenu(not Panel.isOpen(refs.Menu))
    end, function()
        tweenMenu(false)
    end)
    if not refs.ToggleBtn then
        SettingBindings.BindHotkey(janitor, Enum.KeyCode.F1, function()
            tweenMenu(not Panel.isOpen(refs.Menu))
        end)
    end
    SettingBindings.BindToggles(janitor, refs.Toggles, flip)
    SettingBindings.BindAdjusters(janitor, refs.Adjusters, changeAdjuster, resetToDefaults)
end

local function ensureRefs()
    local lp = Players.LocalPlayer
    if not lp then
        return
    end
    local pg = lp:FindFirstChild("PlayerGui")
    if not pg then
        return
    end
    if refs and refs.Menu and refs.Menu.Parent then
        return
    end
    janitor:Cleanup()
    local ok, r = SettingResolver.Resolve(pg)
    if not ok then
        warn("[SettingMenu] re-resolve failed: " .. tostring(r))
        return
    end
    refs = r
    refs.Menu.Visible = false
    refs.Menu.AnchorPoint = Vector2.new(0.5, 0.5)
    refs.Menu.Position = refs.HiddenPos or refs.Menu.Position
    if refs.ToggleBtn and not refs.ToggleBtn:IsA("GuiButton") then
        refs.ToggleBtn.Active = true
        refs.ToggleBtn.Selectable = false
    end
    SettingsAppliers.cacheDefaults(refs)
    state:syncFromAttributes()
    SettingsUI.applyAllIndicators(janitor, refs, state.values)
    SettingsUI.applyAdjustValues(refs, state.values)
    applySettings()
    Promise.delay(0.2):andThen(applySettings)
    Promise.delay(0.6):andThen(applySettings)
    bindAll()
end

local function init(playerGui)
    local ok, r = SettingResolver.Resolve(playerGui)
    if not ok then
        warn("[SettingMenu] " .. tostring(r))
        return
    end
    refs = r
    refs.Menu.Visible = false
    refs.Menu.AnchorPoint = Vector2.new(0.5, 0.5)
    refs.Menu.Position = refs.HiddenPos or refs.Menu.Position
    if refs.ToggleBtn and not refs.ToggleBtn:IsA("GuiButton") then
        refs.ToggleBtn.Active = true
        refs.ToggleBtn.Selectable = false
    end

    SettingsAppliers.cacheDefaults(refs)
    SettingsUI.applyAllIndicators(janitor, refs, state.values)
    SettingsUI.applyAdjustValues(refs, state.values)
    applySettings()
    bindAll()

    SettingsBinder.bind(janitor, applySettings, function()
        if not (refs and refs.Menu and refs.Menu.Parent) then
            ensureRefs()
        end
    end, Promise)
end

function SettingMenu.setupForPlayer(player)
    local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 60)
    if not pg then
        return false
    end
    janitor:Cleanup()
    refs = nil
    state:syncFromAttributes()
    init(pg)
    SettingsUI.applyAllIndicators(janitor, refs, state.values)
    SettingsUI.applyAdjustValues(refs, state.values)
    applySettings()
    Promise.delay(0.2):andThen(applySettings)
    Promise.delay(0.6):andThen(applySettings)
    return true
end

function SettingMenu.toggle()
    if not refs or not refs.Menu then
        return
    end
    tweenMenu(not Panel.isOpen(refs.Menu))
end

function SettingMenu.destroy()
    janitor:Destroy()
end

return SettingMenu
