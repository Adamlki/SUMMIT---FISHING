--!nonstrict
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)
local Panel = require(script.Parent.Parent.UI.Panel)

local DonationsView = {}
DonationsView.__index = DonationsView

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

local function clearList(listFrame, template)
    for _, child in ipairs(listFrame:GetChildren()) do
        if child ~= template and not child:IsA("UIGridLayout") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") and not child:IsA("UISizeConstraint") then
            child:Destroy()
        end
    end
end

function DonationsView.new(refs)
    local self = setmetatable({}, DonationsView)
    self.janitor = Janitor.new()
    self.menuFrame = refs.menuFrame
    self.listFrame = refs.listFrame
    self.template = refs.template
    self.toggleBtn = refs.toggleBtn
    self.closeBtn = refs.closeBtn

    self.hiddenPos = refs.hiddenPos or UDim2.new(0.5, 0, -0.6, 0)
    self.shownPos = refs.shownPos or UDim2.new(0.5, 0, 0.5, 0)

    if self.menuFrame then
        self.menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        self.menuFrame.Position = self.hiddenPos
        self.menuFrame.Visible = false
        Panel.mount(self.menuFrame, { shown = self.shownPos, hidden = self.hiddenPos })
        self.janitor:Add(self.menuFrame, "Destroy")
    end

    if self.template then
        self.template.Visible = false
    end

    if self.toggleBtn then
        connectButton(self.toggleBtn, function()
            if Panel.isOpen(self.menuFrame) then
                self:hide()
            else
                self:show()
            end
        end, self.janitor)
    end

    if self.closeBtn then
        connectButton(self.closeBtn, function()
            self:hide()
        end, self.janitor)
    end

    return self
end

function DonationsView:show()
    if not self.menuFrame then
        return
    end
    Panel.open(self.menuFrame)
end

function DonationsView:hide()
    if not self.menuFrame then
        return
    end
    Panel.close(self.menuFrame)
end

function DonationsView:setProducts(products)
    if not (self.listFrame and self.template) then
        return
    end

    self.template.Visible = false
    clearList(self.listFrame, self.template)

    for idx, product in ipairs(products or {}) do
        local item = self.template:Clone()
        item.Name = "DonationCard_" .. tostring(product.ProductId or idx)
        item.Visible = true
        item.LayoutOrder = idx
        item.Parent = self.listFrame

        -- 1. Tampilkan teks nominal di TotalRobux
        local totalRobuxLbl = item:FindFirstChild("TotalRobux")
        if totalRobuxLbl and totalRobuxLbl:IsA("TextLabel") then
            if product.Text and product.Text ~= "" then
                totalRobuxLbl.Text = product.Text
            elseif product.Robux then
                totalRobuxLbl.Text = tostring(product.Robux) .. " Robux"
            elseif product.Price then
                totalRobuxLbl.Text = tostring(product.Price) .. " Robux"
            else
                totalRobuxLbl.Text = product.Name or "Donate"
            end
        end

        -- 2. Hubungkan tombol DonateButton
        local btn = item:FindFirstChild("DonateButton") or item:FindFirstChildWhichIsA("GuiButton", true)
        if btn then
            local titleLbl = btn:FindFirstChild("Title")
            if titleLbl and titleLbl:IsA("TextLabel") then
                titleLbl.Text = product.ButtonText or "Buy"
            end

            connectButton(btn, function()
                local player = Players.LocalPlayer
                local pid = tonumber(product.ProductId)
                if player and pid and pid > 0 then
                    MarketplaceService:PromptProductPurchase(player, pid)
                else
                    local robuxText = totalRobuxLbl and totalRobuxLbl.Text or (tostring(product.Robux or "0") .. " Robux")
                    warn("[Donate] ProductId belum diatur untuk " .. robuxText .. ". Silakan atur di ReplicatedStorage.DonationConfig!")
                end
            end, self.janitor)
        end
    end
end

function DonationsView:destroy()
    self.janitor:Destroy()
end

return DonationsView
