--!nonstrict
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ButtonClickSoundConfig = require(ReplicatedStorage.Shared.Config.UI.ButtonClickSoundConfig)

local ButtonClickSoundPlayer = {}

local function getSoundConfig(kind)
	local config = ButtonClickSoundConfig[kind]
	if typeof(config) == "table" then
		return config
	end
	return nil
end

local lastClickTime = 0

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

	local sound = Instance.new("Sound")
	sound.Name = "ButtonClickSound"
	sound.SoundId = config.SoundId or ""
	sound.Volume = config.Volume or 0.5
	sound.PlaybackSpeed = config.PlaybackSpeed or 1
	sound.RollOffMaxDistance = 0
	sound.Parent = SoundService

	SoundService:PlayLocalSound(sound)
	Debris:AddItem(sound, 3)
end

return ButtonClickSoundPlayer
