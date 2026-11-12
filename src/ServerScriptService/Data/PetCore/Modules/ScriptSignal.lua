-- Minimal listener list used for ProfileLoadedSignal.
local ScriptConnection = {}
ScriptConnection.__index = ScriptConnection

function ScriptConnection:Disconnect()
	if self._is_connected == false then return end
	self._is_connected = false
	self._script_signal._listener_count -= 1
	if self._script_signal._head == self then
		self._script_signal._head = self._next
	else
		local prev = self._script_signal._head
		while prev ~= nil and prev._next ~= self do prev = prev._next end
		if prev ~= nil then prev._next = self._next end
	end
end

local ScriptSignal = {}
ScriptSignal.__index = ScriptSignal

function ScriptSignal:Connect(listener)
	local script_connection = {
		_listener = listener,
		_script_signal = self,
		_next = self._head,
		_is_connected = true,
	}
	setmetatable(script_connection, ScriptConnection)
	self._head = script_connection
	self._listener_count += 1
	return script_connection
end

function ScriptSignal:Fire(...)
	local item = self._head
	while item ~= nil do
		if item._is_connected == true then
			task.spawn(item._listener, ...)
		end
		item = item._next
	end
end

return function()
	return setmetatable({_head = nil, _listener_count = 0}, ScriptSignal)
end
