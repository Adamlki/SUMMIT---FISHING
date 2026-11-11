-- Get the tool this script is parented to
local tool = script.Parent

-- Get the local player and their character
local player = game.Players.LocalPlayer
-- Wait for the character to load if it hasn't already
local character = player.Character or player.CharacterAdded:Wait()

-- Define the exact name of the accessory that is worn on the character's back
local BACK_ACCESSORY_NAME = "FishingRodAccessory"

-- A function to change the transparency of all parts within an accessory
local function setAccessoryTransparency(accessory, transparency)
	-- If the accessory doesn't exist, stop the function to avoid errors
	if not accessory then return end

	-- Loop through all descendants (parts, meshes, etc.) of the accessory model
	for _, part in ipairs(accessory:GetDescendants()) do
		-- Check if the descendant is a BasePart (a physical object with properties like Transparency)
		if part:IsA("BasePart") then
			-- Set its transparency to the provided value (0 = opaque, 1 = invisible)
			part.Transparency = transparency
		end
	end
end

-- This event fires when the player equips the tool (takes it out in their hand)
tool.Equipped:Connect(function()
	-- Find the accessory on the character's back by its name
	local backAccessory = character:FindFirstChild(BACK_ACCESSORY_NAME)
	-- Make the back accessory invisible, since the player is now holding the tool
	setAccessoryTransparency(backAccessory, 1)
end)

-- This event fires when the player unequips the tool (puts it away)
tool.Unequipped:Connect(function()
	-- Find the accessory on the character's back by its name
	local backAccessory = character:FindFirstChild(BACK_ACCESSORY_NAME)
	-- Make the back accessory visible again
	setAccessoryTransparency(backAccessory, 0)
end)
