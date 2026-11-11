--!nonstrict
local AdminInput = require(script.Parent.Parent.Parent.AdminInput)

local Bind = {}

function Bind.bind(runtime)
	local page = runtime._refs.Pages.Event
	if not page or not page.Root then
		return
	end

	local function markNoClickFlash(button)
		if button then
			button:SetAttribute("NoClickFlash", true)
		end
	end

	AdminInput.bindButton(runtime._janitor, page.Confirm, function()
		runtime:_sendEvent()
	end)

	AdminInput.bindButton(runtime._janitor, page.Cancel, function()
		if page.DurationText and page.DurationText:IsA("TextBox") then
			page.DurationText.Text = ""
		end
		if page.ValueText and page.ValueText:IsA("TextBox") then
			page.ValueText.Text = ""
		end
	end)

	markNoClickFlash(page.Confirm)
	markNoClickFlash(page.Cancel)
end

return Bind
