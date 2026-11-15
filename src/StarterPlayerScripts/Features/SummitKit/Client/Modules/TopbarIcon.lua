--!nonstrict
-- Thin wrapper over TopbarPlus (ReplicatedStorage.Icon, v3).
-- Swap the image IDs here; both icons are image-only, right-aligned.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TopbarIcon = {}

TopbarIcon.Images = {
    Settings = "rbxassetid://7734053495",
    Admin = "rbxassetid://7734056608",
}

local function getIconLib()
    local ok, lib = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Icon", 15))
    end)
    if ok then
        return lib
    end
    return nil
end

-- onClick fires once per click; the icon never stays selected.
function TopbarIcon.create(imageId, onClick)
    local Icon = getIconLib()
    if not Icon then
        warn("[TopbarIcon] TopbarPlus (ReplicatedStorage.Icon) not found")
        return nil
    end
    local icon = Icon.new()
    icon:setImage(imageId)
    icon:setRight()
    icon:oneClick(true)
    icon.toggled:Connect(function(isSelected)
        if isSelected then
            onClick()
        end
    end)
    return icon
end

return TopbarIcon
