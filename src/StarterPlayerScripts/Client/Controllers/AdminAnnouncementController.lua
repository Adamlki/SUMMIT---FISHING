local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared 
local Packages = Shared.Packages
local Knit = require(Packages.Knit)
local Janitor = require(Packages.Janitor)

local AdminAnnouncementNotification = require(script.Parent.Parent.Modules.Notifications.AdminAnnouncementNotification)

local Controller = Knit.CreateController ({ Name = "AdminAnnouncementController" })

function Controller:KnitStart()
    self._janitor = Janitor.new()
    local adminService = Knit.GetService("AdminService")
    if not adminService or not adminService.Announcement then 
        return
    end 

    self._janitor:Add(adminService.Announcement:Connect(function(payload)
        local msg = payload and payload.message or ""
        if msg == "" then 
        return end
        
        local duration = payload and payload.duration or 3
        local displayName = payload and payload.fromDisplayName or payload and payload.from or "Admin"
        local role = payload and payload.fromRole or "Admin"
        local scope = payload and payload.scope or "Server"
        local title = string.format("%s Announcement", tostring(scope))
        local desc = string.format("%s - %s: %s", tostring(role), tostring(displayName), msg)
    
        local userId = payload and payload.fromUserId 
        if userId and userId ~= 0 then 
            task.spawn(function()
                local ok, content = pcall(function()
                    return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                end)
                if ok then 
                    AdminAnnouncementNotification.notify(title, desc, content, duration)
                else
                    AdminAnnouncementNotification.notify(title, desc, nil, duration)
                end
            end)
        else 
            AdminAnnouncementNotification.notify(title, desc, nil, duration)
        end
    end), "Disconnect")
end

function Controller:KnitStop()
    if self._janitor then 
        self._janitor:Destroy()
        self._janitor = nil 
    end 
end

return Controller