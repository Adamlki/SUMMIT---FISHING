--!nonstrict
local AdminInput = require(script.Parent.Parent.Parent.AdminInput)
local ListBuilder = require(script.Parent.Parent.Actions.ListBuilder)

local Bind = {}

function Bind.bind(runtime)
	local page = runtime._refs.Pages.Tools
	if not page or not page.Root then return end
	if page.PlayersBtn and page.List then
		AdminInput.bindButton(runtime._janitor, page.PlayersBtn, function()
			page.List.Visible = not page.List.Visible
		end)
		page.PlayersBtn:SetAttribute("NoClickFlash", true)
	end
	ListBuilder.build(runtime, page.List, page.Template, function(player)
		runtime._selected.Tools = player
	end)
end

return Bind
