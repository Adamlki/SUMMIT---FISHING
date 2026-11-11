--!nonstrict
-- ==============================================================================
-- TitleMenu.luau
-- Client Controller untuk TITLE PANEL & INFORMATION CARD (Mockup 100% Sesuai)
-- Slot 1-3 Teks, Slot 4-6 Gambar, Translucent Lock Overlay, 6 Animated Dynamic Modes
-- ==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer and (localPlayer:FindFirstChild("PlayerGui") or localPlayer:WaitForChild("PlayerGui", 5))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = Shared:WaitForChild("Packages")
local Janitor = require(Packages:WaitForChild("Janitor"))

local ImageTitleConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("TitleConfig"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local CustomTitleNotification = require(script.Parent.Parent:WaitForChild("Notifications"):WaitForChild("CustomTitleNotification"))

local CustomTitleRemotes = ReplicatedStorage:WaitForChild("CustomTitleRemotes")
local GetTitleDataRF = CustomTitleRemotes:WaitForChild("GetTitleData")
local SetTitleRF = CustomTitleRemotes:WaitForChild("SetTitle")
local ClearSlotRF = CustomTitleRemotes:WaitForChild("ClearSlot")

local TitleMenu = {}

local initialized = false
local currentSlot = 1
local serverData = nil
local isPreviewing = false

local function encodeColors(colors)
	if not colors or #colors == 0 then return "" end
	local parts = {}
	for _, c in ipairs(colors) do
		local r = math.round(c.R * 255)
		local g = math.round(c.G * 255)
		local b = math.round(c.B * 255)
		table.insert(parts, string.format("%d,%d,%d", r, g, b))
	end
	return table.concat(parts, ";")
end

-- 6 Slots Draft: Slot 1-3 khusus Text, Slot 4-6 khusus Image
local slotDrafts = {}
for i = 1, 6 do
	slotDrafts[i] = {
		titleType = (i <= 3) and "Text" or "Image",
		text = "",
		mode = "Rainbow Flow",
		colors = Effects.getPalette("Rainbow Flow"),
		imageId = nil,
		imageKey = nil,
	}
end

local function formatCooldown(seconds)
	if seconds <= 0 then return "0s" end
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = math.floor(seconds % 60)
	if h > 0 then
		return string.format("%d jam %d mnt", h, m)
	elseif m > 0 then
		return string.format("%d mnt %d dtk", m, s)
	else
		return string.format("%d dtk", s)
	end
end

function TitleMenu.init()
	if initialized then return true end

	if not localPlayer then
		localPlayer = Players.LocalPlayer
	end
	if not playerGui and localPlayer then
		playerGui = localPlayer:WaitForChild("PlayerGui", 15)
	end
	if not playerGui then return false end

	local gameUI = playerGui:WaitForChild("GameUI", 15)
	if not gameUI then return false end

	local menus = gameUI:WaitForChild("Menus", 15)
	local titleMenuFrame = menus and menus:WaitForChild("Title", 15)
	if not titleMenuFrame then return false end

	local component = gameUI:WaitForChild("Component", 15)
	local buttonsFrame = component and component:WaitForChild("Buttons", 15)
	local adminRight = buttonsFrame and buttonsFrame:WaitForChild("AdminRight", 15)
	local toggleBtn = adminRight and adminRight:WaitForChild("Title", 15)

	if toggleBtn and toggleBtn:IsA("GuiButton") then
		toggleBtn.Visible = true
		for _, ch in ipairs(toggleBtn:GetChildren()) do
			if ch:IsA("GuiObject") then
				ch.Active = false
			end
		end
		local lastToggle = 0
		local function doToggle()
			local now = os.clock()
			if now - lastToggle < 0.25 then return end
			lastToggle = now
			titleMenuFrame.Visible = not titleMenuFrame.Visible
		end
		toggleBtn.Activated:Connect(doToggle)
	end

	-- Referensi MainCard & InfoCard
	local mainCard = titleMenuFrame:WaitForChild("MainCard")
	local mainContent = mainCard:WaitForChild("ContentFrame")
	local header = mainContent:WaitForChild("Header")
	local closeBtn = header:WaitForChild("CloseBtn")

	local content = mainContent:WaitForChild("Content")

	local slotSec = content:WaitForChild("SlotSection")
	local buttonsHolder = slotSec:WaitForChild("ButtonsHolder")
	local statusLabel = slotSec:WaitForChild("StatusLabel")

	local imgSec = content:WaitForChild("ImageSection")
	local imgContainer = imgSec:WaitForChild("Container")

	local textSec = content:WaitForChild("TextSection")
	local inputFrame = textSec:WaitForChild("InputFrame")
	local titleBox = inputFrame:WaitForChild("TitleBox")

	local colSec = content:WaitForChild("ColorSection")
	local colContainer = colSec:WaitForChild("Container")

	local actSec = content:WaitForChild("ActionSection")
	local actHolder = actSec:WaitForChild("ButtonsHolder")
	local btnPreview = actHolder:WaitForChild("BtnPreview")
	local btnSetTitle = actHolder:WaitForChild("BtnSetTitle")
	local btnClearSlot = actHolder:WaitForChild("BtnClearSlot")
	local quotaLabel = actSec:WaitForChild("QuotaLabel")

	initialized = true

	-- ──────────────────────────────────────────────────────────────────────────
	-- Helper: Pengecekan status unlock slot
	-- ──────────────────────────────────────────────────────────────────────────
	local function isSlotUnlocked(slotNum)
		if serverData and serverData.IsAdmin then
			return true, ""
		end
		if serverData and serverData.SlotUnlocks and serverData.SlotUnlocks[slotNum] then
			return serverData.SlotUnlocks[slotNum].Unlocked, serverData.SlotUnlocks[slotNum].Reason or ""
		end
		-- Fallback local
		local req = ImageTitleConfig.SlotMilestones[slotNum]
		if not req then return true, "" end

		local currentSummit = serverData and serverData.Summit or 0
		local currentFish = serverData and serverData.FishCount or 0

		if req.UnlockType == "Summit" then
			if currentSummit < (req.ReqSummit or 0) then
				return false, string.format("Butuh %s (Saat ini: %d Summit)", req.Label, currentSummit)
			end
		elseif req.UnlockType == "FishCount" then
			if currentFish < (req.ReqFishCount or 0) then
				return false, string.format("Butuh %s (Saat ini: %d Mancing)", req.Label, currentFish)
			end
		elseif req.UnlockType == "Group" then
			local inGroup = localPlayer and localPlayer:IsInGroup(req.GroupId or 352750447)
			if not inGroup then
				return false, req.Reason or "Wajib Join Komunitas Roblox & Like Map"
			end
		end
		return true, ""
	end

	-- ──────────────────────────────────────────────────────────────────────────
	-- Render & Visual Sync Functions
	-- ──────────────────────────────────────────────────────────────────────────

	local function refreshQuotaDisplay()
		if not serverData or not serverData.Quota then
			quotaLabel.Text = "Memuat data title..."
			return
		end
		local q = serverData.Quota
		if q.CooldownSeconds and q.CooldownSeconds > 0 and q.Remaining == 0 then
			quotaLabel.Text = string.format("⏳ Cooldown Teks: %s (Sisa 0/2)", formatCooldown(q.CooldownSeconds))
			quotaLabel.TextColor3 = Color3.fromRGB(205, 45, 45)
		else
			quotaLabel.Text = string.format("Quota Ganti Teks: %d/2 Hari Ini", q.Remaining or 0)
			quotaLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
		end
	end

	local colorDefs = {
		Col_Purple = { Name = "Cosmic",  Mode = "Cosmic Spin",  Desc = "Putaran Galaksi Kosmik", Colors = Effects.getPalette("Cosmic Spin"), Icon = "🌌" },
		Col_Orange = { Name = "Sunset",  Mode = "Sunset Flare", Desc = "Aliran Kobaran Senja",    Colors = Effects.getPalette("Sunset Flare"), Icon = "🔥" },
		Col_Blue   = { Name = "Ocean",   Mode = "Ocean Wave",   Desc = "Gelombang Ombak Samudra",Colors = Effects.getPalette("Ocean Wave"), Icon = "🌊" },
		Col_Green  = { Name = "Aurora",  Mode = "Aurora Drift", Desc = "Cahaya Kutub Diagonal",  Colors = Effects.getPalette("Aurora Drift"), Icon = "🌿" },
		Col_Gold   = { Name = "Gold",    Mode = "Royal Gold",   Desc = "Kilau Emas & Perunggu",  Colors = Effects.getPalette("Royal Gold"), Icon = "👑" },
		Col_Pink   = { Name = "Rainbow", Mode = "Rainbow Flow", Desc = "Spektrum Pelangi Penuh", Colors = Effects.getPalette("Rainbow Flow"), Icon = "✨" },
	}

	local function updateColorSelectionVisual(activeMode)
		local sectionLabel = colSec:FindFirstChild("SectionLabel")
		local activeDef = nil

		for _, cBtn in ipairs(colContainer:GetChildren()) do
			if cBtn:IsA("TextButton") then
				local def = colorDefs[cBtn.Name]
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

	local function updateSlotVisuals()
		local isText = (currentSlot <= 3)
		local curReq = ImageTitleConfig.SlotMilestones[currentSlot]
		local curUnlocked, curReason = isSlotUnlocked(currentSlot)

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
			local sBtn = buttonsHolder:FindFirstChild("Slot_" .. i)
			if sBtn then
				local stroke = sBtn:FindFirstChild("Stroke") or sBtn:FindFirstChildWhichIsA("UIStroke")
				local lockOverlay = sBtn:FindFirstChild("LockOverlay")
				local isSelected = (i == currentSlot)
				local unlocked, _ = isSlotUnlocked(i)

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

	local function renderCurrentSlot()
		updateSlotVisuals()
		local isText = (currentSlot <= 3)
		local unlocked, _ = isSlotUnlocked(currentSlot)

		-- SEMUA SECTION SELALU VISIBLE (1 FRAME UTUH SESUAI DESAIN USER)
		slotSec.Visible = true
		imgSec.Visible = true
		textSec.Visible = true
		colSec.Visible = true
		actSec.Visible = true

		local draft = slotDrafts[currentSlot]

		-- Update visual stroke seleksi pada katalog gambar
		for _, card in ipairs(imgContainer:GetChildren()) do
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
			titleBox.Text = draft.text or ""
			titleBox.TextEditable = unlocked
			if not unlocked then
				titleBox.PlaceholderText = "Slot Masih Terkunci"
			else
				titleBox.PlaceholderText = "Enter Title"
			end
			updateColorSelectionVisual(draft.mode)
		else
			-- Slot 4-6 adalah slot gambar
			titleBox.Text = ""
			titleBox.TextEditable = false
			if not unlocked then
				titleBox.PlaceholderText = "Slot Masih Terkunci"
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
					titleBox.PlaceholderText = "Badge Terpilih: " .. badgeName
				else
					titleBox.PlaceholderText = "Pilih Image Title di atas"
				end
			end
			updateColorSelectionVisual(nil)
		end
	end

	local function fetchServerData()
		task.spawn(function()
			local ok, data = pcall(function()
				return GetTitleDataRF:InvokeServer()
			end)

			if ok and data and data.Success then
				serverData = data

				-- Update Image cards unlock states (Translucent Lock Overlay)
				for _, entry in ipairs(ImageTitleConfig.ImageTitles) do
					local card = imgContainer:FindFirstChild("Card_" .. entry.Id)
					if card then
						local lockOverlay = card:FindFirstChild("LockOverlay")
						local unlocked = (data.ImageUnlocks and data.ImageUnlocks[entry.Id] == true) or data.IsAdmin
						if lockOverlay then
							lockOverlay.Visible = not unlocked
							local reqLbl = lockOverlay:FindFirstChild("ReqLabel")
							if reqLbl then
								reqLbl.Text = entry.Description or "Terkunci"
							end
						end
					end
				end

				-- Sync existing saved slots from server DataStore
				if data.Slots then
					for i = 1, 6 do
						local s = data.Slots[i]
						if s then
							if i >= 4 and (s.titleType == "Image" or (s.imageId and s.imageId ~= "")) then
								slotDrafts[i].titleType = "Image"
								slotDrafts[i].imageId = s.imageId
								slotDrafts[i].imageKey = s.imageKey
								slotDrafts[i].text = ""
							elseif i <= 3 and s.text and s.text ~= "" then
								slotDrafts[i].titleType = "Text"
								slotDrafts[i].text = s.text
								slotDrafts[i].mode = s.mode or "Rainbow Flow"
								slotDrafts[i].colors = Effects.getPalette(s.mode or "Rainbow Flow") or { Color3.fromRGB(255, 255, 255) }
								slotDrafts[i].imageId = nil
								slotDrafts[i].imageKey = nil
							end
						end
					end
				end

				refreshQuotaDisplay()
				renderCurrentSlot()
			end
		end)
	end

	-- ──────────────────────────────────────────────────────────────────────────
	-- Slot Selection
	-- ──────────────────────────────────────────────────────────────────────────

	local function selectSlot(slotNum)
		if slotNum < 1 or slotNum > 6 then return end
		currentSlot = slotNum
		renderCurrentSlot()
	end

	for i = 1, 6 do
		local sBtn = buttonsHolder:FindFirstChild("Slot_" .. i)
		if sBtn then
			sBtn.MouseButton1Click:Connect(function()
				selectSlot(i)
			end)
		end
	end

	-- ──────────────────────────────────────────────────────────────────────────
	-- Image Title Selection (Slot 4-6)
	-- ──────────────────────────────────────────────────────────────────────────

	for _, entry in ipairs(ImageTitleConfig.ImageTitles) do
		local card = imgContainer:FindFirstChild("Card_" .. entry.Id)
		if card then
			card.MouseButton1Click:Connect(function()
				if currentSlot < 4 or currentSlot > 6 then
					CustomTitleNotification.info("Pilih Slot 4, 5, atau 6 untuk memasang Title Gambar!", 3)
					return
				end

				local unlocked = (serverData and serverData.ImageUnlocks and serverData.ImageUnlocks[entry.Id] == true) or (serverData and serverData.IsAdmin)
				if not unlocked then
					CustomTitleNotification.error(string.format("Title ini terkunci! Syarat: %s", entry.Description), 3)
					return
				end

				local draft = slotDrafts[currentSlot]
				draft.titleType = "Image"
				draft.imageKey = entry.Id
				draft.imageId = entry.ImageId
				draft.text = ""

				renderCurrentSlot()
			end)
		end
	end

	-- ──────────────────────────────────────────────────────────────────────────
	-- Custom Text Input (Slot 1-3)
	-- ──────────────────────────────────────────────────────────────────────────

	titleBox:GetPropertyChangedSignal("Text"):Connect(function()
		if currentSlot > 3 then return end
		local text = titleBox.Text
		if #text > ImageTitleConfig.TextRules.MaxLength then
			text = string.sub(text, 1, ImageTitleConfig.TextRules.MaxLength)
			titleBox.Text = text
		end

		local draft = slotDrafts[currentSlot]
		draft.titleType = "Text"
		draft.text = text
	end)

	-- ──────────────────────────────────────────────────────────────────────────
	-- Color / Animated Mode Selections (6 Modes)
	-- ──────────────────────────────────────────────────────────────────────────

	for colName, def in pairs(colorDefs) do
		local cBtn = colContainer:FindFirstChild(colName)
		if cBtn then
			cBtn.Text = def.Name
			cBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			cBtn.TextSize = 13
			cBtn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy)
			cBtn.TextStrokeTransparency = 0.4
			cBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

			cBtn.MouseButton1Click:Connect(function()
				if currentSlot > 3 then
					CustomTitleNotification.info("Pilih Slot 1, 2, atau 3 untuk mengatur teks & warna!", 3)
					return
				end
				local draft = slotDrafts[currentSlot]
				draft.mode = def.Mode
				draft.colors = def.Colors
				updateColorSelectionVisual(draft.mode)
			end)
		end
	end

	-- ──────────────────────────────────────────────────────────────────────────
	-- PREVIEW 5 DETIK
	-- ──────────────────────────────────────────────────────────────────────────

	local function startPreview()
		if isPreviewing then return end
		local draft = slotDrafts[currentSlot]
		local isText = (currentSlot <= 3)

		if isText and (#draft.text == 0) then
			CustomTitleNotification.error("Ketik teks title terlebih dahulu untuk preview!", 2.5)
			return
		elseif (not isText) and (not draft.imageId or draft.imageId == "") then
			CustomTitleNotification.error("Pilih title gambar terlebih dahulu untuk preview!", 2.5)
			return
		end

		isPreviewing = true
		titleMenuFrame.Visible = false

		local origText = localPlayer:GetAttribute("CustomTitleText_" .. currentSlot)
		local origImage = localPlayer:GetAttribute("CustomTitleImage_" .. currentSlot)
		local origMode = localPlayer:GetAttribute("CustomTitleMode_" .. currentSlot)
		local origCol = localPlayer:GetAttribute("CustomTitleTextColor_" .. currentSlot)
		local origGrad = localPlayer:GetAttribute("CustomTitleTextGradient_" .. currentSlot)

		if isText then
			local colors = draft.colors or Effects.getPalette(draft.mode or "Rainbow Flow")
			local primaryCol = colors and colors[1] or Color3.fromRGB(255, 255, 255)
			local gradStr = encodeColors(colors)

			localPlayer:SetAttribute("CustomTitleImage_" .. currentSlot, nil)
			localPlayer:SetAttribute("CustomTitleText_" .. currentSlot, draft.text)
			localPlayer:SetAttribute("CustomTitleMode_" .. currentSlot, draft.mode or "Rainbow Flow")
			localPlayer:SetAttribute("CustomTitleTextColor_" .. currentSlot, primaryCol)
			localPlayer:SetAttribute("CustomTitleTextGradient_" .. currentSlot, gradStr)
		else
			localPlayer:SetAttribute("CustomTitleText_" .. currentSlot, nil)
			localPlayer:SetAttribute("CustomTitleTextColor_" .. currentSlot, nil)
			localPlayer:SetAttribute("CustomTitleMode_" .. currentSlot, nil)
			localPlayer:SetAttribute("CustomTitleTextGradient_" .. currentSlot, nil)
			localPlayer:SetAttribute("CustomTitleImage_" .. currentSlot, draft.imageId)
		end

		local pill = Instance.new("Frame")
		pill.Name = "TitlePreviewPill"
		pill.AnchorPoint = Vector2.new(0.5, 0)
		pill.Position = UDim2.new(0.5, 0, 0, 16)
		pill.Size = UDim2.new(0, 240, 0, 36)
		pill.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		pill.BorderSizePixel = 0
		pill.ZIndex = 100
		pill.Parent = gameUI

		local pCorner = Instance.new("UICorner")
		pCorner.CornerRadius = UDim.new(0, 18)
		pCorner.Parent = pill

		local pStroke = Instance.new("UIStroke")
		pStroke.Color = Color3.fromRGB(255, 215, 0)
		pStroke.Thickness = 1.5
		pStroke.Parent = pill

		local pLabel = Instance.new("TextLabel")
		pLabel.Size = UDim2.new(1, 0, 1, 0)
		pLabel.BackgroundTransparency = 1
		pLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy)
		pLabel.TextSize = 13
		pLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		pLabel.Text = "Preview Title: 5s"
		pLabel.ZIndex = 101
		pLabel.Parent = pill

		task.spawn(function()
			for s = 5, 1, -1 do
				pLabel.Text = string.format("Preview Title: %ds", s)
				task.wait(1)
			end
			pill:Destroy()

			if localPlayer then
				localPlayer:SetAttribute("CustomTitleText_" .. currentSlot, origText)
				localPlayer:SetAttribute("CustomTitleImage_" .. currentSlot, origImage)
				localPlayer:SetAttribute("CustomTitleMode_" .. currentSlot, origMode)
				localPlayer:SetAttribute("CustomTitleTextColor_" .. currentSlot, origCol)
				localPlayer:SetAttribute("CustomTitleTextGradient_" .. currentSlot, origGrad)
			end

			titleMenuFrame.Visible = true
			isPreviewing = false
		end)
	end

	btnPreview.MouseButton1Click:Connect(startPreview)

	-- ──────────────────────────────────────────────────────────────────────────
	-- SET TITLE (SIMPAN KE SERVER)
	-- ──────────────────────────────────────────────────────────────────────────

	btnSetTitle.MouseButton1Click:Connect(function()
		local unlocked, reason = isSlotUnlocked(currentSlot)
		if not unlocked then
			CustomTitleNotification.error(string.format("Slot %d terkunci! %s", currentSlot, reason), 3)
			return
		end

		local draft = slotDrafts[currentSlot]
		local isText = (currentSlot <= 3)

		if isText and (#draft.text == 0) then
			CustomTitleNotification.error("Ketik teks title terlebih dahulu sebelum menyimpan!", 3)
			return
		elseif (not isText) and (not draft.imageId or draft.imageId == "") then
			CustomTitleNotification.error("Pilih title gambar terlebih dahulu sebelum menyimpan!", 3)
			return
		end

		local payload = {}
		if isText then
			payload = {
				text = draft.text,
				mode = draft.mode or "Rainbow Flow",
				colors = draft.colors or Effects.getPalette(draft.mode or "Rainbow Flow"),
			}
		else
			payload = {
				id = draft.imageKey,
				imageKey = draft.imageKey,
				imageId = draft.imageId,
			}
		end

		btnSetTitle.Text = "MENYIMPAN..."
		btnSetTitle.Active = false

		task.spawn(function()
			local ok, res = pcall(function()
				return SetTitleRF:InvokeServer(currentSlot, isText and "Text" or "Image", payload)
			end)

			btnSetTitle.Text = "SET TITLE"
			btnSetTitle.Active = true

			if ok and res and res.Success then
				CustomTitleNotification.success(res.Message or "Title berhasil disimpan!", 3)
				fetchServerData()
			else
				local errMsg = (res and res.Message) or "Gagal menyimpan title!"
				CustomTitleNotification.error(errMsg, 3.5)
			end
		end)
	end)

	-- ──────────────────────────────────────────────────────────────────────────
	-- CLEAR ROW (HAPUS SLOT AKTIF)
	-- ──────────────────────────────────────────────────────────────────────────

	btnClearSlot.MouseButton1Click:Connect(function()
		btnClearSlot.Text = "MENGHAPUS..."
		btnClearSlot.Active = false

		task.spawn(function()
			local ok, res = pcall(function()
				return ClearSlotRF:InvokeServer(currentSlot)
			end)

			btnClearSlot.Text = "CLEAR ROW"
			btnClearSlot.Active = true

			if ok and res and res.Success then
				CustomTitleNotification.info(string.format("Slot %d berhasil dikosongkan!", currentSlot), 2.5)

				local isText = (currentSlot <= 3)
				slotDrafts[currentSlot] = {
					titleType = isText and "Text" or "Image",
					text = "",
					mode = "Rainbow Flow",
					colors = Effects.getPalette("Rainbow Flow"),
					imageId = nil,
					imageKey = nil,
				}

				fetchServerData()
			else
				local errMsg = (res and res.Message) or "Gagal menghapus title!"
				CustomTitleNotification.error(errMsg, 3)
			end
		end)
	end)

	-- ──────────────────────────────────────────────────────────────────────────
	-- Close Button & Visibility
	-- ──────────────────────────────────────────────────────────────────────────

	closeBtn.MouseButton1Click:Connect(function()
		titleMenuFrame.Visible = false
	end)

	titleMenuFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if titleMenuFrame.Visible then
			fetchServerData()
		end
	end)

	-- Fetch awal data server
	fetchServerData()
	initialized = true
	return true
end

return TitleMenu
