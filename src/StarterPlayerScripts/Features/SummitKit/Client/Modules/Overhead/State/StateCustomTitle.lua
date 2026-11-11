--!nonstrict
local StateCustomTitle = {}

local function decodeGradient(str)
    if typeof(str) ~= "string" or str == "" then
        return nil
    end
    local colors = {}
    for part in string.gmatch(str, "([^;]+)") do
        local r, g, b = part:match("([^,]+),([^,]+),([^,]+)")
        r, g, b = tonumber(r), tonumber(g), tonumber(b)
        if r and g and b then
            table.insert(colors, Color3.fromRGB(
                math.clamp(r, 0, 255),
                math.clamp(g, 0, 255),
                math.clamp(b, 0, 255)
            ))
        end
    end
    if #colors == 0 then
        return nil
    end
    return colors
end

local function slotName(base, idx)
    return string.format("%s_%d", base, idx)
end

function StateCustomTitle.getCustomTitle(player, config)
    local textAttr = config.CustomTitleTextAttribute or "CustomTitleText"
    local imageAttr = config.CustomTitleImageAttribute or "CustomTitleImage"
    local slotAttr = config.CustomTitleSlotAttribute or "CustomTitleSlot"
    local maxSlots = config.MaxCustomTitleSlots or 8
    local textGradAttr = config.CustomTitleTextGradientAttribute or "CustomTitleTextGradient"
    local colorAttr = config.CustomTitleTextColorAttribute or "CustomTitleTextColor"
    local modeAttr = config.CustomTitleModeAttribute or "CustomTitleMode"

    local slots = {}
    for i = 1, maxSlots do
        local text = player:GetAttribute(slotName(textAttr, i))
        local imageId = player:GetAttribute(slotName(imageAttr, i))
        local hasText = text and text ~= ""
        local hasImage = imageId and imageId ~= ""
        if hasText or hasImage then
            local textColor = player:GetAttribute(slotName(colorAttr, i))
            local grad = decodeGradient(player:GetAttribute(slotName(textGradAttr, i)))
            local colors = {}
            if grad and #grad > 0 then
                colors = grad
            elseif textColor then
                colors = {textColor}
            end
            slots[i] = {
                text = text or "",
                imageId = imageId or "",
                mode = player:GetAttribute(slotName(modeAttr, i)) or "Mirror Gradient",
                colors = colors,
                slot = i,
            }
        end
    end

    if next(slots) == nil then
        return nil
    end

    local activeSlot = math.clamp(tonumber(player:GetAttribute(slotAttr)) or 1, 1, maxSlots)

    return {
        slots = slots,
        slot = activeSlot,
    }
end

return StateCustomTitle
