--!nonstrict
local Players = game:GetService("Players")

local EntryAnimator = require(script.Parent.EntryAnimator)

local PlayerListRenderer = {}

local function isButton(gui)
	return gui and (gui:IsA("TextButton") or gui:IsA("ImageButton"))
end

local function applyAvatar(icon, userId)
	if not icon or not userId then
		return
	end
	task.spawn(function()
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok and icon and icon.Parent then
			icon.Image = content
		end
	end)
end

function PlayerListRenderer.clear(listFrame)
	if not listFrame then
		return
	end
	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then
			if child.Name == "Template" then
				child.Visible = false
			else
				child:Destroy()
			end
		end
	end
end

function PlayerListRenderer.render(refs, onSelect)
	if not (refs.playerList and refs.playerTemplate) then
		return
	end
	PlayerListRenderer.clear(refs.playerList)

	local index = 0
	for _, player in ipairs(Players:GetPlayers()) do
		local item = refs.playerTemplate:Clone()
		item.Name = "PlayerItem"
		item.Visible = true
		item.Parent = refs.playerList

		local nameFrame = item:FindFirstChild("Name")
		local textLabel = nameFrame and nameFrame:FindFirstChild("Text")
		if textLabel and textLabel:IsA("TextLabel") then
			textLabel.Text = player.DisplayName ~= "" and player.DisplayName or player.Name
		end
		local icon = item:FindFirstChild("Icon")
		if icon and icon:IsA("ImageLabel") then
			applyAvatar(icon, player.UserId)
		end

		local selectable = item
		if not isButton(item) then
			selectable = item:FindFirstChildWhichIsA("TextButton") or item:FindFirstChildWhichIsA("ImageButton")
		end
		if selectable and onSelect then
			selectable.MouseButton1Click:Connect(function()
				onSelect(player)
			end)
		end

		EntryAnimator.animate(item, index)
		index += 1
	end
end

return PlayerListRenderer
