--!nonstrict
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)
local Signal = require(Packages.Signal)

local AvatarViewUI = {}
AvatarViewUI.__index = AvatarViewUI

local function connectButton(btn, cb, janitor)
    if not btn then
        return
    end
    if btn:IsA("TextButton") or btn:IsA("ImageButton") then
        local conn = btn.MouseButton1Click:Connect(cb)
        if janitor then
            janitor:Add(conn, "Disconnect")
        end
    else
        local conn = btn.InputBegan:Connect(function(input)
            if input.UserInputType.Name:match("MouseButton") or input.UserInputType == Enum.UserInputType.Touch then
                cb()
            end
        end)
        if janitor then
            janitor:Add(conn, "Disconnect")
        end
    end
end

function AvatarViewUI.new(refs)
    local self = setmetatable({}, AvatarViewUI)
    self.janitor = Janitor.new()
    self.menuFrame = refs.menuFrame
    self.toggleBtn = refs.toggleBtn
    self.closeBtn = refs.closeBtn
    self.inputBox = refs.inputBox
    self.enterBtn = refs.enterBtn
    self.applyBtn = refs.applyBtn

    self.hiddenPos = refs.hiddenPos or UDim2.new(0.5, 0, -0.6, 0)
    self.shownPos = refs.shownPos or UDim2.new(0.5, 0, 0.5, 0)

    self.OnQuery = Signal.new()
    self.OnApply = Signal.new()
    self.OnToggle = Signal.new()
    self.janitor:Add(self.OnQuery, "Destroy")
    self.janitor:Add(self.OnApply, "Destroy")
    self.janitor:Add(self.OnToggle, "Destroy")

    if self.menuFrame then
        self.menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        self.menuFrame.Position = self.hiddenPos
        self.menuFrame.Visible = false
        self.janitor:Add(self.menuFrame, "Destroy")
    end

    if self.toggleBtn then
        connectButton(self.toggleBtn, function()
            self.OnToggle:Fire()
        end, self.janitor)
    end

    if self.closeBtn then
        connectButton(self.closeBtn, function()
            self:hide()
        end, self.janitor)
    end

    if self.enterBtn then
        connectButton(self.enterBtn, function()
            local name = self.inputBox and self.inputBox.Text or ""
            self.OnQuery:Fire(name)
        end, self.janitor)
    end

    if self.inputBox and self.inputBox:IsA("TextBox") then
        local conn = self.inputBox.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local name = self.inputBox.Text or ""
                self.OnQuery:Fire(name)
            end
        end)
        self.janitor:Add(conn, "Disconnect")
    end

    if self.applyBtn then
        connectButton(self.applyBtn, function()
            self.OnApply:Fire()
        end, self.janitor)
    end

    return self
end

function AvatarViewUI:show()
    if not self.menuFrame then
        return
    end
    self.menuFrame.Visible = true
    self.menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    self.menuFrame.Position = self.hiddenPos
    TweenService:Create(self.menuFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = self.shownPos}):Play()
end

function AvatarViewUI:hide()
    if not self.menuFrame then
        return
    end
    local tween = TweenService:Create(self.menuFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = self.hiddenPos})
    self.janitor:Add(tween, "Cancel")
    self.janitor:Add(tween.Completed:Connect(function()
        if self.menuFrame then
            self.menuFrame.Visible = false
        end
    end), "Disconnect")
    tween:Play()
end

function AvatarViewUI:destroy()
    self.janitor:Destroy()
end

return AvatarViewUI
