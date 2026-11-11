--!nonstrict
local AdminNotification = require(script.Parent.Parent.Parent.Parent.Notifications.AdminNotification)
local ServiceCall = require(script.Parent.Parent.Actions.ServiceCall)

local Send = {}

function Send.send(runtime)
	local page = runtime._refs.Pages.Announce
	if not page then return end
	local text = ""
	if page.InputText and page.InputText:IsA("TextBox") then
		text = page.InputText.Text or ""
	elseif page.Input and page.Input:IsA("TextLabel") then
		text = page.Input.Text or ""
	end
	local duration = tonumber(page.Duration and page.Duration.Text) or (runtime._bootstrap and runtime._bootstrap.defaultDuration) or 6
	ServiceCall.call(runtime, function()
		return runtime._service:Announce(text, runtime._announceScope, duration)
	end):andThen(function(ok, reason)
		if ok == false then
			AdminNotification.error("Announce failed: " .. tostring(reason))
		else
			AdminNotification.success("Announcement sent")
		end
	end):catch(function(err)
		AdminNotification.error("Announce error")
		warn("[AdminRuntime] announce failed: " .. tostring(err))
	end)
end

return Send
