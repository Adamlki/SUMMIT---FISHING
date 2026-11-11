--!nonstrict
local Promise = require(game:GetService("ReplicatedStorage").Shared.Packages.Promise)
local AvatarFetcher = require(script.Parent.Parent.AvatarFetcher)

local AvatarActions = {}

local _queryInFlight = false 
local _lastQueryKey = nil 

local function normalizeQuery(username)
    local text = tostring(username or "")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text 
end

local function findExistingIndex(entries, result)
    if not result then 
        return nil 
    end

    for index, entry in ipairs(entries) do 
        if result.UserId and entry.UserId == result.UserId then 
            return index 
        end 
        if result.Username and entry.Username and string.lower(entry.Username) == string.lower(result.Username) then 
            return index
        end 
    end

    return nil
end

function AvatarActions.query(entries, refreshList, username)
    local query = normalizeQuery(username)
    if query == "" then 
        return 
    end

    local queryKey = string.lower(query)
    if _queryInFlight and _lastQueryKey == queryKey then
        return
    end

    if _queryInFlight then
        return
    end

    local _queryInFlight = true 
    local _lastQueryKey = queryKey 

    Promise.try(function()
        return AvatarFetcher.fetch(query)
        end):andThen(function(result)
        if result then 
        local existingIndex = findExistingIndex(entries, result)
        if existingIndex then 
            table.remove(entries, existingIndex)
        end 
        table.insert(entries, 1, result)
        refreshList()
        else
            warn("[AVATARUI] Gagal getch ava nggo arek:" .. tostring(query))
        end
    end):catch(function(err)
        warn("[AVATARUI] Gagal Search:" .. tostring(err))
    end):finally(function()
        _queryInFlight = false
    end)
end

function AvatarActions.apply(avatarService, notifyAvatarError, entry)
	if not entry or not avatarService then
		return
	end

	if entry.isReset then
		local result = avatarService:ResetAvatar()
		if Promise.is(result) then
			result:andThen(function(success)
				if success == false then
					notifyAvatarError("Unable to reset avatar right now")
				end
			end)
		elseif result == false then
			notifyAvatarError("Unable to reset avatar right now")
		end
		return
	end

	if entry.UserId then
		local result = avatarService:ChangeAvatar(entry.UserId)
		if Promise.is(result) then
			result:andThen(function(success, reason)
				if success == false then
					local msg = "Failed to change avatar"
					if reason == "HoldingTools" then
						msg = "Cannot change avatar while holding tools"
					elseif reason == "Cooldown" then
						msg = "Please wait before changing your avatar again"
					end
					notifyAvatarError(msg)
				end
			end)
		elseif result == false then
			notifyAvatarError("Failed to change avatar")
		end
	end
end

-- function AvatarActions.query(entries, refreshList, username)
-- 	local result = AvatarFetcher.fetch(username)
-- 	if result then
-- 		table.insert(entries, 1, result)
-- 		refreshList()
-- 	else
-- 		warn("[AvatarUI] Gagal fetch avatar untuk: " .. tostring(username))
-- 	end
-- end

-- function AvatarActions.apply(avatarService, notifyAvatarError, entry)
-- 	if not entry or not avatarService then
-- 		return
-- 	end

-- 	if entry.isReset then
-- 		local result = avatarService:ResetAvatar()
-- 		if Promise.is(result) then
-- 			result:andThen(function(success)
-- 				if success == false then
-- 					notifyAvatarError("Unable to reset avatar right now")
-- 				end
-- 			end)
-- 		elseif result == false then
-- 			notifyAvatarError("Unable to reset avatar right now")
-- 		end
-- 		return
-- 	end

-- 	if entry.UserId then
-- 		local result = avatarService:ChangeAvatar(entry.UserId)
-- 		if Promise.is(result) then
-- 			result:andThen(function(success, reason)
-- 				if success == false then
-- 					local msg = "Failed to change avatar"
-- 					if reason == "HoldingTools" then
-- 						msg = "Cannot change avatar while holding tools"
-- 					elseif reason == "Cooldown" then
-- 						msg = "Please wait before changing your avatar again"
-- 					end
-- 					notifyAvatarError(msg)
-- 				end
-- 			end)
-- 		elseif result == false then
-- 			notifyAvatarError("Failed to change avatar")
-- 		end
-- 	end
-- end

return AvatarActions
