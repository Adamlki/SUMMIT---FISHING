--!nonstrict
local Players = game:GetService("Players")

local OverheadViewIcons = require(script.Parent.Parent.OverheadViewIcons)
local VipEffects = require(script.Parent.Parent.VipEffects)

local ViewUpdater = {}

function ViewUpdater.applyLocalVisibility(setEnabled)
	local localPlayer = Players.LocalPlayer
	local hideTitles = localPlayer and localPlayer:GetAttribute("HideTitles") == true
	setEnabled(not hideTitles)
end

function ViewUpdater.update(refs, player, state, title, color, roleEffects, customRenderer, setEnabled)
	if refs.Name then
		refs.Name.Text = player.DisplayName
	end
	if refs.Total then
		refs.Total.Text = string.format("Summits: %d", state.summits or 0)
	end
	if refs.Title then
		refs.Title.Visible = true
		local titleText = title or "Pendaki"
		if state.isOwner then
			titleText = "Owner"
		elseif state.isDeveloper then
			titleText = "Developer"
		elseif state.isAdmin then
			titleText = "Admin"
		elseif state.isModerator then
			titleText = "Moderator"
		end
		refs.Title.Text = titleText
		refs.Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		local isSpecialRole = state.isOwner or state.isDeveloper or state.isAdmin or state.isModerator
		if (not isSpecialRole) and color then
			refs.Title.TextColor3 = color
		end
		if refs.LevelGradient and refs.DefaultGradient then
			refs.LevelGradient.Color = refs.DefaultGradient
		end
	end

	local isSpecial = state.isOwner or state.isDeveloper or state.isAdmin or state.isModerator
	local specialRole = state.isOwner and "Owner"
		or state.isDeveloper and "Developer"
		or state.isAdmin and "Admin"
		or state.isModerator and "Moderator"
		or nil
	roleEffects:apply(isSpecial, specialRole)

	if refs.VipLabel and not refs.VipEffect then
		refs.VipEffect = VipEffects.new(nil, refs.VipLabel)
	end
	if refs.VipLabel then
		refs.VipLabel.Visible = state.isVip == true
		if refs.VipLabel.Visible then
			refs.VipLabel.Text = "VIP"
			if refs.VipEffect then
				refs.VipEffect:apply(true)
			end
		else
			if refs.VipEffect then
				refs.VipEffect:apply(false)
			end
		end
	end

	OverheadViewIcons.applyIcons(refs.Canvas, state)
	customRenderer:update(state)
	ViewUpdater.applyLocalVisibility(setEnabled)
end

return ViewUpdater
