--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)

local ResetUIResolver = require(script.Parent.ResetUIHelpers.ResetUIResolver)
local ResetUIRenderer = require(script.Parent.ResetUIHelpers.ResetUIRenderer)
local ResetMenuBinder = require(script.Parent.ResetUIHelpers.ResetUIBinder)

local ResetUI = {}

local janitor = Janitor.new()
local binder
local refs

function ResetUI.init(bus)
	local ok, refsOrErr
	for _ = 1, 10 do
		ok, refsOrErr = ResetUIResolver.resolve()
		if ok then break end
		task.wait(0.5)
	end
	if not ok then return end
	refs = refsOrErr

	ResetUIRenderer.initHidden(refs)

	if binder then
		binder:Destroy()
	end
	binder = ResetMenuBinder.bind(refs, function()
		-- Toggle button
		ResetUIRenderer.toggle(refs)
	end, function()
		-- No button (Cancel)
		ResetUIRenderer.setVisible(refs, false, false)
	end, function()
		-- Yes button (Confirm):
		-- 1. Instant dismissal (0ms UI latency feedback)
		ResetUIRenderer.setVisible(refs, false, true)
		-- 2. Non-blocking reset request to server
		task.spawn(function()
			if bus and bus.requestReset then
				bus.requestReset()
			end
		end)
	end)
end

function ResetUI.destroy()
	if binder then
		binder:Destroy()
		binder = nil
	end
	janitor:Destroy()
end

return ResetUI
