--!nonstrict
local AdminInput = require(script.Parent.Parent.Parent.AdminInput)
local AdminNotification = require(script.Parent.Parent.Parent.Parent.Notifications.AdminNotification)
local Util = require(script.Parent.Parent.Util)
local ServiceCall = require(script.Parent.Parent.Actions.ServiceCall)

local Build = {}

function Build.buildButtons(runtime, roles)
	local page = runtime._refs.Pages.Roles
	if not page or not page.Actions or not page.ActionTemplate then return end
	local setRoleSelected = runtime:_makeSingleSelect()
	page.ActionTemplate.Visible = true
	Util.clearList(page.Actions, page.ActionTemplate)

	page.ActionTemplate.Name = "Remove"
	page.ActionTemplate.LayoutOrder = -100
	if page.ActionTemplate:IsA("TextButton") then
		page.ActionTemplate.Text = "Remove"
	else
		local text = page.ActionTemplate:FindFirstChild("Text")
		if text and text:IsA("TextLabel") then
			text.Text = "Remove"
		end
	end
	page.ActionTemplate:SetAttribute("NoClickFlash", true)
	AdminInput.bindButton(runtime._janitor, page.ActionTemplate, function()
		setRoleSelected(page.ActionTemplate)
		local target = runtime._selected.Roles
		if not target then
			AdminNotification.error("Select a player first")
			return
		end
		ServiceCall.call(runtime, function()
			return runtime._service:RemoveRole(target.UserId)
		end):andThen(function(ok, reason)
			if ok == false then
				AdminNotification.error("Remove role failed: " .. tostring(reason))
			else
				AdminNotification.success("Role removed")
			end
		end):catch(function(err)
			AdminNotification.error("Remove role error")
			warn("[AdminRuntime] remove role failed: " .. tostring(err))
		end)
	end)

	local order = 0
	for _, role in ipairs(roles) do
		order += 1
		local btn = page.ActionTemplate:Clone()
		btn.Visible = true
		btn.Name = "Role_" .. role
		btn.LayoutOrder = order
		if btn:IsA("TextButton") then
			btn.Text = role
		else
			local text = btn:FindFirstChild("Text")
			if text and text:IsA("TextLabel") then
				text.Text = role
			end
		end
		btn.Parent = page.Actions
		btn:SetAttribute("NoClickFlash", true)
		AdminInput.bindButton(runtime._janitor, btn, function()
			setRoleSelected(btn)
			local target = runtime._selected.Roles
			if not target then
				AdminNotification.error("Select a player first")
				return
			end
			ServiceCall.call(runtime, function()
				return runtime._service:AssignRole(target.UserId, role)
			end):andThen(function(ok, reason)
				if ok == false then
					AdminNotification.error("Role failed: " .. tostring(reason))
				else
					AdminNotification.success("Role applied")
				end
			end):catch(function(err)
				AdminNotification.error("Role error")
				warn("[AdminRuntime] role failed: " .. tostring(err))
			end)
		end)
	end
end

return Build
