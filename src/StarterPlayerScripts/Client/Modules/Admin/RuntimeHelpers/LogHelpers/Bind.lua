--!nonstrict
local Bind = {}

function Bind.bind(runtime)
	local page = runtime._refs.Pages.Logs
	if not page or not page.Root or not page.Template then return end
	page.Template.Visible = false
	if runtime._service and runtime._service.Log then
		runtime._janitor:Add(runtime._service.Log:Connect(function(entry)
			local Render = require(script.Parent.Render)
			Render.push(runtime, entry)
		end), "Disconnect")
	end
end

return Bind
