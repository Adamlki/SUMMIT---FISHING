-- System by @thehandofvoid
-- Modified by @jay_peaceee
-- ServerScriptService/FishingServer (Fixed - Tags ALL Rods Including Basic Rod)
local ReplicatedStorageService = game:GetService("ReplicatedStorage")
local ReplicatedStorage = ReplicatedStorageService:WaitForChild("FishingSystem")
local NetworkGateway = require(ReplicatedStorageService:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

local DataManager = require(ReplicatedStorage:WaitForChild("FishingModules"):WaitForChild("DataManager"))
local FishingConfig = require(ReplicatedStorage:WaitForChild("FishingConfig"))
local GameProfileService = require(game:GetService("ServerScriptService").Data.PetCore:WaitForChild("FishData"))

local fishGiverEvent = ReplicatedStorage:FindFirstChild("FishGiver")
local castReplicationEvent = ReplicatedStorage:FindFirstChild("CastReplication")
local cleanupCastEvent = ReplicatedStorage:FindFirstChild("CleanupCast")
local showNotificationEvent = ReplicatedStorage:FindFirstChild("ShowNotification")
local sellFishEvent = ReplicatedStorage:FindFirstChild("SellFish")

local fishFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Fish")
local fishModelFolder = ReplicatedStorage:WaitForChild("Assets"):FindFirstChild("FishModel")
local rodToolFolder = ServerStorage:WaitForChild("AllRods")
local sendChatMessageEvent = ReplicatedStorage:FindFirstChild("SendChatMessage")
local MessagingService = game:GetService("MessagingService")
local SERVER_ID = game.JobId
if SERVER_ID == "" then SERVER_ID = "Studio_" .. tostring(math.random(1000000, 9999999)) end


local FISH_COOLDOWN = 0.5
local lastFishTime = {}
local fishPool = {}
local MAX_POOL_SIZE = 5
local originalTransparencies = {}
local lastReplicationTime = {}
local lastCleanupTime = {}
local lastSellBatchTime = {}
local lastGrantTime = {}
local playerPity = {}
local pendingRolls = {}
local fishingSessions = {} -- H-04: Server-authoritative fishing state machine (Idle -> Casted -> Rolling -> Reeling -> Claimed)
local rollIdCounter = 0
local GRANT_MIN_INTERVAL = 2.5
local MIN_MINIGAME_DURATION = 0.4 -- Anti-bot: Minimum time required to reel minigame
local PENDING_ROLL_TIMEOUT = 120

local function successResponse(data)
	return { Success = true, StatusCode = 200, Data = data }
end

local function failureResponse(statusCode, errorCode, message)
	return { Success = false, StatusCode = statusCode, ErrorCode = errorCode, Message = message }
end


local fishDefs = {}
for _, def in ipairs(FishingConfig.FishTable) do
	fishDefs[def.name] = def
end

local recordFishCatchEvent = ReplicatedStorage:FindFirstChild("RecordFishCatch")

local function getEquippedRodName(player)
	local char = player.Character
	if char then
		local tool = char:FindFirstChildOfClass("Tool")
		if tool and CollectionService:HasTag(tool, "Rod") then
			return tool.Name
		end
	end
	return DataManager:GetLastEquippedRod(player) or "Basic Rod"
end

-- ===================================================================
-- HELPER: TAG ALL RODS IN FOLDER (Run once at startup)
-- ===================================================================
local function tagAllRodsInFolder()
	local tagged = 0
	if rodToolFolder then
		for _, rod in ipairs(rodToolFolder:GetChildren()) do
			if rod:IsA("Tool") and not CollectionService:HasTag(rod, "Rod") then
				CollectionService:AddTag(rod, "Rod")
				tagged = tagged + 1
			end
		end
	end
	local rsRodFolder = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Rod")
	if rsRodFolder then
		for _, rod in ipairs(rsRodFolder:GetChildren()) do
			if rod:IsA("Tool") and not CollectionService:HasTag(rod, "Rod") then
				CollectionService:AddTag(rod, "Rod")
				tagged = tagged + 1
			end
		end
	end
end

-- Run at startup
task.spawn(tagAllRodsInFolder)

-- ===================================================================
-- COLLISION SETUP
-- ===================================================================
local function setupCollisionGroups()
	pcall(function()
		PhysicsService:RegisterCollisionGroup("FishEffect")
		PhysicsService:RegisterCollisionGroup("Players")
		PhysicsService:CollisionGroupSetCollidable("FishEffect", "Players", false)
	end)
end
setupCollisionGroups()

local function saveOriginalTransparency(model)
	if not model or originalTransparencies[model] then return end
	local map = {}
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then map[part] = part.Transparency end
	end
	originalTransparencies[model] = map
end

local function restoreOriginalTransparency(model)
	if not model or not originalTransparencies[model] then return end
	for part, transparency in pairs(originalTransparencies[model]) do
		if part and part.Parent then part.Transparency = transparency end
	end
	originalTransparencies[model] = nil
end

local function getPooledFish(fishName, fishModelFolderRef)
	if not fishPool[fishName] then fishPool[fishName] = {pool = {}, active = {}} end
	local poolData = fishPool[fishName]
	if #poolData.pool > 0 then
		local fish = table.remove(poolData.pool)
		table.insert(poolData.active, fish)
		return fish
	end
	local fishModel = fishModelFolderRef:FindFirstChild(fishName)
	if not fishModel then return nil end
	local newFish = fishModel:Clone()
	table.insert(poolData.active, newFish)
	return newFish
end

local function returnFishToPool(fishName, fish)
	if not fish or not fish.Parent then return end
	fish.Parent = nil
	restoreOriginalTransparency(fish)
	if not fishPool[fishName] then fishPool[fishName] = {pool = {}, active = {}} end
	local poolData = fishPool[fishName]
	for i, activeFish in ipairs(poolData.active) do
		if activeFish == fish then table.remove(poolData.active, i) break end
	end
	if #poolData.pool < MAX_POOL_SIZE then table.insert(poolData.pool, fish) else fish:Destroy() end
end

local function createFishPopEffect(fishName, hookPosition, playerCharacter)
	if not fishModelFolder or not playerCharacter then return end
	local hrp = playerCharacter:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local fishClone = getPooledFish(fishName, fishModelFolder)
	if not fishClone then return end
	saveOriginalTransparency(fishClone)
	local primaryPart = fishClone:IsA("Model") and fishClone.PrimaryPart or fishClone:FindFirstChildOfClass("BasePart") or fishClone
	if not primaryPart then returnFishToPool(fishName, fishClone) return end
	if fishClone:IsA("Model") then fishClone:SetPrimaryPartCFrame(CFrame.new(hookPosition)) else fishClone.CFrame = CFrame.new(hookPosition) end
	fishClone.Parent = workspace
	primaryPart.Anchored = false
	primaryPart.CanCollide = true
	local allParts = {}
	for _, part in ipairs(fishClone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = "FishEffect"
			if part ~= primaryPart then part.CanCollide = false end
			table.insert(allParts, part)
		end
	end
	local settings = FishingConfig.ProjectileSettings
	local playerLookDirection = hrp.CFrame.LookVector
	local behindOffset = settings.behindPlayerDistance
	local sideOffset = 0
	if settings.randomLanding then
		behindOffset = math.random(settings.randomBehindRange.min, settings.randomBehindRange.max)
		sideOffset = math.random(settings.randomSideRange.min, settings.randomSideRange.max)
	end
	local targetPosition = hrp.Position - (playerLookDirection * behindOffset) + (hrp.CFrame.RightVector * sideOffset) + Vector3.new(0, settings.landingHeightOffset, 0)
	local directionToTarget = (targetPosition - hookPosition).Unit
	local distance = (targetPosition - hookPosition).Magnitude
	local timeToReach = settings.flightTime
	local gravity = workspace.Gravity
	local horizontalSpeed = distance / timeToReach
	local verticalSpeed = (targetPosition.Y - hookPosition.Y) / timeToReach + (0.5 * gravity * timeToReach)
	primaryPart.AssemblyLinearVelocity = Vector3.new(directionToTarget.X * horizontalSpeed, verticalSpeed, directionToTarget.Z * horizontalSpeed)
	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(400, 400, 400)
	bodyGyro.D = 100; bodyGyro.P = 3000
	bodyGyro.CFrame = primaryPart.CFrame * CFrame.Angles(math.rad(settings.rotationAngle), 0, 0)
	bodyGyro.Parent = primaryPart
	local hasLanded, canDetectLanding = false, false
	local lastCheckTime = tick()
	local CHECK_INTERVAL = 0.15
	task.delay(settings.detectionDelay, function() canDetectLanding = true end)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {fishClone, playerCharacter}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	local landingCheckConnection
	landingCheckConnection = RunService.Heartbeat:Connect(function()
		if not primaryPart or not primaryPart.Parent then
			if landingCheckConnection then landingCheckConnection:Disconnect() end
			return
		end
		if not canDetectLanding then return end
		local currentTime = tick()
		if currentTime - lastCheckTime < CHECK_INTERVAL then return end
		lastCheckTime = currentTime
		local velocity = primaryPart.AssemblyLinearVelocity or primaryPart.Velocity
		if velocity.Magnitude < settings.landingSpeedThreshold and velocity.Y < settings.landingVelocityY and not hasLanded then
			local rayResult = workspace:Raycast(primaryPart.Position, Vector3.new(0, -settings.landingRayDistance, 0), raycastParams)
			if rayResult and rayResult.Instance and rayResult.Distance < settings.landingGroundDistance then
				hasLanded = true
				if landingCheckConnection then landingCheckConnection:Disconnect() end
				if bodyGyro then bodyGyro:Destroy() end
				primaryPart.Anchored = true
				primaryPart.AssemblyLinearVelocity = Vector3.zero
				primaryPart.RotVelocity = Vector3.zero
				task.wait(settings.fadeInDuration)
				for _, part in ipairs(allParts) do
					if part and part.Parent then TweenService:Create(part, TweenInfo.new(settings.fadeOutDuration), {Transparency = 1}):Play() end
				end
				task.wait(settings.fadeOutDuration)
				returnFishToPool(fishName, fishClone)
			end
		end
	end)
	task.delay(settings.safetyTimeout, function()
		if not hasLanded and fishClone.Parent then
			hasLanded = true
			if landingCheckConnection then landingCheckConnection:Disconnect() end
			if bodyGyro then bodyGyro:Destroy() end
			returnFishToPool(fishName, fishClone)
		end
	end)
end

-- ===================================================================
-- RESTORE FUNCTIONS (WITH ROD TAGGING)
-- ===================================================================
local function restoreSavedFish(player)
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end
	local savedFish = DataManager:GetSavedFish(player)
	if not savedFish or #savedFish == 0 then return end

	-- Pulihkan hingga 50 ikan terakhir ke Backpack agar hotbar tidak penuh dan tidak lag
	local MAX_RESTORE_TOOLS = 50
	local startIndex = math.max(1, #savedFish - MAX_RESTORE_TOOLS + 1)

	for i = startIndex, #savedFish do
		local fishData = savedFish[i]
		if not fishData then continue end

		-- Hindari duplikasi jika tool ikan dengan ID yang sama sudah ada di backpack / character
		local alreadyExists = false
		for _, item in ipairs(backpack:GetChildren()) do
			local idVal = item:FindFirstChild("FishId")
			if idVal and idVal.Value == fishData.uniqueId then
				alreadyExists = true
				break
			end
		end
		if not alreadyExists and player.Character then
			for _, item in ipairs(player.Character:GetChildren()) do
				local idVal = item:FindFirstChild("FishId")
				if idVal and idVal.Value == fishData.uniqueId then
					alreadyExists = true
					break
				end
			end
		end

		if not alreadyExists then
			local fishClone = fishFolder:FindFirstChild(fishData.name)
			if fishClone then
				local toolClone = fishClone:Clone()
				toolClone.ToolTip = " "
				local idValue = Instance.new("StringValue", toolClone); idValue.Name = "FishId"; idValue.Value = fishData.uniqueId
				local weightValue = Instance.new("NumberValue", toolClone); weightValue.Name = "Weight"; weightValue.Value = fishData.weight
				local rarityValue = Instance.new("StringValue", toolClone); rarityValue.Name = "Rarity"; rarityValue.Value = fishData.rarity
				local favValue = Instance.new("BoolValue", toolClone); favValue.Name = "isFavorited"; favValue.Value = fishData.isFavorited or false
				toolClone.Parent = backpack
			end
		end
	end
end

local function restoreOwnedRods(player)
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end
	local ownedRods = DataManager:GetOwnedRods(player)
	for _, rodName in ipairs(ownedRods) do
		if not backpack:FindFirstChild(rodName) then
			local rodTool = rodToolFolder:FindFirstChild(rodName)
			if rodTool then
				local clonedRod = rodTool:Clone()
				-- CRITICAL: Ensure the cloned rod has the "Rod" tag
				if not CollectionService:HasTag(clonedRod, "Rod") then
					CollectionService:AddTag(clonedRod, "Rod")
				end
				clonedRod.Parent = backpack
			end
		end
	end
end

local function restoreRoleRods(player)
	local config = FishingConfig.RoleSettings
	if not config or not config.Enabled or config.GroupID == 0 then return end
	local backpack = player:FindFirstChild("Backpack")
	local playerRank = 0
	pcall(function() playerRank = player:GetRankInGroup(config.GroupID) end)
	if playerRank == 0 then return end
	for _, data in pairs(config.RoleRodMapping) do
		if playerRank == data.RankID then
			local rodToGive = data.RodName
			if not backpack:FindFirstChild(rodToGive) then
				local rodTool = rodToolFolder:FindFirstChild(rodToGive)
				if rodTool then
					local clonedRod = rodTool:Clone()
					-- CRITICAL: Ensure the cloned rod has the "Rod" tag
					if not CollectionService:HasTag(clonedRod, "Rod") then
						CollectionService:AddTag(clonedRod, "Rod")
					end
					clonedRod.Parent = backpack
					DataManager:AddRod(player, rodToGive)
				end
			end
			break
		end
	end
end

-- ===================================================================
-- EVENT HANDLERS
-- ===================================================================
local function sanitizePower(power)
	local p = tonumber(power)
	if not p or p ~= p then return 1 end
	return math.clamp(p, 0, 1)
end

local function getPityTracker(player)
	local pity = playerPity[player]
	if not pity then
		pity = FishingConfig.CreatePityTracker()
		playerPity[player] = pity
	end
	return pity
end

local function rollFishForPlayer(player, powerPercent)
	local rodName = getEquippedRodName(player)
	if not rodName then return nil end

	local config = FishingConfig.GetRodConfig(rodName)
	local totalLuck = FishingConfig.CalculateTotalLuck(config.baseLuck, powerPercent, player)

	local selectedFish = FishingConfig.RollFish(getPityTracker(player), rodName, totalLuck)
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
				ServerId = SERVER_ID,
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
	if not backpack then return end

	local targetFish = fishFolder:FindFirstChild(roll.name)
	if not targetFish then return end

	local uniqueFishId = DataManager:AddFishWithLimit(player, {name = roll.name, weight = roll.weight, rarity = roll.rarity})
	if not uniqueFishId then return end

	local clonedFish = targetFish:Clone()
	clonedFish.ToolTip = " "
	local idValue = Instance.new("StringValue", clonedFish); idValue.Name = "FishId"; idValue.Value = uniqueFishId
	local wValue = Instance.new("NumberValue", clonedFish); wValue.Name = "Weight"; wValue.Value = roll.weight
	local rValue = Instance.new("StringValue", clonedFish); rValue.Name = "Rarity"; rValue.Value = roll.rarity
	local fValue = Instance.new("BoolValue", clonedFish); fValue.Name = "isFavorited"; fValue.Value = false
	clonedFish.Parent = backpack

	if recordFishCatchEvent then
		recordFishCatchEvent:Fire(player, roll.name)
	end

	publishRareCatch(player, roll.name, roll.weight, roll.rarity)
end

local function handleRollRequest(player, power, legacyToken, isLegacy)
	if not player or not player:IsDescendantOf(Players) then
		return failureResponse(400, "INVALID_PLAYER", "Player is not available.")
	end

	local now = os.clock()
	if lastFishTime[player] and now - lastFishTime[player] < FISH_COOLDOWN then
		return failureResponse(429, "RATE_LIMITED", "Please wait before rolling again.")
	end
	lastFishTime[player] = now

	local session = fishingSessions[player]
	local closedOk = session and session.state == "CastedClosed" and (now - (session.closedAt or 0)) <= 2.0
	if not session or (session.state ~= "Casted" and not closedOk) then
		warn("[FishingServer] Security: roll rejected - no active cast session for " .. player.Name)
		return failureResponse(400, "NO_ACTIVE_CAST", "No active cast session found.")
	end

	if (now - session.castTime) < 0.1 then
		return failureResponse(429, "ROLL_TOO_EARLY", "Roll requested too early.")
	end

	session.state = "Rolling"

	local powerToUse = session.power or sanitizePower(power)
	local roll = rollFishForPlayer(player, powerToUse)
	if not roll then
		if fishingSessions[player] == session then
			fishingSessions[player] = nil
			pendingRolls[player] = nil
		end
		return failureResponse(500, "ROLL_FAILED", "Failed to roll a fish.")
	end

	rollIdCounter = rollIdCounter + 1
	roll.rollId = rollIdCounter
	roll.time = now

	session.roll = roll
	session.rollTime = now
	session.state = "Reeling"
	pendingRolls[player] = roll

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

	return successResponse({
		RollId = roll.rollId,
		Name = roll.name,
		Rarity = roll.rarity,
		Weight = roll.weight,
	})
end

local function handleClaimRequest(player, rollId, allowMissingRollId)
	if not player or not player:IsDescendantOf(Players) then
		return failureResponse(400, "INVALID_PLAYER", "Player is not available.")
	end

	local now = os.clock()
	local session = fishingSessions[player]
	if not session or session.state ~= "Reeling" or not session.roll then
		warn("[FishingServer] Security: claim rejected - no reeling session for " .. player.Name)
		return failureResponse(400, "NO_REELING_SESSION", "No active reeling session found.")
	end

	if rollId == nil and allowMissingRollId then
		rollId = session.roll.rollId
	end

	if type(rollId) ~= "number" or rollId ~= math.floor(rollId) then
		warn("[FishingServer] Security: claim rejected - invalid rollId for " .. player.Name)
		return failureResponse(400, "INVALID_ROLL_ID", "RollId must be an integer.")
	end

	if rollId ~= session.roll.rollId then
		warn("[FishingServer] Security: claim rejected - rollId mismatch for " .. player.Name)
		return failureResponse(400, "ROLL_ID_MISMATCH", "RollId does not match the active fishing session.")
	end

	local reelDuration = now - (session.rollTime or session.castTime)
	local totalElapsed = now - session.castTime
	if totalElapsed < 2.5 then
		warn("[FishingServer] Security: claim rejected - terlalu cepat sejak cast (bot pattern) for " .. player.Name .. " (" .. string.format("%.2fs", totalElapsed) .. ")")
		return failureResponse(400, "CLAIM_TOO_EARLY", "Fish cannot be claimed before 2.5 seconds.")
	end

	if reelDuration >= PENDING_ROLL_TIMEOUT then
		if fishingSessions[player] == session then
			fishingSessions[player] = nil
			pendingRolls[player] = nil
		end
		return failureResponse(400, "SESSION_EXPIRED", "The fishing session has expired.")
	end

	if lastGrantTime[player] and now - lastGrantTime[player] < GRANT_MIN_INTERVAL then
		return failureResponse(429, "GRANT_COOLDOWN", "Please wait before claiming another fish.")
	end

	local roll = session.roll
	session.state = "Claimed"
	lastGrantTime[player] = now

	local grantOk, grantErr = pcall(grantCaughtFish, player, roll)
	if not grantOk then
		warn("[FishingServer] grantCaughtFish failed:", grantErr)
	end

	-- Only clear our own session; a new cast may have replaced it while the grant was yielding.
	if fishingSessions[player] == session then
		fishingSessions[player] = nil
		pendingRolls[player] = nil
	end

	return successResponse({
		Name = roll.name,
		Weight = roll.weight,
	})
end

local function fireAllClientsExcept(event, excludePlayer, ...)
	for _, p in Players:GetPlayers() do if p ~= excludePlayer then event:FireClient(p, ...) end end
end

NetworkGateway:RegisterRoute("POST", "/fishing/roll", function(player, payload)
	if type(payload) ~= "table" then
		return failureResponse(400, "INVALID_PAYLOAD", "Payload must be a table.")
	end
	return handleRollRequest(player, payload.Power, nil, false)
end, { rateLimitSeconds = FISH_COOLDOWN })

-- No gateway cooldown here: an early claim must reach the totalElapsed check and be retryable.
NetworkGateway:RegisterRoute("POST", "/fishing/claim", function(player, payload)
	if type(payload) ~= "table" then
		return failureResponse(400, "INVALID_PAYLOAD", "Payload must be a table.")
	end
	return handleClaimRequest(player, payload.RollId, false)
end)

-- H-04 & M-01: Server-authoritative cast handler with state registration & pcall
castReplicationEvent.OnServerEvent:Connect(function(player, rodPos, vel, rodName, power)
	local ok, err = pcall(function()
		if not player or not player:IsDescendantOf(Players) then return end
		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then return end
		if typeof(rodPos) ~= "Vector3" or typeof(vel) ~= "Vector3" then return end
		if type(rodName) ~= "string" or (power ~= nil and type(power) ~= "number") then return end

		local now = os.clock()
		if lastReplicationTime[player] and now - lastReplicationTime[player] < 0.2 then return end
		lastReplicationTime[player] = now

		-- Register active cast session for authoritative validation
		fishingSessions[player] = {
			state = "Casted",
			sessionId = HttpService:GenerateGUID(false),
			castTime = now,
			rodName = rodName,
			power = sanitizePower(power)
		}

		fireAllClientsExcept(castReplicationEvent, player, player, rodPos, vel, rodName, power)
	end)
	if not ok then
		warn("[FishingServer] Error in castReplicationEvent:", err)
	end
end)

cleanupCastEvent.OnServerEvent:Connect(function(player)
	local ok, err = pcall(function()
		if not player or not player:IsDescendantOf(Players) then return end
		local now = os.clock()
		if lastCleanupTime[player] and now - lastCleanupTime[player] < 0.2 then return end
		lastCleanupTime[player] = now

		-- H-04 rev2: Grace period - sesi "Casted" tidak dihapus seketika.
		-- Klien mengirim cleanup tepat sebelum roll (roll terjadi setelah minigame selesai),
		-- jadi sesi bertransisi ke "CastedClosed" dan masih boleh di-roll dalam grace window.
		local session = fishingSessions[player]
		if session and session.state == "Casted" then
			session.state = "CastedClosed"
			session.closedAt = now
		end
		pendingRolls[player] = nil

		fireAllClientsExcept(cleanupCastEvent, player, player)
	end)
	if not ok then
		warn("[FishingServer] Error in cleanupCastEvent:", err)
	end
end)

-- Dual-stack legacy adapter. New clients use NetworkGateway; old clients keep
-- sending { type = "rollRequest" } and { type = "claim" } through FishGiver.
fishGiverEvent.OnServerEvent:Connect(function(player, payload)
	local ok, err = pcall(function()
		if typeof(payload) ~= "table" then return end

		if payload.type == "rollRequest" then
			handleRollRequest(player, payload.power, payload.token, true)
			return
		end

		if payload.type == "claim" then
			handleClaimRequest(player, payload.rollId, true)
		end
	end)
	if not ok then
		warn("[FishingServer] Error in fishGiverEvent handler:", err)
	end
end)

-- ===================================================================
-- PLAYER ADDED (FIXED - GIVES BASIC ROD WITH TAG)
-- ===================================================================
local function handlePlayerFishingInit(player)
	task.spawn(function()
		-- Wait for FishData to load profile
		local profile = nil
		local attempts = 0
		while attempts < 30 and not profile and player:IsDescendantOf(Players) do
			profile = GameProfileService:GetProfile(player)
			if not profile then
				attempts += 1
				task.wait(0.5)
			end
		end

		if not profile then
			warn("[FishingServer] DataStore profile load delay for " .. player.Name .. " - retrying in background without kicking.")
			while not profile and player:IsDescendantOf(Players) do
				task.wait(2)
				profile = GameProfileService:GetProfile(player)
			end
		end

		if not player:IsDescendantOf(Players) or not profile then return end

		-- Add Basic Rod to data
		DataManager:AddRod(player, "Basic Rod")

		-- Function to give Basic Rod with proper tag
		local function giveBasicRodWithTag()
			local backpack = player:FindFirstChild("Backpack")
			if not backpack then return end

			-- Check if player already has Basic Rod
			if backpack:FindFirstChild("Basic Rod") then return end

			local basicRodTemplate = rodToolFolder:FindFirstChild("Basic Rod")
			if basicRodTemplate then
				local clonedRod = basicRodTemplate:Clone()
				-- CRITICAL: Ensure Basic Rod has the "Rod" tag
				if not CollectionService:HasTag(clonedRod, "Rod") then
					CollectionService:AddTag(clonedRod, "Rod")
				end
				clonedRod.Parent = backpack
			else
				warn("⚠️ [FishingServer] Basic Rod not found in ServerStorage.AllRods!")
			end
		end

		player.CharacterAdded:Connect(function(character)
			task.wait(0.3)
			giveBasicRodWithTag()
			restoreRoleRods(player)
		end)

		if player.Character then
			task.spawn(function()
				task.wait(0.3)
				giveBasicRodWithTag()
				restoreRoleRods(player)
			end)
		end
	end)
end

Players.PlayerAdded:Connect(handlePlayerFishingInit)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(handlePlayerFishingInit, player)
end

-- ===================================================================
-- SELL FISH EVENT
-- ===================================================================
sellFishEvent.OnServerEvent:Connect(function(player, sellType, fishData)
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
		if lastSellBatchTime[player] and now - lastSellBatchTime[player] < 0.5 then return end
		lastSellBatchTime[player] = now
		local totalCoins = 0
		for _, fSell in ipairs(fishData) do
			if type(fSell) ~= "table" then continue end
			local removed, removedData = DataManager:RemoveFish(player, fSell.fishId)
			if removed then
				local sellWeight = removedData and removedData.weight or 0
				local sellRarity = removedData and removedData.rarity or "Common"
				totalCoins = totalCoins + DataManager:CalculateFishPrice(sellWeight, sellRarity)
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
		local sellPrice = DataManager:CalculateFishPrice(fishToSell.weight or 0, fishToSell.rarity or "Common")
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
end)

Players.PlayerRemoving:Connect(function(player)
	fishingSessions[player] = nil
	lastFishTime[player] = nil
	lastReplicationTime[player] = nil
	lastCleanupTime[player] = nil
	lastSellBatchTime[player] = nil
	lastGrantTime[player] = nil
	playerPity[player] = nil
	pendingRolls[player] = nil

	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= player then cleanupCastEvent:FireClient(otherPlayer, player) end
	end
end)
