--!strict
-- Shared network timing/limits. Server-only anti-cheat config can reference these.
return {
	RequestTimeoutSeconds = 5,
	RemoteWaitSeconds = 10,
	DefaultRateLimitSeconds = 0.25,
	MaxInFlightPerPlayer = 4,
	MaxIdentifierLength = 128,
}
