--!nonstrict
-- ==============================================================================
-- Visuals.lua
-- Render & sinkronisasi visual panel Title: quota, pilihan warna, slot, isi form.
-- ==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ImageTitleConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("TitleConfig"))
local Config = require(script.Parent:WaitForChild("Config"))

local Visuals = {}
Visuals.__index = Visuals

function Visuals.new(ctx)
	return setmetatable({ ctx = ctx }, Visuals)
end

function Visuals:refreshQuota()
	local quotaLabel = self.ctx.refs.quotaLabel
	local serverData = self.ctx.state.serverData

	if not serverData or not serverData.Quota then
		quotaLabel.Text = "Memuat data title..."
		return
	end
	local q = serverData.Quota
	if q.CooldownSeconds and q.CooldownSeconds > 0 and q.Remaining == 0 then
		quotaLabel.Text = string.format("⏳ Cooldown Teks: %s (Sisa 0/2)", Config.formatCooldown(q.CooldownSeconds))
		quotaLabel.TextColor3 = Color3.fromRGB(205, 45, 45)
	else
		quotaLabel.Text = string.format("Quota Ganti Teks: %d/2 Hari Ini", q.Remaining or 0)
		quotaLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
	end
end

function Visuals:updateColorSelection(activeMode)
	local ctx = self.ctx
	local sectionLabel = ctx.refs.colSec:FindFirstChild("SectionLabel")
	local activeDef = nil

	for _, cBtn in ipairs(ctx.refs.colContainer:GetChildren()) do
		if cBtn:IsA("TextButton") then
			local def = ctx.colorDefs[cBtn.Name]
			local isSelected = def and (def.Mode == activeMode)
			if isSelected then
				activeDef = def
			end

			local stroke = cBtn:FindFirstChild("Stroke") or cBtn:FindFirstChildWhichIsA("UIStroke")
			if stroke then
				stroke.Color = isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(35, 35, 35)
				stroke.Thickness = isSelected and 2.5 or 1.5
			end
		end
	end

	if sectionLabel then
		if activeDef then
			sectionLabel.Text = string.format("Animasi: %s %s (%s)", activeDef.Icon, activeDef.Mode, activeDef.Desc)
		else
			sectionLabel.Text = "Text Color / Animasi"
		end
	end
end

function Visuals:updateSlotVisuals()
	local ctx = self.ctx
	local currentSlot = ctx.state.currentSlot
	local isText = (currentSlot <= 3)
	local curReq = ImageTitleConfig.SlotMilestones[currentSlot]
	local curUnlocked, curReason = Config.isSlotUnlocked(ctx, currentSlot)

	local statusLabel = ctx.refs.statusLabel
	if statusLabel then
		if curUnlocked then
			statusLabel.Text = string.format("Slot %d (%s): ✨ Terbuka (%s)", currentSlot, isText and "Teks" or "Gambar", curReq and curReq.Label or "")
			statusLabel.TextColor3 = Color3.fromRGB(35, 145, 60)
		else
			statusLabel.Text = string.format("Slot %d (%s): 🔒 Terkunci - %s", currentSlot, isText and "Teks" or "Gambar", curReason ~= "" and curReason or (curReq and curReq.Reason or "Belum Terbuka"))
			statusLabel.TextColor3 = Color3.fromRGB(205, 45, 45)
		end
	end

	for i = 1, 6 do
		local sBtn = ctx.refs.buttonsHolder:FindFirstChild("Slot_" .. i)
		if sBtn then
			local stroke = sBtn:FindFirstChild("Stroke") or sBtn:FindFirstChildWhichIsA("UIStroke")
			local lockOverlay = sBtn:FindFirstChild("LockOverlay")
			local isSelected = (i == currentSlot)
			local unlocked, _ = Config.isSlotUnlocked(ctx, i)

			if lockOverlay then
				lockOverlay.Visible = not unlocked
			end

			if isSelected then
				sBtn.BackgroundColor3 = Color3.fromRGB(235, 135, 30)
				if stroke then
					stroke.Color = Color3.fromRGB(255, 235, 130)
					stroke.Thickness = 2
				end
			else
				sBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
				if stroke then
					stroke.Color = Color3.fromRGB(45, 45, 45)
					stroke.Thickness = 1.5
				end
			end
		end
	end
end

function Visuals:renderCurrentSlot()
	self:updateSlotVisuals()

	local ctx = self.ctx
	local refs = ctx.refs
	local currentSlot = ctx.state.currentSlot
	local isText = (currentSlot <= 3)
	local unlocked, _ = Config.isSlotUnlocked(ctx, currentSlot)

	-- SEMUA SECTION SELALU VISIBLE (1 FRAME UTUH SESUAI DESAIN USER)
	refs.slotSec.Visible = true
	refs.imgSec.Visible = true
	refs.textSec.Visible = true
	refs.colSec.Visible = true
	refs.actSec.Visible = true

	local draft = ctx.drafts[currentSlot]

	-- Update visual stroke seleksi pada katalog gambar
	for _, card in ipairs(refs.imgContainer:GetChildren()) do
		if card:IsA("ImageButton") then
			local sel = card:FindFirstChild("SelectionStroke")
			if sel then
				if (not isText) and draft.imageKey then
					sel.Enabled = (card.Name == "Card_" .. draft.imageKey)
				else
					sel.Enabled = false
				end
			end
		end
	end

	if isText then
		refs.titleBox.Text = draft.text or ""
		refs.titleBox.TextEditable = unlocked
		if not unlocked then
			refs.titleBox.PlaceholderText = "Slot Masih Terkunci"
		else
			refs.titleBox.PlaceholderText = "Enter Title"
		end
		self:updateColorSelection(draft.mode)
	else
		-- Slot 4-6 adalah slot gambar
		refs.titleBox.Text = ""
		refs.titleBox.TextEditable = false
		if not unlocked then
			refs.titleBox.PlaceholderText = "Slot Masih Terkunci"
		else
			local badgeName = ""
			if draft.imageKey then
				for _, it in ipairs(ImageTitleConfig.ImageTitles) do
					if it.Id == draft.imageKey then
						badgeName = it.Name
						break
					end
				end
			end
			if badgeName ~= "" then
				refs.titleBox.PlaceholderText = "Badge Terpilih: " .. badgeName
			else
				refs.titleBox.PlaceholderText = "Pilih Image Title di atas"
			end
		end
		self:updateColorSelection(nil)
	end
end

return Visuals
