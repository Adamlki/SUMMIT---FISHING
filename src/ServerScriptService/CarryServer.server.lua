-- ============================================================
-- CarryServer (Script) - entrypoint
-- Lokasi: ServerScriptService > CarryServer
-- Implementasi: ServerScriptService > Carry > Modules
-- SUMMITKIT PREMIUM V1 - MULTI-CARRY & ZERO-DRAG PHYSICS
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FeatureFlags = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("FeatureFlags"))
if not FeatureFlags.Carry then return end

local CarryModules = script.Parent:WaitForChild("Carry"):WaitForChild("Modules")
local Requests = require(CarryModules:WaitForChild("Requests"))
local Lifecycle = require(CarryModules:WaitForChild("Lifecycle"))

Requests.Start()
Lifecycle.Start()
