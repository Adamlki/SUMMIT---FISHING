-- File: ReplicatedStorage/FishingModules/GUIManager

local GUIManager = {}
local TS = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundManager = nil -- Akan kita 'require' nanti

local gui = {}
local fishingFrameOriginalPosition
local imageTapOriginalSize
local notificationCoroutine

local fishingSystemFolder = ReplicatedStorage:WaitForChild("FishingSystem", 15)
local fishAssetsFolder = fishingSystemFolder and fishingSystemFolder:WaitForChild("Assets", 15):WaitForChild("Fish", 15)

-- ===================================================================
-- AUTO BUTTON COLOR CONSTANTS & STATE
-- ===================================================================
local DEFAULT_OFF_GRADIENT = ColorSequence.new(
	Color3.fromRGB(255, 0, 0),
	Color3.fromRGB(122, 0, 0) -- Hex #7a0000
)
local DEFAULT_OFF_STROKE_COLOR = Color3.fromRGB(255, 0, 0)

local defaultAutoGradientColor = nil
local defaultAutoStrokeColor = nil

-- ===================================================================
-- HELPER: 3D FISH VIEWPORT FRAME SETUP
-- ===================================================================
local function setupFishViewport(viewport, fishName)
	if not viewport or not fishName or fishName == "" then return false end
	viewport:ClearAllChildren()

	local template = nil
	if fishAssetsFolder then
		template = fishAssetsFolder:FindFirstChild(fishName)
	end
	if not template then
		warn("[GUIManager] Fish model not found in Assets.Fish: " .. tostring(fishName))
		return false
	end

	local cam = Instance.new("Camera")
	cam.FieldOfView = 70
	cam.Parent = viewport
	viewport.CurrentCamera = cam

	viewport.Ambient = Color3.fromRGB(215, 215, 230)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -1)

	local model = Instance.new("Model")
	model.Name = "FishModel"

	for _, desc in ipairs(template:GetDescendants()) do
		if desc:IsA("BasePart") then
			local isSpecialMesh = desc:FindFirstChildOfClass("SpecialMesh") ~= nil
			local isMeshPart = desc:IsA("MeshPart")
			local isGhostly = desc.Transparency >= 0.9
			local isInvisibleGripHandle = (desc.Name == "Handle" and isGhostly and not isMeshPart and not isSpecialMesh)

			if not isInvisibleGripHandle and (desc.Transparency < 0.9 or isMeshPart or isSpecialMesh) then
				local p = desc:Clone()
				p.Anchored = true
				p.CanCollide = false
				p.Parent = model
			end
		end
	end
	model.Parent = viewport

	-- Auto unpitch if model was saved rotated > 50 degrees around X (e.g. Nila Fish, Rock Fish)
	local preCF, _ = model:GetBoundingBox()
	local rx, _, _ = preCF:ToEulerAnglesXYZ()
	if math.abs(math.deg(rx)) > 50 then
		local unpitchCF = CFrame.Angles(-rx, 0, 0)
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") then
				p.CFrame = unpitchCF * p.CFrame
			end
		end
	end

	local cf, size = model:GetBoundingBox()
	local center = cf.Position

	local axes = {
		{vec = cf.RightVector, dim = size.X},
		{vec = cf.UpVector,    dim = size.Y},
		{vec = cf.LookVector,  dim = size.Z},
	}
	table.sort(axes, function(a, b)
		return math.abs(a.vec.Y) > math.abs(b.vec.Y)
	end)

	local vertAxis = axes[1]
	local vertVec = (vertAxis.vec.Y >= 0) and vertAxis.vec or -vertAxis.vec
	local vertHeight = vertAxis.dim

	local horizA = axes[2]
	local horizB = axes[3]
	local lengthAxis = (horizA.dim >= horizB.dim) and horizA or horizB
	local thickAxis  = (horizA.dim >= horizB.dim) and horizB or horizA

	local lengthVec = lengthAxis.vec
	local lengthVal = lengthAxis.dim
	local sideVec   = thickAxis.vec

	local vFovRad = math.rad(70)
	local tanHalfV = math.tan(vFovRad / 2)
	local vpAspect = 1 -- 80x80 square viewport
	local tanHalfH = tanHalfV * vpAspect

	local distH = (lengthVal / 2) / tanHalfH
	local distV = (vertHeight / 2) / tanHalfV
	local dist = math.max(distH, distV) * 1.30
	if dist < 0.9 then dist = 0.9 end

	local camPos = center + sideVec * (dist * 0.96) + vertVec * (dist * 0.12) + lengthVec * (dist * 0.22)
	cam.CFrame = CFrame.lookAt(camPos, center, vertVec)

	return true
