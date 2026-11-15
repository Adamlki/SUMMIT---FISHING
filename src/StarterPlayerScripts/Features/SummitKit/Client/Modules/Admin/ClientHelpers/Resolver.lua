--!nonstrict
local Players = game:GetService("Players")
local ResolverHelpers = script.Parent:WaitForChild("ResolverHelpers")
local PageResolver = require(ResolverHelpers:WaitForChild("PageResolver"))

local AdminResolver = {}

local function findButton(node)
	if not node then return nil end
	if node:IsA("GuiButton") then return node end
	return node:FindFirstChildWhichIsA("GuiButton", true) or node
end

function AdminResolver.Resolve(playerGui)
	local pg = playerGui or Players.LocalPlayer:WaitForChild("PlayerGui", 60)
	if not pg then
		return false, "PlayerGui not found"
	end

	local gameUI = pg:FindFirstChild("GameUI") or pg:WaitForChild("GameUI", 60)
	if not gameUI then
		return false, "GameUI not found"
	end
	local component = gameUI:FindFirstChild("Component") or gameUI:WaitForChild("Component", 60)
	local menus = gameUI:FindFirstChild("Menus") or gameUI:WaitForChild("Menus", 60)
	if not (component and menus) then
		return false, "Component/Menus missing"
	end

	local buttons = component:FindFirstChild("ButtonsNew")
	local menuKanan = buttons and buttons:FindFirstChild("MenuKanan")
	local toggleBtn = findButton(menuKanan and menuKanan:FindFirstChild("AdminButton"))

	local adminMenu = menus:FindFirstChild("Admin")
	local panel = adminMenu and adminMenu:FindFirstChild("Panel")
	local header = panel and panel:FindFirstChild("Header")
	local timeLabel = header and header:FindFirstChild("Time")
	local closeBtn = header and header:FindFirstChild("Close")
	local container = panel and panel:FindFirstChild("Container")
	local left = container and container:FindFirstChild("Left")
	local right = container and container:FindFirstChild("Right")

	local refs = {
		Toggle = toggleBtn,
		Menu = adminMenu,
		Root = panel,
		Close = closeBtn,
		Time = timeLabel,
		Right = right,
		Left = {
			Announce = findButton(left and left:FindFirstChild("Announce")),
			Event = findButton(left and left:FindFirstChild("Event")),
			Manage = findButton(left and left:FindFirstChild("Manage")),
			Players = findButton(left and left:FindFirstChild("Players")),
			Role = findButton(left and left:FindFirstChild("Role")),
			Logs = findButton(left and left:FindFirstChild("Logs")),
			Server = findButton(left and left:FindFirstChild("Server")),
			Teleport = findButton(left and left:FindFirstChild("Teleport")),
			Tools = findButton(left and left:FindFirstChild("Tools")),
		},
		Pages = {
			Announce = {},
			Event = {},
			Manager = {},
			Players = {},
			Roles = {},
			Logs = {},
			Server = {},
			Teleport = {},
			Tools = {},
		},
	}

	if not (refs.Root and left and right) then
		return false, "Admin panel structure incomplete"
	end

	refs.Pages.Announce = PageResolver.announce(right:FindFirstChild("Announce"))
	refs.Pages.Event = PageResolver.event(right:FindFirstChild("Event"))
	refs.Pages.Manager = PageResolver.manager(right:FindFirstChild("Manager"))
	refs.Pages.Players = PageResolver.players(right:FindFirstChild("Players"))
	refs.Pages.Roles = PageResolver.roles(right:FindFirstChild("Roles"))
	refs.Pages.Logs = PageResolver.logs(right:FindFirstChild("Logs"))
	refs.Pages.Server = PageResolver.server(right:FindFirstChild("Server"))
	refs.Pages.Teleport = PageResolver.teleport(right:FindFirstChild("Teleport"))
	refs.Pages.Tools = PageResolver.tools(right:FindFirstChild("Tools"))

	return true, refs
end

return AdminResolver
