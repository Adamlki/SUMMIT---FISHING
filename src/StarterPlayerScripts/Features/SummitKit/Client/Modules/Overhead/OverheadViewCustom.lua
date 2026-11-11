--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)

local Effects = require(script.Parent.Parent.CustomTitle.Effects)

local OverheadViewCustom = {}
OverheadViewCustom.__index = OverheadViewCustom

function OverheadViewCustom.new(janitor, refs)
	local self = setmetatable({}, OverheadViewCustom)
	self._janitor = janitor
	self._refs = refs
	self._slotJanitors = {}
	return self
end

function OverheadViewCustom:_getSlotJanitor(key)
	local jan = self._slotJanitors[key]
	if not jan then
		jan = Janitor.new()
		self._slotJanitors[key] = jan
		self._janitor:Add(jan, "Destroy")
	end
	return jan
end

function OverheadViewCustom:update(state)
	local refs = self._refs
	if not refs then
		return
	end

	local custom = state.customTitle
	local rawSlots = custom and custom.slots or {}

	-- Pisahkan slot teks (Slot 1–3) dan slot gambar (Slot 4–6)
	local activeTexts = {}
	local activeImages = {}

	-- Prioritas slot 1-3 untuk teks
	for slotIdx = 1, 3 do
		local slotData = rawSlots[slotIdx]
		if slotData and slotData.text and slotData.text ~= "" and #activeTexts < 3 then
			table.insert(activeTexts, {
				slot = slotIdx,
				text = slotData.text,
				colors = slotData.colors or { Color3.fromRGB(255, 255, 255) },
				mode = slotData.mode or "Rainbow Flow",
			})
		end
	end

	-- Prioritas slot 4-6 untuk gambar
	for slotIdx = 4, 6 do
		local slotData = rawSlots[slotIdx]
		if slotData and slotData.imageId and slotData.imageId ~= "" and #activeImages < 3 then
			table.insert(activeImages, {
				slot = slotIdx,
				imageId = slotData.imageId,
			})
		end
	end

	-- Fallback jika ada konfigurasi silang
	for slotIdx = 1, 6 do
		local slotData = rawSlots[slotIdx]
		if slotData then
			if slotData.text and slotData.text ~= "" and slotIdx > 3 and #activeTexts < 3 then
				table.insert(activeTexts, {
					slot = slotIdx,
					text = slotData.text,
					colors = slotData.colors or { Color3.fromRGB(255, 255, 255) },
					mode = slotData.mode or "Rainbow Flow",
				})
			elseif slotData.imageId and slotData.imageId ~= "" and slotIdx <= 3 and #activeImages < 3 then
				table.insert(activeImages, {
					slot = slotIdx,
					imageId = slotData.imageId,
				})
			end
		end
	end

	-- 1. Perbarui TitleText Container
	-- Jika player tidak memasang title teks, matikan visibility frame title teks agar tidak ada spasi kosong
	if refs.TitleText and refs.TextItems then
		if #activeTexts == 0 then
			refs.TitleText.Visible = false
			for _, item in ipairs(refs.TextItems) do
				item.Label.Visible = false
			end
		else
			refs.TitleText.Visible = true
			for i, item in ipairs(refs.TextItems) do
				local titleData = activeTexts[i]
				if titleData then
					item.Label.Visible = true
					item.Label.Text = titleData.text
					if #titleData.colors == 1 then
						item.Label.TextColor3 = titleData.colors[1]
					else
						item.Label.TextColor3 = Color3.fromRGB(255, 255, 255)
					end
					local jan = self:_getSlotJanitor("Text_" .. i)
					jan:Cleanup()
					Effects.apply(item.Label, titleData.colors, titleData.mode, jan)
				else
					item.Label.Visible = false
				end
			end
		end
	end

	-- 2. Perbarui TitleImage Container
	-- Jika player tidak memasang title gambar, matikan visibility frame title gambar agar tidak ada spasi kosong
	if refs.TitleImage and refs.ImageItems then
		if #activeImages == 0 then
			refs.TitleImage.Visible = false
			for _, item in ipairs(refs.ImageItems) do
				item.Image.Visible = false
			end
		else
			refs.TitleImage.Visible = true
			for i, item in ipairs(refs.ImageItems) do
				local titleData = activeImages[i]
				if titleData then
					item.Image.Visible = true
					item.Image.Image = titleData.imageId
				else
					item.Image.Visible = false
				end
			end
		end
	end
end

function OverheadViewCustom:stop()
	for _, jan in pairs(self._slotJanitors) do
		jan:Destroy()
	end
	self._slotJanitors = {}
end

return OverheadViewCustom
