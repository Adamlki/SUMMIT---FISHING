-- ProfileService store, template and the live player -> profile registry.
local RunService = game:GetService("RunService")
local SSS = game:GetService("ServerScriptService")
local DataStoreConfig = require(SSS:WaitForChild("Configs"):WaitForChild("DataStoreConfig"))
local ProfileService = require(SSS.Data.DataModule:WaitForChild("ProfileService"))

local PlayerProfileTemplate = {
	Coins = 0,
	OwnedGamepasses = {},
	SavedFish = {},
	TotalFishCaught = 0,
	FishIndex = {},
	LegacyCatchMigrated = false,
	OwnedRods = {"Basic Rod"},
	LastEquippedRod = "Basic Rod",
	LastPosition = nil,
	LastSessionState = nil,
	FishInventoryLimit = 500,
	HasRemoteSell = false,
	OwnedTrails = {},
	EquippedTrail = "",
}

local store = ProfileService.GetProfileStore(
	DataStoreConfig.Stores.PlayerGameData,
	PlayerProfileTemplate
)

local USE_MOCK_IN_STUDIO = false -- Studio already uses *_Studio keys; set true only if you also want in-memory mock data.

if RunService:IsStudio() and USE_MOCK_IN_STUDIO then
	store = store.Mock
	print("[FishData] ProfileService running in MOCK mode (Studio data will NOT persist to cloud).")
else
	print("[FishData] ProfileService running in REAL DATASTORE mode (Studio uses *_Studio keys).")
end

return {
	Template = PlayerProfileTemplate,
	Store = store,
	Profiles = {},
}
