--!nonstrict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)
local Promise = require(Packages.Promise)
local FpsHelpers = script.Parent:WaitForChild("FpsHelpers")
local PingResolver = require(FpsHelpers:WaitForChild("PingResolver"))
local DragBinder = require(FpsHelpers:WaitForChild("DragBinder"))

local FpsRuntime = {}
FpsRuntime.__index = FpsRuntime

function FpsRuntime.new(refs)
	local self = setmetatable({}, FpsRuntime)
	self._refs = refs
	self._janitor = Janitor.new()
	self._dragJanitor = Janitor.new()
	self._visible = false
	self._frames = 0
	self._accum = 0
	self._lastUpdate = 0
	self._pingItem = nil
	self._pingResolverRunning = false
	self._pingService = nil
	self._pingPending = false
	self._lastPingMs = nil
	self._lastPingAt = 0
	return self
end

function FpsRuntime:SetPingService(service)
	self._pingService = service
end

function FpsRuntime:_ensurePingItem()
	PingResolver.ensure(self)
end

function FpsRuntime:_getPingMs()
	return PingResolver.getMs(self._pingItem)
end

function FpsRuntime:_setVisible(state)
	self._visible = state and true or false
	if self._refs and self._refs.Root then
		self._refs.Root.Visible = self._visible
	end
end

function FpsRuntime:_updateLabels(fps, renderMs, pingMs)
	local refs = self._refs
	if refs.Ping and refs.Ping:IsA("TextLabel") then
		if pingMs then
			refs.Ping.Text = string.format("PING: %d ms", math.floor(pingMs + 0.5))
		else
			refs.Ping.Text = "PING: -- ms"
		end
	end
	if refs.Fps and refs.Fps:IsA("TextLabel") then
		refs.Fps.Text = string.format("FPS: %d fps", math.floor(fps + 0.5))
	end
	if refs.Render and refs.Render:IsA("TextLabel") then
		local renderFps = renderMs > 0 and (1000 / renderMs) or 0
		refs.Render.Text = string.format("Render: %d fps", math.floor(renderFps + 0.5))
	end
end

function FpsRuntime:_startLoop()
	self:_stopLoop()
	self:_ensurePingItem()
	self._frames = 0
	self._accum = 0
	self._lastUpdate = os.clock()
	self:_updateLabels(0, 0, self._lastPingMs or self:_getPingMs())
	self._janitor:Add(RunService.RenderStepped:Connect(function(dt)
		self._frames += 1
		self._accum += dt
		local now = os.clock()
		if now - self._lastUpdate >= 0.25 then
			local fps = self._frames / math.max(self._accum, 1e-4)
			local renderMs = (self._accum / math.max(self._frames, 1)) * 1000
			if not (self._pingItem and self._pingItem.Parent) then
				self._pingItem = nil
				self:_ensurePingItem()
			end
			if self._pingService and not self._pingPending and (now - self._lastPingAt) >= 1 then
				self._lastPingAt = now
				self._pingPending = true
				local t0 = os.clock()
				Promise.try(function()
					return self._pingService:Ping(t0)
				end):andThen(function(result)
					local t1 = os.clock()
					local base = (type(result) == "number") and result or t0
					self._lastPingMs = (t1 - base) * 1000 * 0.5
				end):catch(function()
				end):finally(function()
					self._pingPending = false
				end)
			end
			local pingMs = self._lastPingMs or self:_getPingMs()
			self:_updateLabels(fps, renderMs, pingMs)
			self._frames = 0
			self._accum = 0
			self._lastUpdate = now
		end
	end), "Disconnect")
end

function FpsRuntime:_stopLoop()
	if self._janitor then
		self._janitor:Cleanup()
	end
end

function FpsRuntime:BindDrag(handle)
	DragBinder.bind(self, handle)
end

function FpsRuntime:Toggle()
	local state = not self._visible
	self:_setVisible(state)
	if state then
		self:_startLoop()
	else
		self:_stopLoop()
	end
end

function FpsRuntime:Hide()
	if not self._visible then
		return
	end
	self:_setVisible(false)
	self:_stopLoop()
end

function FpsRuntime:Destroy()
	if self._janitor then
		self._janitor:Destroy()
		self._janitor = nil
	end
	if self._dragJanitor then
		self._dragJanitor:Destroy()
		self._dragJanitor = nil
	end
end

return FpsRuntime
