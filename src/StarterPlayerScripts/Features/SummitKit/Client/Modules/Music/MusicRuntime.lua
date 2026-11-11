--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)
local Logger = require(script.Parent.Parent.Logger)
local MusicInput = require(script.Parent.MusicInput)
local MusicAnimator = require(script.Parent.MusicAnimator)
local MusicListRenderer = require(script.Parent.MusicListRenderer)
local MusicPlayback = require(script.Parent.MusicPlayback)
local RuntimeHelpers = script.Parent:WaitForChild("RuntimeHelpers")
local MusicDisplay = require(RuntimeHelpers:WaitForChild("MusicDisplay"))
local MusicMenuBinder = require(RuntimeHelpers:WaitForChild("MusicMenuBinder"))
local MusicPlaybackBinder = require(RuntimeHelpers:WaitForChild("MusicPlaybackBinder"))

local MusicRuntime = {}
MusicRuntime.__index = MusicRuntime

local _log = Logger.new("MusicRuntime", false)

function MusicRuntime.new(refs, musicData)
	local self = setmetatable({}, MusicRuntime)
	self._janitor = Janitor.new()
	self._refs = refs
	self._musicData = musicData or {}
	self._activeCategory = "Indo"

	local categories = self._musicData.Categories or {}
	local initialCat = categories["Indo"] or (categories[next(categories)])
	self._data = initialCat and initialCat.Songs or {}

	self._isDragging = false
	self._volume = 100
	self._animator = MusicAnimator.new(refs.Menu)
	self._playback = MusicPlayback.new()

	self:_bindUI()
	self:_updateTabVisuals()
	self:_populateList()
	self:_setVolume(100)
	self:_updateDisplay()
	self:_updateProgressBar()
	MusicDisplay.updatePlayPauseIcon(self)

	-- Store globally for Intro screen and other controllers
	_G.ActiveMusicRuntime = self

	return self
end

function MusicRuntime:_updateTabVisuals()
	local refs = self._refs
	local tabs = {
		Indo = refs.IndonesiaBtn,
		Jawa = refs.JawaBtn,
		Inggris = refs.EnglishBtn,
	}

	for key, btn in pairs(tabs) do
		if btn then
			local isActive = (key == self._activeCategory)
			local stroke = btn:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = isActive and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(0, 0, 0)
				stroke.Thickness = isActive and 2 or 1
			end
		end
	end
end

function MusicRuntime:switchCategory(catKey: string, autoPlaySongIndex: number?)
	local categories = self._musicData.Categories or {}
	local catData = categories[catKey]
	if not catData then return end

	self._activeCategory = catKey
	self._data = catData.Songs or {}

	self:_updateTabVisuals()
	self:_populateList()

	if autoPlaySongIndex and self._data[autoPlaySongIndex] then
		self:_loadSong(autoPlaySongIndex, true)
	end
end

function MusicRuntime:_updateDisplay()
	MusicDisplay.updateDisplay(self)
end

function MusicRuntime:_updateProgressBar()
	MusicDisplay.updateProgressBar(self)
end

function MusicRuntime:_setVolume(val)
	MusicDisplay.setVolume(self, val)
end

function MusicRuntime:_getNextIndex()
	return self._playback:getNextIndex(#self._data)
end

function MusicRuntime:_getPrevIndex()
	return self._playback:getPrevIndex(#self._data)
end

function MusicRuntime:_loadSong(index, autoPlay)
	if not self._data[index] then
		return
	end
	self._playback:loadSong(self._data, index, autoPlay)
	self._currentIndex = self._playback:getIndex()
	self:_updateDisplay()
	self:_updateProgressBar()
	MusicDisplay.updatePlayPauseIcon(self)
end

function MusicRuntime:_populateList()
	local list = self._refs.MusicListFrame
	local template = self._refs.Template
	if not list or not template then
		return
	end
	local categories = self._musicData.Categories or {}
	local catData = categories[self._activeCategory]
	local catName = catData and catData.Name or self._activeCategory
	local catIcon = catData and catData.Icon or ""

	MusicListRenderer.render(list, template, self._data, catName, catIcon, function(i)
		self:_loadSong(i, true)
	end, self._janitor)
end

function MusicRuntime:_bindUI()
	MusicMenuBinder.bind(self)
	MusicPlaybackBinder.bind(self)
end

function MusicRuntime:_openMenu()
	local conn = self._animator:Open()
	if conn then
		self._janitor:Add(conn, "Disconnect")
	end
end

function MusicRuntime:_closeMenu()
	local conn = self._animator:Close()
	if conn then
		self._janitor:Add(conn, "Disconnect")
	end
end

function MusicRuntime:_onVolumeDrag()
	local bar = self._refs.VolumeBar
	if not bar then return end
	local barPos = bar.AbsolutePosition
	local barSize = bar.AbsoluteSize
	if barSize.X <= 0 then return end
	local mouseX = MusicInput.getPointerX()
	local relativeX = math.clamp(mouseX - barPos.X, 0, barSize.X)
	self:_setVolume(math.round((relativeX / barSize.X) * 100))
end

function MusicRuntime:OnCharacterAdded()
end

function MusicRuntime:Destroy()
	self._playback:stopAndDestroy()
	if self._janitor then
		self._janitor:Destroy()
		self._janitor = nil
	end
	if _G.ActiveMusicRuntime == self then
		_G.ActiveMusicRuntime = nil
	end
end

return MusicRuntime
