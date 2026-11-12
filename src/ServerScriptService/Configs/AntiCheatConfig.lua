--!strict
-- Server-private anti-cheat thresholds and network limits.
local SharedNetworkConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("NetworkConfig"))

local AntiCheatConfig = {
	Speedrun = {
		Enabled = false,
		MinTimeSeconds = 120,
		KickMessage = "Anti-Cheat: Unreasonable speedrun time detected. Contact an admin if this is a mistake.",
	},

	Network = {
		RequestTimeoutSeconds = SharedNetworkConfig.RequestTimeoutSeconds,
		DefaultRateLimitSeconds = SharedNetworkConfig.DefaultRateLimitSeconds,
		MaxIdentifierLength = SharedNetworkConfig.MaxIdentifierLength,
		Inventory = {
			EquipSeconds = 0.5,
			ReadSeconds = 0.5,
			SellSeconds = 2,
		},
	},

	Fishing = {
		FishCooldownSeconds = 0.5,
		GrantMinIntervalSeconds = 2.5,
		MinMinigameDurationSeconds = 0.4,
		PendingRollTimeoutSeconds = 120,
	},

	AntiAFK = {
		AwayAfterSeconds = 18 * 60,
	},
}

return AntiCheatConfig
