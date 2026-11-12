--!nonstrict
-- ============================================================
-- Title/Modules/Lifecycle (ModuleScript)
-- Join reconcile: country code + saved title attributes.
-- ============================================================

local Players = game:GetService("Players")

local Runtime = require(script.Parent.Runtime)

local Lifecycle = {}

local function handlePlayerAdded(player)
	task.spawn(function()
		local LocalizationService = game:GetService("LocalizationService")
		local success, code = pcall(function()
			return LocalizationService:GetCountryRegionForPlayerAsync(player)
		end)
		if success and code and typeof(code) == "string" and code ~= "" then
			player:SetAttribute("CountryCode", string.upper(code))
		else
			player:SetAttribute("CountryCode", "UNKNOWN")
		end
	end)

	local waited = 0
	while not Runtime.getProfile(player) and waited < 15 do
		task.wait(0.5)
		waited += 0.5
	end

	local profile = Runtime.getProfile(player)
	if not profile or not profile.Data or not profile.Data.customTitles then
		return
	end

	for i = 1, 6 do
		local entry = profile.Data.customTitles[i]
		if entry then
			if entry.titleType == "Image" and entry.imageId and entry.imageId ~= "" then
				player:SetAttribute("CustomTitleImage_" .. i, entry.imageId)
				player:SetAttribute("CustomTitleText_" .. i, nil)
				player:SetAttribute("CustomTitleTextColor_" .. i, nil)
				player:SetAttribute("CustomTitleMode_" .. i, nil)
				player:SetAttribute("CustomTitleTextGradient_" .. i, nil)
			elseif entry.titleType == "Text" and entry.text and entry.text ~= "" then
				player:SetAttribute("CustomTitleImage_" .. i, nil)
				player:SetAttribute("CustomTitleText_" .. i, entry.text)
				local tc = entry.textColor
				if tc then
					player:SetAttribute("CustomTitleTextColor_" .. i, Color3.fromRGB(tc.r or 255, tc.g or 255, tc.b or 255))
				end
				player:SetAttribute("CustomTitleMode_" .. i, entry.mode or "Rainbow Flow")
				player:SetAttribute("CustomTitleTextGradient_" .. i, entry.gradientStr or "")
			end
		end
	end
end

function Lifecycle.Start()
	Players.PlayerAdded:Connect(handlePlayerAdded)
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(handlePlayerAdded, p)
	end
end

return Lifecycle
