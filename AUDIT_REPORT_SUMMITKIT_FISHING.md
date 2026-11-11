# LAPORAN AUDIT TEKNIS — SUMMITKIT + FISHING

| Metadata | Nilai |
|---|---|
| **Place** | adamzz3372's Place (placeId: 98666759053598) |
| **Tanggal audit** | 18 Oktober 2026 |
| **Metode** | Analisis statis menyeluruh via Roblox Studio MCP (read-only) |
| **Auditor** | opencode (AI assistant) |
| **Status file** | Tidak ada file project yang diubah selama audit |

---

## CAKUPAN & KETERBATASAN

- Seluruh container kode di-inventarisasi: **>500 LuaSourceContainer** first-party (di luar paket vendored).
  - Server: `ServerScriptService` (110 descendants, termasuk `Server.Core` **15.491 baris / 494 KB**).
  - Client: `StarterPlayerScripts` (±260 modul), `StarterGui` (13 ScreenGui), `ReplicatedFirst`.
  - Shared: `ReplicatedStorage` (**11.112 descendants**).
- **Tidak ada file yang tidak dapat diakses.** Artefak internal Roblox Assistant (AssistantUI) diabaikan — bukan bagian game.
- Audit ini **statis** (tidak menjalankan playtest/profiling/MicroProfiler). Klaim runtime diberi tanda keyakinan "perlu verifikasi".
- Paket vendored (ProfileStore, ProfileService, Knit, Promise, Janitor, t, dll.) tidak diaudit baris-per-baris — hanya verifikasi penggunaan & integritas sekilas.
- `Server.Core` diperiksa via pemetaan mekanis (grep terarah) + pembacaan delegasi; bukan bacaan penuh baris-per-baris oleh auditor. Temuan Critical yang dilaporkan balik antaragen **diverifikasi ulang langsung** — tiga klaim terbukti keliru/dilebih-lebihkan dan sudah dikoreksi.

---

## A. RINGKASAN EKSEKUTIF

**Kondisi umum.** Ini game fishing yang cukup matang secara fitur: roll ikan **server-authoritative**, sistem judul/role, speedrun, race, carry (gendong), dance, freecam/spectate, shop rod, trail, donasi, leaderboard, anti-AFK, custom title, dan panel admin — dijalankan di atas Knit + ProfileStore/ProfileService. Namun fondasi infrastrukturnya bermasalah: **seluruh server adalah SATU modul raksasa hasil flatten (15.491 baris) berisi layer anti-tamper obfuscated pihak ketiga dengan kill-switch yang bisa mematikan game secara total**, data pemain tersebar di **≥9 DataStore** dengan dua pustaka profil berbeda dan sinkronisasi asimetris, serta otorisasi admin tersebar di ≥4 daftar yang **saling tidak konsisten**.

**Yang sudah baik (terverifikasi):**
- Penentuan ikan, rarity, weight, dan harga jual sepenuhnya server-side (`FishingServer.rollFishForPlayer`, `FishingConfig.CalculateFishPrice`).
- `UnifiedPurchaseGateway` — satu pipeline `ProcessReceipt` dengan dedup receipt persisten (DataStore, retensi 90 hari). Desain benar.
- Tidak ada `loadstring`; `HttpService` hanya untuk `GenerateGUID`; tidak ada `require` dari HTTP.
- Custom title disanitasi `TextService:FilterStringAsync` + whitelist gambar + kuota 2/24 jam; warna divalidasi.
- Carry system butuh persetujuan target (prompt), cek jarak/limit server-side.
- Transfer ikan: data dihapus sebelum tool dihapus (anti-dupe), rate-limit 3 detik.
- `StreamingEnabled = true`; scene Workspace ringan (139 part).

