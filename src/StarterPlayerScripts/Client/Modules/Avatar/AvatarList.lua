--!nonstrict
local AvatarList = {}

local function connectButton(btn, cb, janitor)
    if not btn then
        return
    end
    if btn:IsA("TextButton") or btn:IsA("ImageButton") then
        local conn = btn.MouseButton1Click:Connect(cb)
        if janitor then
            janitor:Add(conn, "Disconnect")
        end
    else
        local conn = btn.InputBegan:Connect(function(input)
            if input.UserInputType.Name:match("MouseButton") or input.UserInputType == Enum.UserInputType.Touch then
                cb()
            end
        end)
        if janitor then
            janitor:Add(conn, "Disconnect")
        end
    end
end

local function clearList(listFrame, template)
    for _, child in ipairs(listFrame:GetChildren()) do
        if child ~= template and not child:IsA("UIGridLayout") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") and not child:IsA("UISizeConstraint") then
            child:Destroy()
        end
    end
end

function AvatarList.render(listFrame, template, entries, onSelect, janitor)
    if not (listFrame and template) then
        return
    end

    template.Visible = false
    clearList(listFrame, template)

    for _, entry in ipairs(entries or {}) do
        local item = template:Clone()
        item.Name = "AvatarCard_" .. tostring(entry.UserId or entry.Username)
        if entry.LayoutOrder then
            item.LayoutOrder = entry.LayoutOrder
        end
        item.Visible = true
        item.Parent = listFrame

        -- 1. Pasang foto avatar (AvatarImage)
        local avatarImg = item:FindFirstChild("AvatarImage") or item:FindFirstChild("Ava")
        if avatarImg and avatarImg:IsA("ImageLabel") then
            avatarImg.Image = entry.Thumbnail or ""
        end

        -- 2. Pasang judul preset / reset
        local titleLbl = item:FindFirstChild("Title")
        if titleLbl and titleLbl:IsA("TextLabel") then
            titleLbl.Text = entry.DisplayName or entry.Username or (entry.isReset and "Reset" or "Avatar")
        end

        -- 3. Click handler
        local clickable = item
        if not clickable:IsA("GuiButton") then
            clickable = item:FindFirstChildWhichIsA("GuiButton", true) or item
        end

        if clickable then
            connectButton(clickable, function()
                if onSelect then
                    onSelect(entry)
                end
            end, janitor)
        end
    end
end

return AvatarList
