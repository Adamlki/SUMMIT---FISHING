--!nonstrict
local MusicResolver = {}

local function findFirst(root, name)
	if not root then return nil end
	return root:FindFirstChild(name)
end

local function findWithWait(root, name, timeout)
	if not root then return nil end
	return root:FindFirstChild(name) or root:WaitForChild(name, timeout)
end

function MusicResolver.Resolve(playerGui)
	if not playerGui then
		return false, "PlayerGui not found"
	end

	local gameUI = findWithWait(playerGui, "GameUI", 60)
	if not gameUI then
		return false, "GameUI not found"
	end

	local menus = findWithWait(gameUI, "Menus", 10)
	local musicMenu = findWithWait(menus, "Music", 10)
	if not musicMenu then
		return false, "Menus/Music not found"
	end

	local closeBtn = findFirst(musicMenu, "CloseButton")
	local headerLabel = findFirst(musicMenu, "HeaderLabel")

	local playingFrame = findFirst(musicMenu, "PlayingFrame")
	local playingImage = playingFrame and findFirst(playingFrame, "ImageMusic")
	local playingSubFrame = playingFrame and findFirst(playingFrame, "Frame")
	local playingTitle = playingSubFrame and findFirst(playingSubFrame, "TitleMusic")
	local playingPlaylist = playingSubFrame and findFirst(playingSubFrame, "TitlePlaylistMusic")

	local durationFrame = findFirst(musicMenu, "DurationFrame")
	local durationBar = durationFrame and findFirst(durationFrame, "BarFrame")
	local durationGreenBar = durationBar and findFirst(durationBar, "GreenBarFrame")
	local durationLabel = durationFrame and findFirst(durationFrame, "DurationLabel")

	local controls = findFirst(musicMenu, "MusicControls")
	local playPauseBtn = controls and findFirst(controls, "PlayPauseButton")
	local playPauseIcon = playPauseBtn and findFirst(playPauseBtn, "ImageLabel")
	local prevBtn = controls and findFirst(controls, "PrevButton")
	local nextBtn = controls and findFirst(controls, "NextButton")
	local shuffleBtn = controls and findFirst(controls, "ShuffleButton")
	local loopBtn = controls and findFirst(controls, "LoopButton")

	local volumeFrame = findFirst(musicMenu, "VolumeFrame")
	local volumeBar = volumeFrame and findFirst(volumeFrame, "BarFrame")
	local volumeGreenBar = volumeBar and findFirst(volumeBar, "GreenBarFrame")
	local percentLabel = volumeFrame and findFirst(volumeFrame, "percentLabel")

	local playlistFrame = findFirst(musicMenu, "PlaylistFrame")
	local playlistBtnFrame = playlistFrame and findFirst(playlistFrame, "Frame")
	local indonesiaBtn = playlistBtnFrame and findFirst(playlistBtnFrame, "IndonesiaButton")
	local jawaBtn = playlistBtnFrame and findFirst(playlistBtnFrame, "JawaButton")
	local englishBtn = playlistBtnFrame and findFirst(playlistBtnFrame, "EnglishButton")

	local musicListFrame = findFirst(musicMenu, "MusicListFrame")
	local template = musicListFrame and findFirst(musicListFrame, "MusicFrame")

	local component = findFirst(gameUI, "Component") or findWithWait(gameUI, "Component", 5)
	local buttons = component and (findFirst(component, "ButtonsNew") or findWithWait(component, "ButtonsNew", 5))
	local menuKiri = buttons and (findFirst(buttons, "MenuKiri") or findWithWait(buttons, "MenuKiri", 5))
	local frameBtn = menuKiri and (findFirst(menuKiri, "FrameBtn") or findWithWait(menuKiri, "FrameBtn", 5))
	local toggleBtn = frameBtn and (findFirst(frameBtn, "MusicButton") or findWithWait(frameBtn, "MusicButton", 5))

	return true, {
		GameUI = gameUI,
		Menu = musicMenu,
		HeaderLabel = headerLabel,
		CloseBtn = closeBtn,
		PlayingFrame = playingFrame,
		PlayingImage = playingImage,
		PlayingTitle = playingTitle,
		PlayingPlaylist = playingPlaylist,
		DurationFrame = durationFrame,
		DurationBar = durationBar,
		DurationGreenBar = durationGreenBar,
		DurationLabel = durationLabel,
		PlayPauseBtn = playPauseBtn,
		PlayPauseIcon = playPauseIcon,
		PrevBtn = prevBtn,
		NextBtn = nextBtn,
		ShuffleBtn = shuffleBtn,
		LoopBtn = loopBtn,
		VolumeFrame = volumeFrame,
		VolumeBar = volumeBar,
		VolumeGreenBar = volumeGreenBar,
		PercentLabel = percentLabel,
		PlaylistFrame = playlistFrame,
		IndonesiaBtn = indonesiaBtn,
		JawaBtn = jawaBtn,
		EnglishBtn = englishBtn,
		MusicListFrame = musicListFrame,
		Template = template,
		ToggleBtn = toggleBtn,
	}
end

return MusicResolver
