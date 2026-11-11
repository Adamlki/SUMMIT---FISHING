--!nonstrict
local Frames = require(script.Parent.Anim.Frames)
local SummitAnim = require(script.Parent.Anim.Summit)

local Anim = {}

Anim.CheckpointFrameIn = Frames.CheckpointFrameIn
Anim.CheckpointFrameOut = Frames.CheckpointFrameOut
Anim.CheckpointCountIn = Frames.CheckpointCountIn
Anim.CheckpointCountOut = Frames.CheckpointCountOut
Anim.SummitGacha = SummitAnim.Play

return Anim
