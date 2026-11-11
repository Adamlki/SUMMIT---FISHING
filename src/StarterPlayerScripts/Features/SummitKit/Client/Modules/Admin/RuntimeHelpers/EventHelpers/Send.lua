--!nonstrict
local AdminNotification = require(script.Parent.Parent.Parent.Parent.Notifications.AdminNotification)
local ServiceCall = require(script.Parent.Parent.Actions.ServiceCall)

local Send = {}

function Send.send(runtime)
	local page = runtime._refs.Pages.Event
	if not page then
		return
	end

	local durationHours = tonumber(page.DurationText and page.DurationText.Text) or 0
	local summitValue = tonumber(page.ValueText and page.ValueText.Text) or 0

	if durationHours <= 0 then
		AdminNotification.error("Duration harus lebih dari 0 jam")
		return
	end

	if summitValue <= 0 then
		AdminNotification.error("Reward summit harus lebih dari 0")
		return
	end

	ServiceCall.call(runtime, function()
		return runtime._service:SetSummitEvent(durationHours, summitValue)
	end):andThen(function(ok, reason, payload)
		if ok == false then
			AdminNotification.error("Summit event gagal: " .. tostring(reason))
			return
		end

		local endsAt = payload and payload.endsAtText or (tostring(durationHours) .. "h")
		AdminNotification.success(string.format("Summit event aktif sampai %s", tostring(endsAt)))
	end):catch(function(err)
		AdminNotification.error("Summit event error")
		warn("[AdminRuntime] summit event failed: " .. tostring(err))
	end)
end

return Send
