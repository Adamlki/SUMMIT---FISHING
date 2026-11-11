--!nonstrict
local TweenService = game:GetService("TweenService")

local Renderer = {}

local function clearList(list, template)
	for _, child in ipairs(list:GetChildren()) do
		if (child:IsA("Frame") or child:IsA("GuiButton")) and child ~= template then
			child:Destroy()
		end
	end
end

function Renderer.render(list, template, data, categoryName, categoryIcon, onSelect, janitor)
	if not list or not template then
		return
	end
	template.Visible = false
	clearList(list, template)

	for i, song in ipairs(data or {}) do
		local item = template:Clone()
		item.Visible = true
		item.Active = true
		item.Name = "Song_" .. i

		local img = item:FindFirstChild("ImageMusic")
		if img and (img:IsA("ImageLabel") or img:IsA("ImageButton")) then
			img.Image = song.Image or categoryIcon or ""
		end

		local textFrame = item:FindFirstChild("Frame")
		if textFrame then
			local titleLbl = textFrame:FindFirstChild("TitleMusic")
			local playlistLbl = textFrame:FindFirstChild("TitlePlaylistMusic")
			if titleLbl and titleLbl:IsA("TextLabel") then
				titleLbl.Text = song.Title or "Unknown"
			end
			if playlistLbl and playlistLbl:IsA("TextLabel") then
				playlistLbl.Text = "Playlist: " .. (categoryName or "Indonesia")
			end
		end

		local hitbox = item:FindFirstChild("HitboxButton")
		if not hitbox then
			hitbox = Instance.new("TextButton")
			hitbox.Name = "HitboxButton"
			hitbox.Size = UDim2.new(1, 0, 1, 0)
			hitbox.Position = UDim2.new(0, 0, 0, 0)
			hitbox.BackgroundTransparency = 1
			hitbox.Text = ""
			hitbox.ZIndex = 10
			hitbox.Active = true
			hitbox.Parent = item
		end

		local uiScale = item:FindFirstChildOfClass("UIScale")
		local baseScale = uiScale and uiScale.Scale or 0.8

		janitor:Add(hitbox.Activated:Connect(function()
			if uiScale then
				TweenService:Create(uiScale, TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Scale = baseScale * 0.95 }):Play()
				task.delay(0.1, function()
					if uiScale and uiScale.Parent then
						TweenService:Create(uiScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = baseScale }):Play()
					end
				end)
			end
			onSelect(i)
		end), "Disconnect")

		janitor:Add(hitbox.MouseEnter:Connect(function()
			if uiScale then
				TweenService:Create(uiScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = baseScale * 1.03 }):Play()
			end
		end), "Disconnect")

		janitor:Add(hitbox.MouseLeave:Connect(function()
			if uiScale then
				TweenService:Create(uiScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = baseScale }):Play()
			end
		end), "Disconnect")

		item.Parent = list
		janitor:Add(item, "Destroy")
	end
end

return Renderer
