--!nonstrict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)

local ButtonBinder = require(script.Parent.ShopHelpers.ButtonBinder)
local GiftFlow = require(script.Parent.ShopHelpers.GiftFlow)
local ShopRenderer = require(script.Parent.ShopRenderer)
local ViewFlow = require(script.Parent.ShopHelpers.ViewFlow)

local ShopBinder = {}

function ShopBinder.bind(refs, state, vipService, shopService)
	local janitor = Janitor.new()
	local toolButtonsJanitor = Janitor.new()
	local showSelection

	local function onPlayerSelected(player)
		ShopRenderer.setVisible(refs, true, false, true)
		if state.selectedToolId then
			local toolId = state.selectedToolId
			GiftFlow.startToolGift(state, shopService, toolId, player.UserId)
			state:setSelectedTool(nil)
			return
		end

		GiftFlow.startVipGift(state, vipService, player.UserId)
	end

	local function renderTools()
		toolButtonsJanitor:Cleanup()

		local toolButtons = ShopRenderer.renderTools(refs, state, function() end, function() end)
		for toolId, rendered in pairs(toolButtons) do
			local entry = rendered.Entry
			if rendered.Buy and not rendered.Owned then
				ButtonBinder.connect(rendered.Buy, function()
					GiftFlow.buyTool(entry)
				end, toolButtonsJanitor)
			end

			if entry.GiftProductId then
				ButtonBinder.connect(rendered.Gift, function()
					state:setSelectedTool(toolId)
					showSelection()
				end, toolButtonsJanitor)
			end
		end
	end

	showSelection = function()
		ViewFlow.showSelection(refs, state, onPlayerSelected)
	end

	janitor:Add(toolButtonsJanitor, "Destroy")

	local function showShop()
		ViewFlow.showShop(refs, state, renderTools)
	end

	local function closeAll()
		ViewFlow.closeAll(refs, state)
	end

	local function toggleShop()
		if refs.shopFeature and refs.shopFeature.Visible then
			closeAll()
		else
			showShop()
		end
	end

	if refs.shopFeature then
		refs.shopFeature.Visible = false
	end

	-- ButtonBinder.connect(refs.toggleBtn, toggleShop, janitor)

	janitor:Add(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.B then
			toggleShop()
		end
	end), "Disconnect")

	ButtonBinder.connect(refs.playerSelectionsClose, function()
		state:setSelectedTool(nil)
		ShopRenderer.setVisible(refs, true, false, true)
	end, janitor)
	ButtonBinder.connect(refs.shopClose, closeAll, janitor)

	ButtonBinder.connect(refs.vipBuy, function()
		GiftFlow.buyVip(state)
	end, janitor)

	ButtonBinder.connect(refs.vipGift, function()
		local targetId = state.selectedUserId
		if not targetId then
			state:setSelectedTool(nil)
			showSelection()
			return
		end

		GiftFlow.startVipGift(state, vipService, targetId)
	end, janitor)

	janitor:Add(Players.PlayerAdded:Connect(function()
		ViewFlow.refreshPlayersIfOpen(refs, state, onPlayerSelected)
		renderTools()
	end), "Disconnect")
	janitor:Add(Players.PlayerRemoving:Connect(function()
		ViewFlow.refreshPlayersIfOpen(refs, state, onPlayerSelected)
		renderTools()
	end), "Disconnect")

	janitor:Add(state.changed:Connect(function(kind)
		if kind == "catalog" or kind == "owned" then
			renderTools()
		end
	end), "Disconnect")

	return janitor
end

return ShopBinder
