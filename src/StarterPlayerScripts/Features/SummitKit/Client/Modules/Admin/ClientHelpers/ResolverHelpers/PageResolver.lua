--!nonstrict
local PageResolver = {}

local function findTextBox(node)
	if not node then
		return nil
	end
	if node:IsA("TextBox") then
		return node
	end
	return node:FindFirstChildWhichIsA("TextBox", true)
end

function PageResolver.announce(announce)
	if not announce then
		return {}
	end
	local pick = announce:FindFirstChild("Pick")
	local send = announce:FindFirstChild("Send")
	local input = announce:FindFirstChild("Input")
	local title = announce:FindFirstChild("Title")
	local duration = announce:FindFirstChild("Durations")
	return {
		Root = announce,
		Global = pick and pick:FindFirstChild("Global"),
		Server = pick and pick:FindFirstChild("Server"),
		Confirm = send and send:FindFirstChild("Confirm"),
		Cancel = send and send:FindFirstChild("Cancel"),
		Input = input,
		InputText = findTextBox(input),
		Title = title,
		Duration = duration,
	}
end

function PageResolver.event(eventPage)
	if not eventPage then 
		return{}
	end
	local send = eventPage:FindFirstChild("Send")
	local durations = eventPage:FindFirstChild("Durations")
	local value = eventPage:FindFirstChild("Value")
	return{
		Root = eventPage, 
		Confirm = send and send:FindFirstChild("Confirm"),
		Cancel = send and send:FindFirstChild("Cancel"), 
		Duration = durations, 
		DurationText = findTextBox(durations) or durations, 
		Value = value, 
		ValueText = findTextBox(value) or value,
	}
end

function PageResolver.manager(manager)
	if not manager then
		return {}
	end
	local actions = manager:FindFirstChild("Actions")
	local list = manager:FindFirstChild("List")
	local value = manager:FindFirstChild("Value")
	return {
		Root = manager,
		Actions = actions,
		Add = actions and actions:FindFirstChild("Add"),
		Gift = actions and actions:FindFirstChild("Gift"),
		ResetBesttime = actions and actions:FindFirstChild("ResetBesttime"),
		ResetSummit = actions and actions:FindFirstChild("ResetSummit"),
		Set = actions and actions:FindFirstChild("Set"),
		Sub = actions and actions:FindFirstChild("Sub"),
		GiveCoins = actions and actions:FindFirstChild("GiveCoins"),
		GiveLuck = actions and actions:FindFirstChild("GiveLuck"),
		List = list,
		Template = list and list:FindFirstChild("Template"),
		PlayersBtn = manager:FindFirstChild("Players"),
		Value = value,
		ValueText = findTextBox(value),
		Input = manager:FindFirstChild("Input"),
		InputText = findTextBox(manager:FindFirstChild("Input")),
	}
end

function PageResolver.players(players)
	if not players then
		return {}
	end
	local actions = players:FindFirstChild("Actions")
	return {
		Root = players,
		Actions = actions,
		Ban = actions and actions:FindFirstChild("Ban"),
		Bring = actions and actions:FindFirstChild("Bring"),
		Cancel = actions and actions:FindFirstChild("Cancel"),
		Freeze = actions and actions:FindFirstChild("Freeze"),
		Unfreeze = actions and actions:FindFirstChild("Unfreeze"),
		Invis = actions and actions:FindFirstChild("Invis"),
		Jail = actions and actions:FindFirstChild("Jail"),
		Unjail = actions and actions:FindFirstChild("Unjail"),
		Kick = actions and actions:FindFirstChild("Kick"),
		Teleport = actions and actions:FindFirstChild("Teleport"),
		Visible = actions and actions:FindFirstChild("Visible"),
		Template = players:FindFirstChild("Template"),
	}
end

function PageResolver.roles(roles)
	if not roles then
		return {}
	end
	local actions = roles:FindFirstChild("Actions")
	local list = roles:FindFirstChild("List")
	local template = list and list:FindFirstChild("Template")
	local removeBtn = template and (template:FindFirstChild("Remove") or template:FindFirstChild("RemoveRole"))
	return {
		Root = roles,
		Actions = actions,
		ActionTemplate = actions and actions:FindFirstChild("Template"),
		Remove = removeBtn or (actions and (actions:FindFirstChild("Remove") or actions:FindFirstChild("RemoveRole"))),
		List = list,
		Template = template,
		PlayersBtn = roles:FindFirstChild("Players"),
	}
end

function PageResolver.logs(logs)
	return logs and {
		Root = logs,
		Template = logs:FindFirstChild("Template"),
	} or {}
end

function PageResolver.server(server)
	if not server then
		return {}
	end
	local pick = server:FindFirstChild("Pick")
	local priv = server:FindFirstChild("Private")
	local send = server:FindFirstChild("Send")
	return {
		Root = server,
		Restart = pick and pick:FindFirstChild("Restart"),
		Shutdown = pick and pick:FindFirstChild("Shutdown"),
		Lock = priv and priv:FindFirstChild("Lock"),
		Unlock = priv and priv:FindFirstChild("Unlock"),
		Confirm = send and send:FindFirstChild("Confirm"),
		Cancel = send and send:FindFirstChild("Cancel"),
	}
end

function PageResolver.teleport(teleport)
	return teleport and {
		Root = teleport,
		Template = teleport:FindFirstChild("Template"),
	} or {}
end

function PageResolver.tools(tools)
	if not tools then
		return {}
	end
	local actions = tools:FindFirstChild("Actions")
	local list = tools:FindFirstChild("List")
	return {
		Root = tools,
		Actions = actions,
		ActionTemplate = actions and actions:FindFirstChild("Template"),
		List = list,
		Template = list and list:FindFirstChild("Template"),
		PlayersBtn = tools:FindFirstChild("Players"),
	}
end

return PageResolver
