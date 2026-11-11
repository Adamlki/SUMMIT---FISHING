--!nonstrict
local EntryAnimator = require(script.Parent.EntryAnimator)

local ToolListRenderer = {}

local TOOLS_PER_GROUP = 3

function ToolListRenderer.render(refs, state)
	local shopList = refs and refs.shopList
	local toolsFrame = refs and refs.toolsFrame
	local template = refs and refs.toolTemplate
	if not (shopList and toolsFrame and template) then
		return {}
	end

	for _, child in ipairs(shopList:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("^ToolsGroup_") then
			child:Destroy()
		end
	end

	toolsFrame.Visible = false

	local function clearGroup(group)
		for _, child in ipairs(group:GetChildren()) do
			if child:IsA("Frame") and child ~= template and child.Name:match("^Tool_") then
				child:Destroy()
			end
		end
	end

	local function createGroup(groupIndex)
		local group = toolsFrame:Clone()
		group.Name = "ToolsGroup_" .. tostring(groupIndex)
		group.Visible = true
		group.LayoutOrder = (toolsFrame.LayoutOrder or 0) + groupIndex - 1
		group.Parent = shopList

		local groupTemplate = group:FindFirstChild("Template")
		if groupTemplate and groupTemplate:IsA("Frame") then
			for _, child in ipairs(group:GetChildren()) do
				if child:IsA("Frame") and child ~= groupTemplate and child.Name:match("^Tool_") then
					child:Destroy()
				end
			end
			groupTemplate.Visible = false
		end

		return group, groupTemplate
	end

	clearGroup(toolsFrame)
	template.Visible = false

	local rendered = {}
	local index = 0
	local currentGroupIndex = 0
	local currentGroup = nil
	local currentTemplate = nil

	for entryIndex, entry in ipairs(state.catalog or {}) do
		local slotIndex = ((entryIndex - 1) % TOOLS_PER_GROUP) + 1
		if slotIndex == 1 then
			currentGroupIndex += 1
			currentGroup, currentTemplate = createGroup(currentGroupIndex)
		end

		if not (currentGroup and currentTemplate) then
			continue
		end

		local item = currentTemplate:Clone()
		item.Name = "Tool_" .. tostring(entry.ToolId)
		item.Visible = true
		item.LayoutOrder = slotIndex
		item.Parent = currentGroup

		local title = item:FindFirstChild("Title")
		if title and title:IsA("TextLabel") then
			title.Text = tostring(entry.Title or entry.ToolName or entry.ToolId)
		end

		local icon = item:FindFirstChild("Icon")
		if icon and icon:IsA("ImageLabel") then
			icon.Image = tostring(entry.Icon or "")
		end

		local actions = item:FindFirstChild("Actions")
		local buyBtn = actions and actions:FindFirstChild("Buy")
		local giftBtn = actions and actions:FindFirstChild("Gift")
		local owned = state.ownedTools and state.ownedTools[entry.ToolId] == true

		if buyBtn and buyBtn:IsA("TextButton") then
			buyBtn.Text = owned and "Owned" or "Buy"
			buyBtn.AutoButtonColor = not owned
			buyBtn.Active = not owned
		end
		if giftBtn and giftBtn:IsA("GuiButton") then
			local canGift = entry.GiftProductId ~= nil
			giftBtn.Visible = canGift
			giftBtn.Active = canGift
		end

		rendered[entry.ToolId] = {
			Root = item,
			Buy = buyBtn,
			Gift = giftBtn,
			Entry = entry,
			Owned = owned,
		}

		EntryAnimator.animate(item, index)
		index += 1
	end

	return rendered
end

return ToolListRenderer
