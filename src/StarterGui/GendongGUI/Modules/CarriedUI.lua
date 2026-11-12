local Module = {}

function Module.Install(Controller)
	-- Update UI saat player sedang di-carry
	function Controller:UpdateCarriedUI()
		if self.isCarried then
			-- Tampilkan "Get Down" button
			self.BtnLeft.Visible = false
			self.BtnRight.Visible = false
			self.BtnDown.Visible = true
			self.BtnDown.Text = "Get Down"

			-- Show carrier name
			self.NameLabel.Text = ("Carried by: %s"):format(self.currentCarrierName or "Player")

			self.Frame2.Visible = true
			self.Frame3.Visible = false
		else
			-- Show carrier UI
			self:RefreshCarrierUI()
		end
	end

	-- Ensure status UI tetap visible saat di-carry
	function Controller:EnsureStatusVisible()
		if not self.isCarried or not self.currentCarrierId then return end
		self:UpdateCarriedUI()
	end

	-- Set mode ke "being carried"
	function Controller:SetModeStatusCarried(carrierName, carrierId)
		self.currentCarrierId = carrierId
		self.currentCarrierName = carrierName
		self.isCarried = true
		self:SetMovementControlsEnabled(false)

		self:UpdateCarriedUI()
		self:StartKeepUi()
		self:StartBlockingJump()
	end

	-- Show prompt request (someone wants to carry you)
	function Controller:ShowPromptRequest(fromId, fromName)
		self.lastRequesterId = fromId
		self.PromptLabel.Text = ("%s wants to carry you. Allow?"):format(fromName or "Someone")

		self.Frame3.Visible = true
		self.Frame2.Visible = false
	end
end

return Module
