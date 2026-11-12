-- Camera shakes and the slow-motion fish drop camera sequence.
local Module = {}

function Module.Install(Controller)
	function Controller:StartCameraShakeHorizontal(duration)
		local camera = workspace.CurrentCamera

		if not camera then
			workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
			camera = workspace.CurrentCamera
		end

		if not camera or camera.CameraSubject == nil then return end

		local startTime = tick()
		local shakeConnection

		if self.activeCameraShake then self.activeCameraShake:Disconnect() end
		shakeConnection = self.RunService.RenderStepped:Connect(function()
			if not camera or not camera.Parent then
				if shakeConnection then shakeConnection:Disconnect() end
				return
			end

			local elapsed = tick() - startTime
			local remaining = duration - elapsed

			if remaining <= 0 then
				-- Hentikan getaran setelah durasi selesai
				if shakeConnection then shakeConnection:Disconnect() end
				return
			end

			-- Ambil CFrame kamera saat ini (agar kamera tetap mengikuti pemain)
			local currentCFrame = camera.CFrame

			-- Kekuatan berkurang dari 100% menjadi 0% seiring waktu
			local normalizedTime = remaining / duration
			local baseStrength = 5
			local shakeStrength = baseStrength * normalizedTime

			-- Pergeseran acak hanya pada sumbu X (kanan-kiri)
			local offsetX = (math.random() * 2 - 1) * shakeStrength * 0.3
			local offsetY = 0.01 * shakeStrength
			local offsetZ = 0

			camera.CFrame = currentCFrame * CFrame.new(offsetX, offsetY, offsetZ)
		end)
		self.activeCameraShake = shakeConnection
	end

	function Controller:StartCameraShakeHorizontal1(duration, strengthOverride)
		local camera = workspace.CurrentCamera

		if not camera then
			workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
			camera = workspace.CurrentCamera
		end

		if not camera or camera.CameraSubject == nil then return end

		local startTime = tick()
		local shakeConnection

		-- Gunakan override, jika tidak ada, pakai 15
		local baseStrength = strengthOverride or 15

		if self.activeCameraShake then self.activeCameraShake:Disconnect() end
		shakeConnection = self.RunService.RenderStepped:Connect(function()
			if not camera or not camera.Parent then
				if shakeConnection then shakeConnection:Disconnect() end
				return
			end

			-- Hentikan koneksi shake yang mungkin sedang berjalan sebelumnya
			if shakeConnection and not shakeConnection.Connected then return end

			local elapsed = tick() - startTime
			local remaining = duration - elapsed

			if remaining <= 0 then
				if shakeConnection then shakeConnection:Disconnect() end
				return
			end

			local currentCFrame = camera.CFrame
			local normalizedTime = remaining / duration
			local shakeStrength = baseStrength * normalizedTime

			local offsetX = (math.random() * 2 - 1) * shakeStrength * 0.3
			local offsetY = 0.01 * shakeStrength
			local offsetZ = 0

			camera.CFrame = currentCFrame * CFrame.new(offsetX, offsetY, offsetZ)
		end)
		self.activeCameraShake = shakeConnection
	end

	-- Sequence kamera jatuh ikan (fixed view ke atas)
	function Controller:FishDropCameraSequence(fishPart, duration)
		local camera = self.camera
		if not camera or not fishPart or not fishPart.Parent then return end

		self.cameraSequenceToken += 1
		local myToken = self.cameraSequenceToken

		local initialCFrame = camera.CFrame -- Simpan posisi kamera awal

		local hrp = self.character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		-- 1. Set CameraType ke Scriptable
		camera.CameraType = Enum.CameraType.Scriptable

		-- Kamera diposisikan dekat pemain (5 stud di depan) dan dihadapkan
		-- lurus ke atas menuju titik 300 stud.
		local distanceInFront = 5
		local fixedPosition = hrp.CFrame.Position + hrp.CFrame.LookVector * distanceInFront + Vector3.new(0, 5, 0)

		local targetPosition = hrp.CFrame.Position + hrp.CFrame.LookVector * (-distanceInFront) + Vector3.new(0, 300, 0)

		local fixedCFrame = CFrame.lookAt(fixedPosition, targetPosition)

		camera.CFrame = fixedCFrame

		-- 2. Tunggu durasi yang diminta
		task.delay(duration, function()
			if myToken ~= self.cameraSequenceToken then return end
			if not camera or not camera.Parent then return end

			-- 3. Kembalikan CameraType ke Custom dengan transisi halus
			local transitionTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

			if camera.CameraType == Enum.CameraType.Scriptable then
				local transitionTween = self.TweenService:Create(camera, transitionTweenInfo, {CFrame = initialCFrame})
				transitionTween:Play()
				transitionTween.Completed:Wait()
			end

			camera.CameraType = Enum.CameraType.Custom
		end)
	end
end

return Module
