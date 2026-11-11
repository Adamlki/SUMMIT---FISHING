--!nonstrict
local HideGuiVisibility = {}

local function protectBranch(set, root)
	if not root then
		return
	end

	local current = root
	while current do
		set[current] = true
		current = current.Parent
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("GuiObject") then
			set[descendant] = true
		end
	end
end

function HideGuiVisibility.buildProtectedSet(runtime)
	local protected = {}
	protectBranch(protected, runtime._refs.HideBtn)
	return protected
end

return HideGuiVisibility
