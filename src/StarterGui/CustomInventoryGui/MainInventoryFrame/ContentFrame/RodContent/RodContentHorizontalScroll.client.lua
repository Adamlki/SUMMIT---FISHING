local rodContent = script.Parent
local gridLayout = rodContent:FindFirstChildOfClass("UIGridLayout")

-- Set ScrollingFrame to scroll horizontally
rodContent.ScrollingDirection = Enum.ScrollingDirection.X

-- Make sure the grid layout arranges items horizontally
if gridLayout then
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
end

-- Update CanvasSize to fit all items horizontally
local function updateCanvasSize()
    if gridLayout then
        local cellCount = #rodContent:GetChildren()
        local cellWidth = gridLayout.CellSize.X.Offset + gridLayout.CellPadding.X.Offset
        rodContent.CanvasSize = UDim2.new(0, cellCount * cellWidth, 0, rodContent.AbsoluteSize.Y)
    end
end

gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
updateCanvasSize()

