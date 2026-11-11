--!nonstrict
local AdminInput = require(script.Parent.Parent.Parent.AdminInput)
local AdminNotification = require(script.Parent.Parent.Parent.Parent.Notifications.AdminNotification)
local ListBuilder = require(script.Parent.Parent.Actions.ListBuilder)
local ServiceCall = require(script.Parent.Parent.Actions.ServiceCall)

local Bind = {}

function Bind.bind(runtime)
	local page = runtime._refs.Pages.Roles
	if not page or not page.Root then return end
	if page.PlayersBtn and page.List then
		AdminInput.bindButton(runtime._janitor, page.PlayersBtn, function()
			page.List.Visible = not page.List.Visible
		end)
		page.PlayersBtn:SetAttribute("NoClickFlash", true)
	end
	ListBuilder.build(runtime, page.List, page.Template, function(player)
		runtime._selected.Roles = player
	end, function(player)
		ServiceCall.call(runtime, function()
			return runtime._service:RemoveRole(player.UserId)
		end):andThen(function(ok, reason)
			if ok == false then
				AdminNotification.error("Remove role failed: " .. tostring(reason))
			else
				AdminNotification.success("Role removed")
			end
		end):catch(function(err)
			AdminNotification.error("Remove role error")
			warn("[AdminRuntime] remove role failed: " .. tostring(err))
		end)
	end)
end

return Bind
