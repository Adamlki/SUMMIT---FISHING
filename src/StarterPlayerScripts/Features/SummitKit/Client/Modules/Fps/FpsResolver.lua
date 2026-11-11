--!nonstrict
local Players = game:GetService("Players")

local FpsResolver = {}

local function findTextLabelByKey(root, key)
	if not root then return nil end
	local keyLower = tostring(key or ""):lower()
	for _, child in ipairs(root:GetDescendants()) do
		if child:IsA("TextLabel") then
			local nameLower = child.Name:lower()
			local textLower = tostring(child.Text or ""):lower()
			if nameLower == keyLower or nameLower:find(keyLower) or textLower:find(keyLower) then
				return child
			end
		end
	end
	return nil
end

function FpsResolver.resolve()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui", 60)
	if not pg then
		return false, "PlayerGui not found"
	end

	local gameUI = pg:FindFirstChild("GameUI") or pg:WaitForChild("GameUI", 60)
	if not gameUI then
		return false, "GameUI not found"
	end
	local component = gameUI:FindFirstChild("Component") or gameUI:WaitForChild("Component", 60)
	if not component then
		return false, "Component not found"
	end

	local fpsFrame = component:FindFirstChild("Fps") or component:FindFirstChild("FPS")
	if not fpsFrame then
		for _, child in ipairs(component:GetChildren()) do
			if child:IsA("Frame") and child:FindFirstChild("Ping") and child:FindFirstChild("Fps") and child:FindFirstChild("Render") then
				fpsFrame = child
				break
			end
		end
	end
	if not fpsFrame then
		return false, "Fps frame not found"
	end

	local header = fpsFrame:FindFirstChild("Header")
	local closeBtn = header and header:FindFirstChild("Close")
	local pingLabel = fpsFrame:FindFirstChild("Ping") or findTextLabelByKey(fpsFrame, "ping")
	local fpsLabel = fpsFrame:FindFirstChild("Fps") or fpsFrame:FindFirstChild("FPS") or findTextLabelByKey(fpsFrame, "fps")
	local renderLabel = fpsFrame:FindFirstChild("Render") or findTextLabelByKey(fpsFrame, "render")

	return true, {
		Root = fpsFrame,
		Header = header,
		Close = closeBtn,
		Ping = pingLabel,
		Fps = fpsLabel,
		Render = renderLabel,
	}
end

return FpsResolver
