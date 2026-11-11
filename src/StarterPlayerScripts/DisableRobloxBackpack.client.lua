--!strict
-- StarterPlayerScripts/DisableRobloxBackpack
-- Bulletproof suppression of Roblox's default CoreGui hotbar (CoreGuiType.Backpack)
-- Ensures only Custom Hotbar & Custom Inventory ("Tas") are used.

local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function enforceDisableBackpack()
	task.spawn(function()
		local attempts = 0
		while attempts < 30 do
			local ok = pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			end)
			if ok then break end
			attempts = attempts + 1
			task.wait(0.1)
		end
	end)
end

-- Run immediately on client load
enforceDisableBackpack()

-- Re-enforce whenever character respawns or changes
player.CharacterAdded:Connect(function()
	enforceDisableBackpack()
end)

print("🛡️ [DisableRobloxBackpack] Roblox default backpack hotbar suppressed successfully.")
