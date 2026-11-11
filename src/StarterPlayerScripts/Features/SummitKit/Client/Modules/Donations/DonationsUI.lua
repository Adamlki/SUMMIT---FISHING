--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)

local DonationsView = require(script.Parent.DonationsView)
local DonationsResolver = require(script.Parent.DonationsResolver)
local DonationsRenderer = require(script.Parent.DonationsRenderer) :: any
local DonationsBinder = require(script.Parent.DonationsBinder)
local DonationsState = require(script.Parent.DonationsState) :: any
local DonationsSync = require(script.Parent.DonationsSync) :: any

local DonationsUI = {}

local view
local janitor = Janitor.new()
local state = DonationsState.new()
local initialized = false

function DonationsUI.init()
    if initialized then
        return true
    end
    local ok, refsOrErr = DonationsResolver.resolve()
    if not ok then
        warn("[DonationsUI] " .. tostring(refsOrErr))
        return false
    end

    view = DonationsView.new(refsOrErr)
    if not view then
        warn("[DonationsUI] UI structure tidak lengkap; menu tidak diinisialisasi")
        return false
    end
    view:hide()

    DonationsSync.bind(janitor, state, view, DonationsRenderer)

    janitor:Add(DonationsBinder.bind(view, function()
        DonationsRenderer.applyProducts(state, view, state.ignoreSet)
        DonationsRenderer.ensureProducts(state, view, state.ignoreSet)
    end), "Destroy")

    initialized = true
    return true
end

function DonationsUI.destroy()
    if view and view.destroy then
        view:destroy()
    end
    janitor:Destroy()
    initialized = false
end

return DonationsUI