**Masalah utama:**
1. **C-01** Kill-switch anti-tamper "JALE" obfuscated di bootstrap + Core — bisa meng-kick semua pemain & mematikan seluruh script; memuat bug `__creditValue` yang tidak pernah di-set.
2. **C-02** `Server.Core` monolit 15.491 baris; ±30 stub 6-baris hanya me-`require` Core — arsitektur asli tertimbun.
3. **H-01** Fragmentasi data: 2 pustaka profil, ≥9 DataStore, sinkronisasi Coins asimetris, `FishingCatchDataStore` tanpa session lock.
4. **H-02** Otorisasi admin tersebar & tidak konsisten (RoleConfig 8 UserId vs AdminLuckManager 2 UserId; Developer/Owner#2 tak diakui di jalur admin event).
5. **H-03** Monetisasi belum tersambung: semua CoinPack & ServerLuckBoost `ProductId = 0` → tidak bisa dibeli di produksi; endpoint gift adalah mock yang (hanya di Studio) memberi coin/VIP gratis.
6. **H-04** Alur fishing bisa diotomasi bot: `rollRequest` tidak terikat sesi cast; `claim` hanya cek rollId — tanpa bukti cast/minigame.

**Risiko paling kritis:** kill-switch anti-tamper (game lumpuh massal karena perubahan file/aset sepele) dan hilangnya/terbelahnya data pemain lintas-sistem.

**Rekomendasi prioritas utama:**
1. Putuskan & singkirkan/isolasi anti-tamper JALE.
2. Konsolidasi layer data ke satu pustaka dengan session lock.
3. Satukan otorisasi admin ke satu modul.
4. Selesaikan wiring monetisasi sebelum rilis.

---

## B. INVENTARISASI & PEMETAAN SISTEM

| Sistem | Lokasi | Fungsi | Dependensi | Status diperiksa |
|---|---|---|---|---|
| Bootstrap server | `ServerScriptService.Server` (1 baris, obfuscated) | Matikan CharacterAutoLoads, init Core, start Knit | Knit, Janitor, `Server.Core` | ✅ penuh (decoded) |
| Core server (16 Knit service) | `Server.Core` (15.491 baris) | Admin, AFK, Avatar, Carry, Checkpoint, Dance, Donations, Leaderboard, Overhead, PlayerCommand, PlayerList, Playtime, Race, Shop, Speedrun, Vip | ProfileStore, MessagingService, dll | ✅ terpetakan + baca terarah |
| Stub service (±30×6 baris) | `Server.Services.*`, `Server.Data.*`, `Server.Components.*` | `return require(Core).Services.X` | Core | ✅ |
| Fishing server | `FishingServerScripts.*` (9 file, ±2.300 baris) | Cast, roll, catch, sell, transfer, shop rod, luck, event global | FishingConfig, FishData, ProfileStore | ✅ |
| Data pemain (fishing) | `Data.PetCore.FishData` (670) + `Data.DataModule.ProfileService` (2.263) | Coins, fish, rod, trail, VIP, session | ProfileService (lama) | ✅ |
| Data pemain (sistem lain) | ProfileStore di `Server.Package._Index` | Checkpoint, Shop tools, Speedrun, Vip, Playtime | ProfileStore 1.0.3 | ✅ |
| Catch stat (legacy) | `FishingCatchDataStore` (174) | "Tangkapan" + fish index | DataStore raw | ✅ penuh |
| Pembelian | `UnifiedPurchaseGateway` (206) + `RodShopGuiServer`, `ExclusiveStoreServer`, `TrailServer` | ProcessReceipt tunggal, gamepass, trail | MarketplaceService | ✅ |
| Admin | Core `AdminService` (~11345-11658) + `AdminLuckManager` (567) + `Server.Config.AdminConfig` + `RoleConfig` | Panel, command, jail, ban, event | MessagingService, ProfileStore | ✅ |
| Judul | `PlayerTitleServer` (496) + `CustomTitleRemotes` + Core CustomTitle | Custom title & preset | ProfileStore, TextService | ✅ |
| Tool/Role | `RoleToolServer` (143), `ToolDistributionConfig`, `ServerStorage.AllRods` (32) / `AllTools` (7) | Distribusi tool | RoleConfig | ✅ |
| Carry (gendong) | `CarryServer` (821) + `CarrySystemSupport` + `CarryRemote` | Gendong antar-pemain | Knit CarryService | ✅ |
| UI Client | 13 ScreenGui + `Client.Modules.*` (±200 modul) + 3 monolit (`CustomInventoryManager` 2.255, `ShopFeatureController` 1.050, `RodShopGuiManager` 462) | Inventory, shop, HUD, admin panel, fish index | Remotes | ✅ inti; sisanya sampling |
| Aset fishing | `ReplicatedStorage.FishingSystem.Assets` | ±110 tool ikan, ±100 model, 35 rod, animasi, sound | — | ✅ struktur |
| Shared | `ReplicatedStorage.Shared` (Config/Data/Packages/Assets) | RoleConfig, MusicData, UI config | Knit, dll | ✅ |

**Catatan aset:**
- `StarterPack` & `StarterCharacterScripts` kosong (tool dibagikan script).
- `Workspace.zona` dan `Workspace.DataFish` adalah **folder kosong** (sisa).
- 2 script tween identik tertanam di `Workspace.JaleMaps.Speedrun.{Start,Finish}`.
- Workspace: 139 part, 30 mesh, 4 union, 26 model, 0 suara, 0 lampu.

---

## C. DAFTAR TEMUAN AUDIT

### C-01 · Anti-tamper obfuscated dengan kill-switch global
- **ID:** C-01
- **Sistem/modul:** Bootstrap server + `Server.Core` (anti-tamper pihak ketiga "JALE DEVELOPMENT")
- **Lokasi:** `ServerScriptService.Server` (seluruhnya obfuscated XOR); `Server.Core` baris 56 & 15452; nilai `Server.Credits` (StringValue)
- **Deskripsi:** Sistem lisensi obfuscated yang memantau `Credits.Value`, heritage Core, dan `Credits` property change. Jika salah satu kondisi gagal → `_stopSystem`: mematikan **semua Script/LocalScript** di `ServerScriptService.Server` + **kick semua pemain** + kick setiap pemain yang masuk setelahnya.
- **Bukti (decode statis XOR):** string tersembunyi `"FREEMODEL BY JALE"` (nilai yang diharapkan), `"[JALE DEVELOPMENT] %s"`, `"KAMU RUBAH APA MAS MAKELAR?"`, `"KAMU HAPUS APA MAS?"`. Bug: pada `Core.Init` (baris 15452), `GetPropertyChangedSignal("Value")` membandingkan `v14.Value ~= __creditValue` — **`__creditValue` tidak pernah di-assign di mana pun** (hanya 1 kemunculan di seluruh project). Artinya **perubahan apa pun** pada `Credits.Value` (bahkan diset ke nilai "benar") memicu kill-switch.
- **Dampak:** satu perubahan tak sengaja pada StringValue → semua server kick-massal; tidak bisa diedit/dipindah tanpa risiko; jalur audit tersembunyi; pesan taunt anti-pemilik. Jika Core di-`Destroy`/reparent → error + shutdown.
- **Tingkat risiko:** **CRITICAL**
- **Keyakinan:** Terbukti (decode + pembacaan logika)
- **Rekomendasi:** Putuskan status legal kit ini dengan pemiliknya; singkirkan anti-tamper (ganti dengan struktur kode normal), atau minimal: perbaiki `__creditValue` → literal nilai, ubah perilaku default menjadi *warn* bukan *kill*, dokumentasikan. **Jangan** menyentuh `Credits` sebelum keputusan.
- **Prioritas:** P0 · **Kompleksitas:** S (hapus) / M (rombak aman)

### C-02 · Monolit `Server.Core` 15.491 baris + ±30 stub re-export
- **ID:** C-02
- **Sistem/modul:** Seluruh arsitektur server
- **Lokasi:** `Server.Core` (baris 1-55 header polos; 58-15451 berisi semua modul: CheckpointProfile ~62, ShopProfile ~430, VipProfile ~690, jail ~800-900, admin ~11345, dst.). Stub: `Server.Services.AdminService` = `return Core.Services.AdminService`.
- **Deskripsi:** Seluruh codebase server di-flatten menjadi satu modul. Modul "asli" (~30 file) berisi 6 baris yang hanya me-`require` Core.
- **Bukti:**
  ```lua
  -- Server.Services.ShopService (6 baris)
  local Core = require(ServerScriptService.Server.Core)
  return Core.Services.ShopService
  ```
- **Dampak:** Editor berat; satu error sintaks = seluruh server mati; tidak bisa di-unit-test; merge/review mustahil; docstring berbahasa Indonesia hasil generate ("---Menjalankan fungsi `new`.") menandakan proses flatten otomatis. Stub menyesatkan (edit stub ≠ mengubah perilaku).
- **Tingkat risiko:** **HIGH** (maintainability)
- **Keyakinan:** Terbukti
- **Rekomendasi:** Ekstraksi bertahap: modul di Core dipindahkan kembali ke stub masing-masing (struktur target **sudah ada** di stub `Services/Data/Components`), Core hanya menjadi aggregator. Uji per-modul.
- **Prioritas:** P4 · **Kompleksitas:** L

### H-01 · Fragmentasi layer data & risiko kehilangan/divergensi data
- **ID:** H-01
- **Sistem/modul:** Persistence layer (semua sistem data pemain)
- **Lokasi:** `FishData` + `ProfileService` (lama); `CheckpointProfile`/`ShopProfile`/`SpeedrunProfile`/`VipProfile`/`PlaytimeProfile` di Core (ProfileStore); `FishingCatchDataStore`; `UnifiedPurchaseGateway`
- **Deskripsi:** ≥9 DataStore aktif: `PlayerGameData_V1`, `FishingCatchDataStore`, `PlayerFishIndexDataStore`, `CheckpointProgress`, `ShopToolsData`, `SpeedrunData`, `VipData`, `PlaytimeData`, `PurchaseReceiptLog_V1`. Dua pustaka profil berjalan paralel.
- **Bukti:**
  - Sinkronisasi asimetris `FishData` (~baris 216, 588): `profile.Data.Coins` tidak ditimpa leaderstats saat logout kecuali kondisi tertentu (`coins.Value > 0 or not profile.Data.Coins or profile.Data.Coins == 0`).
  - Autosave tak seragam: ProfileService `AutoSaveProfiles = 30`s vs ProfileStore `AUTO_SAVE_PERIOD = 300`s.
  - `FishingCatchDataStore:SetAsync("Catch_"..userId, ...)` — **tanpa session lock**.
- **Dampak:** Data loss window hingga 5 menit pada sistem ProfileStore; dua server dengan pemain sama bisa saling menimpa; angka leaderboards/title bisa tidak sinkron dengan klaim judul; beban budget DataStore tersebar.
- **Tingkat risiko:** **HIGH**
- **Keyakinan:** Terbukti
- **Rekomendasi:** Satukan ke **satu** pustaka profil (ProfileStore) dengan session lock; jadikan satu sumber kebenaran per stat (leaderstats = view, profil = truth); hapus/migrasikan `FishingCatchDataStore` raw; samakan interval autosave.
- **Prioritas:** P1 · **Kompleksitas:** L

### H-02 · Otorisasi admin terfragmentasi & inkonsisten
- **ID:** H-02
- **Sistem/modul:** Otorisasi admin/permission
- **Lokasi:** `ReplicatedStorage.Shared.Config.RoleConfig` (baris 21-49), `AdminLuckManager` (baris 18-25, 96-131), `PlayerTitleServer` (baris 14), `JoinCommunityTitle`
- **Deskripsi:** ≥4 daftar otorisasi terpisah yang tidak sinkron.
- **Bukti:**
  - `RoleConfig`: Owner `{8978185974, 10375072008}`; Developer `{10165939218, 9443442225, 2939646349}`; Admin `{7319628066}` + username `guard_zvxjekybix`.
  - `AdminLuckManager`: `ADMIN_IDS = {7319628066, 8978185974}` — **tanpa** 3 ID Developer & **tanpa** Owner#2.
  - Grup `352750447` (PlayerTitleServer) dan cek rank ≥250 (AdminLuckManager baris 126).
- **Dampak:** Role "Developer" (`CanUsePanel = true`) bisa membuka panel admin tapi **ditolak** oleh jalur admin event; Owner#2 tidak bisa memicu event; perubahan daftar admin harus dilakukan di ≥2 file dan mudah lupa. Hardcoded UserId = zero fleksibilitas.
- **Tingkat risiko:** **HIGH**
- **Keyakinan:** Terbukti
- **Rekomendasi:** Satu modul kebenaran (`RoleConfig.GetPermissionLevel(player)`) dipakai oleh **semua** pemeriksaan (AdminLuck, AdminService, PlayerTitle, RoleTool). Tambahkan jalur grup + gamepass, dan config eksternal.
- **Prioritas:** P1 · **Kompleksitas:** M

### H-03 · Monetisasi belum tersambung + endpoint mock di Studio
- **ID:** H-03
- **Sistem/modul:** Ekonomi/monetisasi
- **Lokasi:** `ShopMasterConfig` (baris 43-49, 97-130), `RodShopGuiServer` (baris 274-316, 324-368)
- **Deskripsi:** Semua CoinPack & ServerLuck tier memiliki `ProductId = 0` → di produksi tidak bisa dibeli (return "belum tersedia"). Endpoint `rfRequestGift` adalah mock yang hanya aktif di Studio.
- **Bukti:**
  - `ShopMasterConfig`: 4 coin pack & 5 luck tier semua `ProductId = 0`.
  - `RodShopGuiServer:274-284`: `if not RunService:IsStudio() then return {success=false, message="Paket koin belum tersedia saat ini."}`.
  - `RodShopGuiServer:324-327` (gift): `if not RunService:IsStudio() then return {...` — di Studio langsung `GameProfileService:AddCoins(targetPlayer, pack.Coins)` **tanpa pembayaran**.
- **Dampak:** Di produksi tidak ada jalur pembelian koin/luck → potensi pendapatan hilang; mock gift berbahaya bila di-deploy setengah matang (gate dilepas sebelum logika pembayaran ditulis). **Catatan koreksi:** tidak exploitable di produksi saat ini karena gate `IsStudio()`.
- **Tingkat risiko:** **HIGH** (bisnis) + **MEDIUM** (keamanan laten)
- **Keyakinan:** Terbukti
- **Rekomendasi:** Daftarkan ProductId di dashboard → hubungkan ke gateway receipt yang sudah ada (pola VipService/ToolGiver sudah benar); hapus/matikan jalur mock di build rilis atau bungkus dengan flag config.
- **Prioritas:** P1 (produk) / P0 jika rilis minggu ini · **Kompleksitas:** M

### H-04 · Alur menangkap ikan dapat diotomasi (zero-interaction bot)
- **ID:** H-04
- **Sistem/modul:** Fishing gameplay
- **Lokasi:** `FishingServer.lua` baris 422-478 (fishGiverEvent), 485-500 (castReplicationEvent)
- **Deskripsi:** `rollRequest` tidak divalidasi terhadap sesi cast; `claim` hanya mencocokkan `rollId`. Minigame di client murni kosmetik. Bot bisa mengulang `rollRequest → claim` tanpa interaksi apa pun.
- **Bukti:**
  ```lua
  if payload.type == "rollRequest" then
      -- hanya cek cooldown, tidak cek status fishing/cast
      local roll = rollFishForPlayer(player, sanitizePower(payload.power))
  ...
  if payload.type == "claim" then
      if payload.rollId ~= nil and payload.rollId ~= pending.rollId then return end
      grantCaughtFish(player, roll)  -- tanpa bukti minigame selesai
  ```
- **Dampak:** Bot dapat membanjiri ekonomi (coin dari `SellAll` yang sah server-side), mendegradasi arti rarity & leaderboard. Bukan dupe langsung, tetapi inflasi.
- **Tingkat risiko:** **HIGH** (integritas ekonomi gameplay)
- **Keyakinan:** Terbukti (logika)
- **Rekomendasi:** Ikat `rollRequest` ke token cast yang dibuat server saat `CastReplication` diterima (state machine per pemain: Idle → Casted → Rolling → Reeling → Claimed); wajibkan minimal durasi minigame wajar sebelum `claim` diterima; tambahkan heuristik input (request/detik, pola tetap) + telemetry.
- **Prioritas:** P1 · **Kompleksitas:** M

### M-01 · Handler remote tanpa `pcall`; mutasi parsial saat error
- **ID:** M-01
- **Sistem/modul:** Error handling server
- **Lokasi:** `FishingServer` (handler fishGiver/cast/cleanup/sell), `FishTransferServer`, beberapa handler Core
- **Deskripsi:** Handler event tidak dibungkus `pcall`. Error di tengah mutasi multi-langkah meninggalkan state setengah jalan.
- **Dampak:** Log spam error tak tertangani; potensi state inconsistent (mis. data ikan terhapus sebelum tool terpasang).
- **Tingkat risiko:** **MEDIUM**
- **Keyakinan:** Terbukti
- **Rekomendasi:** Bungkus semua `OnServerEvent/OnServerInvoke` dengan `pcall` + log terstruktur; jadikan operasi multi-langkah idempoten (validasi → catat intent → eksekusi → commit).
- **Prioritas:** P2 · **Kompleksitas:** M

### M-02 · Transfer network ownership karakter ke carrier
- **ID:** M-02
- **Sistem/modul:** Carry system
- **Lokasi:** `CarryServer` ~baris 632 (`giveCarrierOwnership(target, carrier)`)
- **Deskripsi:** Network ownership HRP pemain yang digendong diserahkan ke carrier.
- **Dampak:** Carrier yang exploiting bisa mengendalikan fisika karakter korban (fling/teleport) selama digendong.
- **Tingkat risiko:** **MEDIUM**
- **Keyakinan:** Terbukti
- **Rekomendasi:** Jangan menyerahkan ownership (posisikan carried via CFrame dari server), atau batasi durasi + auto-detach saat kecepatan abnormal.
- **Prioritas:** P2 · **Kompleksitas:** M

### M-03 · GamePassChecker false-negative saat API error
- **ID:** M-03
- **Sistem/modul:** VIP/Gamepass
- **Lokasi:** Core `GamePassChecker` ~baris 12544-12548
- **Deskripsi:** `UserOwnsGamePassAsync` dibungkus pcall; saat error → `resolve(ok and owns == true)` = `false`.
- **Dampak:** Pembeli sah kehilangan manfaat VIP/rod sementara (sampai rejoin/API pulih).
- **Tingkat risiko:** **MEDIUM**
- **Keyakinan:** Indikasi kuat
- **Rekomendasi:** Bedakan error vs "tidak memiliki": retry 3× dengan backoff; cache positif + graceful degrade; jangan downgrade atribut karena kegagalan lookup.
- **Prioritas:** P2 · **Kompleksitas:** S

### M-04 · Performa client: kloning aset & loop per-frame
- **ID:** M-04
- **Sistem/modul:** UI client
- **Lokasi:** `CustomInventoryManager.populateFishGrid` (1118-1145), `ToolbarInteractionManager` (83, 384), `SideDrawerController` (142, 200), `CustomInventoryManager` (2082, 1353, 1477, 2219-2224)
- **Deskripsi:** Setiap buka/tab inventory: destroy semua kartu → kloning `Templates.Fish` → buat ViewportFrame + render model per ikan. Beberapa loop permanen (`RenderStepped`/`Heartbeat`/`while true task.wait(1)`) dan `WaitForChild("Backpack")` tanpa timeout.
- **Bukti:** `for _, fishData in ipairs(allFishData) do local card = Templates.Fish:Clone() ... setupFishViewport(...) end` dijalankan ulang tiap populate.
- **Dampak:** Spike alokasi/stutter saat inventory besar (ratusan ikan); beban per-frame kontinu. **Koreksi penting:** klaim "kebocoran koneksi tombol favorit" **terbantah** — kartu lama di-`Destroy` (baris 1119-1123) sehingga koneksi ikut terputus. Bukan leak (terverifikasi).
- **Tingkat risiko:** **MEDIUM**
- **Keyakinan:** Terbukti (statis) — besaran perlu profiling
- **Rekomendasi:** Batasi ViewportFrame (hanya yang terlihat — virtualisasi/paginasi), reuse kartu, ganti loop tetap dengan event-driven, tambah timeout pada WaitForChild.
- **Prioritas:** P3 · **Kompleksitas:** M

### M-05 · Replikasi aset berat ke semua client
- **ID:** M-05
- **Sistem/modul:** Aset/replikasi
- **Lokasi:** `ReplicatedStorage` (11.112 descendants)
- **Deskripsi:** Semua tool ikan (±110), model ikan (±100), rod (35), efek, animasi ada di ReplicatedStorage → direplikasi penuh ke tiap client saat join.
- **Dampak:** Waktu join & memori client membengkak seiring konten bertambah. (Workspace streaming sudah aktif — baik.)
- **Tingkat risiko:** **MEDIUM**
- **Keyakinan:** Terbukti (angka), dampak perlu profiling
- **Rekomendasi:** Pindahkan model/tool yang tidak butuh ada di client sejak awal ke ServerStorage + replikasi saat dibutuhkan.
- **Prioritas:** P3 · **Kompleksitas:** M

### L-01 · Kode/aset mati & duplikat
- **ID:** L-01
- **Sistem/modul:** Housekeeping
- **Lokasi:** `Workspace.zona` (0 descendant), `Workspace.DataFish` (0 anak), `AssetSpoofRegistry` (215 baris, tanpa konsumen), `ReplicatedStorage.Packages.ProfileStore` (duplikat tak terpakai), `StarterGui.ScreenGui` + `LuckyUIHandler` (2 baris), 2 script `"Super Smooth Tween Loop"` identik di Workspace, `RewandConfig` (typo, dipakai 3× di Core)
- **Deskripsi:** Kode/aset sisa tanpa fungsi atau duplikat.
- **Catatan:** `AssetSpoofRegistry` adalah alat tukar ID animasi/sound (perhatikan aspek legal aset).
- **Tingkat risiko:** **LOW**
- **Keyakinan:** Terbukti
- **Rekomendasi:** Hapus bertahap setelah konfirmasi pemilik; dokumentasikan `RewandConfig` (jangan rename tanpa refactor).
- **Prioritas:** P5 · **Kompleksitas:** S

### L-02 · Pragmatisme kecil lain
- **ID:** L-02
- **Sistem/modul:** Lifecycle/infrastruktur
- **Lokasi:** `FishData` (614), `FishingCatchDataStore` (122), `AntiAFKServer` (136), `ProfileService` (168)
- **Deskripsi:** 4 `BindToClose` terpisah; obfuscation membuat `Server` tidak bisa di-review; docstring mixed ID/EN; `RoleConfig.IsOwner` Studio override (`UserId <= 0`).
- **Dampak:** Rawan urutan shutdown; keterbacaan rendah. Studio override aman di produksi (dev-only) — dokumentasikan.
- **Tingkat risiko:** **LOW**
- **Keyakinan:** Terbukti
- **Rekomendasi:** Satukan BindToClose; hilangkan obfuscation; konsistenkan bahasa komentar.
- **Prioritas:** P5 · **Kompleksitas:** S

---

## D. EVALUASI PER SISTEM

- **Player/karakter/spawn:** `CharacterAutoLoads=false`; bootstrap memanggil `LoadCharacter` manual. Berfungsi, tapi ada dependency: **jika bootstrap gagal (anti-tamper/error), tidak ada pemain yang spawn**. Lifecycle respawn ditangani CarryServer & AntiAFK (terverifikasi baik).
- **Data & progres:** Dua zaman arsitektur (ProfileService lama untuk fishing; ProfileStore baru untuk sisanya) + satu jalur raw. Ini akar risiko H-01. `PurchaseReceiptLog` berdiri sendiri dan sehat.
- **Ekonomi:** Roll/jual/harga benar server-side; pintu monetisasi utama belum tersambung (H-03). Trail coin/Robux benar (validasi config + `TryPurchase`).
- **Admin & permission:** Server-side ada (semua aksi privileged memiliki check di server — klaim "Critical" soal panel admin **tidak terbukti**; panel hanya UI), tetapi daftar-daftar admin tak sinkron (H-02). Jail persisten via ProfileStore (baik).
- **Judul/role/statistik:** Sanitasi + kuota + whitelist (baik); ketergantungan pada leaderstats sebagai sumber judul (berisiko drift bersama H-01).
- **Fishing gameplay:** Fondasi server-authoritative (baik) tetapi celah otomasi (H-04). Transfer & sell memiliki proteksi (baik).
- **Carry/Dance/Race/Speedrun/Freecam/Spectate:** Terstruktur (Janitor/Trove dipakai), kebocoran yang ditemukan minor; speedrun punya anti-cheat waktu tak wajar (`KickMessage` Core ~baris 9234).
- **Anti-AFK:** Menyimpan sesi fishing lintas respawn via remote rate-limited 2 dtk; deteksi murni client-reported — tidak mendeteksi bot (keterbatasan by design, bukan bug).
- **UI/HUD:** Paling matang, tapi tiga monolit client (2.255/1.602/1.050 baris) = utang maintainability besar.
- **Audio/VFX:** Sound tersebar di aset fishing; `SoundService` kosong; tidak ada temuan kritis.
- **Komunikasi client-server:** Mayoritas via RemoteEvent/Function dengan rate-limit pada jalur sensitif (cast 0,2s, transfer 3s, sell 0,5-2s, GetFishIndex 1s) — di atas rata-rata untuk project komunitas.

---

## E. AUDIT KEAMANAN & PERFORMA

### KEAMANAN — status per area

| Area | Hasil | Keyakinan |
|---|---|---|
| Gift coin/VIP gratis | **Hanya di Studio** (gate `IsStudio()`); produksi tertutup. Risiko laten bila gate dilepas | Terbukti (verifikasi langsung baris 324-327) |
| TriggerAdminEvent oleh non-admin | **Diblokir server** (`isPlayerAuthorized`: creator/ID/nama/rank≥250); klaim "Critical" subagent keliru | Terbukti |
| ResumeFishingSession | Remote **server→klien** (dipakai AntiAFKServer); tidak bisa dipalsukan client; arah client→server rate-limited | Terbukti |
| Receipt/pembelian | Pipeline tunggal + dedup; ProductId divalidasi per service | Terbukti |
| Judul custom | Filter teks + whitelist + kuota | Terbukti |
| DataStore dari client | Tidak ada jalur tulis langsung | Terbukti |
| loadstring/HTTP | Tidak ada `loadstring`; HttpService hanya GUID | Terbukti |
| Anti-tamper sendiri | **Risiko operasional terbesar** (C-01) | Terbukti |
| Bot auto-fishing | Celah logika nyata (H-04) | Terbukti |
| Ownership karakter saat carry | Risiko exploiter (M-02) | Terbukti |
| Transfer/sell dupe | Tidak ditemukan celah; urutan aman | Terbukti (terbatas pembacaan) |
| Secrets/API key | Tidak ditemukan key/secret di kode; ID admin hardcoded (bukan rahasia, tapi sensitif) | Terbukti |
| Client authority berlebih | Tidak ditemukan jalur mint currency; UI admin hanya mengirim permintaan yang divalidasi server | Terbukti |

### PERFORMA

**Terbukti (statis):**
- Kloning ViewportFrame massal saat buka inventory (M-04).
- `RenderStepped`/`Heartbeat` permanen (ToolbarInteractionManager), loop `task.wait(1)` ganda.
- `ReplicatedStorage` 11.112 descendants direplikasi ke setiap client (M-05).
- Autosave ±4-5 write/menit/pemain (wajar).

**Perlu profiling:**
- Waktu join riil (didominasi RS).
- FPS saat inventory 500+ ikan.
- Biaya anti-tamper `GetDescendants` (hanya saat `_stopSystem` — jarang).
- Dampak streaming pada fisika fishing lintas wilayah.
- Biaya ViewportFrame pada perangkat mobile low-end.

---

## F. RENCANA PERBAIKAN (ROADMAP)

1. **Keamanan & risiko kritis (P0):** Putuskan JALE anti-tamper (hapus/isolasi, perbaiki `__creditValue`); pastikan gate mock gift & coin pack tetap tertutup/dihapus untuk rilis; ikat roll ke cast (H-04).
2. **Bug yang memengaruhi data pemain (P1):** Konsolidasi data ke ProfileStore + session lock; perbaiki sinkronisasi Coins; migrasi/sunting `FishingCatchDataStore`.
3. **Stabilitas & performa (P2):** `pcall` pada semua handler; retry GamePassChecker; batasi ownership carry; hilangkan loop per-frame; timeout WaitForChild.
4. **Refactor arsitektur (P3-P4):** Pecah `Server.Core` (kembalikan ke stub yang sudah menunjuk struktur target); pecah 3 monolit client; satukan otorisasi (`GetPermissionLevel`); satukan BindToClose.
5. **Optimasi & maintainability (P5):** Virtualisasi inventory, lazy-load aset, hapus kode mati (zona/DataFish/AssetSpoofRegistry/RS ProfileStore), konsistensi penamaan (RewandConfig), dokumentasi.

---

## G. PENGUJIAN YANG DISARANKAN

1. **Join/leave/respawn:** 3 pemain login bersamaan; mati saat fishing; respawn → sesi AntiAFK memulihkan; keluar saat menimbang ikan.
2. **Data:** Kill server paksa (shutdown) saat 10 pemain aktif → verifikasi Coin/Tangkapan/Index/Trail judul; bandingkan store lama vs baru.
3. **Dua server paralel** dengan 1 akun (uji session lock) → cek overwrite.
4. **Transaksi (sandbox):** Beli rod dengan koin; beli trail koin/Robux; prompt gamepass batal → tidak ada grant; receipt duplikat → `PurchaseGranted` tanpa dobel.
5. **Gift:** Di produksi (non-Studio) → pastikan "belum tersedia"; jangan lepas gate tanpa receipt.
6. **Permission matrix:** Uji setiap role (Owner/Owner#2/Developer/Admin/Moderator/VIP/player) terhadap: panel, TriggerAdminEvent, jail, GiveCoins, custom title orang lain.
7. **Simulasi exploit:** Fire `FishGiver` tanpa cast (diharapkan lulus saat ini — target perbaikan H-04); spam semua remote; `TransferResponse` tanpa request; `ClaimClearSlot` orang lain.
8. **Carry exploit:** Carrier mengubah kecepatan saat menggendong; gendong saat mati/respawn/teleport.
9. **Anti-tamper:** Di **copy** project — ubah `Credits.Value` → amati kick massal (diharapkan terjadi; bukti C-01); jangan di tempat utama.
10. **Performa (MicroProfiler):** Join time, buka inventory 500+ ikan, 30 pemain server penuh, device simulator mobile.

---

## H. KESIMPULAN

Project ini **secara fitur sudah mendekati siap-uji-publik**, dengan gameplay fishing yang benar secara arsitektur keamanan (server-authoritative, rate-limited, sanitasi judul, receipt tunggal). Namun **infrastrukturnya belum sehat**: anti-tamper obfuscated dengan kill-switch adalah risiko operasional paling serius, data pemain terfragmentasi di 9 DataStore/di dua era pustaka, otorisasi admin tidak konsisten, dan pintu monetisasi produksi belum tersambung.

**Skor kesiapan:** Fungsional untuk testing tertutup, **BELUM direkomendasikan** untuk rilis monetisasi sebelum P0-P1 dikerjakan.

**Langkah paling tepat sekarang:** Setujui temuan & pilih prioritas. Urutan yang disarankan:
1. **C-01** keputusan anti-tamper.
2. **H-01** konsolidasi data.
3. **H-03** monetisasi.

---

*Laporan dihasilkan dari audit statis read-only. Tidak ada file project yang diubah saat audit. Seluruh temuan berbasis bukti kode/konfigurasi; klaim yang tidak dapat diverifikasi ditandai secara eksplisit.*
