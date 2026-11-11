--!nonstrict
local MusicFormatter = require(script.Parent.Parent.MusicFormatter)

local MusicDisplay = {}

local PLAY_ICON_ID = "rbxassetid://131376679110993"

local function ensurePauseBars(parentBtn)
	if not parentBtn then return nil end
	local pauseBars = parentBtn:FindFirstChild("PauseBars")
	if not pauseBars then
		pauseBars = Instance.new("Frame")
		pauseBars.Name = "PauseBars"
		pauseBars.BackgroundTransparency = 1
		pauseBars.Size = UDim2.fromScale(1, 1)
		pauseBars.Position = UDim2.fromScale(0, 0)
		pauseBars.ZIndex = 2

		local bar1 = Instance.new("Frame")
		bar1.Name = "Bar1"
		bar1.AnchorPoint = Vector2.new(0.5, 0.5)
		bar1.Position = UDim2.new(0.5, -5, 0.5, 0)
		bar1.Size = UDim2.new(0, 5, 0, 18)
		bar1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		bar1.BorderSizePixel = 0
		bar1.ZIndex = 2
		local corner1 = Instance.new("UICorner")
		corner1.CornerRadius = UDim.new(0, 2)
		corner1.Parent = bar1
		bar1.Parent = pauseBars

		local bar2 = Instance.new("Frame")
		bar2.Name = "Bar2"
		bar2.AnchorPoint = Vector2.new(0.5, 0.5)
		bar2.Position = UDim2.new(0.5, 5, 0.5, 0)
		bar2.Size = UDim2.new(0, 5, 0, 18)
		bar2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		bar2.BorderSizePixel = 0
		bar2.ZIndex = 2
		local corner2 = Instance.new("UICorner")
		corner2.CornerRadius = UDim.new(0, 2)
		corner2.Parent = bar2
		bar2.Parent = pauseBars

		pauseBars.Parent = parentBtn
	end
	return pauseBars
end

function MusicDisplay.updateDisplay(runtime)
	local song = runtime._data[runtime._currentIndex]
	if not song then
		return
	end
	
	local refs = runtime._refs
	if refs.PlayingTitle then
		refs.PlayingTitle.Text = song.Title or "Unknown"
	end
	
	local categories = runtime._musicData.Categories or {}
	local catData = categories[runtime._activeCategory]
	local catName = catData and catData.Name or runtime._activeCategory or "Indonesia"
	local catIcon = catData and catData.Icon or ""

	if refs.PlayingPlaylist then
		refs.PlayingPlaylist.Text = "Playlist: " .. catName
	end
	
	if refs.PlayingImage then
		refs.PlayingImage.Image = song.Image or catIcon
	end
end

function MusicDisplay.updateProgressBar(runtime)
	local sound = runtime._playback:getSound()
	local timeLen = sound.TimeLength
	local refs = runtime._refs
	
	if not refs.DurationGreenBar or not refs.DurationLabel then
		return
	end
	
	if timeLen > 0 then
		local progress = math.clamp(sound.TimePosition / timeLen, 0, 1)
		refs.DurationGreenBar.Size = UDim2.new(progress, 0, 1, 0)
		refs.DurationLabel.Text = MusicFormatter.formatTime(sound.TimePosition) .. "/" .. MusicFormatter.formatTime(timeLen)
	else
		refs.DurationGreenBar.Size = UDim2.new(0, 0, 1, 0)
		refs.DurationLabel.Text = "00:00/00:00"
	end
end

function MusicDisplay.setVolume(runtime, value)
	runtime._volume = math.clamp(value, 0, 100)
	local sound = runtime._playback:getSound()
	sound.Volume = runtime._volume / 100
	
	local refs = runtime._refs
	if refs.VolumeGreenBar then
		refs.VolumeGreenBar.Size = UDim2.new(runtime._volume / 100, 0, 1, 0)
	end
	if refs.PercentLabel then
		refs.PercentLabel.Text = tostring(math.round(runtime._volume)) .. "%"
	end
end

function MusicDisplay.updatePlayPauseIcon(runtime)
	local refs = runtime._refs
	local playPauseBtn = refs.PlayPauseButton
	local icon = refs.PlayPauseIcon
	
	local pauseBars = ensurePauseBars(playPauseBtn or (icon and icon.Parent))
	local isPlaying = runtime._playback:isPlaying()
	
	if isPlaying then
		if icon then
			icon.Visible = false
		end
		if pauseBars then
			pauseBars.Visible = true
		end
	else
		if icon then
			icon.Image = PLAY_ICON_ID
			icon.Visible = true
		end
		if pauseBars then
			pauseBars.Visible = false
		end
	end
end

return MusicDisplay
