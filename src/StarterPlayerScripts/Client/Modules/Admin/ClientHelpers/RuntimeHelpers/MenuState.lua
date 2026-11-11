--!nonstrict
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
	runtime._visible = not runtime._visible
	if runtime._visible then
		if runtime._refs.Menu then
			runtime._refs.Menu.Visible = true
		end
		local conn = runtime._animator:Open()
		if conn then
			runtime._janitor:Add(conn, "Disconnect")
		end
	else
		local conn = runtime._animator:Close()
		if conn then
			runtime._janitor:Add(conn, "Disconnect")
		end
		if runtime._refs.Menu then
			task.delay(0.22, function()
				if runtime._refs and runtime._refs.Menu and not runtime._visible then
					runtime._refs.Menu.Visible = false
				end
			end)
		end
	end
end

return MenuState
