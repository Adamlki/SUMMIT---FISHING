--!nonstrict
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local _Janitor = require(Packages.Janitor)

local Frames = {}

local function play(obj: GuiObject, info: TweenInfo, props, onComplete, janitor)
	local tw = TweenService:Create(obj, info, props)
	if onComplete then
		local conn = tw.Completed:Connect(onComplete)
		if janitor then
			janitor:Add(conn, "Disconnect")
		end
	end
	if janitor then
		janitor:Add(tw, "Cancel")
	end
	tw:Play()
	return tw
end

local function getOriginalPos(obj: GuiObject)
	local originalPos = obj:GetAttribute("OriginalPos")
	if not originalPos then
		originalPos = obj.Position
		obj:SetAttribute("OriginalPos", originalPos)
	end
	return originalPos
end

function Frames.CheckpointFrameIn(obj: GuiObject, duration: number?, onComplete, janitor)
    local info = TweenInfo.new(duration or 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local originalPos = getOriginalPos(obj)
    obj.Position = UDim2.new(originalPos.X.Scale - 1, originalPos.X.Offset, originalPos.Y.Scale, originalPos.Y.Offset)
    return play(obj, info, {Position = originalPos}, onComplete, janitor)
end

function Frames.CheckpointFrameOut(obj: GuiObject, duration: number?, onComplete, janitor)
    local info = TweenInfo.new(duration or 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local originalPos = getOriginalPos(obj)
    local leftPos = UDim2.new(originalPos.X.Scale - 1, originalPos.X.Offset, originalPos.Y.Scale, originalPos.Y.Offset)
    return play(obj, info, {Position = leftPos}, onComplete, janitor)
end

function Frames.CheckpointCountIn(obj: GuiObject, duration: number?, onComplete, janitor)
    local info = TweenInfo.new(duration or 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local originalPos = getOriginalPos(obj)
    obj.Position = UDim2.new(originalPos.X.Scale + 1, originalPos.X.Offset, originalPos.Y.Scale, originalPos.Y.Offset)
    return play(obj, info, {Position = originalPos}, onComplete, janitor)
end

function Frames.CheckpointCountOut(obj: GuiObject, duration: number?, onComplete, janitor)
    local info = TweenInfo.new(duration or 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local originalPos = getOriginalPos(obj)
    local rightPos = UDim2.new(originalPos.X.Scale + 1, originalPos.X.Offset, originalPos.Y.Scale, originalPos.Y.Offset)
    return play(obj, info, {Position = rightPos}, onComplete, janitor)
end

return Frames
