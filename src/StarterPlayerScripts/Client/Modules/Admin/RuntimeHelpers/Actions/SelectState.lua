--!nonstrict
local SelectState = {}

function SelectState.new()
	return {
		Manager = nil,
		Players = nil,
		Roles = nil,
		Tools = nil,
	}
end

return SelectState
