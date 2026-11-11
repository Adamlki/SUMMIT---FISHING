--!nonstrict
local Util = require(script.Parent.Parent.Util)

local Render = {}

function Render.set(runtime, entries)
	local page = runtime._refs.Pages.Logs
	if not page or not page.Root or not page.Template then return end
	for _, child in ipairs(page.Root:GetChildren()) do
		if child ~= page.Template and child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	runtime._logEntries = {}
	runtime._logCounter = 0
	for _, entry in ipairs(entries or {}) do
		Render.push(runtime, entry)
	end
end

function Render.push(runtime, entry)
	local page = runtime._refs.Pages.Logs
	if not page or not page.Root or not page.Template then return end
	if not entry then return end
	runtime._logCounter += 1
	local item = page.Template:Clone()
	item.Visible = true
	item.Name = "Log_" .. tostring(entry.id or runtime._logCounter)
	item.LayoutOrder = runtime._logCounter
	item.Parent = page.Root

	local icon = item:FindFirstChild("Icon", true)
	if icon and icon:IsA("ImageLabel") then
		local uid = entry.userId
		if uid then
			Util.setAvatarByUserId(icon, uid)
		end
	end

	local desk = item:FindFirstChild("Desk", true)
	if desk and desk:IsA("TextLabel") then
		local displayName = entry.displayName or "Player"
		local message = entry.message or ""
		if message == "" then
			desk.Text = displayName
		else
			desk.Text = string.format("%s: %s", displayName, message)
		end
	end

	table.insert(runtime._logEntries, item)
	if #runtime._logEntries > runtime._logMax then
		local first = table.remove(runtime._logEntries, 1)
		if first and first.Parent then
			first:Destroy()
		end
	end
end

return Render
