--!nonstrict
local Players = game:GetService("Players")

local AdminInput = require(script.Parent.Parent.Parent.AdminInput)
local Avatars = require(script.Parent.Avatars)

local Lists = {}

function Lists.clearList(list, template)
	if not list then return end
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("GuiButton") and child ~= template then
			child:Destroy()
		end
	end
end

function Lists.buildPlayerList(params)
	local janitor = params.janitor
	local list = params.list
	local template = params.template
	local onSelect = params.onSelect
	local onRemove = params.onRemove
	local applySelect = params.applySelect

	if not (list and template) then return nil end
	template.Visible = false
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("GuiButton") and child.Name:sub(1, 7) == "Player_" then
			child:Destroy()
		end
	end

	local obj = {
		list = list,
		template = template,
		entries = {},
		selected = nil,
		selectedButton = nil,
	}

	local function addPlayer(player)
		local item = template:Clone()
		item.Visible = true
		item.Name = "Player_" .. player.UserId
		item.Parent = list
		item:SetAttribute("NoClickFlash", true)

		local icon = item:FindFirstChild("Icon") or (item:FindFirstChild("Avatar") and item.Avatar:FindFirstChild("Icon"))
		if icon and icon:IsA("ImageLabel") then
			Avatars.setAvatar(icon, player)
		end

		local nameLabel = item:FindFirstChild("Name")
		if nameLabel and nameLabel:IsA("TextLabel") then
			nameLabel.Text = player.DisplayName or player.Name
		end

		local removeBtn = item:FindFirstChild("Remove") or item:FindFirstChild("RemoveRole") or item:FindFirstChild("RemoveBtn")
		if removeBtn and onRemove then
			removeBtn:SetAttribute("NoClickFlash", true)
			AdminInput.bindButton(janitor, removeBtn, function()
				onRemove(player)
			end)
		end

		obj.entries[player] = item
		local function onClick()
			if obj.selectedButton and obj.selectedButton.Parent then
				applySelect(obj.selectedButton, false)
			end
			obj.selectedButton = item
			applySelect(item, true)
			obj.selected = player
			if onSelect then
				onSelect(player)
			end
		end
		AdminInput.bindButton(janitor, item, onClick)
		for _, child in ipairs(item:GetDescendants()) do
			if child:IsA("GuiButton") or child:IsA("ImageLabel") or child:IsA("Frame") then
				AdminInput.bindButton(janitor, child, onClick)
			end
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		addPlayer(player)
	end

	janitor:Add(Players.PlayerAdded:Connect(function(player)
		addPlayer(player)
	end), "Disconnect")
	janitor:Add(Players.PlayerRemoving:Connect(function(player)
		local item = obj.entries[player]
		if item then
			item:Destroy()
			obj.entries[player] = nil
		end
		if obj.selected == player then
			obj.selected = nil
			obj.selectedButton = nil
		end
	end), "Disconnect")

	return obj
end

return Lists
