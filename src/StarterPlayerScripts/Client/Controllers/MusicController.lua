--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Knit = require(Packages.Knit)
local Janitor = require(Packages.Janitor)
local Promise = require(Packages.Promise)

local MusicResolver = require(script.Parent.Parent.Modules.Music.MusicResolver)
local MusicRuntime = require(script.Parent.Parent.Modules.Music.MusicRuntime)
local Logger = require(script.Parent.Parent.Modules.Logger)

local Controller = Knit.CreateController({Name = "MusicController"})

local LocalPlayer = Players.LocalPlayer
local log = Logger.new("MusicController", false)

function Controller:KnitStart()
	local janitor = Janitor.new()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui", 30)
	if not playerGui then
		warn("[MusicController] PlayerGui not found")
		return
	end

	Promise.new(function(resolve, reject)
		local refsOrErr
		for attempt = 1, 10 do
			local ok, res = MusicResolver.Resolve(playerGui)
			if ok then
				refsOrErr = res
				break
			end
			task.wait(1)
		end
		if not refsOrErr then
			reject("MusicResolver failed after 10 attempts")
			return
		end
		resolve(refsOrErr)
	end):andThen(function(refs)
		local dataFolder = Shared:WaitForChild("Data", 10)
		local musicDataModule = dataFolder and dataFolder:WaitForChild("MusicData", 10)
		if not musicDataModule then
			warn("[MusicController] Shared/Data/MusicData not found")
			return
		end

		local musicData = require(musicDataModule)
		local runtime = MusicRuntime.new(refs, musicData)
		self._runtime = runtime
		_G.ActiveMusicRuntime = runtime
		janitor:Add(runtime, "Destroy")

		-- Check if player already picked a category in ReplicatedFirst loading screen
		local initialCat = LocalPlayer:GetAttribute("InitialMusicCategory")
		if initialCat and initialCat ~= "None" then
			runtime:switchCategory(initialCat, 1)
		end

		janitor:Add(LocalPlayer:GetAttributeChangedSignal("InitialMusicCategory"):Connect(function()
			local cat = LocalPlayer:GetAttribute("InitialMusicCategory")
			if cat and cat ~= "None" then
				runtime:switchCategory(cat, 1)
			end
		end), "Disconnect")

		janitor:Add(LocalPlayer.CharacterAdded:Connect(function()
			runtime:OnCharacterAdded()
		end), "Disconnect")
		print("[MusicController] ✅ Music runtime initialized successfully!")
	end):catch(function(err)
		warn("[MusicController] Init failed: " .. tostring(err))
	end)
end

--- Plays a specific music category (e.g. "Indo", "Jawa", "Inggris")
function Controller:PlayCategory(categoryKey: string, songIndex: number?)
	if self._runtime then
		self._runtime:switchCategory(categoryKey, songIndex or 1)
	elseif _G.ActiveMusicRuntime then
		_G.ActiveMusicRuntime:switchCategory(categoryKey, songIndex or 1)
	end
end

--- Retrieves the active runtime instance
function Controller:GetRuntime()
	return self._runtime or _G.ActiveMusicRuntime
end

return Controller
