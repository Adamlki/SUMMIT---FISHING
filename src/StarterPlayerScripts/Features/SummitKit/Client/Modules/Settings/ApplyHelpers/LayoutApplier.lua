--!nonstrict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LayoutApplier = {}
local sharedDefaults = {}

local function copyUDim2(value)
	return UDim2.new(value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
end

local function cloneLayout(layout)
	return {
		Size = copyUDim2(layout.Size),
		Position = copyUDim2(layout.Position),
	}
end

function LayoutApplier.cacheDefaults(refs)
	if not refs then
		return
	end
	refs.Defaults = refs.Defaults or {}
	if refs.Targets then
		if refs.Targets.Jump then
			sharedDefaults.Jump = sharedDefaults.Jump or cloneLayout(refs.Targets.Jump)
			refs.Defaults.Jump = cloneLayout(sharedDefaults.Jump)
		end
		if refs.Targets.Shiftlock then
			sharedDefaults.Shiftlock = sharedDefaults.Shiftlock or cloneLayout(refs.Targets.Shiftlock)
			refs.Defaults.Shiftlock = cloneLayout(sharedDefaults.Shiftlock)
		end
	end
	refs.Defaults.JumpButton = refs.Defaults.JumpButton or (sharedDefaults.JumpButton and cloneLayout(sharedDefaults.JumpButton)) or nil
end

function LayoutApplier.applyJumpSettings(refs, values)
	if not UserInputService.TouchEnabled then
		return
	end
	local lp = Players.LocalPlayer
	if not lp then
		return
	end
	local pg = lp:FindFirstChild("PlayerGui")
	if not pg then
		return
	end
	local touchGui = pg:FindFirstChild("TouchGui")
	local touchFrame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
	local jump = touchFrame and touchFrame:FindFirstChild("JumpButton")
	if not jump then
		return
	end

	refs.Defaults = refs.Defaults or {}
	if not sharedDefaults.JumpButton then
		sharedDefaults.JumpButton = cloneLayout(jump)
	end
	refs.Defaults.JumpButton = cloneLayout(sharedDefaults.JumpButton)
	local base = refs.Defaults.JumpButton
	local factor = 1 + (values.JumpSize / 100)
	jump.Size = UDim2.new(
		base.Size.X.Scale * factor,
		base.Size.X.Offset * factor,
		base.Size.Y.Scale * factor,
		base.Size.Y.Offset * factor
	)
	jump.Position = UDim2.new(
		base.Position.X.Scale + (values.JumpHorizontal / 100),
		base.Position.X.Offset,
		base.Position.Y.Scale + (values.JumpVertical / 100),
		base.Position.Y.Offset
	)
end

function LayoutApplier.applyShiftlockSettings(refs, values)
	if not (refs and refs.Targets and refs.Targets.Shiftlock and refs.Defaults and refs.Defaults.Shiftlock) then
		return
	end
	local base = refs.Defaults.Shiftlock
	local frame = refs.Targets.Shiftlock
	local factor = 1 + (values.ShiftlockSize / 100)
	frame.Size = UDim2.new(
		base.Size.X.Scale * factor,
		base.Size.X.Offset * factor,
		base.Size.Y.Scale * factor,
		base.Size.Y.Offset * factor
	)
	frame.Position = UDim2.new(
		base.Position.X.Scale + (values.ShiftlockHorizontal / 100),
		base.Position.X.Offset,
		base.Position.Y.Scale + (values.ShiftlockVertical / 100),
		base.Position.Y.Offset
	)
end

return LayoutApplier
