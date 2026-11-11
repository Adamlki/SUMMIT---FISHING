--!nonstrict
local Promise = require(game:GetService("ReplicatedStorage").Shared.Packages.Promise)

local Roles = require(script.Parent.Parent.Parent.RuntimeHelpers.Roles)
local Teleport = require(script.Parent.Parent.Parent.RuntimeHelpers.Teleport)
local Tools = require(script.Parent.Parent.Parent.RuntimeHelpers.Tools)
local Logs = require(script.Parent.Parent.Parent.RuntimeHelpers.Logs)

local PageLoader = {}

function PageLoader.load(runtime)
	local service = runtime._service
	if not service then
		return
	end
	Promise.try(function()
		return service:GetBootstrap()
	end):andThen(function(data)
		runtime._bootstrap = data or {}
		PageLoader.apply(runtime)
	end):catch(function(err)
		warn("[AdminRuntime] bootstrap failed: " .. tostring(err))
	end)
end

function PageLoader.apply(runtime)
	local data = runtime._bootstrap or {}
	runtime._logMax = tonumber(data.logMax) or runtime._logMax or 100
	Roles.buildButtons(runtime, data.roles or {})
	Teleport.buildButtons(runtime, data.teleports or {})
	Tools.buildButtons(runtime, data.tools or {})
	local eventPage = runtime._refs and runtime._refs.Pages and runtime._refs.Pages.Event
	local summitEvent = data.summitEvent
	if eventPage and summitEvent then
		if eventPage.ValueText and eventPage.ValueText:IsA("TextBox") then
			eventPage.ValueText.Text = tostring(tonumber(summitEvent.value) or 0)
		end
		if eventPage.DurationText and eventPage.DurationText:IsA("TextBox") then
			local remainingHours = tonumber(summitEvent.durationHours) or 0
			local endsAt = tonumber(summitEvent.endsAt) or 0
			if summitEvent.active == true and endsAt > 0 then
				remainingHours = math.max(0, math.ceil((endsAt - os.time()) / 3600))
			end
			eventPage.DurationText.Text = tostring(remainingHours)
		end
	end
	runtime:_updateAnnounceCounter()
	Logs.set(runtime, data.logs or {})
end

return PageLoader
