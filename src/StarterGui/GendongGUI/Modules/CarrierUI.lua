local Module = {}

function Module.Install(Controller)
	-- Refresh carrier UI (showing carried players list)
	function Controller:RefreshCarrierUI()
		local count = #self.carriedList

		-- Kalau tidak ada yang di-carry, hide UI
		if count <= 0 then
			self.Frame2.Visible = false
			return
		end

		-- Clamp carried index
		if self.carriedIndex < 1 then
			self.carriedIndex = 1
		end
		if self.carriedIndex > count then
			self.carriedIndex = count
		end

		-- Update UI text
		local item = self.carriedList[self.carriedIndex]
		if item then
			self.NameLabel.Text = string.format("Carrying (%d/%d): %s", self.carriedIndex, count, item.name or "Player")
			self.Frame2.Visible = true
			self.Frame3.Visible = false
		end
	end

	-- Stop keep UI connection
	function Controller:StopKeepUi()
		if self.keepUiConn then
			self.keepUiConn:Disconnect()
			self.keepUiConn = nil
		end
	end

	-- Start keep UI connection (ensure UI tetap visible)
	function Controller:StartKeepUi()
		self:StopKeepUi()

		self.keepUiConn = self.RunService.Heartbeat:Connect(function()
			if self.isCarried then
				self:EnsureStatusVisible()
				-- FIX: Pastikan animasi sit terus berjalan selama di-carry
				local hum = self:GetHumanoid()
				if hum then
					hum.Sit = false
					hum.PlatformStand = false
					if self.sitTrack and not self.sitTrack.IsPlaying then
						self.sitTrack:Play(0.1)
					end
				end
			else
				self:StopKeepUi()
			end
		end)
	end

	-- Add carried player ke list
	function Controller:AddCarried(id, name)
		-- Check kalau sudah ada, update name aja
		for _, it in ipairs(self.carriedList) do
			if it.id == id then
				it.name = name
				self:RefreshCarrierUI()
				return
			end
		end

		-- Add new carried player
		table.insert(self.carriedList, {id = id, name = name})
		self.carriedIndex = #self.carriedList
		self:RefreshCarrierUI()
	end

	-- Remove carried player dari list
	function Controller:RemoveCarried(id)
		local idx

		-- Find index
		for i, it in ipairs(self.carriedList) do
			if it.id == id then
				idx = i
				break
			end
		end

		-- Remove dari list
		if idx then
			table.remove(self.carriedList, idx)
		end

		-- Adjust index
		if self.carriedIndex > #self.carriedList then
			self.carriedIndex = #self.carriedList
		end

		-- Update UI
		if #self.carriedList > 0 then
			self:RefreshCarrierUI()
		else
			self.Frame2.Visible = false
		end
	end

	-- Set carried list dari snapshot (server sync)
	function Controller:SetCarriedListFromSnapshot(list)
		self.carriedList = {}

		for _, it in ipairs(list or {}) do
			table.insert(self.carriedList, {
				id = it.id,
				name = it.name
			})
		end

		-- Adjust index
		if self.carriedIndex > #self.carriedList then
			self.carriedIndex = #self.carriedList
		end
		if self.carriedIndex < 1 and #self.carriedList > 0 then
			self.carriedIndex = 1
		end

		-- Update UI
		if #self.carriedList > 0 then
			self:RefreshCarrierUI()
		else
			self.Frame2.Visible = false
		end
	end
end

return Module
