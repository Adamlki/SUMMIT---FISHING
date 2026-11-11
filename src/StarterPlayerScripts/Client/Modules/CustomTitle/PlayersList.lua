--!nonstrict
local Players = game:GetService("Players")

local PlayersList = {}

local function clearList(list, template)
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("GuiButton") and child ~= template then
            child:Destroy()
        end
    end
end

function PlayersList.Rebuild(refs, onSelect, query)
    if not (refs.PlayersList and refs.PlayerTemplate) then
        return
    end
    clearList(refs.PlayersList, refs.PlayerTemplate)
    local q = string.lower(query or "")
    for _, player in ipairs(Players:GetPlayers()) do
        local name = string.lower(player.Name)
        local display = string.lower(player.DisplayName)
        if q == "" or name:find(q, 1, true) or display:find(q, 1, true) then
            local btn = refs.PlayerTemplate:Clone()
            btn.Name = player.Name
            btn.Text = player.DisplayName
            btn.Visible = true
            btn.Parent = refs.PlayersList
            btn.MouseButton1Click:Connect(function()
                onSelect(player, btn)
            end)
        end
    end
end

return PlayersList
