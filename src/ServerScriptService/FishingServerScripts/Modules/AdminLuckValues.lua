-- Auto-setup of the ReplicatedStorage values/remotes shared by the luck system.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Values = {}

Values.FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem", 15)

local function ensureValue(className, name, defaultValue)
	local inst = Values.FishingSystem:FindFirstChild(name)
	if not inst then
		inst = Instance.new(className)
		inst.Name = name
		inst.Value = defaultValue
		inst.Parent = Values.FishingSystem
	end
	return inst
end

local function ensureRemote(name)
	local inst = Values.FishingSystem:FindFirstChild(name)
	if not inst then
		inst = Instance.new("RemoteEvent")
		inst.Name = name
		inst.Parent = Values.FishingSystem
	end
	return inst
end

Values.LuckValue = ensureValue("NumberValue", "GlobalLuckMultiplier", 1)
Values.MutationValue = ensureValue("NumberValue", "GlobalMutationMultiplier", 1)
Values.ActiveEventName = ensureValue("StringValue", "ActiveEventName", "")
Values.TimerValue = ensureValue("IntValue", "LuckBoostTimer", 0)
Values.TriggerAdminEvent = ensureRemote("TriggerAdminEvent")
Values.AdminEventActivated = ensureRemote("AdminEventActivated")

Values.ShowNotification = Values.FishingSystem:WaitForChild("ShowNotification")
Values.SendChatMessage = Values.FishingSystem:WaitForChild("SendChatMessage")

return Values
