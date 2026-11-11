--!nonstrict
local AdminInput = require(script.Parent.Parent.Parent.AdminInput)
local AdminNotification = require(script.Parent.Parent.Parent.Parent.Notifications.AdminNotification)
local Util = require(script.Parent.Parent.Util)
local ServiceCall = require(script.Parent.Parent.Actions.ServiceCall)

local Build = {}

function Build.buildButtons(runtime, destinations)
	local page = runtime._refs.Pages.Teleport
	if not page or not page.Template then return end
	local setTeleportSelected = runtime:_makeSingleSelect()
	page.Template.Visible = false
	Util.clearList(page.Root, page.Template)

	for _, name in ipairs(destinations) do
		local btn = page.Template:Clone()
		btn.Visible = true
		btn.Name = "Teleport_" .. name
		if btn:IsA("TextButton") then
			btn.Text = name
		end
		btn.Parent = page.Root
		btn:SetAttribute("NoClickFlash", true)
		AdminInput.bindButton(runtime._janitor, btn, function()
			setTeleportSelected(btn)
			ServiceCall.call(runtime, function()
				return runtime._service:Teleport(name)
			end):andThen(function(ok, reason)
				if ok == false then
					AdminNotification.error("Teleport failed: " .. tostring(reason))
				else
					AdminNotification.success("Teleported")
				end
			end):catch(function(err)
				AdminNotification.error("Teleport error")
				warn("[AdminRuntime] teleport failed: " .. tostring(err))
			end)
		end)
	end
end

return Build
