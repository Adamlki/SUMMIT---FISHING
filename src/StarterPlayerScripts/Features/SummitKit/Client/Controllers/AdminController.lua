--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)
local Janitor = require(Packages.Janitor)

local AdminResolver = require(script.Parent.Parent.Modules.Admin.AdminResolver)
local AdminRuntime = require(script.Parent.Parent.Modules.Admin.AdminRuntime)
local Logger = require(script.Parent.Parent.Modules.Logger)
local TopbarIcon = require(script.Parent.Parent.Modules.TopbarIcon)
local AdminHelpers = script.Parent:WaitForChild("AdminHelpers")
local PermissionResolver = require(AdminHelpers:WaitForChild("PermissionResolver"))
local ResolverBootstrap = require(AdminHelpers:WaitForChild("ResolverBootstrap"))

local Controller = Knit.CreateController({Name = "AdminController"})

local LocalPlayer = Players.LocalPlayer
local log = Logger.new("AdminController", false)

function Controller:KnitStart()
	local janitor = Janitor.new()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui", 60)
	if not playerGui then
		log:error("PlayerGui not found")
		return
	end

	ResolverBootstrap.resolve(AdminResolver, playerGui):andThen(function(refs)
		if refs.Toggle then
			refs.Toggle.Visible = false
		end
		if refs.Root then
			refs.Root.Visible = false
		end
		if refs.Menu then
			refs.Menu.Visible = false
		end
		local adminService = Knit.GetService("AdminService")
		local overheadService = Knit.GetService("OverheadService")
		local runtime
		local adminIcon

		local function applyPermission(canUse)
			if refs.Toggle then
				refs.Toggle.Visible = canUse == true
			end
			if canUse ~= true then
				if adminIcon then
					adminIcon:destroy()
					adminIcon = nil
				end
				if refs.Menu then
					refs.Menu.Visible = false
				end
				if refs.Root then
					refs.Root.Visible = false
				end
				return
			end
			if not runtime then
				local ok, result = pcall(AdminRuntime.new, refs, adminService)
				if not ok then
					warn("[AdminController] AdminRuntime init failed: " .. tostring(result))
					return
				end
				runtime = result
				janitor:Add(runtime, "Destroy")
			end
			if not adminIcon then
				adminIcon = TopbarIcon.create(TopbarIcon.Images.Admin, function()
					runtime:Toggle()
				end)
				if adminIcon then
					janitor:Add(adminIcon, "Destroy")
				end
			end
		end

		local function resolvePermission(config)
			local canUse = PermissionResolver.resolve(adminService, config, LocalPlayer)
			applyPermission(canUse)
		end

		if overheadService and overheadService.Config and overheadService.Config.Observe then
			overheadService.Config:Observe(function(cfg)
				resolvePermission(cfg)
			end)
		else
			local cfg = overheadService and overheadService.Config and overheadService.Config:Get()
			resolvePermission(cfg)
		end
	end):catch(function(err)
		log:warn("Init failed: " .. tostring(err))
	end)
end

return Controller
