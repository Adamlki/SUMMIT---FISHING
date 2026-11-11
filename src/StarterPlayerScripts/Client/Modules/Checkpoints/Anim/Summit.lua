--!nonstrict
local TweenService = game:GetService("TweenService")

local SummitAnim = {}

function SummitAnim.Play(summitCountFrame: Frame, summitReward: number, oldTotal: number, newTotal: number, gachaTickSound, summitSound, onComplete)
    local leftLabel = summitCountFrame:FindFirstChild("Left")
    local midLabel = summitCountFrame:FindFirstChild("Mid")
    local rightLabel = summitCountFrame:FindFirstChild("Right")

    if leftLabel then
        leftLabel.Position = UDim2.fromScale(0.165, 0.5)
        leftLabel.TextTransparency = 0
        leftLabel.Visible = true
    end
    if midLabel then
        midLabel.Position = UDim2.fromScale(0.5, 0.5)
        midLabel.Text = "+"
        midLabel.TextTransparency = 0
        midLabel.Visible = true
    end
    if rightLabel then
        rightLabel.Position = UDim2.fromScale(0.835, 0.5)
        rightLabel.TextTransparency = 0
        rightLabel.Visible = true
    end

    for _ = 1, 30 do
        if leftLabel then
            leftLabel.Text = tostring(math.random(0, 999))
        end
        if rightLabel then
            rightLabel.Text = tostring(math.random(0, 999))
        end
        if gachaTickSound then
            gachaTickSound:Play()
        end
        task.wait(0.08)
    end

    if leftLabel then
        leftLabel.Text = tostring(oldTotal)
    end
    if rightLabel then
        rightLabel.Text = tostring(summitReward)
    end
    if midLabel then
        midLabel.Text = "+"
    end
    task.wait(0.3)
    if midLabel then
        midLabel.Text = "="
    end
    task.wait(0.3)

    if leftLabel and rightLabel then
        local centerPos = UDim2.fromScale(0.5, 0.5)
        local slideInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(leftLabel, slideInfo, {Position = centerPos}):Play()
        TweenService:Create(rightLabel, slideInfo, {Position = centerPos}):Play()
        task.wait(0.9)
        leftLabel.Visible = false
        rightLabel.Visible = false
    end

    if midLabel then
        midLabel.Text = tostring(newTotal)
        midLabel.TextTransparency = 0
    end
    if summitSound then
        summitSound:Play()
    end

    if onComplete then
        task.delay(0.8, onComplete)
    end
end

return SummitAnim
