--!nonstrict
local DanceResolver = {}

local function findFirst(root, name)
	if not root then return nil end
	return root:FindFirstChild(name)
end

local function findWithWait(root, name, timeout)
	if not root then return nil end
	return root:FindFirstChild(name) or root:WaitForChild(name, timeout)
end

function DanceResolver.Resolve(playerGui)
	if not playerGui then
		return false, "PlayerGui not found"
	end

local gameUI = findWithWait(playerGui, "GameUI", 60)
	if not gameUI then
		return false, "GameUI not found"
	end

local menus = findWithWait(gameUI, "Menus", 60)
	local danceMenu = menus and findFirst(menus, "Dance")
	if not danceMenu then
		return false, "Menus/Dance not found"
	end

	local background = findFirst(danceMenu, "Background")
	local header = background and findFirst(background, "Header")
	local container = background and findFirst(background, "Container")
	if not header then
		return false, "Dance/Background/Header not found"
	end
	if not container then
		return false, "Dance/Background/Container not found"
	end

	local danceTab = findFirst(header, "Dance")
	local poseTab = findFirst(header, "Pose")
	local danceScroll = findFirst(container, "Dance")
	local poseScroll = findFirst(container, "Pose")

	if not danceScroll then
		return false, "Dance ScrollingFrame not found"
	end
	if not poseScroll then
		return false, "Pose ScrollingFrame not found"
	end

	local component = findFirst(gameUI, "Component")
	local buttons = component and findFirst(component, "ButtonsNew")
	local menuKiri = buttons and findFirst(buttons, "MenuKiri")
	local frameBtn = menuKiri and findFirst(menuKiri, "FrameBtn")
	local toggleBtn = frameBtn and findFirst(frameBtn, "EmoteButton")

	return true, {
		GameUI = gameUI,
		Menu = danceMenu,
		Background = background,
		Header = header,
		Container = container,
		DanceTab = danceTab,
		PoseTab = poseTab,
		DanceScroll = danceScroll,
		PoseScroll = poseScroll,
		ToggleBtn = toggleBtn,
	}
end

return DanceResolver