end

-- ===================================================================
-- ===== [FITUR BARU] MEMBUAT GUI EFEK LANGKA =====
-- ===================================================================
local function createRareEffectGui(playerGui)
	local existing = playerGui:FindFirstChild("RareFishEffectGui")
	if existing then
		local existingBg = existing:FindFirstChild("Background")
		local existingText = existingBg and existingBg:FindFirstChild("RarityText")
		local existingStroke = existingText and existingText:FindFirstChildOfClass("UIStroke")
		if existingBg and existingText and existingStroke then
			return existingBg, existingText, existingStroke
		end
		existing:Destroy()
	end

	local rareGui = Instance.new("ScreenGui")
	rareGui.Name = "RareFishEffectGui"
	rareGui.Enabled = false
	rareGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	rareGui.ResetOnSpawn = false

	-- Frame Hitam Transparan Penuh
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 1 -- Mulai dari transparan
	background.Size = UDim2.new(1, 0, 1, 0)
	background.ZIndex = 9
	background.Parent = rareGui

	-- Teks Rarity (cth: "LEGENDARY!")
	local rarityText = Instance.new("TextLabel")
	rarityText.Name = "RarityText"
	rarityText.BackgroundTransparency = 1
	rarityText.Size = UDim2.new(0.8, 0, 0.3, 0)
	rarityText.AnchorPoint = Vector2.new(0.5, 0.5)
	rarityText.Position = UDim2.new(0.5, 0, 0.5, 0)
	rarityText.Font = Enum.Font.ArimoBold
	rarityText.Text = "LEGENDARY!"
	rarityText.TextColor3 = Color3.fromRGB(255, 255, 255)
	rarityText.TextScaled = true
	rarityText.TextTransparency = 1 -- Mulai dari transparan
	rarityText.ZIndex = 10
	rarityText.Parent = background

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 3
	stroke.Transparency = 1 -- Mulai dari transparan
	stroke.Parent = rarityText

	rareGui.Parent = playerGui

	return background, rarityText, stroke
end
-- ===================================================================

function GUIManager:Initialize(player)
	local playerGui = player:WaitForChild("PlayerGui")
	local fishingGui = playerGui:WaitForChild("FishingGui")

	-- == BIND KE TOMBOL AUTO GUI USER ==
	local autoButton = fishingGui:WaitForChild("AutoButton")
	local autoText = autoButton:FindFirstChildOfClass("TextLabel")
	local autoGradient = autoButton:FindFirstChildOfClass("UIGradient")
	local autoStroke = autoButton:FindFirstChildOfClass("UIStroke")

	-- Simpan warna default GUI user saat startup
	if autoGradient and not defaultAutoGradientColor then
		defaultAutoGradientColor = autoGradient.Color
	end
	if autoStroke and not defaultAutoStrokeColor then
		defaultAutoStrokeColor = autoStroke.Color
	end

	-- == SETUP 3D VIEWPORT FRAME PADA ImageFish ==
	local imageFish = fishingGui.Notification:WaitForChild("ImageFish")
	imageFish.Image = ""
	imageFish.BackgroundTransparency = 1

	local fishViewport = imageFish:FindFirstChild("FishViewport")
	if not fishViewport then
		fishViewport = Instance.new("ViewportFrame")
		fishViewport.Name = "FishViewport"
		fishViewport.Size = UDim2.new(1, 0, 1, 0)
		fishViewport.Position = UDim2.new(0, 0, 0, 0)
		fishViewport.BackgroundTransparency = 1
		fishViewport.BorderSizePixel = 0
		fishViewport.Visible = false
		fishViewport.ImageTransparency = 0
		fishViewport.Parent = imageFish
	end

	-- == [FITUR BARU] MEMBUAT GUI EFEK LANGKA ==
	local rareBg, rareText, rareStroke = createRareEffectGui(playerGui)

	gui = {
		notificationFrame = fishingGui:WaitForChild("Notification"),
		messageLabel = fishingGui.Notification:WaitForChild("Message"),
		imageFish = imageFish,
		fishViewport = fishViewport,

		tapMobileButton = fishingGui:WaitForChild("TapMobile"),
		tapMobileText = fishingGui.TapMobile:WaitForChild("TAP"),
		barFrame = fishingGui:WaitForChild("Bar"),
		fillFrame = fishingGui.Bar:WaitForChild("Fill"),
		luckMultiText = fishingGui.Bar:WaitForChild("LuckMulti"),
		fishingFrame = fishingGui:WaitForChild("Fishing"),
		fishingBarFrame = fishingGui.Fishing:WaitForChild("Bar"),
		fishingFillFrame = fishingGui.Fishing.Bar:WaitForChild("Fill"),
		whiteBox = fishingGui.Fishing:WaitForChild("WhiteBox"),
		imageTap = fishingGui.Fishing.WhiteBox:WaitForChild("ImageTap"),
		infoText = fishingGui.Fishing:WaitForChild("Info"),

		autoButton = autoButton,
		autoButtonText = autoText,
		autoGradient = autoGradient,
		autoStroke = autoStroke,

		rareEffectBackground = rareBg,
		rareEffectText = rareText,
		rareEffectStroke = rareStroke
	}

	gui.barFrame.Visible = false
	gui.fishingFrame.Visible = false
	gui.tapMobileButton.Visible = false
	gui.autoButton.Visible = false
	gui.imageFish.Visible = false
	gui.fishViewport.Visible = false

	fishingFrameOriginalPosition = gui.fishingFrame.Position
	imageTapOriginalSize = gui.imageTap.Size

	-- Inisialisasi awal warna tombol auto ke OFF (Merah)
	GUIManager:UpdateAutoButton(false)

	SoundManager = require(script.Parent:WaitForChild("SoundManager"))
