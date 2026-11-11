--!nonstrict
local AdminInput = require(script.Parent.Parent.Parent.AdminInput)
local AdminNotification = require(script.Parent.Parent.Parent.Parent.Notifications.AdminNotification)
local ListBuilder = require(script.Parent.Parent.Actions.ListBuilder)
local ServiceCall = require(script.Parent.Parent.Actions.ServiceCall)

local Bind = {}

function Bind.bind(runtime)
	local page = runtime._refs.Pages.Players
	if not page or not page.Root then
		return
	end
	local setActionSelected = runtime:_makeSingleSelect()

	local function markNoClickFlash(button)
		if button then
			button:SetAttribute("NoClickFlash", true)
		end
	end

	page.Actions.Visible = false
	ListBuilder.build(runtime, page.Root, page.Template, function(player)
		runtime._selected.Players = player
		if page.Actions then
			page.Actions.Visible = true
		end
	end)

	local function run(action, button)
		if button then
			setActionSelected(button)
		end
		local target = runtime._selected.Players
		if not target then
			AdminNotification.error("Select a player first")
			return
		end
		ServiceCall.call(runtime, function()
			return runtime._service:PlayerAction(action, target.UserId)
		end):andThen(function(ok, reason)
			if ok == false then
				AdminNotification.error("Action failed: " .. tostring(reason))
			else
				AdminNotification.success("Action applied")
			end
		end):catch(function(err)
			AdminNotification.error("Action error")
			warn("[AdminRuntime] player action failed: " .. tostring(err))
		end)
	end
	runtime._runPlayerAction = run

	AdminInput.bindButton(runtime._janitor, page.Ban, function()
		run("Ban", page.Ban)
	end)
	AdminInput.bindButton(runtime._janitor, page.Kick, function()
		run("Kick", page.Kick)
	end)
	AdminInput.bindButton(runtime._janitor, page.Bring, function()
		run("Bring", page.Bring)
	end)
	AdminInput.bindButton(runtime._janitor, page.Freeze, function()
		run("Freeze", page.Freeze)
	end)
	AdminInput.bindButton(runtime._janitor, page.Unfreeze, function()
		run("Unfreeze", page.Unfreeze)
	end)
	AdminInput.bindButton(runtime._janitor, page.Invis, function()
		run("Invis", page.Invis)
	end)
	AdminInput.bindButton(runtime._janitor, page.Visible, function()
		run("Visible", page.Visible)
	end)
	AdminInput.bindButton(runtime._janitor, page.Jail, function()
		run("Jail", page.Jail)
	end)
	AdminInput.bindButton(runtime._janitor, page.Unjail, function()
		run("Unjail", page.Unjail)
	end)
	AdminInput.bindButton(runtime._janitor, page.Teleport, function()
		run("Teleport", page.Teleport)
	end)
	AdminInput.bindButton(runtime._janitor, page.Cancel, function()
		if page.Cancel then
			setActionSelected(page.Cancel)
		end
		runtime._selected.Players = nil
		if page.Actions then
			page.Actions.Visible = false
		end
	end)

	markNoClickFlash(page.Ban)
	markNoClickFlash(page.Kick)
	markNoClickFlash(page.Bring)
	markNoClickFlash(page.Freeze)
	markNoClickFlash(page.Unfreeze)
	markNoClickFlash(page.Invis)
	markNoClickFlash(page.Visible)
	markNoClickFlash(page.Jail)
	markNoClickFlash(page.Unjail)
	markNoClickFlash(page.Teleport)
	markNoClickFlash(page.Cancel)
end

return Bind
