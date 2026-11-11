--!nonstrict
-- local Players = game:GetService("Players")

-- local AdminAnnouncementNotification = require(script.Parent.Parent.Parent.Parent.Notifications.AdminAnnouncementNotification)
local AdminNotification = require(script.Parent.Parent.Parent.Parent.Notifications.AdminNotification)
local Util = require(script.Parent.Parent.Parent.RuntimeHelpers.Util)

local ServiceBinder = {}

function ServiceBinder.bindAnnouncements(runtime)
	-- local service = runtime._service
	-- if not service or not service.Announcement then
		return
	end

function ServiceBinder.bindNotices(runtime)
	local service = runtime._service
	if not service or not service.Notice then 
		return
	end
-- 	runtime._janitor:Add(service.Announcement:Connect(function(payload)
-- 		local msg = payload and payload.message or ""
-- 		if msg == "" then
-- 			return
-- 		end
-- 		local duration = payload and payload.duration or 3
-- 		local displayName = payload and payload.fromDisplayName or payload and payload.from or "Admin"
-- 		local role = payload and payload.fromRole or "Admin"
-- 		local title = role
-- 		local desc = string.format("%s: %s", displayName, msg)

-- 		local userId = payload and payload.fromUserId
-- 		if userId and userId ~= 0 then
-- 			task.spawn(function()
-- 				local ok, content = pcall(function()
-- 					return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
-- 				end)
-- 				if ok then
-- 					AdminAnnouncementNotification.notify(title, desc, content, duration)
-- 				else
-- 					AdminAnnouncementNotification.notify(title, desc, nil, duration)
-- 				end
-- 			end)
-- 		else
-- 			AdminAnnouncementNotification.notify(title, desc, nil, duration)
-- 		end
-- 	end), "Disconnect")
-- end

	runtime._janitor:Add(service.Notice:Connect(function(payload)
		local ok = payload and payload.ok == true
		local message = payload and payload.message or ""
		if message == "" then
			return
		end
		if ok then
			AdminNotification.success(message)
		else
			AdminNotification.error(message)
		end
	end), "Disconnect")
end

function ServiceBinder.bindUptime(runtime)
	local service = runtime._service
	if not service or not service.Uptime then
		return
	end
	runtime._janitor:Add(service.Uptime:Connect(function(seconds)
		if runtime._refs.Time and runtime._refs.Time:IsA("TextLabel") then
			runtime._refs.Time.Text = Util.formatTime(seconds)
		end
	end), "Disconnect")
end

return ServiceBinder