--!nonstrict
local ShopRenderer = require(script.Parent.Parent.ShopRenderer)

local ViewFlow = {}

function ViewFlow.closeAll(refs, state)
	state:setSelectedTool(nil)
	ShopRenderer.setVisible(refs, false, false, false)
end

function ViewFlow.showShop(refs, state, renderTools)
	ShopRenderer.setVisible(refs, true, false, true)
	state:setSelectedTool(nil)
	renderTools()
end

function ViewFlow.showSelection(refs, state, onPlayerSelected)
	ShopRenderer.setVisible(refs, true, true, true)
	ShopRenderer.renderPlayers(refs, state, function(player)
		state:setTarget(player.UserId, player.DisplayName ~= "" and player.DisplayName or player.Name)
		onPlayerSelected(player)
	end)
end

function ViewFlow.refreshPlayersIfOpen(refs, state, onPlayerSelected)
	if refs.playerSelections and refs.playerSelections.Visible then
		ViewFlow.showSelection(refs, state, onPlayerSelected)
	end
end

return ViewFlow
