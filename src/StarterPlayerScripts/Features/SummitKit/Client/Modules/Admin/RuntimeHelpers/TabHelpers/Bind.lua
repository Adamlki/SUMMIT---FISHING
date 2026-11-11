--!nonstrict
local AdminInput = require(script.Parent.Parent.Parent.AdminInput)

local Bind = {}

function Bind.bind(runtime)
	local left = runtime._refs.Left or {}
	local map = {
		Announce = "Announce",
		Event = "Event",
		Manage = "Manager",
		Players = "Players",
		Role = "Roles",
		Logs = "Logs",
		Server = "Server",
		Teleport = "Teleport",
		Tools = "Tools",
	}
	runtime._tabButtons = {}

	local function disableFlash(node)
		if not node then return end
		node:SetAttribute("NoClickFlash", true)
	end

	local function bindAllClickable(node, onClick)
		if not node then return end
		disableFlash(node)
		AdminInput.bindButton(runtime._janitor, node, onClick)
		for _, child in ipairs(node:GetDescendants()) do
			if child:IsA("GuiButton") or child:IsA("ImageLabel") or child:IsA("Frame") then
				disableFlash(child)
				AdminInput.bindButton(runtime._janitor, child, onClick)
			end
		end
	end

	for btnName, pageName in pairs(map) do
		local btn = left[btnName]
		if btn then
			runtime._tabButtons[pageName] = btn
		end
		bindAllClickable(btn, function()
			runtime:_showPage(pageName)
		end)
	end
	runtime:_hideAllPages()
	runtime:_showPage("Manager")
end

return Bind
