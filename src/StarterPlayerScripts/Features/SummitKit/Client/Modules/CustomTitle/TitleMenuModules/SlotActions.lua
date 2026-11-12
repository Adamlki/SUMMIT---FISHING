--!nonstrict
-- ==============================================================================
-- SlotActions.lua
-- Aksi tombol Set Title & Clear Row lewat NetworkGateway.
-- ==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NetworkGateway = require(Shared:WaitForChild("Network"):WaitForChild("NetworkGateway"))
local Effects = require(script.Parent.Parent:WaitForChild("Effects"))
local CustomTitleNotification = require(script.Parent.Parent.Parent:WaitForChild("Notifications"):WaitForChild("CustomTitleNotification"))
local Config = require(script.Parent:WaitForChild("Config"))

local SlotActions = {}

local function bindSetTitle(ctx, data)
	local btnSetTitle = ctx.refs.btnSetTitle

	btnSetTitle.MouseButton1Click:Connect(function()
		local currentSlot = ctx.state.currentSlot
		local unlocked, reason = Config.isSlotUnlocked(ctx, currentSlot)
		if not unlocked then
			CustomTitleNotification.error(string.format("Slot %d terkunci! %s", currentSlot, reason), 3)
			return
		end

		local draft = ctx.drafts[currentSlot]
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
			local ok, awaitedOk, res = pcall(function()
				return NetworkGateway:Request("PUT", "/title/set-slot", {
					Slot = ctx.state.currentSlot,
					TitleType = isText and "Text" or "Image",
					Payload = payload,
				}):await()
			end)

			btnSetTitle.Text = "SET TITLE"
			btnSetTitle.Active = true

			if ok and awaitedOk and type(res) == "table" and res.Success then
				CustomTitleNotification.success(res.Message or "Title berhasil disimpan!", 3)
				data:fetch()
			else
				local errMsg = (type(res) == "table" and res.Message) or "Gagal menyimpan title!"
				CustomTitleNotification.error(errMsg, 3.5)
			end
		end)
	end)
end

local function bindClearSlot(ctx, data)
	local btnClearSlot = ctx.refs.btnClearSlot

	btnClearSlot.MouseButton1Click:Connect(function()
		btnClearSlot.Text = "MENGHAPUS..."
		btnClearSlot.Active = false

		task.spawn(function()
			local ok, awaitedOk, res = pcall(function()
				return NetworkGateway:Request("DELETE", "/title/clear-slot", {
					Slot = ctx.state.currentSlot,
				}):await()
			end)

			btnClearSlot.Text = "CLEAR ROW"
			btnClearSlot.Active = true

			if ok and awaitedOk and type(res) == "table" and res.Success then
				local currentSlot = ctx.state.currentSlot
				CustomTitleNotification.info(string.format("Slot %d berhasil dikosongkan!", currentSlot), 2.5)

				local isText = (currentSlot <= 3)
				ctx.drafts[currentSlot] = Config.newDraft(isText)

				data:fetch()
			else
				local errMsg = (type(res) == "table" and res.Message) or "Gagal menghapus title!"
				CustomTitleNotification.error(errMsg, 3)
			end
		end)
	end)
end

function SlotActions.bind(ctx, data)
	bindSetTitle(ctx, data)
	bindClearSlot(ctx, data)
end

return SlotActions
