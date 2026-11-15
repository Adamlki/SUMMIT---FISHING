--!nonstrict
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ButtonClickSoundConfig = require(ReplicatedStorage.Shared.Config.UI.ButtonClickSoundConfig)

local ButtonClickSoundPlayer = {}

local sounds = {} -- cache per kind: Sound yang sudah di-preload
local lastClickTime = 0

local function getSoundConfig(kind)
	local config = ButtonClickSoundConfig[kind]
	if typeof(config) == "table" then
		return config
	end
	return nil
end

local function ensureSound(kind, config)
	local sound = sounds[kind]
	if sound and sound.Parent then
		return sound
	end

	sound = Instance.new("Sound")
	sound.Name = "ButtonClickSound_" .. tostring(kind)
	sound.SoundId = config.SoundId or ""
	sound.Volume = config.Volume or 0.5
	sound.PlaybackSpeed = config.PlaybackSpeed or 1
	sound.Parent = SoundService
	sounds[kind] = sound
	return sound
end

-- Preload sekali di awal: sound baru yang dibuat saat klik akan menunggu asset
-- load (suara terdengar delay).
function ButtonClickSoundPlayer.preload()
	local list = {}
	for kind, config in pairs(ButtonClickSoundConfig) do
		if typeof(config) == "table" then
			table.insert(list, ensureSound(kind, config))
		end
	end
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(list)
		end)
	end)
end

function ButtonClickSoundPlayer.play(kind, _button)
	local config = getSoundConfig(kind)
	if not config then
		return
	end

	if kind == "ButtonClick" then
		local now = os.clock()
		if now - lastClickTime < 0.08 then
			return
		end
		lastClickTime = now
	end

	local sound = ensureSound(kind, config)
	sound.Volume = config.Volume or 0.5
	sound.PlaybackSpeed = config.PlaybackSpeed or 1
	sound.TimePosition = 0
	sound:Play()
end

return ButtonClickSoundPlayer
