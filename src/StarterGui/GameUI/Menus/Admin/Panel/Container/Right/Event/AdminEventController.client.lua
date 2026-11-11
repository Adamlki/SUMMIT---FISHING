local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local tab = script.Parent

local presetSection = tab:WaitForChild("PresetSection")
local presetsList = presetSection:WaitForChild("List")

local luckRow = tab:WaitForChild("LuckRow")
local luckPills = luckRow:WaitForChild("Pills")
local luckCustom = luckRow:WaitForChild("CustomInput")

local mutRow = tab:WaitForChild("MutationRow")
local mutPills = mutRow:WaitForChild("Pills")
local mutCustom = mutRow:WaitForChild("CustomInput")

local durRow = tab:WaitForChild("DurationRow")
local durPills = durRow:WaitForChild("Pills")
local durCustom = durRow:WaitForChild("CustomInput")

local scopeRow = tab:WaitForChild("ScopeRow")
local scopeBtns = scopeRow:WaitForChild("Buttons")
local btnLocal = scopeBtns:WaitForChild("ScopeLocal")
local btnGlobal = scopeBtns:WaitForChild("ScopeGlobal")

local actionRow = tab:WaitForChild("ActionRow")
local activateBtn = actionRow:WaitForChild("ActivateButton")
local stopBtn = actionRow:WaitForChild("StopButton")

local fishingSystem = ReplicatedStorage:WaitForChild("FishingSystem", 10)
local triggerRemote = fishingSystem and fishingSystem:WaitForChild("TriggerAdminEvent", 10)

-- State
local currentLuck = 30
local currentMutation = 7
local currentDuration = 30
local currentScope = "Global"
local currentEventTitle = "Secret Event"

-- Update Row Visuals
local function updateRowHighlight(pillsContainer, customBox, activeVal)
    for _, btn in ipairs(pillsContainer:GetChildren()) do
        if btn:IsA("TextButton") and string.sub(btn.Name, 1, 5) == "Pill_" then
            local val = tonumber(string.sub(btn.Name, 6))
            if val == activeVal then
                btn.BackgroundColor3 = Color3.fromRGB(45, 130, 220)
            else
                btn.BackgroundColor3 = Color3.fromRGB(34, 40, 54)
            end
        end
    end
    customBox.Text = tostring(activeVal)
end

-- Connect Pills
local function setupRow(pillsContainer, customBox, onValChanged)
    for _, btn in ipairs(pillsContainer:GetChildren()) do
        if btn:IsA("TextButton") and string.sub(btn.Name, 1, 5) == "Pill_" then
            local val = tonumber(string.sub(btn.Name, 6))
            btn.MouseButton1Click:Connect(function()
                onValChanged(val)
                updateRowHighlight(pillsContainer, customBox, val)
            end)
        end
    end

    customBox.FocusLost:Connect(function()
        local val = tonumber(customBox.Text)
        if val and val > 0 then
            onValChanged(val)
            updateRowHighlight(pillsContainer, customBox, val)
        else
            customBox.Text = tostring(onValChanged(nil))
        end
    end)
end

setupRow(luckPills, luckCustom, function(v)
    if v then currentLuck = v end
    return currentLuck
end)

setupRow(mutPills, mutCustom, function(v)
    if v then currentMutation = v end
    return currentMutation
end)

setupRow(durPills, durCustom, function(v)
    if v then currentDuration = v end
    return currentDuration
end)

-- Scope toggle
local function setScope(scope)
    currentScope = scope
    if scope == "Global" then
        btnGlobal.BackgroundColor3 = Color3.fromRGB(45, 130, 220)
        btnLocal.BackgroundColor3 = Color3.fromRGB(34, 40, 54)
    else
        btnLocal.BackgroundColor3 = Color3.fromRGB(45, 130, 220)
        btnGlobal.BackgroundColor3 = Color3.fromRGB(34, 40, 54)
    end
end

btnLocal.MouseButton1Click:Connect(function() setScope("Local") end)
btnGlobal.MouseButton1Click:Connect(function() setScope("Global") end)

-- Preset Buttons
local function applyPreset(name, luck, mut, dur, title)
    currentEventTitle = title
    currentLuck = luck
    currentMutation = mut
    currentDuration = dur

    updateRowHighlight(luckPills, luckCustom, luck)
    updateRowHighlight(mutPills, mutCustom, mut)
    updateRowHighlight(durPills, durCustom, dur)
end

local secretBtn = presetsList:WaitForChild("Preset_Secret")
secretBtn.MouseButton1Click:Connect(function()
    applyPreset("Secret", 30, 7, 45, "Secret Event")
end)

local megaLuckBtn = presetsList:WaitForChild("Preset_MegaLuck")
megaLuckBtn.MouseButton1Click:Connect(function()
    applyPreset("MegaLuck", 50, 2, 30, "Mega Luck Event")
end)

local superMutBtn = presetsList:WaitForChild("Preset_SuperMutation")
superMutBtn.MouseButton1Click:Connect(function()
    applyPreset("SuperMutation", 15, 10, 20, "Super Mutated Event")
end)

-- Activate Event Button with click feedback
local isSubmitting = false
activateBtn.MouseButton1Click:Connect(function()
    if isSubmitting then return end
    isSubmitting = true

    print("🚀 [AdminEvent] Mengirim request aktifkan event:", currentEventTitle, "Luck:", currentLuck, "Mut:", currentMutation)

    if not triggerRemote then
        fishingSystem = ReplicatedStorage:WaitForChild("FishingSystem", 5)
        triggerRemote = fishingSystem and fishingSystem:FindFirstChild("TriggerAdminEvent")
    end

    if not triggerRemote then
        warn("❌ [AdminEvent] TriggerAdminEvent Remote tidak ditemukan di ReplicatedStorage!")
        activateBtn.Text = "❌ GAGAL: REMOTE NOT FOUND"
        task.wait(2)
        activateBtn.Text = "🔥 AKTIFKAN EVENT SEKARANG 🔥"
        isSubmitting = false
        return
    end

    activateBtn.Text = "⏳ MEMPROSES EVENT..."
    
    triggerRemote:FireServer({
        action = "ACTIVATE",
        eventName = currentEventTitle,
        luck = currentLuck,
        mutation = currentMutation,
        durationMinutes = currentDuration,
        scope = currentScope,
    })

    task.wait(0.6)
    activateBtn.Text = "✅ EVENT BERHASIL DIAKTIFKAN!"
    task.wait(1.5)
    activateBtn.Text = "🔥 AKTIFKAN EVENT SEKARANG 🔥"
    isSubmitting = false
end)

-- Stop Event Button with click feedback
stopBtn.MouseButton1Click:Connect(function()
    if not triggerRemote then
        fishingSystem = ReplicatedStorage:WaitForChild("FishingSystem", 5)
        triggerRemote = fishingSystem and fishingSystem:FindFirstChild("TriggerAdminEvent")
    end

    if not triggerRemote then return end

    stopBtn.Text = "⏳..."
    triggerRemote:FireServer({
        action = "STOP"
    })
    task.wait(0.5)
    stopBtn.Text = "✅ STOPPED"
    task.wait(1.2)
    stopBtn.Text = "⏹ STOP"
end)
