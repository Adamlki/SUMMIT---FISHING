--!nonstrict
local AdminInput = require(script.Parent.Parent.Parent.AdminInput)
local AdminNotification = require(script.Parent.Parent.Parent.Parent.Notifications.AdminNotification)
local ListBuilder = require(script.Parent.Parent.Actions.ListBuilder)
local ServiceCall = require(script.Parent.Parent.Actions.ServiceCall)

local Bind = {}

function Bind.bind(runtime)
	local page = runtime._refs.Pages.Manager
	if not page or not page.Root then
		return
	end
	local setActionSelected = runtime:_makeSingleSelect()

	local function markNoClickFlash(button)
		if button then
			button:SetAttribute("NoClickFlash", true)
		end
	end

	if page.PlayersBtn and page.List then
		AdminInput.bindButton(runtime._janitor, page.PlayersBtn, function()
			page.List.Visible = not page.List.Visible
		end)
		page.PlayersBtn:SetAttribute("NoClickFlash", true)
	end

	ListBuilder.build(runtime, page.List, page.Template, function(player)
		runtime._selected.Manager = player
	end)

	local function run(action, button)
		if button then
			setActionSelected(button)
		end
		local target = runtime._selected.Manager
		if not target then
			AdminNotification.error("Select a player first")
			return
		end
		local amount = 0
		if page.ValueText and page.ValueText:IsA("TextBox") then
			amount = tonumber(page.ValueText.Text) or 0
		elseif page.Value and page.Value:IsA("TextLabel") then
			amount = tonumber(page.Value.Text) or 0
		end
		ServiceCall.call(runtime, function()
			return runtime._service:Manage(action, target.UserId, amount)
		end):andThen(function(ok, reason)
			if ok == false then
				AdminNotification.error("Action failed: " .. tostring(reason))
			else
				AdminNotification.success("Action applied")
			end
		end):catch(function(err)
			AdminNotification.error("Action error")
			warn("[AdminRuntime] manager action failed: " .. tostring(err))
		end)
	end

	AdminInput.bindButton(runtime._janitor, page.Add, function()
		run("Add", page.Add)
	end)
	AdminInput.bindButton(runtime._janitor, page.Gift, function()
		run("Gift", page.Gift)
	end)
	AdminInput.bindButton(runtime._janitor, page.ResetBesttime, function()
		run("ResetBesttime", page.ResetBesttime)
	end)
	AdminInput.bindButton(runtime._janitor, page.ResetSummit, function()
		run("ResetSummit", page.ResetSummit)
	end)
	AdminInput.bindButton(runtime._janitor, page.Set, function()
		run("Set", page.Set)
	end)
	AdminInput.bindButton(runtime._janitor, page.Sub, function()
		run("Sub", page.Sub)
	end)

	markNoClickFlash(page.Add)
	markNoClickFlash(page.Gift)
	markNoClickFlash(page.ResetBesttime)
	markNoClickFlash(page.ResetSummit)
	markNoClickFlash(page.Set)
	markNoClickFlash(page.Sub)

	-- =========================================================
	-- 👑 TARGETED ADMIN ACTIONS: GIVE COINS & GIVE LUCK
	-- =========================================================
	local function runAdminPlayerAction(action, button)
		if button then
			setActionSelected(button)
		end
		local target = runtime._selected.Manager
		if not target then
			AdminNotification.error("Pilih pemain terlebih dahulu!")
			return
		end
		local amount = 0
		if page.ValueText and page.ValueText:IsA("TextBox") then
			amount = tonumber(page.ValueText.Text) or 0
		elseif page.Value and page.Value:IsA("TextBox") then
			amount = tonumber(page.Value.Text) or 0
		elseif page.Value and page.Value:IsA("TextLabel") then
			amount = tonumber(page.Value.Text) or 0
		end

		if amount <= 0 then
			AdminNotification.error("Masukkan nominal angka > 0!")
			return
		end

		local fishingSystem = game:GetService("ReplicatedStorage"):WaitForChild("FishingSystem", 10)
		local rf = fishingSystem and fishingSystem:FindFirstChild("AdminPlayerAction")
		if rf then
			task.spawn(function()
				local res = rf:InvokeServer(action, target.UserId, amount)
				if res and res.success then
					AdminNotification.success(res.message or "Aksi berhasil diterapkan!")
				else
					AdminNotification.error(res and res.message or "Aksi gagal!")
				end
			end)
		else
			AdminNotification.error("AdminPlayerAction remote tidak ditemukan!")
		end
	end

	if page.GiveCoins then
		AdminInput.bindButton(runtime._janitor, page.GiveCoins, function()
			runAdminPlayerAction("GiveCoins", page.GiveCoins)
		end)
		markNoClickFlash(page.GiveCoins)
	end

	if page.GiveLuck then
		AdminInput.bindButton(runtime._janitor, page.GiveLuck, function()
			runAdminPlayerAction("GiveLuck", page.GiveLuck)
		end)
		markNoClickFlash(page.GiveLuck)
	end
end

return Bind
