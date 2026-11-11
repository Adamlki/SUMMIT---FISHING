--!nonstrict
local Bind = {}

function Bind.bind(runtime)
	local page = runtime._refs.Pages.Teleport
	if not page or not page.Root then return end
end

return Bind
