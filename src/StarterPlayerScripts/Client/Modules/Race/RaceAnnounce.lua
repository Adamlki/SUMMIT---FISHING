--!nonstrict
local RaceAnnounce = {}
local INTRO_DURATION_SECONDS = 3
local _introUntil = 0
local _introText = "START RACE IN 0 SECOND"
local _lastStatus = "Deactive"

local HIDE_STATUSES = {
    Deactive = true,
    Finished = true,
}

function RaceAnnounce.syncState(refs, state)
    if not refs.Announce then
        return
    end
    state = state or {}
    local status = tostring(state.status or "Deactive")

    if _lastStatus ~= "Preparing" and status == "Preparing" then
        local startSeconds = tonumber(state.joinWindow) or 0
        _introText = string.format("START RACE IN %d SECOND", math.max(startSeconds, 0))
        _introUntil = os.clock() + INTRO_DURATION_SECONDS
    end

    if status == "Preparing" then
        if os.clock() <= _introUntil then
            refs.Announce.Visible = true
            if refs.AnnounceHeaderFrame then
                refs.AnnounceHeaderFrame.Visible = true
            end
            if refs.AnnounceTimerFrame then
                refs.AnnounceTimerFrame.Visible = false
            end
            if refs.AnnounceHeader and refs.AnnounceHeader:IsA("TextLabel") then
                refs.AnnounceHeader.Text = string.gsub(_introText, "START RACE IN", "RACE START IN")
            end
            if refs.AnnounceTimer and refs.AnnounceTimer:IsA("TextLabel") then
                refs.AnnounceTimer.Text = ""
            end
        else
            local preparingSecondsLeft = tonumber(state.joinWindow) or 0
            refs.Announce.Visible = false
            refs.Announce.Visible = preparingSecondsLeft > 0
            if refs.AnnounceHeaderFrame then
                refs.AnnounceHeaderFrame.Visible = false
            end
            if refs.AnnounceTimerFrame then
                refs.AnnounceTimerFrame.Visible = preparingSecondsLeft > 0
            end
            if refs.AnnounceHeader and refs.AnnounceHeader:IsA("TextLabel") then
                refs.AnnounceHeader.Text = ""
            end
            if refs.AnnounceTimer and refs.AnnounceTimer:IsA("TextLabel") then
                refs.AnnounceTimer.Text = preparingSecondsLeft > 0 and tostring(preparingSecondsLeft) or ""
            end
        end
        _lastStatus = status
        return
    end

    if HIDE_STATUSES[status] then
        refs.Announce.Visible = false
    else
        refs.Announce.Visible = false
    end

    _lastStatus = status
end

function RaceAnnounce.render(refs, payload)
end

return RaceAnnounce