end

function GUIManager:GetElement(elementName)
	return gui[elementName]
end

-- == FUNGSI UPDATE TOMBOL AUTO DENGAN UIGRADIENT & UISTROKE ==
function GUIManager:UpdateAutoButton(isOn)
	if not gui.autoButton then return end

	if gui.autoButtonText then
		gui.autoButtonText.Text = "AUTO"
	end

	if isOn then
		-- Status ON: Warna hijau default sesuai settingan GUI user
		if gui.autoGradient and defaultAutoGradientColor then
			gui.autoGradient.Color = defaultAutoGradientColor
		end
		if gui.autoStroke and defaultAutoStrokeColor then
			gui.autoStroke.Color = defaultAutoStrokeColor
		end
	else
		-- Status OFF: Gradien Merah (kiri 255,0,0 ke kanan #7a0000) dan Stroke Merah 255,0,0
		if gui.autoGradient then
			gui.autoGradient.Color = DEFAULT_OFF_GRADIENT
		end
		if gui.autoStroke then
			gui.autoStroke.Color = DEFAULT_OFF_STROKE_COLOR
		end
	end
end

function GUIManager:ShowAutoButton(visible)
	if gui.autoButton then
		gui.autoButton.Visible = visible
	end
end

-- ===================================================================
-- ===== FUNGSI UNTUK MEMUTAR "CUTSCENE" LANGKA =====
-- ===================================================================
function GUIManager:PlayRareEffect(rarityName, rarityColor, onCompleteCallback)
	if not gui.rareEffectBackground then
		onCompleteCallback()
		return
	end

	local bg = gui.rareEffectBackground
	local text = gui.rareEffectText
	local stroke = gui.rareEffectStroke

	bg.Parent.Enabled = true
	text.Text = rarityName:upper() .. "!"
	text.TextColor3 = rarityColor

	-- Reset Awal
	bg.BackgroundTransparency = 1
	text.TextTransparency = 1
	stroke.Transparency = 1
	text.Size = UDim2.new(0.8, 0, 0.3, 0)

	-- Animasi
	task.spawn(function()
		-- Suara Dramatis
		if SoundManager then
			SoundManager:Play("Success", 1.0)
		end

		-- 1. Fade in background hitam
		TS:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 0.6}):Play()

		-- 2. Teks muncul dan membesar (Zoom-in)
		text.TextTransparency = 0
		stroke.Transparency = 0
		TS:Create(text, TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.9, 0, 0.35, 0)
		}):Play()

		-- 3. Tahan selama 3 detik
		task.wait(3)

		-- 4. Fade out semuanya
		TS:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		TS:Create(text, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		TS:Create(stroke, TweenInfo.new(0.5), {Transparency = 1}):Play()

		-- 5. Tunggu fade out selesai, lalu panggil callback
		task.wait(0.5)
		bg.Parent.Enabled = false

		if onCompleteCallback then
			onCompleteCallback()
		end
	end)
