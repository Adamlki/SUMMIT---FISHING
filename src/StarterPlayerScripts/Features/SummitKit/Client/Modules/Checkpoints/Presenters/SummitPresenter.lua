--!nonstrict

local Anim = require(script.Parent.Parent.CheckpointUIAnim)
local util = require(script.Parent.CheckpointPresenterUtil)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundConfig = require(ReplicatedStorage.Shared.Config.Checkpoints.SoundConfig)

local SummitPresenter = {}

function SummitPresenter.show(frames, reward, oldTotal, newTotal)
    if not frames then return end

    local uiParent = frames.uiParent

    local sfClone
    if frames.SummitFrame and uiParent then
        util.clearClones(uiParent, "SummitFrameClone")
        sfClone = frames.SummitFrame:Clone()
        sfClone.Name = "SummitFrameClone"
        local t = sfClone:FindFirstChild("Text")
        if t and t:IsA("TextLabel") then
            t.Text = ""
            t.Text = "Summit Reached!"
        end
        sfClone.Visible = true
        sfClone.Parent = uiParent
    end

    if frames.SummitCount and uiParent then
        util.clearClones(uiParent, "SummitCountClone")
        local scClone = frames.SummitCount:Clone()
        scClone.Name = "SummitCountClone"
        scClone.Visible = true
        scClone.Parent = uiParent

        local gachaSoundInstance
        if SoundConfig.GachaTick then
            gachaSoundInstance = Instance.new("Sound")
            gachaSoundInstance.SoundId = SoundConfig.GachaTick.SoundId
            gachaSoundInstance.Volume = SoundConfig.GachaTick.Volume
            gachaSoundInstance.Parent = scClone
        end
        local summitSoundInstance
        if SoundConfig.Summit then
            summitSoundInstance = Instance.new("Sound")
            summitSoundInstance.SoundId = SoundConfig.Summit.SoundId
            summitSoundInstance.Volume = SoundConfig.Summit.Volume
            summitSoundInstance.Parent = scClone
        end

        Anim.SummitGacha(scClone, reward, oldTotal, newTotal, gachaSoundInstance, summitSoundInstance, function()
            if sfClone then
                sfClone:Destroy()
            end
            scClone:Destroy()
        end)
    end
end

return SummitPresenter
