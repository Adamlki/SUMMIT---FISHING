--!nonstrict
local ColorParser = {}

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function fromHex(hex)
    if #hex == 3 then
        local r = tonumber(hex:sub(1, 1) .. hex:sub(1, 1), 16)
        local g = tonumber(hex:sub(2, 2) .. hex:sub(2, 2), 16)
        local b = tonumber(hex:sub(3, 3) .. hex:sub(3, 3), 16)
        if r and g and b then
            return Color3.fromRGB(r, g, b)
        end
    elseif #hex == 6 then
        local r = tonumber(hex:sub(1, 2), 16)
        local g = tonumber(hex:sub(3, 4), 16)
        local b = tonumber(hex:sub(5, 6), 16)
        if r and g and b then
            return Color3.fromRGB(r, g, b)
        end
    end
    return nil
end

function ColorParser.parse(text)
    if not text then
        return nil
    end
    local raw = trim(tostring(text))
    if raw == "" then
        return nil
    end
    if raw:sub(1, 1) == "#" then
        return fromHex(raw:sub(2))
    end
    if raw:match("^%x%x%x%x%x%x$") or raw:match("^%x%x%x$") then
        return fromHex(raw)
    end
    local parts = {}
    for part in raw:gmatch("[^,%s]+") do
        table.insert(parts, part)
    end
    if #parts >= 3 then
        local r = tonumber(parts[1])
        local g = tonumber(parts[2])
        local b = tonumber(parts[3])
        if r and g and b then
            return Color3.fromRGB(
                math.clamp(math.floor(r + 0.5), 0, 255),
                math.clamp(math.floor(g + 0.5), 0, 255),
                math.clamp(math.floor(b + 0.5), 0, 255)
            )
        end
    end
    return nil
end

return ColorParser
