--!nonstrict
local _Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)
local Janitor = require(Packages.Janitor)

local AvatarUIData = require(script.Parent.AvatarUIData)
local Logger = require(script.Parent.Parent.Logger)
local AvatarNotification = require(script.Parent.Parent.Notifications.AvatarNotification)
local AvatarUIHelpers = script.Parent:WaitForChild("AvatarUIHelpers")
local AvatarViewBuilder = require(AvatarUIHelpers:WaitForChild("AvatarViewBuilder"))

local AvatarUI = {}

local function notifyAvatarError(message)
    AvatarNotification.error(message, 2.5)
end

local view
local entries = {}
local resetEntry
local avatarService
local _currentConfig
local log = Logger.new("AvatarUI", false)
local janitor = Janitor.new()
local initialized = false

local function replaceEntries(nextEntries)
    table.clear(entries)
    for _, entry in ipairs(nextEntries or {}) do
        table.insert(entries, entry)
    end
end

local function refreshList()
    if not view then
        return
    end
    view:setList(entries)
    if resetEntry then
        view:setPreview(resetEntry)
    elseif entries[1] then
        view:setPreview(entries[1])
    end
    log:info(string.format("loaded %d avatar entries", #entries))
end

local function applyConfig(cfg)
    log = Logger.new("AvatarUI", cfg and cfg.LogEnabled)
    _currentConfig = cfg

    local buildEntries, buildResetEntry = AvatarUIData.buildEntries(cfg)
    replaceEntries(buildEntries)
    resetEntry = buildResetEntry
    refreshList()
    -- JANGAN PERNAH panggil view:hide() di sini!
    -- Menghapus bug auto-close agar menu tetap terbuka saat pemain sedang melihatnya.
end

local function ensureView()
    local ok, resolvedView = AvatarViewBuilder.ensureView({
        view = view,
        avatarService = avatarService,
        entries = entries,
        log = log,
        notifyAvatarError = notifyAvatarError,
        refreshList = refreshList,
    })
    if ok and resolvedView and not view then
        view = resolvedView
    end
    return ok
end

function AvatarUI.init()
    if initialized then
        return true
    end
    avatarService = Knit.GetService("AvatarService")
    if not ensureView() then
        return false
    end

    -- Siapkan kartu Reset terlebih dahulu secara instan
    local _, defaultResetEntry = AvatarUIData.buildEntries(nil)
    if defaultResetEntry then
        resetEntry = defaultResetEntry
        replaceEntries({ resetEntry })
        refreshList()
    end

    janitor:Add(avatarService:GetConfig():andThen(function(cfg)
        applyConfig(cfg)
    end):catch(function(err)
        warn("[AvatarUI] gagal ambil config: " .. tostring(err))
    end), "cancel")

    initialized = true
    return true
end

function AvatarUI.destroy()
    if view and view.destroy then
        view:destroy()
    end
    janitor:Destroy()
    initialized = false
end

return AvatarUI
