--!nonstrict
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Promise = require(Packages.Promise)

local VipNotification = require(script.Parent.Parent.Parent.Notifications.VipNotification)

local GiftFlow = {}

function GiftFlow.startVipGift(state, vipService, targetId)
	local cfg = state.vipConfig or {}
	local productId = cfg.GiftProductId
	if not productId or productId == 0 then
		warn("[Shop] GiftProductId belum diisi di VipConfig")
		return
	end

	local player = Players.LocalPlayer
	local promise = vipService:BeginGift(targetId)
	if Promise.is(promise) then
		promise:andThen(function(ok, reason)
			if ok then
				MarketplaceService:PromptProductPurchase(player, productId)
			elseif reason == "AlreadyVip" then
				VipNotification.error("Target already has VIP.")
			else
				VipNotification.error("Unable to gift VIP.")
			end
		end)
	else
		if promise then
			MarketplaceService:PromptProductPurchase(player, productId)
		else
			VipNotification.error("Unable to gift VIP.")
		end
	end
end

function GiftFlow.startToolGift(state, shopService, toolId, targetUserId)
	local promise = shopService:BeginGift(toolId, targetUserId)
	if not Promise.is(promise) then
		return
	end

	promise:andThen(function(ok, reason)
		if ok then
			for _, entry in ipairs(state.catalog or {}) do
				if entry.ToolId == toolId and entry.GiftProductId and entry.GiftProductId > 0 then
					MarketplaceService:PromptProductPurchase(Players.LocalPlayer, entry.GiftProductId)
					return
				end
			end
		elseif reason == "AlreadyOwned" then
			warn("[Shop] Target already owns tool")
		elseif reason == "GiftUnavailable" then
			warn("[Shop] Gift product belum diisi untuk tool ini")
		else
			warn("[Shop] Tool gift failed: " .. tostring(reason))
		end
	end)
end

function GiftFlow.buyVip(state)
	local cfg = state.vipConfig or {}
	local passId = cfg.GamePassId
	if not passId or passId == 0 then
		warn("[Shop] GamePassId belum diisi di VipConfig")
		return
	end

	MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, passId)
end

function GiftFlow.buyTool(entry)
	if entry.GamePassId and entry.GamePassId > 0 then
		MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, entry.GamePassId)
	end
end

return GiftFlow
