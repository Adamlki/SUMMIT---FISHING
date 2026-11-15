-- Sell fish remote: batch and single sell, coin payout and tool cleanup.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local DataManager = require(FishingSystem:WaitForChild("FishingModules"):WaitForChild("DataManager"))
local GameProfileService = require(ServerScriptService.Data.PetCore:WaitForChild("FishData"))
local State = require(script.Parent.State)
local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))

local sellFishEvent = FishingSystem:FindFirstChild("SellFish")

local Sell = {}

function Sell.Install()
	local function handleSell(player, sellType, fishData)
		local ok, err = pcall(function()
		local function formatNumberWithCommas(number)
			local s = tostring(math.floor(number))
			local reversed = string.reverse(s)
			local formatted = reversed:gsub("(%d%d%d)", "%1,")
			return string.reverse(formatted):gsub("^,", "")
		end

		if type(fishData) ~= "table" then return end

		if sellType == "SellAllBatch" then
			local now = os.clock()
			if State.lastSellBatchTime[player] and now - State.lastSellBatchTime[player] < 0.5 then return end
			State.lastSellBatchTime[player] = now
			local totalCoins = 0
			for _, fSell in ipairs(fishData) do
				if type(fSell) ~= "table" then continue end
				local removed, removedData = DataManager:RemoveFish(player, fSell.fishId)
				if removed then
					local sellWeight = removedData and removedData.weight or 0
					local sellRarity = removedData and removedData.rarity or "Common"
					local sellMutation = removedData and removedData.mutation or nil
					totalCoins = totalCoins + DataManager:CalculateFishPrice(sellWeight, sellRarity, sellMutation)
					local bp = player:FindFirstChild("Backpack")
					if bp then for _, t in ipairs(bp:GetChildren()) do if t:FindFirstChild("FishId") and t.FishId.Value == fSell.fishId then t:Destroy() break end end end
				end
			end
			if totalCoins > 0 then
				GameProfileService:AddCoins(player, totalCoins)
			end
		elseif sellType == "SellSingle" then
			local fishId = fishData.fishId
			if type(fishId) ~= "string" then return end
			local savedFish = DataManager:GetSavedFish(player)
			local fishToSell = nil
			for _, fData in ipairs(savedFish) do
				if fData.uniqueId == fishId then fishToSell = fData; break end
			end
			if not fishToSell then return end
			local sellPrice = DataManager:CalculateFishPrice(fishToSell.weight or 0, fishToSell.rarity or "Common", fishToSell.mutation)
			local removed, removedData = DataManager:RemoveFish(player, fishId)
			if removed then
				GameProfileService:AddCoins(player, sellPrice)
				local toolDestroyed = false
				if player.Character then
					local equippedTool = player.Character:FindFirstChildOfClass("Tool")
					if equippedTool and equippedTool:FindFirstChild("FishId") and equippedTool.FishId.Value == fishId then
						equippedTool:Destroy()
						toolDestroyed = true
					end
				end
				local backpack = player:FindFirstChild("Backpack")
				if backpack and not toolDestroyed then
					for _, tool in ipairs(backpack:GetChildren()) do
						if tool:IsA("Tool") and tool:FindFirstChild("FishId") and tool:FindFirstChild("FishId").Value == fishId then
							tool:Destroy()
							toolDestroyed = true
							break
						end
					end
				end
			end
		end
		end)
		if not ok then
			warn("[FishingServer] Error in sellFishEvent handler:", err)
		end
	end

	sellFishEvent.OnServerEvent:Connect(function(player, sellType, fishData)
		NetworkGateway:RunLegacy(player, "sell", function()
			handleSell(player, sellType, fishData)
		end, 0.2)
	end)
end

return Sell
