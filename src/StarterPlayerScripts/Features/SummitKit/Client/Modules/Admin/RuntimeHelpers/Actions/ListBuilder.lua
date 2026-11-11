--!nonstrict
local ListBuilder = {}

function ListBuilder.build(runtime, list, template, onSelect, onRemove)
	return runtime:_buildPlayerList(list, template, onSelect, onRemove)
end

return ListBuilder
