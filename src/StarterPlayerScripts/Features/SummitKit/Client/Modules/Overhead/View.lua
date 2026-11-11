--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)

local OverheadViewCustom = require(script.Parent.OverheadViewCustom)
local OverheadRoleEffects = require(script.Parent.OverheadRoleEffects)
local ViewHelpers = script.Parent:WaitForChild("ViewHelpers")
local ViewBuilder = require(ViewHelpers:WaitForChild("ViewBuilder"))
local ViewUpdater = require(ViewHelpers:WaitForChild("ViewUpdater"))

local View = {}

function View.new(template: BillboardGui, _customTemplate: BillboardGui, player, character)
    local refs = ViewBuilder.build(template, character)
    if not refs then
        return nil
    end

    local viewJanitor = Janitor.new()
    viewJanitor:Add(refs.Root, "Destroy")

    local customRenderer = OverheadViewCustom.new(viewJanitor, refs)
    local roleEffects = OverheadRoleEffects.new(viewJanitor, refs.Title)

    local function setEnabled(enabled)
        if refs.Root and refs.Root.Parent then
            refs.Root.Enabled = enabled
        end
    end

    local function applyLocalVisibility()
        ViewUpdater.applyLocalVisibility(setEnabled)
    end

    local function update(state, title, color, _displayRoles)
        if refs.VipLabel and not refs.VipEffect then
            refs.VipEffect = require(script.Parent.VipEffects).new(viewJanitor, refs.VipLabel)
        end
        ViewUpdater.update(refs, player, state, title, color, roleEffects, customRenderer, setEnabled)
    end

    return {
        update = update,
        setEnabled = setEnabled,
        applyLocalVisibility = applyLocalVisibility,
        destroy = function()
            customRenderer:stop()
            viewJanitor:Destroy()
        end,
    }
end

return View
