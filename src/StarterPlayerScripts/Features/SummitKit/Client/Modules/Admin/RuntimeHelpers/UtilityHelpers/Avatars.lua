--!nonstrict
local Players = game:GetService("Players")

local Avatars = {}

function Avatars.setAvatar(icon, player)
	if not icon or not player then return end
	task.spawn(function()
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if ok and icon and icon.Parent then
			icon.Image = content
		end
	end)
end

function Avatars.setAvatarByUserId(icon, userId)
	if not icon or not userId then return end
	task.spawn(function()
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if ok and icon and icon.Parent then
			icon.Image = content
		end
	end)
end

return Avatars
