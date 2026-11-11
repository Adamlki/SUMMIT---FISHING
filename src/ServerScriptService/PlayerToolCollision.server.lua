local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local PLAYER_GROUP = "Players"
local TOOL_GROUP = "Tools"

-- Register collision groups if not already present
pcall(function()
	if PhysicsService.RegisterCollisionGroup then
		PhysicsService:RegisterCollisionGroup(PLAYER_GROUP)
	else
		PhysicsService:CreateCollisionGroup(PLAYER_GROUP)
	end
end)
pcall(function()
	if PhysicsService.RegisterCollisionGroup then
		PhysicsService:RegisterCollisionGroup(TOOL_GROUP)
	else
		PhysicsService:CreateCollisionGroup(TOOL_GROUP)
	end
end)

-- Set collision rules
PhysicsService:CollisionGroupSetCollidable(PLAYER_GROUP, PLAYER_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(PLAYER_GROUP, TOOL_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(TOOL_GROUP, TOOL_GROUP, true) -- Tools can collide with each other

local function SetCollisionGroupRecursive(object, groupName)
	if object:IsA("BasePart") then
		object.CollisionGroup = groupName
	end
	for _, child in object:GetChildren() do
		SetCollisionGroupRecursive(child, groupName)
	end
end

local function OnToolEquipped(tool)
	SetCollisionGroupRecursive(tool, TOOL_GROUP)
end

local function OnToolAdded(tool)
	if tool:IsA("Tool") then
		tool.Equipped:Connect(function()
			OnToolEquipped(tool)
		end)
		-- If tool is already equipped (e.g., on respawn), set collision group
		if tool.Parent and Players:GetPlayerFromCharacter(tool.Parent) then
			OnToolEquipped(tool)
		end
	end
end

local function HandleCharacterAdded(Character)
	for _, Part in Character:GetDescendants() do
		if Part:IsA("BasePart") then
			Part.CollisionGroup = PLAYER_GROUP
		end
	end
	Character.ChildAdded:Connect(function(Object)
		if Object:IsA("BasePart") then
			Object.CollisionGroup = PLAYER_GROUP
		elseif Object:IsA("Tool") then
			OnToolAdded(Object)
		end
	end)
	-- Also handle tools already in character
	for _, child in Character:GetChildren() do
		if child:IsA("Tool") then
			OnToolAdded(child)
		end
	end
end

Players.PlayerAdded:Connect(function(Player)
	Player.CharacterAdded:Connect(function(Character)
		HandleCharacterAdded(Character)
	end)
end)

-- For players already in game
for _, player in Players:GetPlayers() do
	if player.Character then
		HandleCharacterAdded(player.Character)
	end
end

