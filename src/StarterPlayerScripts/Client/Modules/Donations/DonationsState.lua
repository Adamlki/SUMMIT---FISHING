--!nonstrict
local DonationsState = {}
DonationsState.__index = DonationsState

function DonationsState.new()
    local self = setmetatable({}, DonationsState)
    self.loaded = false
    self.loading = false
    self.ignoreSet = nil
    self.needsRefresh = false
    self.products = nil
    self.vipGiftId = nil
    self.toolGiftIds = {}
    return self
end

local function buildIgnoreSet(state)
    local nextIgnore = {}

    local vipGiftId = tonumber(state.vipGiftId)
    if vipGiftId and vipGiftId > 0 then
        nextIgnore[vipGiftId] = true
        nextIgnore[tostring(vipGiftId)] = true
    end

    for _, giftProductId in ipairs(state.toolGiftIds or {}) do
        local numericId = tonumber(giftProductId)
        if numericId and numericId > 0 then
            nextIgnore[numericId] = true
            nextIgnore[tostring(numericId)] = true
        end
    end

    return nextIgnore
end

local function didIgnoreSetChange(current, nextIgnore)
    for key in pairs(current or {}) do
        if not nextIgnore[key] then
            return true
        end
    end

    for key in pairs(nextIgnore) do
        if not (current and current[key]) then
            return true
        end
    end

    return false
end

function DonationsState:RefreshIgnoreSet()
    local nextIgnore = buildIgnoreSet(self)
    local changed = didIgnoreSetChange(self.ignoreSet, nextIgnore)

    if changed then
        self.ignoreSet = nextIgnore
        if self.loading then
            self.needsRefresh = true
        else
            self.loaded = false
        end
    end

    return nextIgnore
end

function DonationsState:ApplyVipConfig(cfg)
    self.vipGiftId = cfg and cfg.GiftProductId or nil
end

function DonationsState:ApplyShopCatalog(catalog)
    local toolGiftIds = {}
    for _, entry in ipairs(catalog or {}) do
        local giftProductId = tonumber(entry.GiftProductId)
        if giftProductId and giftProductId > 0 then
            table.insert(toolGiftIds, giftProductId)
        end
    end

    self.toolGiftIds = toolGiftIds
end

return DonationsState
