--!nonstrict
local AdminInput = require(script.Parent.Parent.Parent.AdminInput)
local AdminNotification = require(script.Parent.Parent.Parent.Parent.Notifications.AdminNotification)
local Util = require(script.Parent.Parent.Util)
local ServiceCall = require(script.Parent.Parent.Actions.ServiceCall)

local Build = {}

function Build.buildButtons(runtime, tools)
	local page = runtime._refs.Pages.Tools
	if not page or not page.Actions or not page.ActionTemplate then return end
	local setToolSelected = runtime:_makeSingleSelect()
	page.ActionTemplate.Visible = false
	Util.clearList(page.Actions, page.ActionTemplate)

	for _, name in ipairs(tools) do
		local btn = page.ActionTemplate:Clone()
		btn.Visible = true
		btn.Name = "Tool_" .. name
		if btn:IsA("TextButton") then
			btn.Text = name
		else
			local text = btn:FindFirstChild("Name")
			if text and text:IsA("TextLabel") then
				text.Text = name
			end
		end
		btn.Parent = page.Actions
		btn:SetAttribute("NoClickFlash", true)
		AdminInput.bindButton(runtime._janitor, btn, function()
			setToolSelected(btn)
			local target = runtime._selected.Tools
			local targetId = target and target.UserId or nil
			ServiceCall.call(runtime, function()
				return runtime._service:GiveTool(name, targetId)
			end):andThen(function(ok, reason)
				if ok == false then
					AdminNotification.error("Give tool failed: " .. tostring(reason))
				else
					AdminNotification.success("Tool given")
				end
			end):catch(function(err)
				AdminNotification.error("Tool error")
				warn("[AdminRuntime] give tool failed: " .. tostring(err))
			end)
		end)
	end
end

return Build
