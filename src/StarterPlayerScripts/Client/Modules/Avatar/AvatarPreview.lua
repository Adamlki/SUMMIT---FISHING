--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)
local Promise = require(Packages.Promise)
local Signal = require(Packages.Signal)

local function getIdleAnimation(model)
    local animFolder = model:FindFirstChild("Animate")
    if animFolder then
        local idleFolder = animFolder:FindFirstChild("idle")
        if idleFolder then
            local anim = idleFolder:FindFirstChildWhichIsA("Animation")
            if anim and anim.AnimationId ~= "" then
                return anim
            end
        end
    end
    local fallback = Instance.new("Animation")
    fallback.AnimationId = "http://www.roblox.com/asset/?id=507766388"
    return fallback
end

local AvatarPreview = {}
AvatarPreview.__index = AvatarPreview

function AvatarPreview.new(viewport)
    local self = setmetatable({}, AvatarPreview)
    self.janitor = Janitor.new()
    self.viewport = viewport
    self.camera = nil
    self.world = nil
    self.rotateConn = nil
    self.activeAnimTrack = nil
    self.stagingModel = nil
    self.previewToken = 0
    self.OnLoaded = Signal.new()
    self.janitor:Add(self.OnLoaded, "Destroy")

    if self.viewport then
        for _, ch in ipairs(self.viewport:GetChildren()) do
            if ch:IsA("Camera") or ch:IsA("WorldModel") then
                ch:Destroy()
            end
        end

        self.camera = Instance.new("Camera")
        self.camera.FieldOfView = 48
        self.camera.Parent = self.viewport
        self.viewport.CurrentCamera = self.camera

        self.world = Instance.new("WorldModel")
        self.world.Parent = self.viewport
        self.janitor:Add(self.camera, "Destroy")
        self.janitor:Add(self.world, "Destroy")
    end

    return self
end

function AvatarPreview:_clearPreview()
    if self.rotateConn then
        self.rotateConn:Disconnect()
        self.rotateConn = nil
    end
    if self.stagingModel then
        self.stagingModel:Destroy()
        self.stagingModel = nil
    end
    if self.activeAnimTrack then
        self.activeAnimTrack:Stop(0)
        self.activeAnimTrack:Destroy()
        self.activeAnimTrack = nil
    end
    if self.world then
        self.world:ClearAllChildren()
    end
end

function AvatarPreview:load(entry)
    self:_clearPreview()
    local userId = entry and tonumber(entry.UserId)
    if not (userId and userId > 0 and self.viewport and self.camera and self.world) then
        return
    end

    self.previewToken += 1
    local token = self.previewToken

    Promise.try(function()
        local model = Players:CreateHumanoidModelFromUserId(userId)
        self.stagingModel = model

        -- 1. Pasang sejenak di workspace bawah tanah agar engine merakit rig & deformasi mesh
        model:PivotTo(CFrame.new(0, -500, 0))
        local hrp = model:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Anchored = true
        end
        model.Parent = workspace
        task.wait(0.2)

        -- 2. Jalankan animasi idle agar sendi & kepala berada di posisi natural
        local hum = model:FindFirstChildOfClass("Humanoid")
        local animator = hum and hum:FindFirstChildOfClass("Animator")
        local track = nil
        if animator then
            local idleAnim = getIdleAnimation(model)
            track = animator:LoadAnimation(idleAnim)
            track.Looped = true
            track:Play()
        end
        task.wait(0.15)

        return model, track
    end):andThen(function(model, track)
        if token ~= self.previewToken or not model then
            if model then
                model:Destroy()
            end
            if track then
                track:Destroy()
            end
            return
        end

        self.stagingModel = nil
        self.activeAnimTrack = track

        -- 3. Masukkan ke WorldModel (HANYA HumanoidRootPart yang di-anchor)
        local hrp = model:FindFirstChild("HumanoidRootPart")
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") then
                if part == hrp then
                    part.Anchored = true
                else
                    part.Anchored = false
                end
            end
        end

        model:PivotTo(CFrame.new(0, 0, 0))
        model.Parent = self.world

        -- 4. Ambil bounding box yang sudah bersih dan terakit sempurna
        local bbCFrame, bbSize = model:GetBoundingBox()
        local clampedHeight = math.clamp(bbSize.Y, 5.0, 13.0)
        local clampedWidth = math.clamp(math.max(bbSize.X, bbSize.Z), 3.0, 7.5)

        local aspect = 0.605
        if self.viewport and self.viewport.AbsoluteSize.Y > 0 then
            aspect = self.viewport.AbsoluteSize.X / self.viewport.AbsoluteSize.Y
        end

        local fov = 48
        self.camera.FieldOfView = fov
        local tanHalfFov = math.tan(math.rad(fov / 2))

        local distH = (clampedHeight * 1.15) / (2 * tanHalfFov)
        local distW = (clampedWidth * 1.25) / (2 * tanHalfFov * aspect)
        local distance = math.max(distH, distW, 8.5)

        local centerY = bbCFrame.Position.Y
        local focusY = centerY - 0.2

        -- 5. Rotasi Orbit Kamera 360° mulus
        local startClock = os.clock()
        self.rotateConn = RunService.RenderStepped:Connect(function()
            if not model.Parent then
                if self.rotateConn then
                    self.rotateConn:Disconnect()
                    self.rotateConn = nil
                end
                return
            end
            local elapsed = os.clock() - startClock
            local angle = math.pi + (elapsed * math.rad(35))
            local camPos = Vector3.new(math.sin(angle) * distance, focusY, math.cos(angle) * distance)
            self.camera.CFrame = CFrame.lookAt(camPos, Vector3.new(0, focusY, 0))
        end)
        self.janitor:Add(self.rotateConn, "Disconnect")

        self.OnLoaded:Fire(entry, model)
    end):catch(function(err)
        warn("[AvatarPreview] failed to load preview: " .. tostring(err))
    end)
end

function AvatarPreview:destroy()
    self:_clearPreview()
    self.janitor:Destroy()
end

function AvatarPreview:Destroy()
    self:destroy()
end

return AvatarPreview
