--!nonstrict
local AdminInput = require(script.Parent.Parent.Parent.AdminInput)
local AdminNotification = require(script.Parent.Parent.Parent.Parent.Notifications.AdminNotification)
local ServiceCall = require(script.Parent.Parent.Actions.ServiceCall)

local Bind = {}

function Bind.bind(runtime)
	local page = runtime._refs.Pages.Server
	if not page or not page.Root then return end
	local setSelected = runtime:_makeSingleSelect()
	local pending = nil

	local function choose(button, action)
		pending = action
		setSelected(button)
	end

	if page.Restart then
		AdminInput.bindButton(runtime._janitor, page.Restart, function()
			choose(page.Restart, "Restart")
		end)
		page.Restart:SetAttribute("NoClickFlash", true)
	end
	if page.Shutdown then
		AdminInput.bindButton(runtime._janitor, page.Shutdown, function()
			choose(page.Shutdown, "Shutdown")
		end)
		page.Shutdown:SetAttribute("NoClickFlash", true)
	end
	if page.Lock then
		AdminInput.bindButton(runtime._janitor, page.Lock, function()
			choose(page.Lock, "Lock")
		end)
		page.Lock:SetAttribute("NoClickFlash", true)
	end
	if page.Unlock then
		AdminInput.bindButton(runtime._janitor, page.Unlock, function()
			choose(page.Unlock, "Unlock")
		end)
		page.Unlock:SetAttribute("NoClickFlash", true)
	end

	if page.Confirm then
		AdminInput.bindButton(runtime._janitor, page.Confirm, function()
			if not pending then
				AdminNotification.error("Select action first")
				return
			end
			ServiceCall.call(runtime, function()
				return runtime._service:ServerControl(pending)
			end):andThen(function(ok, reason)
				if ok == false then
					AdminNotification.error("Server action failed: " .. tostring(reason))
				else
					AdminNotification.success("Server action sent")
				end
			end):catch(function(err)
				local msg = tostring(err)
				AdminNotification.error("Server action error: " .. msg)
				warn("[AdminRuntime] server action failed: " .. msg)
			end)
		end)
		page.Confirm:SetAttribute("NoClickFlash", true)
	end
	if page.Cancel then
		AdminInput.bindButton(runtime._janitor, page.Cancel, function()
			pending = nil
			setSelected(nil)
		end)
		page.Cancel:SetAttribute("NoClickFlash", true)
	end
end

return Bind
