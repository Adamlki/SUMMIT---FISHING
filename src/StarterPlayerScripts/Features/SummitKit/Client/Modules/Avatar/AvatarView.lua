--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)
local Signal = require(Packages.Signal)

local AvatarView = {}
AvatarView.__index = AvatarView

local AvatarViewUI = require(script.Parent.AvatarViewUI)
local AvatarPreview = require(script.Parent.AvatarPreview)
local AvatarList = require(script.Parent.AvatarList)

function AvatarView.new(refs)
    local self = setmetatable({}, AvatarView)
    self.janitor = Janitor.new()
    self.listFrame = refs.listFrame
    self.template = refs.template
    self.previewFrame = refs.previewFrame
    self.viewport = self.previewFrame and self.previewFrame:FindFirstChild("ViewportFrame") or nil
    self.onQuery = refs.onQuery
    self.onApply = refs.onApply

    self.ui = AvatarViewUI.new(refs)
    self.preview = AvatarPreview.new(self.viewport)
    self.janitor:Add(self.preview, "destroy")
    self.janitor:Add(self.ui, "destroy")

    self.selected = nil

    self.janitor:Add(self.ui.OnToggle:Connect(function()
        if self.ui:isOpen() then
            self.ui:hide()
        else
            self.ui:show()
        end
    end), "Disconnect")

    self.janitor:Add(self.ui.OnQuery:Connect(function(name)
        if self.onQuery then
            self.onQuery(name)
        end
    end), "Disconnect")

    self.janitor:Add(self.ui.OnApply:Connect(function()
        if self.onApply and self.selected then
            self.onApply(self.selected)
        end
    end), "Disconnect")

    self.OnPreviewLoaded = Signal.new()
    self.janitor:Add(self.OnPreviewLoaded, "Destroy")
    self.janitor:Add(self.preview.OnLoaded:Connect(function(entry, model)
        self.OnPreviewLoaded:Fire(entry, model)
    end), "Disconnect")

    return self
end

function AvatarView:setPreview(entry)
    self.selected = entry
    if self.previewFrame then
        local btn = self.previewFrame:FindFirstChild("ButtonsApply") or self.previewFrame:FindFirstChild("Buttons")
        if btn then
            local title = btn:FindFirstChild("Title", true)
            if title and title:IsA("TextLabel") then
                title.Text = (entry and entry.isReset) and "Reset" or "Apply"
            elseif btn:IsA("TextButton") then
                btn.Text = (entry and entry.isReset) and "Reset" or "Apply"
            end
        end
    end
    self.preview:load(entry)
end

function AvatarView:show()
    if self.ui then
        self.ui:show()
    end
end

function AvatarView:hide()
    if self.ui then
        self.ui:hide()
    end
end

function AvatarView:setList(entries)
    AvatarList.render(self.listFrame, self.template, entries, function(entry)
        self:setPreview(entry)
    end, self.janitor)
end

function AvatarView:destroy()
    if self.preview then
        self.preview:destroy()
    end
    self.janitor:Destroy()
end

return AvatarView
