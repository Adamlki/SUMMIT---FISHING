--!nonstrict
local AdminInput = require(script.Parent.Parent.Parent.AdminInput)

local Bind = {}

function Bind.bind(runtime)
	local page = runtime._refs.Pages.Announce
	if not page or not page.Root then
		return
	end
	local setPickSelected = runtime:_makeSingleSelect()

	local function markNoClickFlash(button)
		if button then
			button:SetAttribute("NoClickFlash", true)
		end
	end

	AdminInput.bindButton(runtime._janitor, page.Global, function()
		runtime._announceScope = "Global"
		if page.Global then
			setPickSelected(page.Global)
		end
	end)
	AdminInput.bindButton(runtime._janitor, page.Server, function()
		runtime._announceScope = "Server"
		if page.Server then
			setPickSelected(page.Server)
		end
	end)
	markNoClickFlash(page.Global)
	markNoClickFlash(page.Server)

	if page.InputText then
		runtime._janitor:Add(page.InputText:GetPropertyChangedSignal("Text"):Connect(function()
			runtime:_updateAnnounceCounter()
		end), "Disconnect")
	end

	AdminInput.bindButton(runtime._janitor, page.Confirm, function()
		runtime:_sendAnnounce()
	end)
	AdminInput.bindButton(runtime._janitor, page.Cancel, function()
		if page.InputText and page.InputText:IsA("TextBox") then
			page.InputText.Text = ""
		elseif page.Input and page.Input:IsA("TextLabel") then
			page.Input.Text = ""
		end
		runtime:_updateAnnounceCounter()
	end)
	markNoClickFlash(page.Confirm)
	markNoClickFlash(page.Cancel)
end

return Bind
