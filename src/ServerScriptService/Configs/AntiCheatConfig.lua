--!strict
-- Server-private anti-cheat thresholds and network limits.
local AntiCheatConfig = {
	Speedrun = {
		Enabled = false,
		MinTimeSeconds = 120,
		KickMessage = "Anti-Cheat: Unreasonable speedrun time detected. Contact an admin if this is a mistake.",
	},

	Network = {
		RequestTimeoutSeconds = 5,
		DefaultRateLimitSeconds = 0,
	},

	AntiAFK = {
		AwayAfterSeconds = 18 * 60,
	},
}

return AntiCheatConfig
