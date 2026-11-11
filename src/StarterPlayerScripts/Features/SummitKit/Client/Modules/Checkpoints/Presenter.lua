--!nonstrict
local CheckpointPresenter = require(script.Parent.Presenters.CheckpointPresenter)
local SummitPresenter = require(script.Parent.Presenters.SummitPresenter)

local Presenter = {}

function Presenter.showCheckpoint(frames, index)
    CheckpointPresenter.show(frames, index)
end

function Presenter.showSummit(frames, reward, oldTotal, newTotal)
    SummitPresenter.show(frames, reward, oldTotal, newTotal)
end

return Presenter
