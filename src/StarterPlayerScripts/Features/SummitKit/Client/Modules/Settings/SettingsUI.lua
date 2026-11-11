--!nonstrict
local TweenService = game:GetService("TweenService")

local SettingsUI = {}

local OFF_ANCHOR = Vector2.new(0, 0.5)
local OFF_POS = UDim2.new(0, 3, 0.5, 0)
local ON_ANCHOR = Vector2.new(1, 0.5)
local ON_POS = UDim2.new(1, -3, 0.5, 0)

local CAPSULE_ON_COLOR = Color3.fromRGB(35, 210, 85)
local CAPSULE_OFF_COLOR = Color3.fromRGB(20, 20, 24)

function SettingsUI.toggleIndicator(janitor, toggleRef, enabled)
    if not toggleRef or not toggleRef.Indicator or not toggleRef.Sliding then return end

    local targetAnchor = enabled and ON_ANCHOR or OFF_ANCHOR
    local targetPos = enabled and ON_POS or OFF_POS
    local targetCapsuleColor = enabled and CAPSULE_ON_COLOR or CAPSULE_OFF_COLOR

    toggleRef.Indicator.AnchorPoint = targetAnchor
    toggleRef.Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

    local tweenKnob = TweenService:Create(toggleRef.Indicator, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = targetPos,
    })
    local tweenCapsule = TweenService:Create(toggleRef.Sliding, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = targetCapsuleColor,
    })

    janitor:Add(tweenKnob, "Cancel")
    janitor:Add(tweenCapsule, "Cancel")
    tweenKnob:Play()
    tweenCapsule:Play()
end

function SettingsUI.applyAllIndicators(janitor, refs, values)
    if not (refs and refs.Toggles) then return end
    for name, t in pairs(refs.Toggles) do
        SettingsUI.toggleIndicator(janitor, t, values[name])
    end
end

function SettingsUI.applyAdjustValues(refs, values)
    if not (refs and refs.Adjusters) then return end
    local function fmt(v)
        return string.format("%d%%", v)
    end
    for name, adj in pairs(refs.Adjusters) do
        if typeof(adj) == "table" and adj.Value and values[name] ~= nil then
            adj.Value.Text = fmt(values[name])
        end
    end
end

return SettingsUI
