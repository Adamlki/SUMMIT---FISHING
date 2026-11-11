--!nonstrict
local StateSummits = {}

function StateSummits.getSummits(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    local summit = leaderstats and leaderstats:FindFirstChild("Summit")
    return summit and summit.Value or 0
end

return StateSummits
