-- Session resume state and the remote-sell permission flag.
local Session = {}

function Session:SetLastSessionState(player, stateData)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end
	profile.Data.LastSessionState = stateData
	return true
end

function Session:GetLastSessionState(player)
	local profile = self:GetProfile(player)
	if not profile then return nil end
	return profile.Data.LastSessionState
end

function Session:HasRemoteSell(player)
	local profile = self:GetProfile(player)
	if not profile then return false end
	return profile.Data.HasRemoteSell == true
end

function Session:SetRemoteSell(player, val)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end
	profile.Data.HasRemoteSell = val
	player:SetAttribute("HasRemoteSell", val)
	return true
end

return Session
