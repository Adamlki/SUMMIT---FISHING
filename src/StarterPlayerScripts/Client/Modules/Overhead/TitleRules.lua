--!nonstrict
local TitleRules = {}

local function pickSummitTitle(summitLevels, summits)
    if not summitLevels or #summitLevels == 0 then
        return "Pendaki", nil
    end
    local title = summitLevels[1].Title or "Pendaki"
    local color = summitLevels[1].Color
    for _, step in ipairs(summitLevels) do
        if summits >= (step.Min or 0) then
            title = step.Title or title
            color = step.Color or color
        else
            break
        end
    end
    return title, color
end

function TitleRules.getTitle(configTitle, state)
    local titleCfg = configTitle or {}
    return pickSummitTitle(titleCfg.SummitLevels, state.summits or 0)
end

return TitleRules
