--!nonstrict
-- ==============================================================================
-- TitlePreview.lua
-- Preview title 5 detik lewat attribute lokal + pill hitung mundur.
-- ==============================================================================

local CustomTitleNotification = require(script.Parent.Parent.Parent:WaitForChild("Notifications"):WaitForChild("CustomTitleNotification"))
local Effects = require(script.Parent.Parent:WaitForChild("Effects"))
local Config = require(script.Parent:WaitForChild("Config"))

local TitlePreview = {}
TitlePreview.__index = TitlePreview

function TitlePreview.new(ctx)
	return setmetatable({ ctx = ctx, isPreviewing = false }, TitlePreview)
end

function TitlePreview:start()
	if self.isPreviewing then return end

	local ctx = self.ctx
	local localPlayer = ctx.localPlayer
	local slot = ctx.state.currentSlot
	local draft = ctx.drafts[slot]
	local isText = (slot <= 3)

	if isText and (#draft.text == 0) then
		CustomTitleNotification.error("Ketik teks title terlebih dahulu untuk preview!", 2.5)
		return
	elseif (not isText) and (not draft.imageId or draft.imageId == "") then
		CustomTitleNotification.error("Pilih title gambar terlebih dahulu untuk preview!", 2.5)
		return
	end

	self.isPreviewing = true
	ctx.titleMenuFrame.Visible = false

	local origText = localPlayer:GetAttribute("CustomTitleText_" .. slot)
	local origImage = localPlayer:GetAttribute("CustomTitleImage_" .. slot)
	local origMode = localPlayer:GetAttribute("CustomTitleMode_" .. slot)
	local origCol = localPlayer:GetAttribute("CustomTitleTextColor_" .. slot)
	local origGrad = localPlayer:GetAttribute("CustomTitleTextGradient_" .. slot)

	if isText then
		local colors = draft.colors or Effects.getPalette(draft.mode or "Rainbow Flow")
		local primaryCol = colors and colors[1] or Color3.fromRGB(255, 255, 255)
		local gradStr = Config.encodeColors(colors)

		localPlayer:SetAttribute("CustomTitleImage_" .. slot, nil)
		localPlayer:SetAttribute("CustomTitleText_" .. slot, draft.text)
		localPlayer:SetAttribute("CustomTitleMode_" .. slot, draft.mode or "Rainbow Flow")
		localPlayer:SetAttribute("CustomTitleTextColor_" .. slot, primaryCol)
		localPlayer:SetAttribute("CustomTitleTextGradient_" .. slot, gradStr)
	else
		localPlayer:SetAttribute("CustomTitleText_" .. slot, nil)
		localPlayer:SetAttribute("CustomTitleTextColor_" .. slot, nil)
		localPlayer:SetAttribute("CustomTitleMode_" .. slot, nil)
		localPlayer:SetAttribute("CustomTitleTextGradient_" .. slot, nil)
		localPlayer:SetAttribute("CustomTitleImage_" .. slot, draft.imageId)
	end

	local pill = Instance.new("Frame")
	pill.Name = "TitlePreviewPill"
	pill.AnchorPoint = Vector2.new(0.5, 0)
	pill.Position = UDim2.new(0.5, 0, 0, 16)
	pill.Size = UDim2.new(0, 240, 0, 36)
	pill.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	pill.BorderSizePixel = 0
	pill.ZIndex = 100
	pill.Parent = ctx.gameUI

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
			localPlayer:SetAttribute("CustomTitleText_" .. slot, origText)
			localPlayer:SetAttribute("CustomTitleImage_" .. slot, origImage)
			localPlayer:SetAttribute("CustomTitleMode_" .. slot, origMode)
			localPlayer:SetAttribute("CustomTitleTextColor_" .. slot, origCol)
			localPlayer:SetAttribute("CustomTitleTextGradient_" .. slot, origGrad)
		end

		ctx.titleMenuFrame.Visible = true
		self.isPreviewing = false
	end)
end

return TitlePreview
