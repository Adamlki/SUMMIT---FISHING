--!nonstrict
local FrameTracker = {}

function FrameTracker.setup(gameUI, janitor)
	local tracked = {}
	local syncing = false

	local function closeOtherFrames(activeFrame)
		if syncing then
			return
		end
		syncing = true
		for frame in pairs(tracked) do
			if frame ~= activeFrame and frame.Parent and frame:GetAttribute("IsOpen") == true then
				frame:SetAttribute("IsOpen", false)
				frame.Visible = false
			end
		end
		syncing = false
	end

	local function syncFrameState(frame, source)
		if syncing then
			return
		end
		syncing = true

		if source == "attribute" then
			local isOpen = frame:GetAttribute("IsOpen")
			if isOpen == true then
				syncing = false
				closeOtherFrames(frame)
				return
			end
		elseif source == "visible" then
			local isVisible = frame.Visible == true
			frame:SetAttribute("IsOpen", isVisible)
			if isVisible then
				syncing = false
				closeOtherFrames(frame)
				return
			end
		end

		syncing = false
	end

	local function trackFrame(frame)
		if tracked[frame] ~= nil then
			return
		end
		if not frame:IsA("GuiObject") then
			return
		end
		if typeof(frame:GetAttribute("IsOpen")) ~= "boolean" then
			return
		end

		local frameJanitor = {}
		tracked[frame] = frameJanitor

		frameJanitor.attributeConn = frame:GetAttributeChangedSignal("IsOpen"):Connect(function()
			syncFrameState(frame, "attribute")
		end)
		frameJanitor.visibleConn = frame:GetPropertyChangedSignal("Visible"):Connect(function()
			syncFrameState(frame, "visible")
		end)
		frameJanitor.ancestryConn = frame.AncestryChanged:Connect(function(_, parent)
			if parent then
				return
			end
			local entry = tracked[frame]
			if not entry then
				return
			end
			if entry.attributeConn then
				entry.attributeConn:Disconnect()
			end
			if entry.visibleConn then
				entry.visibleConn:Disconnect()
			end
			if entry.ancestryConn then
				entry.ancestryConn:Disconnect()
			end
			tracked[frame] = nil
		end)

		janitor:Add(frameJanitor.attributeConn, "Disconnect")
		janitor:Add(frameJanitor.visibleConn, "Disconnect")
		janitor:Add(frameJanitor.ancestryConn, "Disconnect")

		if frame.Visible == true then
			syncFrameState(frame, "visible")
		else
			frame:SetAttribute("IsOpen", false)
		end
	end

	for _, descendant in ipairs(gameUI:GetDescendants()) do
		trackFrame(descendant)
	end

	janitor:Add(gameUI.DescendantAdded:Connect(function(descendant)
		trackFrame(descendant)
	end), "Disconnect")

	return {
		tracked = tracked,
	}
end

return FrameTracker
