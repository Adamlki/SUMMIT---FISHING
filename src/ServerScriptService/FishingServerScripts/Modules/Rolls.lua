-- Fish roll / claim logic: server-authoritative session validation and granting.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local FishingConfig = require(FishingSystem:WaitForChild("FishingConfig"))
local DataManager = require(FishingSystem:WaitForChild("FishingModules"):WaitForChild("DataManager"))
local State = require(script.Parent.State)
local PlayerSetup = require(script.Parent.PlayerSetup)

local fishFolder = FishingSystem:WaitForChild("Assets"):WaitForChild("Fish")
local fishGiverEvent = FishingSystem:FindFirstChild("FishGiver")
local sendChatMessageEvent = FishingSystem:FindFirstChild("SendChatMessage")
local recordFishCatchEvent = FishingSystem:FindFirstChild("RecordFishCatch")

local Rolls = {}

local lastSecurityWarn = setmetatable({}, { __mode = "k" })
local function securityWarn(player, message)
	local now = os.clock()
	local last = lastSecurityWarn[player]
	if last and now - last < 5 then
		return
	end
	lastSecurityWarn[player] = now
	warn(message)
end

local function rollFishForPlayer(player, powerPercent)
	local rodName = PlayerSetup.getEquippedRodName(player)
	if not rodName then return nil end

	local config = FishingConfig.GetRodConfig(rodName)
	local totalLuck = FishingConfig.CalculateTotalLuck(config.baseLuck, powerPercent, player)

	local selectedFish = FishingConfig.RollFish(State.getPityTracker(player), rodName, totalLuck)
	if not selectedFish then
		for _, fishDef in ipairs(FishingConfig.FishTable) do
			if fishDef.rarity == "Common" then selectedFish = fishDef break end
		end
		if not selectedFish then return nil end
	end

	local fishWeight = FishingConfig.GenerateFishWeight(selectedFish, totalLuck, config.maxWeight)
	fishWeight = math.floor(fishWeight * 10 + 0.5) / 10

	return { name = selectedFish.name, rarity = selectedFish.rarity, weight = fishWeight }
end

local function publishRareCatch(player, fishName, weight, rarity)
	if rarity ~= "Epic" and rarity ~= "Legendary" and rarity ~= "Mitos" and rarity ~= "Secret" then return end

	local displayName = player.DisplayName or player.Name

	if sendChatMessageEvent then
		sendChatMessageEvent:FireAllClients("General", displayName, fishName, weight, rarity)
	end

	if rarity == "Secret" then
		local ok, err = pcall(function()
			MessagingService:PublishAsync("GlobalFishCatch", {
				ServerId = State.SERVER_ID,
				SenderName = displayName,
				FishName = fishName,
				Weight = weight,
				Rarity = rarity
			})
		end)
		if not ok then
			warn("[GlobalFish] Failed to publish:", err)
		end
	end
end

local function grantCaughtFish(player, roll)
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return false, "no_backpack" end

	local targetFish = fishFolder:FindFirstChild(roll.name)
	if not targetFish then return false, "missing_template" end

	local clonedFish = targetFish:Clone()
	local uniqueFishId = DataManager:AddFishWithLimit(player, {name = roll.name, weight = roll.weight, rarity = roll.rarity})
	if not uniqueFishId then return false, "inventory_full" end

	local setupOk = pcall(function()
		clonedFish.ToolTip = " "
		local idValue = Instance.new("StringValue", clonedFish); idValue.Name = "FishId"; idValue.Value = uniqueFishId
		local wValue = Instance.new("NumberValue", clonedFish); wValue.Name = "Weight"; wValue.Value = roll.weight
		local rValue = Instance.new("StringValue", clonedFish); rValue.Name = "Rarity"; rValue.Value = roll.rarity
		local fValue = Instance.new("BoolValue", clonedFish); fValue.Name = "isFavorited"; fValue.Value = false
		clonedFish.Parent = backpack
	end)
	if not setupOk then
		DataManager:RemoveFish(player, uniqueFishId)
		return false, "tool_error"
	end

	if recordFishCatchEvent then
		pcall(function()
			recordFishCatchEvent:Fire(player, roll.name)
		end)
	end

	publishRareCatch(player, roll.name, roll.weight, roll.rarity)
	return true
end

