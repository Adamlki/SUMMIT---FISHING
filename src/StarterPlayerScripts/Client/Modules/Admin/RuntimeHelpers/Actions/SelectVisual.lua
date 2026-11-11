--!nonstrict
local SelectVisual = {}

function SelectVisual.apply(runtime, button, selected)
	runtime:_applySelectVisual(button, selected)
end

function SelectVisual.makeSingle(runtime)
	return runtime:_makeSingleSelect()
end

return SelectVisual
