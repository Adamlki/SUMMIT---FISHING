-- ServerScriptService/AntiAFKServer
-- OOP Service Architecture for Anti-AFK & Session Restoration

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))

local fishingFolder = ReplicatedStorage:WaitForChild("FishingSystem")
local syncSessionRemote = fishingFolder:WaitForChild("SyncSessionState")
local resumeFishingRemote = fishingFolder:WaitForChild("ResumeFishingSession")

local FishData = require(ServerScriptService:WaitForChild("Data"):WaitForChild("PetCore"):WaitForChild("FishData"))

-- Snapshot lebih tua dari ini tidak di-restore (langsung spawn di checkpoint)
local RESTORE_MAX_AGE_SECONDS = 30 * 60

local AntiAFKService = {}
AntiAFKService.__index = AntiAFKService

function AntiAFKService.new()
	local self = setmetatable({}, AntiAFKService)
	self._activePlayerState = {}
	self._isInitialSpawn = {}
	self._lastSyncTime = {}
	self._running = false
	return self
end

function AntiAFKService:SaveSnapshot(player)
	if not player then return end
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end

	local currentAction = self._activePlayerState[player.UserId] or { Action = "Idle" }
	local cfComponents = { hrp.CFrame:GetComponents() }
	local equippedTool = character:FindFirstChildOfClass("Tool")

	local snapshot = {
		CFrame = cfComponents,
		Action = currentAction.Action or "Idle",
		RodName = currentAction.RodName or nil,
		IsAutoFishing = currentAction.IsAutoFishing == true,
		Away = currentAction.Away == true,
		EquippedTool = equippedTool and equippedTool.Name or nil,
		Timestamp = os.time(),
	}

	pcall(function()
		FishData:SetLastSessionState(player, snapshot)
	end)
end

function AntiAFKService:HandleCharacterAdded(player, character)
	if self._isInitialSpawn[player.UserId] == true then
		self._isInitialSpawn[player.UserId] = false

		task.spawn(function()
			task.wait(0.3)
			local profile = FishData:GetProfile(player)
			local startWait = os.clock()
			while not profile and (os.clock() - startWait < 5) do
				task.wait(0.1)
				profile = FishData:GetProfile(player)
			end

			local session = FishData:GetLastSessionState(player)
			local fresh = session
				and typeof(session.Timestamp) == "number"
				and (os.time() - session.Timestamp) <= RESTORE_MAX_AGE_SECONDS
			local restoreEligible = session
				and session.Away == true
				and fresh == true
				and session.CFrame ~= nil
				and #session.CFrame == 12
			if restoreEligible then
				local hrp = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
				if hrp then
					local success, targetCF = pcall(function()
						return CFrame.new(unpack(session.CFrame))
					end)
					if success and targetCF then
						hrp.CFrame = targetCF
						-- Teleport checkpoint game bisa berjalan SESUDAH restore (load profile checkpoint lambat),
						-- jadi posisi ditegakkan ulang sebentar selama pemain belum menggerakkan karakter.
						task.spawn(function()
							local hum = character:FindFirstChildOfClass("Humanoid")
							for _ = 1, 12 do
								task.wait(0.35)
								local h = character:FindFirstChild("HumanoidRootPart")
								if not h or not h.Parent then break end
								if hum and hum.MoveDirection.Magnitude > 0.1 then break end
								if (h.Position - targetCF.Position).Magnitude > 3 then
									h.CFrame = targetCF
								end
							end
						end)
						local resumeFishing = session.Action == "Fishing" and session.IsAutoFishing == true
						if session.EquippedTool ~= nil or resumeFishing then
							task.wait(0.4)
							resumeFishingRemote:FireClient(player, session)
						end
					end
				end
			end
		end)
	end
end

function AntiAFKService:HandlePlayerAdded(player)
	self._isInitialSpawn[player.UserId] = true
	self._activePlayerState[player.UserId] = { Action = "Idle", Away = false }

	player.CharacterAdded:Connect(function(char)
		self:HandleCharacterAdded(player, char)
	end)
	if player.Character then
		self:HandleCharacterAdded(player, player.Character)
	end
end

function AntiAFKService:HandlePlayerRemoving(player)
	self:SaveSnapshot(player)
	self._activePlayerState[player.UserId] = nil
	self._isInitialSpawn[player.UserId] = nil
	self._lastSyncTime[player.UserId] = nil
