--!nonstrict
-- ==============================================================================
-- Effects.luau
-- Dynamic Animated Gradients for Custom Titles (Mobile-Optimized & 6 Unique Modes)
-- ==============================================================================

local TweenService = game:GetService("TweenService")

local Effects = {}

local function getGradient(label)
    local grad = label:FindFirstChildWhichIsA("UIGradient")
    if not grad then
        grad = Instance.new("UIGradient")
        grad.Parent = label
    end
    return grad
end

local function buildSequence(colors)
    if not colors or #colors == 0 then
        return ColorSequence.new(Color3.fromRGB(255, 255, 255))
    end
    if #colors == 1 then
        return ColorSequence.new(colors[1])
    end
    local keypoints = {}
    for i, c in ipairs(colors) do
        local t = (i - 1) / math.max(1, (#colors - 1))
        table.insert(keypoints, ColorSequenceKeypoint.new(t, c))
    end
    return ColorSequence.new(keypoints)
end

-- 6 Master Color Palettes
function Effects.getPalette(name)
    if name == "Cosmic Spin" or name == "Cosmic Glow" then
        return {
            Color3.fromRGB(123, 31, 162), -- Deep Violet
            Color3.fromRGB(224, 64, 251), -- Electric Magenta
            Color3.fromRGB(0, 229, 255),   -- Cosmic Cyan
            Color3.fromRGB(41, 121, 255),  -- Neon Blue
            Color3.fromRGB(123, 31, 162), -- Deep Violet
        }
    elseif name == "Sunset Flare" or name == "Solar Pulse" then
        return {
            Color3.fromRGB(213, 0, 0),     -- Crimson Red
            Color3.fromRGB(255, 109, 0),   -- Fiery Orange
            Color3.fromRGB(255, 214, 0),   -- Sun Yellow
            Color3.fromRGB(255, 138, 101), -- Coral Glow
            Color3.fromRGB(255, 109, 0),   -- Fiery Orange
        }
    elseif name == "Ocean Wave" or name == "Wave Shimmer" then
        return {
            Color3.fromRGB(13, 71, 161),   -- Deep Ocean
            Color3.fromRGB(41, 121, 255),  -- Electric Wave
            Color3.fromRGB(0, 229, 255),   -- Crystal Cyan
            Color3.fromRGB(105, 240, 174), -- Sea Mint
            Color3.fromRGB(41, 121, 255),  -- Electric Wave
        }
    elseif name == "Aurora Drift" then
        return {
            Color3.fromRGB(0, 200, 83),    -- Emerald
            Color3.fromRGB(29, 233, 182),  -- Mint Neon
            Color3.fromRGB(174, 234, 0),   -- Bright Lime
            Color3.fromRGB(0, 229, 255),   -- Aurora Cyan
            Color3.fromRGB(0, 200, 83),    -- Emerald
        }
    elseif name == "Royal Gold" or name == "Golden Crown" then
        return {
            Color3.fromRGB(141, 110, 99),  -- Metallic Bronze
            Color3.fromRGB(255, 215, 0),   -- 24K Pure Gold
            Color3.fromRGB(255, 248, 220), -- Champagne Gleam
            Color3.fromRGB(255, 193, 7),   -- Radiant Amber
            Color3.fromRGB(255, 215, 0),   -- 24K Pure Gold
        }
    elseif name == "Rainbow Flow" or name == "Rainbow Gradient" then
        return {
            Color3.fromRGB(255, 23, 68),   -- Vivid Red
            Color3.fromRGB(255, 145, 0),  -- Orange
            Color3.fromRGB(255, 234, 0),  -- Yellow
            Color3.fromRGB(0, 230, 118),  -- Green
            Color3.fromRGB(0, 176, 255),  -- Cyan Blue
            Color3.fromRGB(213, 0, 249),  -- Violet Magenta
        }
    end
    return nil
end

local function resetGradient(grad)
    grad.Enabled = true
    grad.Offset = Vector2.new(0, 0)
    grad.Rotation = 0
    grad.Transparency = NumberSequence.new(0)
end

function Effects.apply(label, colors, mode, janitor)
    if not label then return end

    -- Normalize mode aliases
    local anim = mode or "Rainbow Flow"
    if anim == "Cosmic Glow" or anim == "Rotating / Spinning Gradient (360°)" then
        anim = "Cosmic Spin"
    elseif anim == "Solar Pulse" then
        anim = "Sunset Flare"
    elseif anim == "Wave Shimmer" or anim == "Mirror Gradient" or anim == "Scrolling Gradient" then
        anim = "Ocean Wave"
    elseif anim == "Diagonal Gradient" then
        anim = "Aurora Drift"
    elseif anim == "Golden Crown" then
        anim = "Royal Gold"
    elseif anim == "Rainbow Gradient" or anim == "Neon Pulse" then
        anim = "Rainbow Flow"
    end

    if anim == "Solid" then
        local grad = label:FindFirstChildWhichIsA("UIGradient")
        if grad then grad.Enabled = false end
        if colors and #colors > 0 then
            label.TextColor3 = colors[1]
        end
        return
    end

    -- Always keep TextColor3 pure white so UIGradient renders with 100% full vibrant color fidelity
    label.TextColor3 = Color3.fromRGB(255, 255, 255)

    local grad = getGradient(label)
    resetGradient(grad)

    -- Resolve sequence colors: prioritize custom multi-stop colors if provided, else use official palette
    local sequenceColors = nil
    if colors and #colors >= 2 then
        sequenceColors = colors
    else
        sequenceColors = Effects.getPalette(anim) or Effects.getPalette("Rainbow Flow")
    end

    grad.Color = buildSequence(sequenceColors)

    -- Mobile-optimized hardware accelerated animations via TweenService
    if anim == "Cosmic Spin" then
        grad.Rotation = 0
        local tween = TweenService:Create(
            grad,
            TweenInfo.new(3.0, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false),
            { Rotation = 360 }
        )
        tween:Play()
        if janitor then janitor:Add(tween, "Cancel") end

    elseif anim == "Sunset Flare" then
        grad.Offset = Vector2.new(-1, 0)
        local tween = TweenService:Create(
            grad,
            TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
            { Offset = Vector2.new(1, 0) }
        )
        tween:Play()
        if janitor then janitor:Add(tween, "Cancel") end

    elseif anim == "Ocean Wave" then
        grad.Offset = Vector2.new(-1, 0)
        local tween = TweenService:Create(
            grad,
            TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            { Offset = Vector2.new(1, 0) }
        )
        tween:Play()
        if janitor then janitor:Add(tween, "Cancel") end

    elseif anim == "Aurora Drift" then
        grad.Rotation = 45
        grad.Offset = Vector2.new(-1, -0.5)
        local tween = TweenService:Create(
            grad,
            TweenInfo.new(2.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true),
            { Offset = Vector2.new(1, 0.5) }
        )
        tween:Play()
        if janitor then janitor:Add(tween, "Cancel") end

    elseif anim == "Royal Gold" then
        grad.Offset = Vector2.new(-1.2, 0)
        local tween = TweenService:Create(
            grad,
            TweenInfo.new(2.0, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
            { Offset = Vector2.new(1.2, 0) }
        )
        tween:Play()
        if janitor then janitor:Add(tween, "Cancel") end

    elseif anim == "Rainbow Flow" then
        grad.Offset = Vector2.new(-1, 0)
        local tween = TweenService:Create(
            grad,
            TweenInfo.new(2.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true),
            { Offset = Vector2.new(1, 0) }
        )
        tween:Play()
        if janitor then janitor:Add(tween, "Cancel") end
    end
end

return Effects
