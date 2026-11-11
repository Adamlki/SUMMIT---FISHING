--!nonstrict
-- ==============================================================================
-- PlayerTitleServer
-- Menangani pembuatan title kustom teks (kuota 2x/24h, min 1 summit) & title gambar
-- Terintegrasi dengan ProfileStore OverheadCustomTitles, Knit OverheadService & Admin
-- ==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local MarketplaceService = game:GetService("MarketplaceService")
local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = Shared:WaitForChild("Packages")
local Knit = require(Packages:WaitForChild("Knit"))

local ImageTitleConfig = require(Shared:WaitForChild("Config"):WaitForChild("CustomTitle"):WaitForChild("ImageTitleConfig"))
local RoleConfig = require(ReplicatedStorage:WaitForChild("RoleConfig"))

local CustomTitleRemotes = ReplicatedStorage:WaitForChild("CustomTitleRemotes")
local GetTitleDataRF = CustomTitleRemotes:WaitForChild("GetTitleData")
local SetTitleRF = CustomTitleRemotes:WaitForChild("SetTitle")
local ClearSlotRF = CustomTitleRemotes:WaitForChild("ClearSlot")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")

local OverheadService = nil

-- Tunggu OverheadService aktif melalui Knit
task.spawn(function()
    Knit.OnStart():await()
    OverheadService = Knit.GetService("OverheadService")
end)

local function checkSlotUnlocked(player, slot, summit, fishCount)
    local slotReq = ImageTitleConfig.SlotMilestones[slot]
    if not slotReq then return true, "" end

    if slotReq.UnlockType == "Summit" then
        local req = slotReq.ReqSummit or 0
        if summit < req then
            return false, string.format("Butuh %s (Saat ini: %d Summit)", slotReq.Label, summit)
        end
    elseif slotReq.UnlockType == "FishCount" then
        local req = slotReq.ReqFishCount or 0
        if fishCount < req then
            return false, string.format("Butuh %s (Saat ini: %d Mancing)", slotReq.Label, fishCount)
        end
    elseif slotReq.UnlockType == "Group" then
        local ok, inGroup = pcall(function()
            return player:IsInGroup(slotReq.GroupId or 352750447)
        end)
        if not (ok and inGroup) then
            return false, slotReq.Reason or "Wajib Join Komunitas Roblox & Like Map"
        end
    end
    return true, ""
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Helper Functions
-- ──────────────────────────────────────────────────────────────────────────────

local function getOverheadProfile(player)
    if not OverheadService or not OverheadService.profiles then
        return nil
    end
    return OverheadService.profiles[player]
end

