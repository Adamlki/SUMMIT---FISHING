--!nonstrict
local Players = game:GetService("Players")

local AvatarFetcher = {}
local userIdCache = {}

local function getUserId(identifier)
    if typeof(identifier) == "number" then
        return identifier
    end
    if typeof(identifier) ~= "string" or identifier == "" then
        return nil
    end
    if tonumber(identifier) then
        return tonumber(identifier)
    end
    local cached = userIdCache[identifier:lower()]
    if cached then
        return cached
    end
    local ok, uid = pcall(function()
        return Players:GetUserIdFromNameAsync(identifier)
    end)
    if ok and uid then
        userIdCache[identifier:lower()] = uid
        return uid
    end
    return nil
end

local function getThumbnail(userId)
    if not userId or userId <= 0 then
        return ""
    end
    -- Instant non-blocking Roblox native engine streaming!
    -- 0ms blocking time, loaded in background by C++ content provider
    return string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=420&h=420", userId)
end

function AvatarFetcher.fetch(identifier)
    if not identifier or identifier == "" then
        return nil
    end
    local userId = getUserId(identifier)
    if not userId then
        return nil
    end
    return {
        UserId = userId,
        Username = typeof(identifier) == "string" and identifier or tostring(userId),
        Thumbnail = getThumbnail(userId),
        Description = nil,
    }
end

return AvatarFetcher
