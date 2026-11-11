--!nonstrict
local TweenService = game:GetService("TweenService")

local MenuState = {}

function MenuState.switchTab(runtime, tabName)
	runtime._activeTab = tabName
	runtime._refs.DanceScroll.Visible = (tabName == "Dance")
	runtime._refs.PoseScroll.Visible = (tabName == "Pose")
end

function MenuState.open(runtime)
	local menu = runtime._refs.Menu
	if not menu then
		return
	end

	if runtime._menuTween then
		runtime._menuTween:Cancel()
		runtime._menuTween = nil
	end

	runtime._menuTweenId += 1
	local currentId = runtime._menuTweenId

	if not runtime._defaultAnchor then
		runtime._defaultAnchor = menu.AnchorPoint
	end
	if not runtime._defaultPos then
		runtime._defaultPos = menu.Position
	end

	menu.AnchorPoint = Vector2.new(0, 0.5)
	menu.Position = UDim2.new(0, -menu.AbsoluteSize.X, 0.5, 0)
	menu.Visible = true

	MenuState.switchTab(runtime, runtime._activeTab)

	runtime._menuTween = TweenService:Create(
		menu,
		TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = UDim2.new(0, 20, 0.5, 0)}
	)
	local conn = runtime._menuTween.Completed:Connect(function()
		if currentId ~= runtime._menuTweenId then
			return
		end
		runtime._menuTween = nil
	end)
	runtime._janitor:Add(conn, "Disconnect")
	runtime._menuTween:Play()
end

function MenuState.close(runtime)
	local menu = runtime._refs.Menu
	if not menu then
		return
	end

	if runtime._menuTween then
		runtime._menuTween:Cancel()
		runtime._menuTween = nil
	end

	runtime._menuTweenId += 1
	local currentId = runtime._menuTweenId

	runtime._menuTween = TweenService:Create(
		menu,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = UDim2.new(0, -menu.AbsoluteSize.X, 0.5, 0)}
	)
	local conn = runtime._menuTween.Completed:Connect(function()
		if currentId ~= runtime._menuTweenId then
			return
		end
		menu.Visible = false
		if runtime._defaultAnchor then
			menu.AnchorPoint = runtime._defaultAnchor
		end
		if runtime._defaultPos then
			menu.Position = runtime._defaultPos
		end
		runtime._menuTween = nil
	end)
	runtime._janitor:Add(conn, "Disconnect")
	runtime._menuTween:Play()
end

function MenuState.toggle(runtime)
	local menu = runtime._refs.Menu
	if not menu then
		return
	end

	if menu.Visible then
		MenuState.close(runtime)
	else
		MenuState.open(runtime)
	end
end

return MenuState
