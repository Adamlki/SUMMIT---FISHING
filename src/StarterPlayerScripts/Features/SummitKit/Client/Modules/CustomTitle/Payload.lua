--!nonstrict
local Payload = {}

local function colorToArray(color)
    return {
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5),
    }
end

function Payload.Build(state)
    local view = state:buildView()
    local colors = {}
    for _, c in ipairs(view.Colors) do
        table.insert(colors, colorToArray(c))
    end
    return {
        slot = view.Slot,
        mode = view.Mode,
        text = view.Text,
        colors = colors,
    }
end

return Payload
