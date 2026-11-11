local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = script.Parent

local capsule = gui:WaitForChild("BannerCapsule")
local flash = gui:WaitForChild("FlashOverlay")

local iconOrb = capsule:WaitForChild("IconOrb")
local orbEmoji = iconOrb:WaitForChild("Emoji")

local contentCol = capsule:WaitForChild("ContentCol")
local headerTag = contentCol:WaitForChild("HeaderTag")
local eventTitle = contentCol:WaitForChild("EventTitle")
local badgesRow = contentCol:WaitForChild("BadgesRow")

local chipLuck = badgesRow:WaitForChild("ChipLuck"):WaitForChild("Label")
local chipMutation = badgesRow:WaitForChild("ChipMutation"):WaitForChild("Label")
local chipDuration = badgesRow:WaitForChild("ChipDuration"):WaitForChild("Label")

local fishingSystem = ReplicatedStorage:WaitForChild("FishingSystem", 10)
local announceRemote = fishingSystem and fishingSystem:WaitForChild("AdminEventActivated", 10)

-- Audio asset
local luckySound = ReplicatedStorage:FindFirstChild("luckysound")
local rareSound = fishingSystem and fishingSystem:FindFirstChild("Assets")
    and fishingSystem.Assets:FindFirstChild("Sound")
    and fishingSystem.Assets.Sound:FindFirstChild("RareCatchSound")

local isPlaying = false

-- Ensure clean initial state (invisible and off-screen)
capsule.Visible = false
capsule.GroupTransparency = 1
capsule.Position = UDim2.new(0.5, 0, 0, -120)

local function playEventAnimation(data)
    if isPlaying then return end
    isPlaying = true

    local titleText = data.title or "SECRET EVENT ACTIVATED"
    local adminName = data.admin or "Admin"
    local durationMin = data.durationMinutes or 30
    local luckMult = data.luck or 30
    local mutMult = data.mutation or 7

    -- 1. Format Info
    eventTitle.Text = string.upper(titleText)
    headerTag.Text = string.format("⭐ EVENT BY %s ⭐", string.upper(adminName))
    chipLuck.Text = string.format("🍀 %dx Luck", luckMult)
    chipMutation.Text = string.format("🧬 %dx Mutation", mutMult)
    chipDuration.Text = string.format("⏱️ %dm", durationMin)

    -- Dynamic Emoji & Colors based on event name
    local lowerTitle = string.lower(titleText)
    if string.find(lowerTitle, "secret") then
        orbEmoji.Text = "🌟"
        iconOrb.BackgroundColor3 = Color3.fromRGB(35, 20, 50)
    elseif string.find(lowerTitle, "mega") or string.find(lowerTitle, "luck") then
        orbEmoji.Text = "🍀"
        iconOrb.BackgroundColor3 = Color3.fromRGB(15, 40, 25)
    elseif string.find(lowerTitle, "mutat") then
        orbEmoji.Text = "🧬"
        iconOrb.BackgroundColor3 = Color3.fromRGB(45, 18, 25)
    else
        orbEmoji.Text = "🎣"
        iconOrb.BackgroundColor3 = Color3.fromRGB(20, 32, 48)
    end

    -- 2. Audio Fanfare (Crisp & non-intrusive)
    if rareSound then
        local snd = rareSound:Clone()
        snd.Parent = gui
        snd.Volume = 0.65
        snd:Play()
        task.delay(4, function() snd:Destroy() end)
    elseif luckySound then
        local snd = luckySound:Clone()
        snd.Parent = gui
        snd.Volume = 0.5
        snd:Play()
        task.delay(5, function() snd:Destroy() end)
    end

    -- 3. Soft Ambient Flash (very gentle)
    flash.BackgroundTransparency = 0.8
    flash.Visible = true
    TweenService:Create(flash, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1
    }):Play()

    -- 4. Ultra-Smooth Capsule Glide & Alpha Fade In (CanvasGroup)
    -- Meluncur halus dari atas tanpa memotong layar atau item manapun
    capsule.Position = UDim2.new(0.5, 0, 0, -80)
    capsule.GroupTransparency = 1
    capsule.Visible = true

    local twSlideIn = TweenService:Create(capsule, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0, 20)
    })
    local twFadeIn = TweenService:Create(capsule, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        GroupTransparency = 0
    })

    twSlideIn:Play()
    twFadeIn:Play()

    -- 5. TAMPIL SELAMA 5.0 DETIK, LALU DRIFT OUT ULTRA-SMOOTH
    task.delay(5.0, function()
        local twSlideOut = TweenService:Create(capsule, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 0, -20)
        })
        local twFadeOut = TweenService:Create(capsule, TweenInfo.new(0.40, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            GroupTransparency = 1
        })

        twSlideOut:Play()
        twFadeOut:Play()

        twSlideOut.Completed:Connect(function()
            capsule.Visible = false
            flash.Visible = false
            isPlaying = false
        end)
    end)
end

if announceRemote then
    announceRemote.OnClientEvent:Connect(playEventAnimation)
end