end

function AntiAFKService:SyncSessionData(player, data)
	if typeof(data) ~= "table" then return end
	local now = os.clock()
	local awayOnly = data.Away ~= nil and data.Action == nil
	local minInterval = awayOnly and 0.5 or 2.0
	if self._lastSyncTime[player.UserId] and now - self._lastSyncTime[player.UserId] < minInterval then
		return
	end
	self._lastSyncTime[player.UserId] = now

	local existing = self._activePlayerState[player.UserId] or {}
	local prevAway = existing.Away
	existing.Action = data.Action or existing.Action or "Idle"
	if data.RodName ~= nil then existing.RodName = data.RodName end
	if data.IsAutoFishing ~= nil then existing.IsAutoFishing = (data.IsAutoFishing == true) end
	if data.Away ~= nil then existing.Away = (data.Away == true) end
	self._activePlayerState[player.UserId] = existing

	-- Snapshot ditulis saat status Away BERUBAH (profile masih aktif di sini).
	-- Jalur PlayerRemoving tidak bisa diandalkan: FishData:Release() berjalan
	-- lebih dulu sehingga profile sudah tidak aktif saat snapshot disimpan.
	if data.Away ~= nil and existing.Away ~= prevAway then
		self:SaveSnapshot(player)
	end

	-- In-memory state only during gameplay.
	-- Snapshot is written to FishData on PlayerRemoving or server shutdown to eliminate 7s DataStore churn.
end

function AntiAFKService:Start()
	if self._running then return end
	self._running = true

	syncSessionRemote.OnServerEvent:Connect(function(player, data)
		NetworkGateway:RunLegacy(player, "syncSession", function()
			self:SyncSessionData(player, data)
		end, 0.5)
	end)

	Players.PlayerAdded:Connect(function(player)
		self:HandlePlayerAdded(player)
	end)
	for _, p in ipairs(Players:GetPlayers()) do
		self:HandlePlayerAdded(p)
	end

	Players.PlayerRemoving:Connect(function(player)
		self:HandlePlayerRemoving(player)
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			self:SaveSnapshot(player)
		end
	end)
end

local service = AntiAFKService.new()
FishData:RegisterBeforeRelease(function(player)
	service:SaveSnapshot(player)
end)
service:Start()

-- ===================================================================
-- REST ROUTE (NETWORK GATEWAY)
-- ===================================================================

NetworkGateway:RegisterRoute("PUT", "/afk/sync", function(player, payload)
	if type(payload) ~= "table" then
		return {
			Success = false,
			StatusCode = 400,
			ErrorCode = "INVALID_PAYLOAD",
			Message = "Payload must be a table.",
		}
	end
	if payload.Away ~= nil and type(payload.Away) ~= "boolean" then
		return {
			Success = false,
			StatusCode = 400,
			ErrorCode = "INVALID_PAYLOAD",
			Message = "Away must be a boolean.",
		}
	end
	if payload.Action ~= nil and type(payload.Action) ~= "string" then
		return {
			Success = false,
			StatusCode = 400,
			ErrorCode = "INVALID_PAYLOAD",
			Message = "Action must be a string.",
		}
	end
	if payload.RodName ~= nil and type(payload.RodName) ~= "string" then
		return {
			Success = false,
			StatusCode = 400,
			ErrorCode = "INVALID_PAYLOAD",
			Message = "RodName must be a string.",
		}
	end
	if payload.IsAutoFishing ~= nil and type(payload.IsAutoFishing) ~= "boolean" then
		return {
			Success = false,
			StatusCode = 400,
			ErrorCode = "INVALID_PAYLOAD",
			Message = "IsAutoFishing must be a boolean.",
		}
	end
	if payload.Away == nil and payload.Action == nil and payload.RodName == nil and payload.IsAutoFishing == nil then
		return {
			Success = false,
			StatusCode = 400,
			ErrorCode = "INVALID_PAYLOAD",
			Message = "At least one session field is required.",
		}
	end

	service:SyncSessionData(player, payload)

	return {
		Success = true,
		StatusCode = 200,
		Data = payload,
		Message = "Session state synced.",
	}
end, { rateLimitSeconds = 0.5 })

return AntiAFKService
