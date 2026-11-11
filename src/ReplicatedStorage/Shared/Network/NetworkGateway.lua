--!strict
--[[
	Unified Network Gateway

	Server:
		NetworkGateway:RegisterRoute("GET", "/profile", function(player, payload, context)
			return { Success = true, StatusCode = 200, Data = { name = player.Name } }
		end, { rateLimitSeconds = 1 })

	Client:
		NetworkGateway:Request("GET", "/profile"):andThen(function(response)
			if response.Success then
				print(response.Data)
			end
		end)

	Request returns a Promise<Response>. Timeouts and network failures resolve with
	Success = false so callers can handle every outcome in one place.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Instance
local Packages = Shared:WaitForChild("Packages") :: Instance
local Promise: any = require(Packages:WaitForChild("Promise") :: ModuleScript)

local networkFolder = script.Parent :: Instance

local REMOTES_FOLDER_NAME = "Remotes"
local REQUEST_REMOTE_NAME = "NetworkGateway"
local STREAM_REMOTE_NAME = "NetworkStream"
local REQUEST_TIMEOUT_SECONDS = 5
local REMOTE_WAIT_SECONDS = 10

export type Response = {
	Success: boolean,
	StatusCode: number,
	Data: any?,
	ErrorCode: string?,
	Message: string?,
}

export type RequestContext = {
	Player: Player,
	Method: string,
	Route: string,
	ReceivedAt: number,
}

export type RouteHandler = (player: Player, payload: any, context: RequestContext) -> any

export type RouteOptions = {
	rateLimitSeconds: number?,
}

type RouteEntry = {
	Method: string,
	Route: string,
	Handler: RouteHandler,
	RateLimitSeconds: number,
	LastRequest: { [Player]: number },
}

local VALID_METHODS: { [string]: boolean } = {
	GET = true,
	POST = true,
	PUT = true,
	DELETE = true,
}

local routes: { [string]: RouteEntry } = {}
local serverRequestRemote: RemoteFunction? = nil
local serverStreamRemote: RemoteEvent? = nil
local clientRequestRemote: RemoteFunction? = nil
local clientStreamRemote: RemoteEvent? = nil
local streamConnection: RBXScriptConnection? = nil
local streamListeners: { [string]: { (data: any) -> () } } = {}

local function respond(
	success: boolean,
	statusCode: number,
	errorCode: string?,
	message: string?,
	data: any?
): Response
	return {
		Success = success,
		StatusCode = statusCode,
		Data = data,
		ErrorCode = errorCode,
		Message = message,
	}
end

local function normalizeMethod(method: any): string?
	if type(method) ~= "string" then
		return nil
	end
	local normalized = string.upper(method)
	if not VALID_METHODS[normalized] then
		return nil
	end
	return normalized
end

local function normalizeRoute(route: any): string?
	if type(route) ~= "string" then
		return nil
	end
	if #route == 0 or #route > 120 then
		return nil
	end
	local normalized = route
	if string.sub(normalized, 1, 1) ~= "/" then
		normalized = "/" .. normalized
	end
	if not string.match(normalized, "^/[%w%-_/]+$") then
		return nil
	end
	if string.find(normalized, "//", 1, true) then
		return nil
	end
	if string.sub(normalized, -1) == "/" then
		return nil
	end
	return normalized
end

local function normalizeEventName(eventName: any): string?
	if type(eventName) ~= "string" then
		return nil
	end
	if #eventName == 0 or #eventName > 64 then
		return nil
	end
	if not string.match(eventName, "^[%w%-_%.]+$") then
		return nil
	end
	if string.find(eventName, "..", 1, true) then
		return nil
	end
	return eventName
end

local function normalizeHandlerResult(result: any): Response
	if type(result) == "table" then
		local candidate = result :: { [string]: any }
		local success = candidate.Success
		if type(success) == "boolean" then
			local status = candidate.StatusCode
			if type(status) ~= "number" or status ~= status or status < 100 or status > 599 then
				status = if success then 200 else 400
			end
			local errorCode = candidate.ErrorCode
			local message = candidate.Message
			return respond(
				success,
				math.floor(status :: number),
				if type(errorCode) == "string" then errorCode else nil,
				if type(message) == "string" then message else nil,
				candidate.Data
			)
		end
	end
	if result == nil then
		return respond(true, 200)
	end
	return respond(true, 200, nil, nil, result)
end

local function getRemotesFolder(): Folder
	local existing = networkFolder:FindFirstChild(REMOTES_FOLDER_NAME)
	if existing and not existing:IsA("Folder") then
		existing:Destroy()
		existing = nil
	end
	if not existing then
		local created = Instance.new("Folder")
		created.Name = REMOTES_FOLDER_NAME
		created.Parent = networkFolder
		existing = created
	end
	return existing :: Folder
end

local function getRemoteFunction(folder: Folder): RemoteFunction
	local existing = folder:FindFirstChild(REQUEST_REMOTE_NAME)
	if existing and not existing:IsA("RemoteFunction") then
		existing:Destroy()
		existing = nil
	end
	if not existing then
		local created = Instance.new("RemoteFunction")
		created.Name = REQUEST_REMOTE_NAME
		created.Parent = folder
		existing = created
	end
	return existing :: RemoteFunction
end

local function getRemoteEvent(folder: Folder): RemoteEvent
	local existing = folder:FindFirstChild(STREAM_REMOTE_NAME)
	if existing and not existing:IsA("RemoteEvent") then
		existing:Destroy()
		existing = nil
	end
	if not existing then
		local created = Instance.new("RemoteEvent")
		created.Name = STREAM_REMOTE_NAME
		created.Parent = folder
		existing = created
	end
	return existing :: RemoteEvent
end

local function getClientRemoteFunction(): RemoteFunction?
	if clientRequestRemote then
		return clientRequestRemote
	end
	local folder = networkFolder:FindFirstChild(REMOTES_FOLDER_NAME)
	if not folder then
		folder = networkFolder:WaitForChild(REMOTES_FOLDER_NAME, REMOTE_WAIT_SECONDS)
	end
	if not folder or not folder:IsA("Folder") then
		return nil
	end
	local remote = folder:FindFirstChild(REQUEST_REMOTE_NAME)
	if not remote then
		remote = folder:WaitForChild(REQUEST_REMOTE_NAME, REMOTE_WAIT_SECONDS)
	end
	if not remote or not remote:IsA("RemoteFunction") then
		return nil
	end
	clientRequestRemote = remote :: RemoteFunction
	return clientRequestRemote
end

local function getClientRemoteEvent(): RemoteEvent?
	if clientStreamRemote then
		return clientStreamRemote
	end
	local folder = networkFolder:FindFirstChild(REMOTES_FOLDER_NAME)
	if not folder then
		folder = networkFolder:WaitForChild(REMOTES_FOLDER_NAME, REMOTE_WAIT_SECONDS)
	end
	if not folder or not folder:IsA("Folder") then
		return nil
	end
	local remote = folder:FindFirstChild(STREAM_REMOTE_NAME)
	if not remote then
		remote = folder:WaitForChild(STREAM_REMOTE_NAME, REMOTE_WAIT_SECONDS)
	end
	if not remote or not remote:IsA("RemoteEvent") then
		return nil
	end
	clientStreamRemote = remote :: RemoteEvent
	return clientStreamRemote
end

local function handleRequest(player: Player, method: any, route: any, payload: any): Response
	local normalizedMethod = normalizeMethod(method)
	if not normalizedMethod then
		return respond(false, 405, "METHOD_NOT_ALLOWED", "Unsupported HTTP method.")
	end

	local normalizedRoute = normalizeRoute(route)
	if not normalizedRoute then
		return respond(false, 400, "BAD_ROUTE", "Invalid route format.")
	end

	local key = normalizedMethod .. " " .. normalizedRoute
	local entry = routes[key]
	if not entry then
		return respond(false, 404, "ROUTE_NOT_FOUND", "No handler is registered for this route.")
	end

	local now = Workspace:GetServerTimeNow()
	if entry.RateLimitSeconds > 0 then
		local lastRequest = entry.LastRequest[player]
		if lastRequest and now - lastRequest < entry.RateLimitSeconds then
			return respond(false, 429, "RATE_LIMITED", "Too many requests for this route.")
		end
		entry.LastRequest[player] = now
	end

	local context: RequestContext = {
		Player = player,
		Method = normalizedMethod,
		Route = normalizedRoute,
		ReceivedAt = now,
	}

	local ok, result = pcall(entry.Handler, player, payload, context)
	if not ok then
		warn(string.format(
			"[NetworkGateway] Handler error | player=%s | %s %s | %s",
			player.Name,
			normalizedMethod,
			normalizedRoute,
			tostring(result)
		))
		return respond(false, 500, "HANDLER_ERROR", "Internal server error.")
	end

	return normalizeHandlerResult(result)
end

local function initializeServer(): ()
	if serverRequestRemote and serverStreamRemote then
		return
	end
	local folder = getRemotesFolder()
	local requestRemote = getRemoteFunction(folder)
	local streamRemote = getRemoteEvent(folder)
	serverRequestRemote = requestRemote
	serverStreamRemote = streamRemote
	requestRemote.OnServerInvoke = function(player: Player, method: any, route: any, payload: any): Response
		return handleRequest(player, method, route, payload)
	end
end

local function ensureStreamListener(): ()
	if streamConnection and streamConnection.Connected then
		return
	end
	streamConnection = nil
	local remote = getClientRemoteEvent()
	if not remote then
		return
	end
	streamConnection = remote.OnClientEvent:Connect(function(receivedEvent: any, data: any)
		if type(receivedEvent) ~= "string" then
			return
		end
		local listeners = streamListeners[receivedEvent]
		if not listeners then
			return
		end
		for _, callback in ipairs(listeners) do
			task.spawn(function()
				local ok, err = pcall(callback, data)
				if not ok then
					warn(string.format(
						"[NetworkGateway] Stream listener error | event=%s | %s",
						receivedEvent,
						tostring(err)
					))
				end
			end)
		end
	end)
end

local NetworkGateway = {}

function NetworkGateway:RegisterRoute(
	method: string,
	routeName: string,
	handlerFunction: RouteHandler,
	options: RouteOptions?
): ()
	assert(RunService:IsServer(), "[NetworkGateway] RegisterRoute can only be called on the server.")

	local normalizedMethod = normalizeMethod(method)
	assert(normalizedMethod ~= nil, "[NetworkGateway] Invalid HTTP method: " .. tostring(method))

	local normalizedRoute = normalizeRoute(routeName)
	assert(normalizedRoute ~= nil, "[NetworkGateway] Invalid route: " .. tostring(routeName))

	assert(type(handlerFunction) == "function", "[NetworkGateway] handlerFunction must be a function.")

	local rateLimitSeconds = 0
	if options and options.rateLimitSeconds ~= nil then
		local value = options.rateLimitSeconds
		assert(
			type(value) == "number" and value == value and value >= 0 and value < math.huge,
			"[NetworkGateway] options.rateLimitSeconds must be a finite number >= 0."
		)
		rateLimitSeconds = value :: number
	end

	local key = (normalizedMethod :: string) .. " " .. (normalizedRoute :: string)
	assert(routes[key] == nil, "[NetworkGateway] Duplicate route: " .. key)

	routes[key] = {
		Method = normalizedMethod :: string,
		Route = normalizedRoute :: string,
		Handler = handlerFunction,
		RateLimitSeconds = rateLimitSeconds,
		LastRequest = setmetatable({}, { __mode = "k" }) :: { [Player]: number },
	}
end

function NetworkGateway:Broadcast(eventName: string, data: any?, target: Player?): ()
	assert(RunService:IsServer(), "[NetworkGateway] Broadcast can only be called on the server.")

	local normalizedEvent = normalizeEventName(eventName)
	assert(normalizedEvent ~= nil, "[NetworkGateway] Invalid event name: " .. tostring(eventName))

	if target ~= nil then
		assert(typeof(target) == "Instance" and target:IsA("Player"), "[NetworkGateway] target must be a Player.")
	end

	initializeServer()

	local remote = serverStreamRemote
	assert(remote ~= nil, "[NetworkGateway] NetworkStream is not available.")

	local eventKey = normalizedEvent :: string
	if target then
		if target.Parent then
			remote:FireClient(target, eventKey, data)
		end
	else
		remote:FireAllClients(eventKey, data)
	end
end

function NetworkGateway:On(eventName: string, callback: (data: any) -> ()): () -> ()
	assert(RunService:IsClient(), "[NetworkGateway] On can only be called on the client.")

	local normalizedEvent = normalizeEventName(eventName)
	assert(normalizedEvent ~= nil, "[NetworkGateway] Invalid event name: " .. tostring(eventName))
	assert(type(callback) == "function", "[NetworkGateway] callback must be a function.")

	local eventKey = normalizedEvent :: string
	ensureStreamListener()

	local listeners = streamListeners[eventKey]
	if not listeners then
		listeners = {}
		streamListeners[eventKey] = listeners
	end
	table.insert(listeners, callback)

	return function()
		local current = streamListeners[eventKey]
		if not current then
			return
		end
		local index = table.find(current, callback)
		if index then
			table.remove(current, index)
		end
		if #current == 0 then
			streamListeners[eventKey] = nil
		end
	end
end

function NetworkGateway:Request(method: string, route: string, payload: any?): any
	assert(RunService:IsClient(), "[NetworkGateway] Request can only be called on the client.")
	assert(type(method) == "string", "[NetworkGateway] method must be a string.")
	assert(type(route) == "string", "[NetworkGateway] route must be a string.")

	return Promise.new(function(resolve: (Response) -> ())
		local settled = false

		local function complete(response: Response): ()
			if settled then
				return
			end
			settled = true
			resolve(response)
		end

		task.delay(REQUEST_TIMEOUT_SECONDS, function()
			complete(respond(false, 408, "TIMEOUT", "Request timed out after 5 seconds."))
		end)

		task.spawn(function()
			local remote = getClientRemoteFunction()
			if settled then
				return
			end
			if not remote then
				complete(respond(false, 503, "NETWORK_UNAVAILABLE", "Network gateway is not available."))
				return
			end

			local ok, result = pcall(function()
				return remote:InvokeServer(string.upper(method), route, payload)
			end)

			if not ok then
				complete(respond(false, 500, "NETWORK_ERROR", "Failed to communicate with the server."))
				return
			end

			complete(normalizeHandlerResult(result))
		end)
	end)
end

if RunService:IsServer() then
	Players.PlayerRemoving:Connect(function(player: Player)
		for _, entry in pairs(routes) do
			entry.LastRequest[player] = nil
		end
	end)
	initializeServer()
end

return NetworkGateway
