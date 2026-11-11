--!nonstrict
local Players = game:GetService("Players")

local SpectateList = {}

function SpectateList.build(localPlayer, excludedRoles)
	local others = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= localPlayer and not SpectateList.isExcluded(plr, excludedRoles) then
			table.insert(others, plr)
		end
	end
	table.sort(others, function(a, b)
		return a.Name:lower() < b.Name:lower()
	end)
	local list = { localPlayer }
	for _, p in ipairs(others) do
		table.insert(list, p)
	end
	return list
end

function SpectateList.isExcluded(player, excludedRoles)
	local role = player:GetAttribute("RoleTitle") or "Member"
	return excludedRoles[role] == true
end

function SpectateList.findIndex(list, player)
	if not player then return 1 end
	for i, x in ipairs(list) do
		if x == player then return i end
	end
	return 1
end

return SpectateList
