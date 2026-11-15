--!nonstrict
local Panel = require(script.Parent.Parent.Parent.Parent.UI.Panel)

local MenuState = {}

function MenuState.hideAllPages(runtime)
	if runtime._refs.Right then
		for _, child in ipairs(runtime._refs.Right:GetChildren()) do
			if child:IsA("GuiObject") then
				child.Visible = false
			end
		end
	end
	for _, page in pairs(runtime._refs.Pages or {}) do
		if page and page.Root then
			page.Root.Visible = false
		end
	end
end

function MenuState.applyTabVisual(runtime, activePage)
	local buttons = runtime._tabButtons or {}
	for pageName, btn in pairs(buttons) do
		local active = pageName == activePage
		local activeColor = btn:GetAttribute("ActiveColor")
		local inactiveColor = btn:GetAttribute("InactiveColor")
		local color = active and activeColor or inactiveColor
		if not color or typeof(color) ~= "Color3" then
			color = active and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 255, 255)
		end

		if btn.BackgroundTransparency < 1 then
			btn.BackgroundColor3 = color
		else
			local bg = btn:FindFirstChild("Background", true)
			if bg and bg:IsA("Frame") and bg.BackgroundTransparency < 1 then
				bg.BackgroundColor3 = color
			end
		end
	end
end

function MenuState.showPage(runtime, name)
	MenuState.hideAllPages(runtime)
	for pageName, page in pairs(runtime._refs.Pages or {}) do
		if page and page.Root then
			page.Root.Visible = (pageName == name)
		end
	end
	MenuState.applyTabVisual(runtime, name)
end

function MenuState.toggle(runtime)
	local refs = runtime._refs
	if not refs.Menu or not refs.Root then
		return
	end
	runtime._visible = not Panel.isOpen(refs.Root)
	refs.Menu.Visible = runtime._visible
	if runtime._visible then
		Panel.open(refs.Root)
	else
		Panel.close(refs.Root)
		task.delay(0.25, function()
			if runtime._refs and runtime._refs.Menu and not Panel.isOpen(runtime._refs.Root) then
				runtime._refs.Menu.Visible = false
			end
		end)
	end
end

return MenuState
