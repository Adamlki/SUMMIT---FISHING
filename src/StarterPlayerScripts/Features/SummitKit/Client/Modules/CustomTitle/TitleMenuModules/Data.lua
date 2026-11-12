--!nonstrict
-- ==============================================================================
-- Data.lua
-- Fetch /title/data via NetworkGateway dan penerapan data ke panel.
-- ==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NetworkGateway = require(Shared:WaitForChild("Network"):WaitForChild("NetworkGateway"))
local ImageTitleConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("TitleConfig"))
local Effects = require(script.Parent.Parent:WaitForChild("Effects"))

local Data = {}
Data.__index = Data

function Data.new(ctx, visuals)
	return setmetatable({ ctx = ctx, visuals = visuals }, Data)
end

function Data:apply(data)
	local ctx = self.ctx
	ctx.state.serverData = data

	-- Update Image cards unlock states (Translucent Lock Overlay)
	for _, entry in ipairs(ImageTitleConfig.ImageTitles) do
		local card = ctx.refs.imgContainer:FindFirstChild("Card_" .. entry.Id)
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
					ctx.drafts[i].titleType = "Image"
					ctx.drafts[i].imageId = s.imageId
					ctx.drafts[i].imageKey = s.imageKey
					ctx.drafts[i].text = ""
				elseif i <= 3 and s.text and s.text ~= "" then
					ctx.drafts[i].titleType = "Text"
					ctx.drafts[i].text = s.text
					ctx.drafts[i].mode = s.mode or "Rainbow Flow"
					ctx.drafts[i].colors = Effects.getPalette(s.mode or "Rainbow Flow") or { Color3.fromRGB(255, 255, 255) }
					ctx.drafts[i].imageId = nil
					ctx.drafts[i].imageKey = nil
				end
			end
		end
	end

	self.visuals:refreshQuota()
	self.visuals:renderCurrentSlot()
end

function Data:fetch()
	task.spawn(function()
		local ok, awaitedOk, response = pcall(function()
			return NetworkGateway:Request("GET", "/title/data"):await()
		end)

		local data = nil
		if ok and awaitedOk and type(response) == "table" and response.Success then
			data = response.Data
		end

		if type(data) == "table" and data.Success then
			self:apply(data)
		end
	end)
end

return Data
