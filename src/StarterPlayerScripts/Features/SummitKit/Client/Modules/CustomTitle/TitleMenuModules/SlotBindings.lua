--!nonstrict
-- ==============================================================================
-- SlotBindings.lua
-- Event binding panel: pilih slot, pilih image title, input teks, mode warna,
-- dan tombol preview.
-- ==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ImageTitleConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("TitleConfig"))
local CustomTitleNotification = require(script.Parent.Parent.Parent:WaitForChild("Notifications"):WaitForChild("CustomTitleNotification"))

local SlotBindings = {}

function SlotBindings.bind(ctx, visuals, preview)
	local function selectSlot(slotNum)
		if slotNum < 1 or slotNum > 6 then return end
		ctx.state.currentSlot = slotNum
		visuals:renderCurrentSlot()
	end

	for i = 1, 6 do
		local sBtn = ctx.refs.buttonsHolder:FindFirstChild("Slot_" .. i)
		if sBtn then
			sBtn.MouseButton1Click:Connect(function()
				selectSlot(i)
			end)
		end
	end

	-- Image Title Selection (Slot 4-6)
	for _, entry in ipairs(ImageTitleConfig.ImageTitles) do
		local card = ctx.refs.imgContainer:FindFirstChild("Card_" .. entry.Id)
		if card then
			card.MouseButton1Click:Connect(function()
				if ctx.state.currentSlot < 4 or ctx.state.currentSlot > 6 then
					CustomTitleNotification.info("Pilih Slot 4, 5, atau 6 untuk memasang Title Gambar!", 3)
					return
				end

				local serverData = ctx.state.serverData
				local unlocked = (serverData and serverData.ImageUnlocks and serverData.ImageUnlocks[entry.Id] == true) or (serverData and serverData.IsAdmin)
				if not unlocked then
					CustomTitleNotification.error(string.format("Title ini terkunci! Syarat: %s", entry.Description), 3)
					return
				end

				local draft = ctx.drafts[ctx.state.currentSlot]
				draft.titleType = "Image"
				draft.imageKey = entry.Id
				draft.imageId = entry.ImageId
				draft.text = ""

				visuals:renderCurrentSlot()
			end)
		end
	end

	-- Custom Text Input (Slot 1-3)
	ctx.refs.titleBox:GetPropertyChangedSignal("Text"):Connect(function()
		if ctx.state.currentSlot > 3 then return end
		local text = ctx.refs.titleBox.Text
		if #text > ImageTitleConfig.TextRules.MaxLength then
			text = string.sub(text, 1, ImageTitleConfig.TextRules.MaxLength)
			ctx.refs.titleBox.Text = text
		end

		local draft = ctx.drafts[ctx.state.currentSlot]
		draft.titleType = "Text"
		draft.text = text
	end)

	-- Color / Animated Mode Selections (6 Modes)
	for colName, def in pairs(ctx.colorDefs) do
		local cBtn = ctx.refs.colContainer:FindFirstChild(colName)
		if cBtn then
			cBtn.Text = def.Name
			cBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			cBtn.TextSize = 13
			cBtn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy)
			cBtn.TextStrokeTransparency = 0.4
			cBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

			cBtn.MouseButton1Click:Connect(function()
				if ctx.state.currentSlot > 3 then
					CustomTitleNotification.info("Pilih Slot 1, 2, atau 3 untuk mengatur teks & warna!", 3)
					return
				end
				local draft = ctx.drafts[ctx.state.currentSlot]
				draft.mode = def.Mode
				draft.colors = def.Colors
				visuals:updateColorSelection(draft.mode)
			end)
		end
	end

	ctx.refs.btnPreview.MouseButton1Click:Connect(function()
		preview:start()
	end)
end

return SlotBindings
