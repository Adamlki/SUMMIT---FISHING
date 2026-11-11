--!nonstrict
local TweenService = game:GetService("TweenService")

local EntryAnimator = {}

local function cacheAndHide(item)
	local targets = {}

	local function cache(inst, key, current)
		local attr = "_shop_orig_" .. key
		if inst:GetAttribute(attr) == nil then
			inst:SetAttribute(attr, current)
		end
		table.insert(targets, {
			inst = inst,
			key = key,
			value = inst:GetAttribute(attr),
		})
	end

	if item:IsA("TextButton") then
		cache(item, "bg", item.BackgroundTransparency)
		cache(item, "text", item.TextTransparency)
		item.BackgroundTransparency = 1
		item.TextTransparency = 1
	elseif item:IsA("ImageButton") then
		cache(item, "bg", item.BackgroundTransparency)
		cache(item, "image", item.ImageTransparency)
		item.BackgroundTransparency = 1
		item.ImageTransparency = 1
	elseif item:IsA("Frame") then
		cache(item, "bg", item.BackgroundTransparency)
		item.BackgroundTransparency = 1
	end

	for _, child in ipairs(item:GetDescendants()) do
		if child:IsA("TextLabel") then
			cache(child, "text", child.TextTransparency)
			child.TextTransparency = 1
		elseif child:IsA("TextButton") then
			cache(child, "bg", child.BackgroundTransparency)
			cache(child, "text", child.TextTransparency)
			child.BackgroundTransparency = 1
			child.TextTransparency = 1
		elseif child:IsA("ImageLabel") then
			cache(child, "image", child.ImageTransparency)
			child.ImageTransparency = 1
		elseif child:IsA("ImageButton") then
			cache(child, "bg", child.BackgroundTransparency)
			cache(child, "image", child.ImageTransparency)
			child.BackgroundTransparency = 1
			child.ImageTransparency = 1
		elseif child:IsA("Frame") then
			cache(child, "bg", child.BackgroundTransparency)
			child.BackgroundTransparency = 1
		end
	end

	return targets
end

function EntryAnimator.animate(item, index)
	local targets = cacheAndHide(item)
	local info = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	task.delay((index or 0) * 0.03, function()
		if not item or not item.Parent then
			return
		end
		for _, target in ipairs(targets) do
			if target.inst and target.inst.Parent then
				if target.key == "bg" then
					TweenService:Create(target.inst, info, { BackgroundTransparency = target.value }):Play()
				elseif target.key == "text" then
					TweenService:Create(target.inst, info, { TextTransparency = target.value }):Play()
				elseif target.key == "image" then
					TweenService:Create(target.inst, info, { ImageTransparency = target.value }):Play()
				end
			end
		end
	end)
end

return EntryAnimator
