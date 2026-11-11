-- Nama: PlayEquipAnim
-- Letakkan di dalam Tool ikan (misal: "Colossal Squid")

local tool = script.Parent

local character = nil
local humanoid = nil
local animTrack = nil
local animationObject = nil -- [DIUBAH] Kita cari nanti

-- Fungsi untuk memuat animasi
local function loadAnimation()
	if not character then
		character = tool.Parent
	end

	if not humanoid and character then
		humanoid = character:FindFirstChildOfClass("Humanoid")
	end

	-- Pastikan kita punya humanoid & animasi
	if humanoid and animationObject then
		-- Cek jika track sudah ada, hancurkan (untuk mencegah error)
		if animTrack then
			animTrack:Stop()
			animTrack:Destroy()
		end

		-- Muat animasi ke humanoid
		animTrack = humanoid:LoadAnimation(animationObject)
	end
end

-- Saat Tool dipegang (equipped)
tool.Equipped:Connect(function()

	-- [DIUBAH] Kita baru cari 'HoldAnimation' SEKARANG
	if not animationObject then
		animationObject = tool:FindFirstChild("HoldAnimation")
	end

	-- Jika masih tidak ketemu (seharusnya tidak mungkin), beri peringatan
	if not animationObject then
		warn("ERROR: Tidak bisa menemukan 'HoldAnimation' di dalam " .. tool.Name)
		return
	end

	-- Panggil fungsi untuk memuat animasi
	loadAnimation()

	-- Mainkan animasi
	if animTrack then
		animTrack:Play()
	end
end)

-- Saat Tool dilepas (unequipped)
tool.Unequipped:Connect(function()
	-- Hentikan animasi
	if animTrack then
		animTrack:Stop()
	end
end)

-- Bersihkan jika tool dihancurkan (misal: dijual)
tool.Destroying:Connect(function()
	if animTrack then
		animTrack:Stop()
		animTrack:Destroy()
	end
end)