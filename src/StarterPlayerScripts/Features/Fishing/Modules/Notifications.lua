-- Fish roll request, fish model lookup, catch notifications and fish VFX.
local Module = {}

function Module.Install(Controller)
	function Controller:RequestServerFish(powerPercent)
		-- Promise:await() returns (success, value); Gateway still resolves failures as response tables.
		local callOk, awaitedOk, response = pcall(function()
			return self.NetworkGateway:Request("POST", "/fishing/roll", { Power = powerPercent }):await()
		end)

		if not callOk or not awaitedOk or type(response) ~= "table" then
			self.GUIManager:ShowNotification("Gagal menghubungi server untuk roll ikan.", 3, Color3.fromRGB(255, 100, 100))
			return nil
		end

		if response.Success and type(response.Data) == "table" then
			return response.Data
		end

		self.GUIManager:ShowNotification(response.Message or "Roll ikan ditolak server.", 3, Color3.fromRGB(255, 100, 100))
		return nil
	end

	function Controller:SelectFish()
		local gameState = self.gameState
		local rodName = self:GetCurrentRodName()
		if not rodName then
			warn("⚠ No rod equipped!")
			return nil
		end

		local powerPercent = self.PowerBarSystem:GetCurrentPower() / 100

		if gameState.isAutoFishing then
			powerPercent = 1.0
		end

		local serverResult = self:RequestServerFish(powerPercent)
		if not serverResult then
			gameState.lastRollId = nil
			return nil
		end

		gameState.lastRollId = serverResult.RollId
		return { name = serverResult.Name, rarity = serverResult.Rarity }, serverResult.Weight
	end

	function Controller:GetFishModelTemplate(fishName)
		local RepStorage = self.RepStorage
		local FishModelFolder = RepStorage:FindFirstChild("Assets") and RepStorage.Assets:FindFirstChild("FishModel")
		local template = FishModelFolder and FishModelFolder:FindFirstChild(fishName)
		if template and template:IsA("Model") then
			return template
		end

		-- Auto-fallback: extract model on the fly from Assets.Fish Tool
		local fishToolsFolder = RepStorage:FindFirstChild("Assets") and RepStorage.Assets:FindFirstChild("Fish")
		local tool = fishToolsFolder and fishToolsFolder:FindFirstChild(fishName)
		if tool and tool:IsA("Tool") then
			local fallback = Instance.new("Model")
			fallback.Name = tool.Name
			local primary = nil
			for _, c in ipairs(tool:GetChildren()) do
				if c:IsA("BasePart") then
					local cp = c:Clone()
					cp.CanCollide = false
					cp.Anchored = false
					cp.Parent = fallback
					if c.Name == "Handle" or c.Name == "MainBody" then
						primary = cp
					end
				end
			end
			fallback.PrimaryPart = primary or fallback:FindFirstChildWhichIsA("BasePart")
			return fallback
		end
		return nil
	end

	function Controller:ShowFishBouncingDropAnimation(selectedFish)
		local fishModelName = selectedFish.name
		local fishTemplate = self:GetFishModelTemplate(fishModelName)

		if not fishTemplate then
			warn("⚠ Model ikan tidak ditemukan untuk: " .. fishModelName)
			return
		end

		local hrp = self.character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		-- Kloning model dan setup dasar
		local fishClone = fishTemplate:Clone()
		fishClone.Parent = workspace

		local primaryPart = fishClone.PrimaryPart or fishClone:FindFirstChildOfClass("BasePart")
		if not primaryPart then
			warn("Model ikan tidak memiliki PrimaryPart yang ditetapkan.")
			fishClone:Destroy()
			return
		end

		-- Pastikan SEMUA bagian unanchored agar model dapat digerakkan oleh Tween
		for _, part in fishClone:GetDescendants() do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Anchored = false
			end
		end

		local horizontalDistance = 5 -- Jarak di depan pemain
		local startHeight = 300 -- Ketinggian awal jatuh
		local groundHeight = 0.5 -- Ketinggian 'tanah'
		local dropDuration = 20.0 -- Durasi jatuh utama
		local durasicamera = 2.0

		-- CFrame awal: di udara
		local startCFrame = hrp.CFrame * CFrame.new(0, startHeight, -horizontalDistance) * CFrame.Angles(math.rad(-60), math.rad(45), math.rad(15))

		-- CFrame akhir: posisi kontak pertama
		local groundCFrame = hrp.CFrame * CFrame.new(0, groundHeight, -horizontalDistance) * CFrame.Angles(0, 0, 0)

		fishClone:SetPrimaryPartCFrame(startCFrame)

		-- Panggil fungsi kamera sebelum tween jatuh dimulai
		self:FishDropCameraSequence(primaryPart, durasicamera)

		local dropTweenInfo = TweenInfo.new(
			dropDuration,
			Enum.EasingStyle.Quart,
			Enum.EasingDirection.In
		)

		local dropTween = self.TweenService:Create(primaryPart, dropTweenInfo, {
			CFrame = groundCFrame,
			Rotation = Vector3.new(0, 360 * 2, 0)
		})

		dropTween:Play()

		-- Anchor kembali PrimaryPart setelah tween selesai
		dropTween.Completed:Connect(function(state)
			if state == Enum.PlaybackState.Completed then
				primaryPart.Anchored = true
			end
		end)

		-- Ikan akan hilang setelah semua animasi selesai
		self.Debris:AddItem(fishClone, dropDuration + 1.0)
	end

	function Controller:ShowFishCatchAnimation(selectedFish)
		local fishModelName = selectedFish.name
		local fishTemplate = self:GetFishModelTemplate(fishModelName)

		if not fishTemplate then
			warn("⚠ Model ikan tidak ditemukan untuk: " .. fishModelName)
			return
		end

		local hrp = self.character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local fishClone = fishTemplate:Clone()
		fishClone.Parent = workspace

		local primaryPart = fishClone.PrimaryPart or fishClone:FindFirstChildOfClass("BasePart")
		if not primaryPart then
			warn("Model ikan tidak memiliki PrimaryPart yang ditetapkan.")
			fishClone:Destroy()
			return
		end

		primaryPart.Anchored = true

		-- Jarak di depan dan belakang pemain
		local distance = 10
		-- Ketinggian lompatan
		local height = 10
		-- Durasi total animasi melintas
		local duration = 0.8

		-- CFrame awal: depan pemain
		local startCFrame = hrp.CFrame * CFrame.new(0, 1.5, -distance) * CFrame.Angles(0, math.pi, 0)

		-- CFrame tengah: puncak lompatan di atas pemain
		local peakCFrame = hrp.CFrame * CFrame.new(0, 1.5 + height, 0) * CFrame.Angles(0, math.pi / 2, 0)

		-- CFrame akhir: belakang pemain
		local endCFrame = hrp.CFrame * CFrame.new(0, 1.5, distance) * CFrame.Angles(0, 0, 0)

		fishClone:SetPrimaryPartCFrame(startCFrame)

		-- 1. Tween melompat ke atas (depan -> atas)
		local tweenInfo1 = TweenInfo.new(
			duration / 2,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)

		local tween1 = self.TweenService:Create(primaryPart, tweenInfo1, {CFrame = peakCFrame})

		-- 2. Tween turun ke belakang (atas -> belakang)
		local tweenInfo2 = TweenInfo.new(
			duration / 2,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		)

		local tween2 = self.TweenService:Create(primaryPart, tweenInfo2, {CFrame = endCFrame})

		tween1:Play()

		tween1.Completed:Connect(function(state)
			if state == Enum.PlaybackState.Completed then
				tween2:Play()
			end
		end)

		-- Hancurkan ikan setelah durasi total
		self.Debris:AddItem(fishClone, duration + 0.1)
	end

	function Controller:ShowFishCatchNotification(selectedFish, fishWeight)
		if not selectedFish then return end
		local FishingConfig = self.FishingConfig
		local GUIManager = self.GUIManager
		local rarityColor = FishingConfig and FishingConfig.GetRarityColor(selectedFish.rarity) or Color3.fromRGB(255, 255, 255)
		local message = string.format("Mendapatkan %s %.1fkg", selectedFish.name, fishWeight or 1)
		if GUIManager and GUIManager.ShowFishNotification then
			GUIManager:ShowFishNotification(message, selectedFish.name, 4, rarityColor)
		elseif GUIManager then
			GUIManager:ShowNotification(message, 4, rarityColor)
		end
	end
end

return Module
