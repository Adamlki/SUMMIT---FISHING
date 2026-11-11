--!nonstrict
local AvatarView = require(script.Parent.Parent.AvatarView)
local AvatarUIResolver = require(script.Parent.Parent.AvatarUIResolver)
local AvatarActions = require(script.Parent.AvatarActions)

local AvatarViewBuilder = {}

function AvatarViewBuilder.ensureView(state)
	if state.view then
		return true, state.view
	end

	local ok, refsOrErr = AvatarUIResolver.resolve()
	if not ok then
		state.log:warn(tostring(refsOrErr))
		return false
	end

	local view = AvatarView.new({
		menuFrame = refsOrErr.menuFrame,
		listFrame = refsOrErr.listFrame,
		template = refsOrErr.template,
		toggleBtn = refsOrErr.toggleBtn,
		closeBtn = refsOrErr.closeBtn,
		inputBox = refsOrErr.inputBox,
		enterBtn = refsOrErr.enterBtn,
		previewFrame = refsOrErr.previewFrame,
		applyBtn = refsOrErr.applyBtn,
		hiddenPos = refsOrErr.hiddenPos,
		shownPos = refsOrErr.shownPos,
		onQuery = function(username)
			AvatarActions.query(state.entries, state.refreshList, username)
		end,
		onApply = function(entry)
			AvatarActions.apply(state.avatarService, state.notifyAvatarError, entry)
		end,
	})

	return true, view
end

return AvatarViewBuilder
