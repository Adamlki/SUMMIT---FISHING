--!nonstrict

local Anim = require(script.Parent.Parent.CheckpointUIAnim)
local util = require(script.Parent.CheckpointPresenterUtil)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundConfig = require(ReplicatedStorage.Shared.Config.Checkpoints.SoundConfig)

local CheckpointPresenter = {}

function CheckpointPresenter.show(frames, index)
    if not frames then return end

    if not (frames.CheckpointFrame and frames.CheckpointCount) then
        return
    end

    local uiParent = frames.uiParent

    local cf
    util.clearClones(uiParent, "CheckpointFrameClone")
    cf = frames.CheckpointFrame:Clone()
    cf.Name = "CheckpointFrameClone"
    cf.Visible = true
    local t = cf:FindFirstChild("Text")
    if t and t:IsA("TextLabel") then
        t.Text = ""
        t.Text = "CHECKPOINT"
    end
    cf.Parent = uiParent

    if SoundConfig.Checkpoint then
        local sound = Instance.new("Sound")
        sound.SoundId = SoundConfig.Checkpoint.SoundId
        sound.Volume = SoundConfig.Checkpoint.Volume
        sound.Parent = cf
        sound:Play()
        task.delay(2, function()
            sound:Destroy()
        end)
    end

    Anim.CheckpointFrameIn(cf, 0.4, function()
        task.delay(1.0, function()
            Anim.CheckpointFrameOut(cf, 0.4, function()
                cf:Destroy()
            end)
        end)
    end)

    util.clearClones(uiParent, "CheckpointCountClone")
    local cc = frames.CheckpointCount:Clone()
    cc.Name = "CheckpointCountClone"
    cc.Visible = true
    local tc = cc:FindFirstChild("Text")
    if tc and tc:IsA("TextLabel") then
        tc.Text = util.toRoman(index)
        tc.TextTransparency = 0
    end
    cc.Parent = uiParent
    Anim.CheckpointCountIn(cc, 0.4, function()
        task.delay(1.0, function()
            Anim.CheckpointCountOut(cc, 0.4, function()
                cc:Destroy()
            end)
        end)
    end)
end

return CheckpointPresenter
