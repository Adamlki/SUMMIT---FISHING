--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)

local PermissionResolver = require(script.Parent.Parent.Parent.Controllers.AdminHelpers.PermissionResolver)

local RaceClientPermission = {}

local function getServices()
    local adminService = Knit.GetService("AdminService")
    local overheadService = Knit.GetService("OverheadService")
    return adminService, overheadService
end

function RaceClientPermission.canUseRaceAdmin()
    local adminService, overheadService = getServices()
    local ok, canUse = pcall(function()
        if adminService and adminService.IsAdminOnly then
            return adminService:IsAdminOnly()
        end
        return false
    end)
    if ok and canUse == true then
        return true
    end

    local config = overheadService and overheadService.Config and overheadService.Config.Get and overheadService.Config:Get() or nil
    return PermissionResolver.resolve(adminService, config, Players.LocalPlayer)
end

function RaceClientPermission.canSeeRaceOverhead()
    return RaceClientPermission.canUseRaceAdmin()
end

return RaceClientPermission