local function getPlayerSummit(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    local summit = leaderstats and leaderstats:FindFirstChild("Summit")
    if summit and summit:IsA("IntValue") then
        return summit.Value
    end
    return 0
end

local function getPlayerFishCount(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    local tangkapan = leaderstats and leaderstats:FindFirstChild("Tangkapan")
    if tangkapan and tangkapan:IsA("IntValue") then
        return tangkapan.Value
    end
    local bindable = FishingSystem:FindFirstChild("GetFishIndexBindable")
    if bindable then
        local ok, data = pcall(function()
            return bindable:Invoke(player)
        end)
        if ok and type(data) == "table" then
            local count = 0
            for _ in pairs(data) do
                count += 1
            end
            return count
        end
    end
    return 0
end

local function getPlayerVip(player)
    if player:GetAttribute("VIP") == true then
        return true
    end
    local ok, owns = pcall(function()
        return MarketplaceService:UserOwnsGamePassAsync(player.UserId, 1874479701)
    end)
    return ok and owns == true
end

local function getPlayerQuota(profile)
    local now = os.time()
    profile.Data.titleQuota = profile.Data.titleQuota or {}
    local quota = profile.Data.titleQuota
    if not quota.resetTime or now >= quota.resetTime then
        quota.count = 0
        quota.resetTime = now + 86400
    end
    return quota
end

local function filterText(player, text)
    if not text or text == "" then return "" end
    local ok, res = pcall(function()
        local obj = TextService:FilterStringAsync(text, player.UserId)
        return obj:GetNonChatStringForBroadcastAsync()
    end)
    if ok and res then
        return res
    end
    return ""
end

local function encodeColors(colors)
    if not colors or #colors == 0 then return "" end
    local parts = {}
    for _, c in ipairs(colors) do
        local r = math.round(c.R * 255)
        local g = math.round(c.G * 255)
        local b = math.round(c.B * 255)
        table.insert(parts, string.format("%d,%d,%d", r, g, b))
    end
    return table.concat(parts, ";")
end

local function sanitizeColor(c)
    if typeof(c) == "Color3" then
        return c
    elseif typeof(c) == "table" then
        local r = c.r or c.R or c[1] or 255
        local g = c.g or c.G or c[2] or 255
        local b = c.b or c.B or c[3] or 255
        if r <= 1 and g <= 1 and b <= 1 and (r > 0 or g > 0 or b > 0) then
            return Color3.new(r, g, b)
        end
        return Color3.fromRGB(math.clamp(r, 0, 255), math.clamp(g, 0, 255), math.clamp(b, 0, 255))
    end
    return Color3.fromRGB(255, 255, 255)
end

local function checkImageUnlocked(player, entry, summit, fishCount, hasVip)
    if entry.UnlockType == "Group" then
        local ok, inGroup = pcall(function()
            return player:IsInGroup(entry.GroupId or 352750447)
        end)
        return ok and inGroup == true
    elseif entry.UnlockType == "Summit" then
        return summit >= (entry.ReqSummit or 0)
    elseif entry.UnlockType == "FishIndex" or entry.UnlockType == "FishCount" then
        return fishCount >= (entry.ReqFishCount or 0)
    elseif entry.UnlockType == "VIP" then
        return hasVip == true
    elseif entry.UnlockType == "Free" then
        return true
    end
    return false
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Remote Functions
-- ──────────────────────────────────────────────────────────────────────────────

local function getTitleData(player)
    local waited = 0
    while not getOverheadProfile(player) and waited < 10 do
        task.wait(0.5)
        waited += 0.5
    end

    local profile = getOverheadProfile(player)
    local summit = getPlayerSummit(player)
    local fishCount = getPlayerFishCount(player)
    local hasVip = getPlayerVip(player)
    local isAdmin = RoleConfig.IsAdmin(player)

    local quota = profile and getPlayerQuota(profile) or { count = 0, resetTime = os.time() + 86400 }
    local remaining = math.max(0, 2 - (quota.count or 0))
    local cooldown = math.max(0, (quota.resetTime or 0) - os.time())

    local slots = {}
    if profile and profile.Data and profile.Data.customTitles then
        for i = 1, 6 do
            local item = profile.Data.customTitles[i]
            if item then
                slots[i] = item
            end
        end
    end

    local imageUnlockStatus = {}
    for _, img in ipairs(ImageTitleConfig.ImageTitles) do
        imageUnlockStatus[img.Id] = checkImageUnlocked(player, img, summit, fishCount, hasVip) or isAdmin
    end

    local slotUnlockStatus = {}
    for i = 1, 6 do
        local isUnlocked, reason = checkSlotUnlocked(player, i, summit, fishCount)
        slotUnlockStatus[i] = {
            Unlocked = isUnlocked or isAdmin,
            Reason = reason,
        }
    end

    return {
        Success = true,
        Summit = summit,
        FishCount = fishCount,
        HasVip = hasVip,
        IsAdmin = isAdmin,
        ActiveSlot = profile and profile.Data and profile.Data.activeSlot or 1,
        Slots = slots,
        Quota = {
            Remaining = remaining,
            Total = 2,
            ResetTime = quota.resetTime,
            CooldownSeconds = cooldown,
        },
        ImageUnlocks = imageUnlockStatus,
        SlotUnlocks = slotUnlockStatus,
    }
end

local function setTitleSlot(player, slot, titleType, payload, targetUserId)
    slot = tonumber(slot)
    if not slot or slot < 1 or slot > 6 then
        return { Success = false, Message = "Slot title tidak valid (1-6)!" }
    end

    -- Validasi: Slot 1-3 khusus Text, Slot 4-6 khusus Image
    if slot >= 1 and slot <= 3 then
        if titleType ~= "Text" then
            return { Success = false, Message = "Slot 1–3 khusus untuk Title Teks!" }
        end
    elseif slot >= 4 and slot <= 6 then
        if titleType ~= "Image" then
            return { Success = false, Message = "Slot 4–6 khusus untuk Title Gambar!" }
        end
    end

    local isCallerAdmin = RoleConfig.IsAdmin(player)
    local targetPlayer = player
    if targetUserId and targetUserId ~= player.UserId then
        if not isCallerAdmin then
            return { Success = false, Message = "Hanya Admin yang dapat mengubah title pemain lain!" }
        end
        targetPlayer = Players:GetPlayerByUserId(targetUserId)
        if not targetPlayer then
            return { Success = false, Message = "Pemain target sedang offline!" }
        end
    end

    local profile = getOverheadProfile(targetPlayer)
    if not profile then
        return { Success = false, Message = "Profil data pemain belum siap. Coba beberapa saat lagi!" }
    end

    local summit = getPlayerSummit(targetPlayer)
    local fishCount = getPlayerFishCount(targetPlayer)
    local hasVip = getPlayerVip(targetPlayer)

    -- Cek syarat slot baris (1 = 3 summit, 2 = 1.000 summit, dst.)
    if not isCallerAdmin then
        local unlocked, reason = checkSlotUnlocked(targetPlayer, slot, summit, fishCount)
        if not unlocked then
            return { Success = false, Message = string.format("Slot %d terkunci! %s", slot, reason) }
        end
    end

    if titleType == "Text" then
        if not isCallerAdmin then
            if summit < ImageTitleConfig.TextRules.MinSummit then
                return { Success = false, Message = string.format("Minimal %d Summit untuk membuat Title Teks kustom!", ImageTitleConfig.TextRules.MinSummit) }
            end

            local quota = getPlayerQuota(profile)
            if quota.count >= ImageTitleConfig.TextRules.DailyQuota and os.time() < quota.resetTime then
                local remainingSec = quota.resetTime - os.time()
                local hours = math.floor(remainingSec / 3600)
                local mins = math.floor((remainingSec % 3600) / 60)
                return {
                    Success = false,
                    Message = string.format("Batas pembuatan title kustom 2x per hari tercapai! Tunggu %d jam %d menit.", hours, mins),
                    Cooldown = remainingSec,
                }
            end
        end

        local rawText = payload and (payload.Text or payload.text) or ""
        rawText = tostring(rawText)
        if #rawText == 0 then
            return { Success = false, Message = "Teks title tidak boleh kosong!" }
        end
        if #rawText > ImageTitleConfig.TextRules.MaxLength then
            rawText = string.sub(rawText, 1, ImageTitleConfig.TextRules.MaxLength)
        end

        local cleanText = filterText(player, rawText)
        if #cleanText == 0 then
            return { Success = false, Message = "Teks tidak lolos filter sensor Roblox!" }
        end

        local mode = payload and (payload.Mode or payload.mode) or "Rainbow Flow"
        local rawColors = payload and (payload.Colors or payload.colors) or {}
        local colors = {}
        for _, c in ipairs(rawColors) do
            table.insert(colors, sanitizeColor(c))
        end
        if #colors == 0 then
            table.insert(colors, Color3.fromRGB(255, 255, 255))
        end

        local textColor = colors[1]
        local gradientStr = encodeColors(colors)

        -- Simpan ke Profile
        profile.Data.customTitles = profile.Data.customTitles or {}
        profile.Data.customTitles[slot] = {
            titleType = "Text",
            text = cleanText,
            textColor = { r = math.round(textColor.R * 255), g = math.round(textColor.G * 255), b = math.round(textColor.B * 255) },
            mode = mode,
            gradientStr = gradientStr,
        }
        profile.Data.activeSlot = slot

        -- Potong kuota (jika bukan admin)
        if not isCallerAdmin then
            local quota = getPlayerQuota(profile)
            quota.count += 1
        end

        -- Update atribut pemain (menghapus imageId)
        targetPlayer:SetAttribute("CustomTitleImage_" .. slot, nil)
        targetPlayer:SetAttribute("CustomTitleText_" .. slot, cleanText)
        targetPlayer:SetAttribute("CustomTitleTextColor_" .. slot, textColor)
        targetPlayer:SetAttribute("CustomTitleMode_" .. slot, mode)
        targetPlayer:SetAttribute("CustomTitleTextGradient_" .. slot, gradientStr)
        targetPlayer:SetAttribute("CustomTitleSlot", slot)

        return { Success = true, Message = string.format("Title Baris %d berhasil disimpan!", slot) }

    elseif titleType == "Image" then
        local imageKey = payload and (payload.ImageKey or payload.imageKey or payload.Id or payload.id)
        local foundEntry = nil
        for _, entry in ipairs(ImageTitleConfig.ImageTitles) do
            if entry.Id == imageKey then
                foundEntry = entry
                break
            end
        end

        if not foundEntry then
            return { Success = false, Message = "Title Gambar tidak ditemukan di daftar!" }
        end

        if not isCallerAdmin then
            local unlocked = checkImageUnlocked(targetPlayer, foundEntry, summit, fishCount, hasVip)
            if not unlocked then
                return { Success = false, Message = string.format("Title Gambar ini belum terbuka! Syarat: %s", foundEntry.Description) }
            end
        end

        -- Simpan ke Profile
        profile.Data.customTitles = profile.Data.customTitles or {}
        profile.Data.customTitles[slot] = {
            titleType = "Image",
            imageId = foundEntry.ImageId,
            imageKey = foundEntry.Id,
        }
        profile.Data.activeSlot = slot

        -- Update atribut pemain (menghapus text)
        targetPlayer:SetAttribute("CustomTitleText_" .. slot, nil)
        targetPlayer:SetAttribute("CustomTitleTextColor_" .. slot, nil)
        targetPlayer:SetAttribute("CustomTitleMode_" .. slot, nil)
        targetPlayer:SetAttribute("CustomTitleTextGradient_" .. slot, nil)
        targetPlayer:SetAttribute("CustomTitleImage_" .. slot, foundEntry.ImageId)
        targetPlayer:SetAttribute("CustomTitleSlot", slot)

        return { Success = true, Message = string.format("Title Gambar Baris %d berhasil dipasang!", slot) }
    else
        return { Success = false, Message = "Tipe title tidak dikenal!" }
    end
end

local function clearTitleSlot(player, slot, targetUserId)
    slot = tonumber(slot)
    if not slot or slot < 1 or slot > 6 then
        return { Success = false, Message = "Slot baris tidak valid (1-6)!" }
    end

    local isCallerAdmin = RoleConfig.IsAdmin(player)
    local targetPlayer = player
    if targetUserId and targetUserId ~= player.UserId then
        if not isCallerAdmin then
            return { Success = false, Message = "Hanya Admin yang dapat menghapus title pemain lain!" }
        end
        targetPlayer = Players:GetPlayerByUserId(targetUserId)
        if not targetPlayer then
            return { Success = false, Message = "Pemain target sedang offline!" }
        end
    end

    local profile = getOverheadProfile(targetPlayer)
    if profile and profile.Data and profile.Data.customTitles then
        profile.Data.customTitles[slot] = nil
    end

    targetPlayer:SetAttribute("CustomTitleText_" .. slot, nil)
    targetPlayer:SetAttribute("CustomTitleTextColor_" .. slot, nil)
    targetPlayer:SetAttribute("CustomTitleMode_" .. slot, nil)
    targetPlayer:SetAttribute("CustomTitleTextGradient_" .. slot, nil)
    targetPlayer:SetAttribute("CustomTitleImage_" .. slot, nil)

    return { Success = true, Message = string.format("Title Baris %d berhasil dihapus!", slot) }
end

-- ──────────────────────────────────────────────────────────────────────────────
-- Dual-Stack Legacy Remotes
-- ──────────────────────────────────────────────────────────────────────────────

GetTitleDataRF.OnServerInvoke = function(player)
    return getTitleData(player)
end

SetTitleRF.OnServerInvoke = function(player, slot, titleType, payload, targetUserId)
    return setTitleSlot(player, slot, titleType, payload, targetUserId)
end

ClearSlotRF.OnServerInvoke = function(player, slot, targetUserId)
    return clearTitleSlot(player, slot, targetUserId)
end

-- ──────────────────────────────────────────────────────────────────────────────
-- REST Routes (Network Gateway)
-- ──────────────────────────────────────────────────────────────────────────────

NetworkGateway:RegisterRoute("GET", "/title/data", function(player)
    local data = getTitleData(player)
    return {
        Success = true,
        StatusCode = 200,
        Data = data,
        Message = "Title data loaded.",
    }
end, { rateLimitSeconds = 1 })

NetworkGateway:RegisterRoute("PUT", "/title/set-slot", function(player, payload)
    if type(payload) ~= "table" then
        return { Success = false, StatusCode = 400, Message = "Payload must be a table." }
    end
    if payload.TargetUserId ~= nil and type(payload.TargetUserId) ~= "number" then
        return { Success = false, StatusCode = 400, Message = "TargetUserId must be a number." }
    end

    local result = setTitleSlot(player, payload.Slot, payload.TitleType, payload.Payload, payload.TargetUserId)
    return {
        Success = result.Success == true,
        StatusCode = result.Success and 200 or 400,
        Data = result,
        Message = result.Message,
    }
end, { rateLimitSeconds = 1 })

NetworkGateway:RegisterRoute("DELETE", "/title/clear-slot", function(player, payload)
    if type(payload) ~= "table" then
        return { Success = false, StatusCode = 400, Message = "Payload must be a table." }
    end
    if payload.TargetUserId ~= nil and type(payload.TargetUserId) ~= "number" then
        return { Success = false, StatusCode = 400, Message = "TargetUserId must be a number." }
    end

    local result = clearTitleSlot(player, payload.Slot, payload.TargetUserId)
    return {
        Success = result.Success == true,
        StatusCode = result.Success and 200 or 400,
        Data = result,
        Message = result.Message,
    }
end, { rateLimitSeconds = 1 })

-- ──────────────────────────────────────────────────────────────────────────────
-- Reconcile Profile on Join (Image Titles sync)
-- ──────────────────────────────────────────────────────────────────────────────

local function handlePlayerAdded(player)
    task.spawn(function()
        local LocalizationService = game:GetService("LocalizationService")
        local success, code = pcall(function()
            return LocalizationService:GetCountryRegionForPlayerAsync(player)
        end)
        if success and code and typeof(code) == "string" and code ~= "" then
            player:SetAttribute("CountryCode", string.upper(code))
        else
            player:SetAttribute("CountryCode", "UNKNOWN")
        end
    end)

    local waited = 0
    while not getOverheadProfile(player) and waited < 15 do
        task.wait(0.5)
        waited += 0.5
    end

    local profile = getOverheadProfile(player)
    if not profile or not profile.Data or not profile.Data.customTitles then
        return
    end

    for i = 1, 6 do
        local entry = profile.Data.customTitles[i]
        if entry then
            if entry.titleType == "Image" and entry.imageId and entry.imageId ~= "" then
                player:SetAttribute("CustomTitleImage_" .. i, entry.imageId)
                player:SetAttribute("CustomTitleText_" .. i, nil)
                player:SetAttribute("CustomTitleTextColor_" .. i, nil)
                player:SetAttribute("CustomTitleMode_" .. i, nil)
                player:SetAttribute("CustomTitleTextGradient_" .. i, nil)
            elseif entry.titleType == "Text" and entry.text and entry.text ~= "" then
                player:SetAttribute("CustomTitleImage_" .. i, nil)
                player:SetAttribute("CustomTitleText_" .. i, entry.text)
                local tc = entry.textColor
                if tc then
                    player:SetAttribute("CustomTitleTextColor_" .. i, Color3.fromRGB(tc.r or 255, tc.g or 255, tc.b or 255))
                end
                player:SetAttribute("CustomTitleMode_" .. i, entry.mode or "Rainbow Flow")
                player:SetAttribute("CustomTitleTextGradient_" .. i, entry.gradientStr or "")
            end
        end
    end
end

Players.PlayerAdded:Connect(handlePlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
    task.spawn(handlePlayerAdded, p)
end

print("[PlayerTitleServer] ✅ Player Title Server initialized successfully!")
