local Module = {}

function Module.Install(Controller)
-- ===================================================================
-- MODAL GIFTING LOGIC
-- ===================================================================
function Controller:OpenPlayerModal(category: string, itemId: string, itemTitle: string)
	self.currentGiftCategory = category
	self.currentGiftId = itemId

	local modal = self.modal
	local modalContainer = self.modalContainer
	local modalTemplate = self.modalTemplate

	self.modalTitle.Text = "KIRIM HADIAH"
	self.modalSubtitle.Text = "Pilih pemain di server untuk menerima: " .. itemTitle
	modal.Visible = true

	for _, child in ipairs(modalContainer:GetChildren()) do
		if child:IsA("Frame") and child ~= modalTemplate then
			child:Destroy()
		end
	end

	local serverPlayers = self.Players:GetPlayers()
	local count = 0

	for _, p in ipairs(serverPlayers) do
		if p ~= self.localPlayer then
			count += 1
			local item = modalTemplate:Clone()
			item.Name = "Player_" .. tostring(p.UserId)
			item.Visible = true
			item.Parent = modalContainer

			local dn = item:FindFirstChild("DisplayName") :: TextLabel?
			local un = item:FindFirstChild("Username") :: TextLabel?
			local av = item:FindFirstChild("Avatar") :: ImageLabel?
			local giftBtn = item:FindFirstChild("GiftActionBtn") :: TextButton?

			if dn then dn.Text = p.DisplayName end
			if un then un.Text = "@" .. p.Name end

			if av then
				task.spawn(function()
					local thumb, isReady = self.Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
					if av and av.Parent then av.Image = thumb end
				end)
			end

			if giftBtn then
				giftBtn.MouseButton1Click:Connect(function()
					modal.Visible = false
					self.NetworkGateway:Request("POST", "/shop/gift", {
						ItemCategory = self.currentGiftCategory,
						ItemId = self.currentGiftId,
						TargetUserId = p.UserId
					})
				end)
			end
		end
	end

	if count == 0 then
		local notice = Instance.new("TextLabel")
		notice.Name = "EmptyNotice"
		notice.Size = UDim2.new(1, 0, 0, 50)
		notice.BackgroundTransparency = 1
		notice.Font = Enum.Font.FredokaOne
		notice.TextSize = 14
		notice.TextColor3 = Color3.fromRGB(180, 190, 210)
		notice.Text = "Tidak ada pemain lain di server saat ini."
		notice.Parent = modalContainer
	end
end

function Controller:WireGiftModal()
	self.modalCloseBtn.MouseButton1Click:Connect(function()
		self.modal.Visible = false
	end)
end
end

return Module
