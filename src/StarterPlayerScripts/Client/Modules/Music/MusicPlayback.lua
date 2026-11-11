--!strict
-- MusicPlayback: High-Fidelity Client-Side Audio Engine with Studio DSP Mastering Chain
local SoundService = game:GetService("SoundService")

local Playback = {}
Playback.__index = Playback

-- Initialize or retrieve the Studio Mastering SoundGroup
local function getMusicSoundGroup(): SoundGroup
	local group = SoundService:FindFirstChild("MusicMaster") :: SoundGroup?
	if not group then
		group = Instance.new("SoundGroup")
		group.Name = "MusicMaster"
		group.Volume = 0.8
		group.Parent = SoundService

		-- 1. Studio Mastering Compressor: Prevents audio distortion / clipping ("pecah")
		local comp = Instance.new("CompressorSoundEffect")
		comp.Name = "StudioCompressor"
		comp.Threshold = -14
		comp.Ratio = 4
		comp.Attack = 0.05
		comp.Release = 0.2
		comp.Priority = 1
		comp.Parent = group

		-- 2. Equalizer: Warm bass body, smooth mids, gentle roll-off of harsh highs (anti-cempreng)
		local eq = Instance.new("EqualizerSoundEffect")
		eq.Name = "StudioEqualizer"
		eq.LowGain = 2.5
		eq.MidGain = 0.0
		eq.HighGain = -2.5
		eq.Priority = 2
		eq.Parent = group

		-- 3. Subtle Room Acoustics: Natural, comfortable soundstage presence
		local reverb = Instance.new("ReverbSoundEffect")
		reverb.Name = "StudioReverb"
		reverb.DecayTime = 1.0
		reverb.Density = 0.7
		reverb.Diffusion = 0.7
		reverb.WetLevel = -18
		reverb.Priority = 3
		reverb.Parent = group
	end
	return group
end

function Playback.new()
	local self = setmetatable({}, Playback)
	local soundGroup = getMusicSoundGroup()

	local sound = Instance.new("Sound")
	sound.Name = "ClientMusicTrack"
	sound.SoundGroup = soundGroup
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.Volume = 0.5
	sound.Looped = false
	sound.Parent = SoundService

	self._sound = sound
	self._soundGroup = soundGroup
	self._currentIndex = 1
	self._isPlaying = false
	self._isRepeat = false
	self._isShuffle = false

	return self
end

function Playback:getSound(): Sound
	return self._sound
end

function Playback:getIndex(): number
	return self._currentIndex
end

function Playback:setIndex(index: number)
	self._currentIndex = index
end

function Playback:isPlaying(): boolean
	return self._isPlaying
end

function Playback:setPlaying(val: boolean)
	self._isPlaying = val
	if val then
		self._sound:Resume()
	else
		self._sound:Pause()
	end
end

function Playback:isRepeat(): boolean
	return self._isRepeat
end

function Playback:toggleRepeat(): boolean
	self._isRepeat = not self._isRepeat
	return self._isRepeat
end

function Playback:isShuffle(): boolean
	return self._isShuffle
end

function Playback:toggleShuffle(): boolean
	self._isShuffle = not self._isShuffle
	return self._isShuffle
end

function Playback:getNextIndex(total: number): number
	if total <= 1 then return 1 end
	if self._isShuffle then
		local nextIdx = math.random(1, total)
		if nextIdx == self._currentIndex and total > 1 then
			nextIdx = (nextIdx % total) + 1
		end
		return nextIdx
	end
	local nextIndex = self._currentIndex + 1
	return nextIndex > total and 1 or nextIndex
end

function Playback:getPrevIndex(total: number): number
	if total <= 1 then return 1 end
	local prevIndex = self._currentIndex - 1
	return prevIndex < 1 and total or prevIndex
end

--- Loads a song and applies tempo normalization (PlaybackSpeed)
function Playback:loadSong(data: { any }, index: number, autoPlay: boolean)
	local song = data[index]
	if not song then return end

	self._currentIndex = index
	self._sound:Stop()

	-- Set audio ID and restore natural tempo
	self._sound.SoundId = "rbxassetid://" .. tostring(song.Id)
	self._sound.PlaybackSpeed = song.PlaybackSpeed or 1.0

	self._isPlaying = false
	if autoPlay then
		self._sound:Play()
		self._isPlaying = true
	end
end

function Playback:stopAndDestroy()
	self._sound:Stop()
	self._sound:Destroy()
end

return Playback
