local Module = {}

function Module.Install(Controller)
	function Controller:ConnectRemotes()
		-- Yes button (accept carry request)
		self.BtnYes.MouseButton1Click:Connect(function()
			if self.lastRequesterId then
				self.Frame3.Visible = false
				self.NetworkGateway:Request("POST", "/carry/response", {
					RequesterId = self.lastRequesterId,
					Accept = true
				})
			end
		end)

		-- No button (decline carry request)
		self.BtnNo.MouseButton1Click:Connect(function()
			if self.lastRequesterId then
				self.Frame3.Visible = false
				self.NetworkGateway:Request("POST", "/carry/response", {
					RequesterId = self.lastRequesterId,
					Accept = false
				})
			end
		end)

		-- Down button (get down or drop carried player)
		self.BtnDown.MouseButton1Click:Connect(function()
			if self.isCarried then
				-- Get down dari carrier
				self.NetworkGateway:Request("DELETE", "/carry/stop", {})
			else
				-- Drop carried player
				local item = self.carriedList[self.carriedIndex]
				if item and item.id then
					self.NetworkGateway:Request("DELETE", "/carry/stop", {
						TargetId = item.id
					})
				end
			end
		end)

		-- Right button (next carried player)
		self.BtnRight.MouseButton1Click:Connect(function()
			if #self.carriedList == 0 then return end

			self.carriedIndex += 1
			if self.carriedIndex > #self.carriedList then
				self.carriedIndex = 1
			end

			self:RefreshCarrierUI()
		end)

		-- Left button (previous carried player)
		self.BtnLeft.MouseButton1Click:Connect(function()
			if #self.carriedList == 0 then return end

			self.carriedIndex -= 1
			if self.carriedIndex < 1 then
				self.carriedIndex = #self.carriedList
			end

			self:RefreshCarrierUI()
		end)

		self.NetworkGateway:On("Carry/Event", function(event)
			local action = type(event) == "table" and event.Action or nil
			local data = type(event) == "table" and event.Data or nil
			-- ========================================
			-- PROMPT ACTION (someone wants to carry you)
			-- ========================================
			if action == "Prompt" then
				self:ShowPromptRequest(data.fromId, data.fromName)

				-- ========================================
				-- START ACTION (carry started)
				-- ========================================
			elseif action == "Start" then
				if data and data.youAreCarrier then
					-- You started carrying someone
					self:AddCarried(data.targetId, data.targetName)

				else
					-- You are being carried
					if data and data.carrierName and data.carrierId then
						self:SetModeStatusCarried(data.carrierName, data.carrierId)
						self:PlaySit()
					end
				end

				-- ========================================
				-- END ACTION (carry ended)
				-- ========================================
			elseif action == "End" then
				if data and data.youAreCarrier then
					-- Someone you were carrying is no longer carried
					if data.removedId then
						self:RemoveCarried(data.removedId)
					end

					-- Hide carrier UI when list is empty
					if #self.carriedList <= 0 then
						self.Frame2.Visible = false
					end
				else
					-- You are no longer being carried
					self.isCarried = false
					self.currentCarrierId = nil
					self:SetMovementControlsEnabled(true)
					self.currentCarrierName = nil

					self:StopKeepUi()
					self:StopSit() -- sudah include reset velocity & state
					self:StopBlockingJump()

					-- FIX: Pastikan HRP tidak punya sisa rotasi/velocity di client
					local hrp = self:GetHRP()
					if hrp then
						pcall(function()
							hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
							hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
						end)
					end

					self.Frame2.Visible = false
					self.Frame3.Visible = false
				end

				-- ========================================
				-- CARRIER LIST UPDATE (sync from server)
				-- ========================================
			elseif action == "CarrierList" then
				if data and data.list then
					self:SetCarriedListFromSnapshot(data.list)
				end

				-- ========================================
				-- ERROR/NOTIFICATION ACTIONS
				-- ========================================
			elseif action == "Declined" or action == "TooFar" or action == "Busy" or action == "Failed" or action == "RequestExpired" or action == "Limit" then
				-- Hide prompt
				self.Frame3.Visible = false

			elseif action == "PromptExpire" or action == "PromptClose" then
				-- Hide prompt
				self.Frame3.Visible = false
			end
		end)

		-- ========================================
		-- CHARACTER RESPAWN HANDLER
		-- ========================================

		self.player.CharacterAdded:Connect(function()
			-- Stop all animations
			if self.sitTrack then
				self.sitTrack:Stop(0.1)
				self.sitTrack = nil
			end

			-- Stop connections
			self:StopKeepUi()
			self:StopBlockingJump()

			-- Reset state
			self.isCarried = false
			self.currentCarrierId = nil
			self.currentCarrierName = nil
			self.carriedList = {}
			self.carriedIndex = 1
			self.uiMode = "idle"

			-- Hide UI
			self.Frame2.Visible = false
			self.Frame3.Visible = false

			-- Reset humanoid properties
			task.wait(1)
			local hum = self:GetHumanoid()
			if hum then
				hum.Sit = false
				hum.PlatformStand = false
				hum.WalkSpeed = 16
			end
		end)
	end
end

return Module
