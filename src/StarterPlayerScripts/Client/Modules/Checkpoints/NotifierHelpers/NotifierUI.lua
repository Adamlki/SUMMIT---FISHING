--!nonstrict
local NotifierUI = {}

local function setDefault(obj, pos)
    if not obj then
        return
    end
    obj.AnchorPoint = Vector2.new(0.5, 0.5)
    obj.Position = pos
    obj:SetAttribute("OriginalPos", pos)
end

function NotifierUI.normalize(frames)
    if not frames then
        return
    end
    setDefault(frames.CheckpointFrame, UDim2.fromScale(0.5, 0.4))
    setDefault(frames.CheckpointCount, UDim2.fromScale(0.5, 0.5))
end

function NotifierUI.hideAll(frames)
    if not frames then
        return
    end
    if frames.CheckpointFrame then
        frames.CheckpointFrame.Visible = false
    end
    if frames.CheckpointCount then
        frames.CheckpointCount.Visible = false
    end
    if frames.SummitFrame then
        frames.SummitFrame.Visible = false
    end
    if frames.SummitCount then
        frames.SummitCount.Visible = false
    end
end

return NotifierUI
