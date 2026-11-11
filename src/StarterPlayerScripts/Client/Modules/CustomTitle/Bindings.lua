--!nonstrict
local BindingHelpers = script.Parent:WaitForChild("BindingHelpers")
local ActionBinder = require(BindingHelpers:WaitForChild("ActionBinder"))

local Bindings = {}

function Bindings.Bind(ctx, refs, overheadService, actions)
	ActionBinder.bindButtons(ctx, refs, overheadService, actions)
	ActionBinder.bindTextBoxes(ctx, refs)
end

return Bindings