function Rolls.handleRollRequest(player, power, legacyToken, isLegacy)
	if not player or not player:IsDescendantOf(Players) then
		return State.failureResponse(400, "INVALID_PLAYER", "Player is not available.")
	end

	local now = os.clock()
	if State.lastFishTime[player] and now - State.lastFishTime[player] < State.FISH_COOLDOWN then
		return State.failureResponse(429, "RATE_LIMITED", "Please wait before rolling again.")
	end
	State.lastFishTime[player] = now

	local session = State.fishingSessions[player]
	local closedOk = session and session.state == "CastedClosed" and (now - (session.closedAt or 0)) <= 2.0
	if not session or (session.state ~= "Casted" and not closedOk) then
		securityWarn(player, "[FishingServer] Security: roll rejected - no active cast session for " .. player.Name)
		return State.failureResponse(400, "NO_ACTIVE_CAST", "No active cast session found.")
	end

	if (now - session.castTime) < 0.1 then
		return State.failureResponse(429, "ROLL_TOO_EARLY", "Roll requested too early.")
	end

	session.state = "Rolling"

	local powerToUse = session.power or State.sanitizePower(power)
	local roll = rollFishForPlayer(player, powerToUse)
	if not roll then
		if State.fishingSessions[player] == session then
			State.fishingSessions[player] = nil
			State.pendingRolls[player] = nil
		end
		return State.failureResponse(500, "ROLL_FAILED", "Failed to roll a fish.")
	end

	State.rollIdCounter += 1
	roll.rollId = State.rollIdCounter
	roll.time = now

	session.roll = roll
	session.rollTime = now
	session.state = "Reeling"
	State.pendingRolls[player] = roll

	if isLegacy then
		fishGiverEvent:FireClient(player, {
			type = "rollResult",
			token = legacyToken,
			rollId = roll.rollId,
			name = roll.name,
			rarity = roll.rarity,
			weight = roll.weight
		})
	end

	return State.successResponse({
		RollId = roll.rollId,
		Name = roll.name,
		Rarity = roll.rarity,
		Weight = roll.weight,
	})
end

function Rolls.handleClaimRequest(player, rollId, allowMissingRollId)
	if not player or not player:IsDescendantOf(Players) then
		return State.failureResponse(400, "INVALID_PLAYER", "Player is not available.")
	end

	local now = os.clock()
	local session = State.fishingSessions[player]
	if not session or session.state ~= "Reeling" or not session.roll then
		securityWarn(player, "[FishingServer] Security: claim rejected - no reeling session for " .. player.Name)
		return State.failureResponse(400, "NO_REELING_SESSION", "No active reeling session found.")
	end

	if rollId == nil and allowMissingRollId then
		rollId = session.roll.rollId
	end

	if type(rollId) ~= "number" or rollId ~= math.floor(rollId) then
		securityWarn(player, "[FishingServer] Security: claim rejected - invalid rollId for " .. player.Name)
		return State.failureResponse(400, "INVALID_ROLL_ID", "RollId must be an integer.")
	end

	if rollId ~= session.roll.rollId then
		securityWarn(player, "[FishingServer] Security: claim rejected - rollId mismatch for " .. player.Name)
		return State.failureResponse(400, "ROLL_ID_MISMATCH", "RollId does not match the active fishing session.")
	end

	local reelDuration = now - (session.rollTime or session.castTime)
	local totalElapsed = now - session.castTime
	local minDuration = State.MIN_MINIGAME_DURATION or 2.5
	if totalElapsed < minDuration then
		securityWarn(player, "[FishingServer] Security: claim rejected - terlalu cepat sejak cast (bot pattern) for " .. player.Name .. " (" .. string.format("%.2fs", totalElapsed) .. ")")
		return State.failureResponse(400, "CLAIM_TOO_EARLY", string.format("Fish cannot be claimed before %.1f seconds.", minDuration))
	end

	if reelDuration >= State.PENDING_ROLL_TIMEOUT then
		if State.fishingSessions[player] == session then
			State.fishingSessions[player] = nil
			State.pendingRolls[player] = nil
		end
		return State.failureResponse(400, "SESSION_EXPIRED", "The fishing session has expired.")
	end

	if State.lastGrantTime[player] and now - State.lastGrantTime[player] < State.GRANT_MIN_INTERVAL then
		return State.failureResponse(429, "GRANT_COOLDOWN", "Please wait before claiming another fish.")
	end

	local roll = session.roll
	local grantOk, grantResult = pcall(grantCaughtFish, player, roll)
	if not grantOk then
		warn("[FishingServer] grantCaughtFish failed:", grantResult)
		session.state = "Reeling"
		return State.failureResponse(500, "GRANT_FAILED", "Failed to grant the fish. Please try again.")
	end
	if grantResult ~= true then
		session.state = "Reeling"
		local message = "The fish could not be granted. Please try again."
		if grantResult == "inventory_full" then
			message = "Your fish inventory is full. Sell some fish first."
		end
		return State.failureResponse(400, "GRANT_FAILED", message)
	end

	session.state = "Claimed"
	State.lastGrantTime[player] = now

	-- Only clear our own session; a new cast may have replaced it while the grant was yielding.
	if State.fishingSessions[player] == session then
		State.fishingSessions[player] = nil
		State.pendingRolls[player] = nil
	end

	return State.successResponse({
		Name = roll.name,
		Weight = roll.weight,
	})
end

return Rolls