end

-- ===================================================================
-- ===== FUNGSI NOTIFIKASI DENGAN 3D VIEWPORT FRAME IKAN =====
-- ===================================================================
function GUIManager:ShowFishNotification(message, fishName, duration, textColor)
	duration = duration or 4
	textColor = textColor or Color3.fromRGB(255, 255, 255)

	if notificationCoroutine then
		coroutine.close(notificationCoroutine)
	end

	gui.notificationFrame.Visible = true
	gui.messageLabel.TextTransparency = 0
	gui.messageLabel.Text = message
	gui.messageLabel.TextColor3 = textColor

	local hasModel = false
	if gui.fishViewport and fishName and fishName ~= "" then
		hasModel = setupFishViewport(gui.fishViewport, fishName)
		if hasModel then
			gui.imageFish.Visible = true
			gui.fishViewport.Visible = true
			gui.fishViewport.ImageTransparency = 0
		end
	end

	if not hasModel then
		if gui.fishViewport then
			gui.fishViewport.Visible = false
		end
		if gui.imageFish then
			gui.imageFish.Visible = false
		end
	end

	notificationCoroutine = coroutine.create(function()
		task.wait(duration)

		-- Fade out teks dan model 3D secara bersamaan
		for i = 0, 1, 0.1 do
			if gui.messageLabel then
				gui.messageLabel.TextTransparency = i
			end
			if gui.fishViewport and gui.fishViewport.Visible then
				gui.fishViewport.ImageTransparency = i
			end
			task.wait(0.02)
		end

		if gui.notificationFrame then
			gui.notificationFrame.Visible = false
		end
		if gui.fishViewport then
			gui.fishViewport.Visible = false
			gui.fishViewport.ImageTransparency = 1
			gui.fishViewport:ClearAllChildren()
		end
		if gui.imageFish then
			gui.imageFish.Visible = false
		end
	end)

	coroutine.resume(notificationCoroutine)
end

-- ===================================================================
-- ===== FUNGSI NOTIFIKASI STANDARD (Text Only) =====
-- ===================================================================
function GUIManager:ShowNotification(message, duration, textColor)
	GUIManager:ShowFishNotification(message, nil, duration, textColor)
end

function GUIManager:UpdateMobileButtonText(text)
	gui.tapMobileText.Text = text
end

function GUIManager:ShowMobileButton(visible)
	gui.tapMobileButton.Visible = visible
end

function GUIManager:SlideFishingFrameIn()
	if not gui.fishingFrame then return end

	gui.fishingFrame.Position = UDim2.new(
		fishingFrameOriginalPosition.X.Scale,
		fishingFrameOriginalPosition.X.Offset,
		1.2, 0
	)

	gui.fishingFrame.Visible = true

	local slideInTween = TS:Create(
		gui.fishingFrame,
		TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{Position = fishingFrameOriginalPosition}
	)

	slideInTween:Play()
end

function GUIManager:SlideFishingFrameOut(callback)
	if not gui.fishingFrame or not fishingFrameOriginalPosition then
		if callback then callback() end
		return
	end

	local slideOutTween = TS:Create(
		gui.fishingFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
		{Position = UDim2.new(
			fishingFrameOriginalPosition.X.Scale,
			fishingFrameOriginalPosition.X.Offset,
			1.2, 0
			)}
	)

	slideOutTween:Play()

	slideOutTween.Completed:Connect(function()
		gui.fishingFrame.Visible = false
		gui.fishingFrame.Position = fishingFrameOriginalPosition

		if callback then callback() end
	end)
end

function GUIManager:AnimateImageTap()
	if not gui.imageTap or not imageTapOriginalSize then return end

	local compressTween = TS:Create(
		gui.imageTap,
		TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(
			imageTapOriginalSize.X.Scale * 0.8,
			imageTapOriginalSize.X.Offset * 0.8,
			imageTapOriginalSize.Y.Scale * 0.8,
			imageTapOriginalSize.Y.Offset * 0.8
			)}
	)

	local bounceTween = TS:Create(
		gui.imageTap,
		TweenInfo.new(0.15, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
		{Size = imageTapOriginalSize}
	)

	compressTween:Play()
	compressTween.Completed:Connect(function()
		bounceTween:Play()
	end)
end

return GUIManager
