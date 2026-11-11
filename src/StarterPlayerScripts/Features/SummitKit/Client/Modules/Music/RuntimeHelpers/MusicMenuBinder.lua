--!nonstrict
local MusicInput = require(script.Parent.Parent.MusicInput)
local MusicDisplay = require(script.Parent.MusicDisplay)

local MusicMenuBinder = {}

function MusicMenuBinder.bind(runtime)
	local refs = runtime._refs
	refs.Menu.Visible = false

	-- Close Button in Header
	if refs.CloseBtn then
		MusicInput.bindButton(runtime._janitor, refs.CloseBtn, function()
			runtime:_closeMenu()
		end)
	end

	-- Category Buttons Binding (Indonesia, Jawa, English)
	if refs.IndonesiaBtn then
		MusicInput.bindButton(runtime._janitor, refs.IndonesiaBtn, function()
			runtime:switchCategory("Indo", nil)
		end)
	end
	if refs.JawaBtn then
		MusicInput.bindButton(runtime._janitor, refs.JawaBtn, function()
			runtime:switchCategory("Jawa", nil)
		end)
	end
	if refs.EnglishBtn then
		MusicInput.bindButton(runtime._janitor, refs.EnglishBtn, function()
			runtime:switchCategory("Inggris", nil)
		end)
	end

	-- Menu Toggle Button in TopMid
	if refs.ToggleBtn then
		MusicInput.bindButton(runtime._janitor, refs.ToggleBtn, function()
			if refs.Menu.Visible then
				runtime:_closeMenu()
			else
				runtime:_openMenu()
			end
		end)
	end

	-- Play / Pause Button
	if refs.PlayPauseBtn then
		MusicInput.bindButton(runtime._janitor, refs.PlayPauseBtn, function()
			if #runtime._data == 0 then
				return
			end
			if runtime._playback:isPlaying() then
				runtime._playback:getSound():Pause()
				runtime._playback:setPlaying(false)
			else
				local sound = runtime._playback:getSound()
				if sound.SoundId == "" or sound.SoundId == "rbxassetid://0" then
					runtime:_loadSong(runtime._playback:getIndex(), true)
				else
					sound:Resume()
					runtime._playback:setPlaying(true)
				end
			end
			MusicDisplay.updatePlayPauseIcon(runtime)
		end)
	end

	-- Next & Previous Buttons
	if refs.NextBtn then
		MusicInput.bindButton(runtime._janitor, refs.NextBtn, function()
			runtime:_loadSong(runtime:_getNextIndex(), runtime._playback:isPlaying())
		end)
	end

	if refs.PrevBtn then
		MusicInput.bindButton(runtime._janitor, refs.PrevBtn, function()
			if runtime._playback:getSound().TimePosition > 3 then
				runtime._playback:getSound().TimePosition = 0
				runtime:_updateProgressBar()
			else
				runtime:_loadSong(runtime:_getPrevIndex(), runtime._playback:isPlaying())
			end
		end)
	end

	-- Repeat & Shuffle Buttons
	if refs.LoopBtn then
		MusicInput.bindButton(runtime._janitor, refs.LoopBtn, function()
			local val = runtime._playback:toggleRepeat()
			local icon = refs.LoopBtn:FindFirstChild("ImageLabel") or refs.LoopBtn
			if icon then
				icon.ImageTransparency = val and 0 or 0.5
			end
		end)
	end

	if refs.ShuffleBtn then
		MusicInput.bindButton(runtime._janitor, refs.ShuffleBtn, function()
			local val = runtime._playback:toggleShuffle()
			local icon = refs.ShuffleBtn:FindFirstChild("ImageLabel") or refs.ShuffleBtn
			if icon then
				icon.ImageTransparency = val and 0 or 0.5
			end
		end)
	end

	-- Volume Slider Drag & Click
	MusicInput.bindVolumeDrag(
		runtime._janitor,
		refs.VolumeBar,
		refs.VolumeGreenBar,
		function()
			runtime._isDragging = true
			runtime:_onVolumeDrag()
		end,
		function()
			if runtime._isDragging then
				runtime:_onVolumeDrag()
			end
		end,
		function()
			runtime._isDragging = false
		end
	)
end

return MusicMenuBinder
