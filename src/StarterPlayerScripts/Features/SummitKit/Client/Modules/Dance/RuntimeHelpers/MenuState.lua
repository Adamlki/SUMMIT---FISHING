--!nonstrict
local Panel = require(script.Parent.Parent.Parent.UI.Panel)

local MenuState = {}

local SHOWN = UDim2.new(0, 20, 0.5, 0)

function MenuState.switchTab(runtime, tabName)
	runtime._activeTab = tabName
	runtime._refs.DanceScroll.Visible = (tabName == "Dance")
	runtime._refs.PoseScroll.Visible = (tabName == "Pose")
end

local function mount(runtime)
	local menu = runtime._refs.Menu
	local card = menu:FindFirstChild("Container", true)
	local width = (card and card:IsA("GuiObject") and card.AbsoluteSize.X) or 200
	Panel.mount(menu, {
		shown = SHOWN,
		hidden = UDim2.new(0, -(width + 32), 0.5, 0),
		noDim = true,
	})
	return menu
end

function MenuState.open(runtime)
	local menu = runtime._refs.Menu
	if not menu then
		return
	end
	MenuState.switchTab(runtime, runtime._activeTab)
	Panel.open(mount(runtime))
end

function MenuState.close(runtime)
	local menu = runtime._refs.Menu
	if not menu then
		return
	end
	Panel.close(mount(runtime))
end

function MenuState.toggle(runtime)
	local menu = runtime._refs.Menu
	if not menu then
		return
	end
	MenuState.switchTab(runtime, runtime._activeTab)
	Panel.toggle(mount(runtime))
end

return MenuState
