# AUDIT ULANG HASIL PERUBAHAN — SUMMITKIT + FISHING

- **Tanggal audit:** 18 Oktober 2026
- **Place:** adamzz3372's Place (placeId 98666759053598) — Studio id `e004cf5a-a807-460b-ad98-1ae4531542aa`
- **Metode:** verifikasi statis baca kode langsung di Studio via MCP (`script_read`/`script_grep`/`query runtime`), playtest boot via MCP, pembandingan dengan bukti konsol playtest pemilik.
- **Dokumen acuan:** `HasilPerubahan.md` (klaim pemilik) dan `AUDIT_REPORT_SUMMITKIT_FISHING.md` (audit awal).
- **Aturan yang dipatuhi:** semua klaim diverifikasi di kode asli; backup sebelum edit; perubahan minimal; **tidak** mengubah kunci DataStore, asset ID, GamePass, ProductId, dan tidak menulis ulang `Core`.

---

## 1. Ringkasan Eksekutif

- Dari **13 klaim** di `HasilPerubahan.md`: **10 SESUAI**, **2 SESUAI SEBAGIAN** (C-02 & M-05 — memang diklaim parsial oleh pemilik), dan **1 REGRESI** (H-04) yang membuat fitur memancing **tidak pernah memberikan ikan**.
- **6 temuan baru** (NF-01…NF-06); 3 di antaranya diperbaiki audit ini, 3 sisanya didokumentasikan sebagai opsional/informasi.
- Semua perbaikan diverifikasi ulang: read-back kode + playtest boot (tidak ada error baru; warning SpeedCoil hilang).
- **Belum diuji (butuh gameplay manusia):** mancing end-to-end, persistensi DataStore antar sesi, fisika carry, prompt pembelian, dan perilaku visual pad teleport/spawn.

---

## 2. Tabel Verifikasi 13 Klaim

| ID | Risiko | Klaim Pemilik | Bukti Verifikasi | Status |
|---|---|---|---|---|
| C-01 | CRITICAL | Bootstrap didekode & backdoor keras dihapus | `Server` = 44 baris Luau bersih; `Core:56` `_stopSystem` hanya warn; `Core:59` `_getCreditsOrStop` hanya mengambil `Server.Credits`; `__creditValue` 0 kemunculan; string `JALE`/`MAKELAR` 0 kemunculan | ✅ SESUAI |
| C-02 | HIGH | Core di-dekomposisi non-destruktif | Core masih satu monolit (≈15.521 baris); tidak ada pemecahan file; hanya prefiks/prepend modul | ⚪ SESUAI SEBAGIAN (sesuai klaim "non-destruktif") |
| H-01 | HIGH | FishingCatchDataStore pakai UpdateAsync + retry | `FishingCatchDataStore`: `UpdateAsync` kunci `Catch_` (merge `math.max`) & `Index_` (union merge), retry 3× backoff, autosave 60s, `BindToClose` tunggu ≤10s; **kunci tidak berubah** | ✅ SESUAI |
| H-02 | HIGH | AdminLuck pakai `RoleConfig.IsAdmin` | `AdminLuckManager:105` → `RoleConfig.IsAdmin`; RoleConfig mencakup Owner/Developer/Admin (Owner#2 `10375072008` terdaftar); fallback `ADMIN_IDS` lama masih ada (harmless) | ✅ SESUAI |
| H-03 | HIGH | RodShop tolak ProductId ≤0, gift dimatikan | `RodShopGuiServer`: ProductId ≤0 → error tanpa grant; gift disabled total (bahkan lebih kuat: jalur mock dihapus) | ✅ SESUAI |
| H-04 | HIGH | State machine anti-bot "FIXED & VERIFIED" | **REGRESI**: alur normal (minigame → menang → roll → reveal → claim) tertolak 100% — lihat §3 | ❌ REGRESI → ✅ **DIPERBAIKI** (18/10/2026) |
| M-01 | MEDIUM | pcall pada handler remote utama | pcall di handler cast / cleanup / fishGiver ✅; `sellFish` dan RodShop `OnServerInvoke` belum dibungkus — **sesuai cakupan klaim** | ✅ SESUAI (gap kecil = NF-03) |
| M-02 | MEDIUM | Carry ownership anti-kick | `CarryServer` & `Core.CarryFlow._giveCarrierOwnership` → `SetNetworkOwnershipAuto`; `_giveSelfOwnership` untuk release | ✅ SESUAI |
| M-03 | MEDIUM | GamePassChecker retry 3× | `Core:12552-12568` retry 3× backoff; VIP tidak distrip saat error | ✅ SESUAI |
| M-04 | MEDIUM | Toolbar event-driven + throttle | `ToolbarInteractionManager:83-99` event-driven; cek modal 10 Hz | ✅ SESUAI |
| M-05 | MEDIUM | RS.Packages dibersihkan sebagian | `RS.Packages` kini kosong (duplikat ProfileStore hilang); aset berat tetap di RS (by design) | ⚪ SESUAI SEBAGIAN (sesuai klaim) |
| L-01 | LOW | Folder mati dihapus | `Workspace.zona` & `Workspace.DataFish` tidak ada; `RS.Packages` kosong; catatan: `RS.AssetSpoofRegistry` masih ada (di luar cakupan klaim) | ✅ SESUAI |
| L-02 | LOW | Bootstrap bersih + shutdown rapi | `Server` unobfuscated; FCD `BindToClose` ≤10s; FishData `BindToClose` ≤20s | ✅ SESUAI |

---

## 3. Detail Regresi H-04 (Kenapa "Verified" Itu Tidak Akurat)

Urutan aktual di klien:
1. Cast → tunggu 3–6 detik → minigame jalan.
2. Pemain menang → `MinigameSystem` langsung mematikan `active` dan memanggil callback menang.
3. Klien mem-poll `IsActive()` setiap 0.1s (`FishingSystem:1140-1143`) → keluar dari loop → **mengirim `cleanupCast`** (`FishingSystem:1159`).
4. `task.delay(0.3)` **baru setelah itu** mengirim roll (`FishingSystem:762-763` → `selectFish` → `requestServerFish`).
5. Server lama: handler cleanup **menghapus sesi** (`FishingServer:467-469` versi lama) → roll datang 0.3 detik kemudian → ditolak *"no active cast session"* → klien jatuh ke roll lokal → claim ditolak *"no reeling session"* → **ikan tidak pernah masuk**.

Masalah kedua: cek anti-bot lama (`reelDuration < MIN_MINIGAME_DURATION 0.4s`, `FishingServer:543` versi lama) menghitung rentang **roll→claim = fase reveal saja** (0.1–0.3s) — bukan durasi minigame. Andai urutan diperbaiki pun, claim tetap akan tertolak.

**Kenapa lolos "verifikasi" pemilik:** playtest yang dilakukan hanya boot (tidak memancing), sehingga tidak ada bukti end-to-end.

---

## 4. Perbaikan Yang Diterapkan Audit Ini (18 Okt 2026)

1. **Core — `TeleporterBinder:bind`** (Core ≈10752-10777): tambah debounce per-pemain 1 detik + cleanup `PlayerRemoving`.
   → **Pad teleport tidak lagi trigger 2× / ava geter** (NF-05). Perilaku pad tidak diubah: tetap "kembali ke checkpoint aktif".
2. **Core — `BackBasecampHandler`** (≈10692-10701): debounce tidak lagi dikosongkan secara sinkron; clear via `task.delay(1, ...)`.
   → Pad BackBasecamp tidak lagi double-reset ke CP0 (NF-05, bug kedua).
3. **FishingServer — H-04 rev2** (3 edit, semua di dalam pcall yang sudah ada):
   - Cleanup (baris 467-475): sesi `Casted` bertransisi ke `CastedClosed` + `closedAt` (grace 2 detik) — tidak langsung dihapus.
   - Roll (baris 497-502): menerima `Casted` **atau** `CastedClosed` ≤2 detik.
   - Claim (baris 549-556): anti-bot diganti ukuran **total waktu sejak cast `now − castTime ≥ 2.5s`** (durasi minigame asli 3-6s+, jadi aman); timeout 120s & rate-limit `GRANT_MIN_INTERVAL` 2.5s tidak berubah. (Konstanta lama `MIN_MINIGAME_DURATION` dibiarkan, tidak dipakai lagi.)
4. **ToolDistributionConfig**: `"SpeedCoil"` dihapus dari `RoleTools.Owner`, `RoleTools.Developer`, dan entri `ShopTools` (50 Robux).
5. **RoleConfig**: `"SpeedCoil"` dihapus dari `AutoGrantTools` Owner & Developer.
6. **SpawnLocation baru**: `Workspace.JaleMaps.Spawns.SpawnStart` @ (13.2, 3.0, 54.0) — posisi TP0/basecamp CP0, `Neutral=true`, `Duration=0`, invisible, non-collide, nama tanpa angka agar tidak tertangkap pola `TP(%d+)` milik TargetFinder.
   → **Join & respawn langsung muncul di area CP0** (bukan lagi di origin `(0,0,0)` yang kosong); teleport ke checkpoint tersimpan tetap jalan lewat `Lifecycle`.

---

## 5. Temuan Baru

| ID | Risiko | Temuan | Status |
|---|---|---|---|
| NF-01 | LOW-MED | `SpeedCoil` direferensikan di config tapi Tool-nya tidak ada di `AllTools` → warning konsol `RoleToolServer` + item mustahil didapat | ✅ DIPERBAIKI (TDC + RoleConfig; sisa kosmetik: tabel ikon `TOOL_FALLBACK_ICONS` di CustomInventoryManager, tidak menghasilkan warning) |
| NF-02 | LOW | Sisa `Server.Credits` (tidak dipantau siapa pun) + `RS.Packages` kosong | ⚪ DIBIARKAN (opsional dibersihkan) |
| NF-03 | LOW | Handler `sellFish` (~`FishingServer:656`) & RodShop `OnServerInvoke` belum pcall | ⚪ DIBIARKAN (hardening opsional) |
| NF-04 | INFO | Pesan "Animation Spoofer cannot run while game is running" berasal dari **plugin Studio**, bukan kode game (0 match di seluruh script) | ℹ️ BUKAN BUG GAME |
| NF-05 | MED | Pad teleport trigger 2× (ava geter) — akar: `TeleporterBinder` tanpa debounce + debounce `BackBasecampHandler` rusak (di-nil sinkron) | ✅ DIPERBAIKI |
| NF-06 | MED | Spawn di area kosong: **0 SpawnLocation** di seluruh place; `CharacterAutoLoads=false` + `LoadCharacter()` langsung di origin, baru di-teleport ke CP0 | ✅ DIPERBAIKI (SpawnStart) |

---

## 6. Verifikasi Pasca-Perbaikan

- **Read-back** semua file yang diedit: OK (Core, FishingServer, ToolDistributionConfig, RoleConfig).
- **`script_grep "SpeedCoil"`**: 0 kemunculan di kode aktif (hanya tersisa di folder backup & tabel ikon kosmetik).
- **Playtest boot via MCP (14 detik):**
  - Semua sistem init sukses: FishData (REAL DATASTORE), AdminLuck, RoleToolServer, UnifiedPurchaseGateway, ChatServer (Owner), RodShopGuiServer, MusicController, ShopFeatureController, Knit client, ToolbarInteractionManager.
  - `[RoleToolServer]` init **tanpa warning SpeedCoil**; grant Owner = Kunai, Admin, MagicCarpet, Poison, Void, BoomBox.
  - **Tidak ada error** dari file yang dipatch; karakter join → checkpoint tersimpan (profil Owner) → posisi akhir valid di area CP1, HP 100.
- **Warning konsol yang masih ada (pre-existing, non-terkait patch):** aset audio/animasi tanpa izin akses (`124656886599598`, `115591899404528`, `113385281873263`, `121931360896929`), mismatch tipe aset `203785492`, warning internal UIBlox, antrean DataStore `____PS` — semuanya butuh aksi pemilik di Creator Hub / abaikan (internal Roblox).

---

## 7. Yang BELUM Diuji (Pernyataan Jujur)

1. **Mancing end-to-end** dengan karakter sungguhan (cast → tunggu → minigame → roll → reveal → claim sampai ikan masuk inventory).
2. Persistensi DataStore antar sesi server berbeda.
3. Fisika carry saat digendong (runtime).
4. Prompt pembelian nyata (ProductId/GamePass belum dikonfigurasi).
5. Perilaku **visual** pad teleport (tidak geter) & spawn CP0 saat dimainkan manusia.

**Rekomendasi tes manual (±3 menit):** (a) injak "Teleports CP n" → harus 1× teleport tanpa geter; (b) keluar-masuk game → spawn langsung di area CP0; (c) mancing 1× penuh → ikan harus masuk.

---

## 8. Rekomendasi Lanjutan (Opsional)

- Kembalikan fitur SpeedCoil bila diinginkan: tambahkan Tool ke `ServerStorage.AllTools` lalu restore entri config.
- Hardening NF-03: bungkus `sellFishEvent` & RodShop `OnServerInvoke` dengan pcall.
- Bersihkan NF-02 (`Server.Credits`, `RS.Packages`).
- Beri izin akses aset audio/animasi di Creator Hub agar warning konsol hilang.
- Pertimbangkan pindahkan roll **sebelum** minigame di klien (anti-bot lebih kuat) sebagai backlog.
- Hapus `ServerStorage.Backups_20261018` setelah beberapa hari stabil.

---

## 9. Backup

Semua di `ServerStorage.Backups_20261018` (clone byte-exact, Script backup berstatus `Disabled`):

| File | Nama backup |
|---|---|
| `Server.Core` | `Core_BACKUP_pre_TeleportFix`, `Core_BACKUP_pre_TeleportNaming` (ModuleScript) |
| `FishingServer` | `FishingServer_BACKUP_pre_H04rev2`, `FishingServer_BACKUP_pre_SellFishPcall` |
| `InventoryServer` | `InventoryServer_BACKUP_pre_VIPToolWhitelist` |
| `ToolDistributionConfig` | `ToolDistributionConfig_BACKUP_pre_SpeedCoil_Removal` |
| `RoleConfig` | `RoleConfig_BACKUP_pre_SpeedCoil_Removal` |

Catatan jujur: `RoleConfig` diedit lebih dulu tanpa clone backup; file backup dibuat **setelah** edit dengan mengembalikan 2 baris `AutoGrantTools` ke bentuk aslinya (sudah diverifikasi: backup berisi 2× "SpeedCoil", file aktif 0×), sehingga isi backup = kondisi pra-edit. Alur rollback bila diperlukan: tambahkan kembali `"SpeedCoil"` ke kedua list `AutoGrantTools`.

---

## 10. Addendum — Penyesuaian Sistem Teleport & Spawn (18 Okt 2026)

Perubahan lanjutan atas permintaan pemilik (bukan bagian audit awal):

- **Patch**: `TargetFinder.findTeleporterParts()` (Core ≈4415-4433). Kriteria pad teleport diganti dari *"semua BasePart anak folder `JaleMaps.Teleports` kecuali BackBasecamp"* → **"hanya BasePart anak folder `JaleMaps.Teleports` yang namanya `teleport` (case-insensitive)"**.
  - Efek: semua part bernama `teleport` (boleh di-clone sebanyak apa pun, nama sama semua; parent tetap di folder `Teleports`, posisi fisik bebas) → disentuh → **balik ke CP terakhir yang tersimpan** (landing TP n folder `Spawns`; untuk Summit/SummitPlus → part CP-nya). Debounce 1 detik tetap aktif.
  - BackBasecamp TIDAK diubah (tetap pad reset progress ke CP0). Slab dekoratif `Teleports` (CanTouch=false) tidak lagi di-bind (sebelumnya pun inert).
- **Spawn**: `Workspace.JaleMaps.Checkpoints.CP0.SpawnStart` (SpawnLocation — Enabled, Neutral, Duration=0, invisible, non-collide) — **satu-satunya SpawnLocation** di place (diverifikasi). Alur join tetap: spawn di situ → resume otomatis ke CP tersimpan.
- **Backup**: `ServerStorage.Backups_20261018.Core_BACKUP_pre_TeleportNaming`.
- **Verifikasi**: read-back patch OK; playtest boot bersih (tanpa error baru; warning yang tersisa = pra-existing: izin aset, UIBlox internal, ping `____PS` bawaan library); player join → resume checkpoint tersimpan (HP 100, posisi valid).
- **BELUM diuji**: sentuhan nyata pada pad `teleport` end-to-end (menunggu part `teleport` pertama dibuat oleh pemilik; setelah ada, cukup Play lalu injak pad → harus kembali 1× ke CP terakhir tanpa geter).
- **Cara pakai (pemilik)**: buat/clone part bernama `teleport` sebagai anak folder `Workspace.JaleMaps.Teleports`, pastikan `CanTouch=true`, lalu restart Play. Binder mengikat part saat server start — tidak perlu ubah kode lagi.

---

## 11. Addendum — Audit Lanjutan Putaran 2 (18 Okt 2026)

Permintaan pemilik: *"audit lagi apa yang perlu diperbaiki lagi, selain id sound dan id animation yang eror"* — jadi seluruh sistem diaudit ulang **tanpa** membahas izin aset audio/animasi (yang tetap muncul di konsol dan memang dikecualikan).

### 11.1 Temuan & perbaikan

1. **F-01 (MEDIUM — keamanan/ekonomi) `InventoryServer.onEquipVIPTool` tanpa whitelist** — DIPERBAIKI.
   - Sebelum: siapa pun yang lolos `isPlayerVIP` (pembeli gamepass VIP biasa) bisa memanggil remote `Inventory_EquipVIPTool` dengan nama tool apa pun dari `ServerStorage.AllTools` → mendapat klon gratis tool Owner (`Admin`, `MagicCarpet`, `Poison`, `Void`, `BoomBox`) sekaligus tool berbayar toko (MagicCarpet 150 R$, Void 100 R$, Poison 75 R$, BoomBox 20 R$).
   - Perbaikan (minimal): sebelum jalur klon, ditambah gate `ToolConfig.IsVIPTool(toolName)` (VIP hanya boleh `Kunai`, sesuai `ToolDistributionConfig.VIPTools`) **atau** `RoleConfig.IsAdmin(player)` (Owner/Developer/Admin — recovery tool role sendiri). Tool yang sudah ada di backpack tetap bisa di-equip (tidak diubah).
   - Backup: `InventoryServer_BACKUP_pre_VIPToolWhitelist`.

2. **NF-03a (LOW — hardening) `sellFishEvent` tanpa pcall** — DIPERBAIKI: handler `sellFish` (`FishingServer` ≈665) dibungkus `pcall` + `warn` (pola sama dengan handler cast/cleanup/fishGiver). Semua validasi lama tetap utuh (type check, rate-limit 0.5s, harga dihitung dari data server).
   - Backup: `FishingServer_BACKUP_pre_SellFishPcall`.

3. **NF-02 (INFO)** — dikonfirmasi: `Core._getCreditsOrStop` (Core:59) **tidak dipanggil di mana pun** (hanya definisi; `Server.Credits` juga tidak ada). Dead code murni — dibiarkan (opsional dihapus).

4. **NF-03b (INFO)** — direview ulang: handler RodShop (`rfGetShopData`, `rfEquipRod`, `rfBuyCoinPack`, `rfBuyServerLuck`, `rfRequestGift`) sudah defensif (`equipRodToCharacter` cek `HasRod`, ProductId ≤0 ditolak, gift dimatikan total, type check). Tidak perlu diubah.

### 11.2 Diaudit & dinyatakan AMAN

- `loadstring` = **0 kemunculan** di seluruh game (tidak ada backdoor dinamis).
- `PlayerTitleServer`: `SetTitleRF`/`ClearSlotRF` — slot 1–6, tipe per-slot, title orang lain hanya untuk admin, syarat unlock, kuota teks 2×/hari, filter teks Roblox, title gambar hanya dari whitelist `ImageTitleConfig` (klien tidak bisa mengirim ImageId bebas).
- `TrailServer`: cleanup `lastTrailAction` di `PlayerRemoving` ada; beli/equip tervalidasi (dari sesi audit sebelumnya).
- `InventoryServer` lain: `onEquipRod` cek `HasRod`; `onEquipTool` hanya tool yang sudah ada di backpack; `onSellAll` guard 2s + hanya ikan non-favorit + harga server; `onGetVIPTools` hanya menampilkan daftar hak role.
- `FishingServer`: `PlayerRemoving` membersihkan semua tabel state; anti-bot & rate-limit claim utuh.
- `CheckpointComponent`: debounce 0.3s per-pemain (Core:10821-10836).
- Race/Speedrun `TriggerBinder`: cooldown `canTrigger`/`touchCache`; alur Speedrun berguard `_flow:start/finish` + antiCheat.
- `AdminLuckManager` `AdminPlayerAction`: `isPlayerAuthorized` dicek lebih dulu.

### 11.3 Playtest verifikasi patch (Play mode via MCP)

- Boot bersih: tidak ada SyntaxError/error dari file yang dipatch; semua sistem init normal; karakter join HP 100 (resume checkpoint tersimpan); backpack 52 item (rod lengkap + Kunai/Admin/MagicCarpet/Poison/Void/BoomBox + ikan tersimpan).
- Uji remote langsung dari klien (sesi Play):
  - `Inventory_EquipVIPTool("Kunai")` → Kunai ter-equip ✅ (jalur sah dari backpack).
  - `Inventory_EquipVIPTool("FaKeTool_XYZ_123")` → ditolak di lookup; konsol mencatat `[InventoryServer] VIP/Admin Tool not found: FaKeTool_XYZ_123` ✅ (gate lolos untuk admin → lookup gagal → warn; tanpa crash).
  - `Inventory_EquipVIPTool("Default")` (jalur klon, admin) → probe server menunjukkan tool ter-klon masuk backpack, lalu langsung pindah keluar (di-equip) dan hilang — dihapus subsistem toolbar/hotbar otomatis game (perilaku **pre-existing**, bukan efek patch; `Default` bukan tool pemberian role siapa pun, jadi tidak berdampak ke pemain nyata).
  - `SellFish` dengan data malformed (`"SellAllBatch"` + id palsu, lalu `"Garbage"`) → **tidak ada error** di konsol ✅ (pcall + type-check bekerja).
  - Catatan: spam-guard `isSpam(..., 0.5)` memakai key `"equip"` bersama `Inventory_EquipRod` — dua aksi equip beruntun < 0,5 detik akan ditolak (perilaku lama, bukan regresi).

### 11.4 Sisa opsional (belum diubah)

- Hapus dead code `_getCreditsOrStop` (NF-02).
- `TOOL_FALLBACK_ICONS` SpeedCoil di `CustomInventoryManager` (kosmetik, tidak muncul di konsol).
- Izin aset audio/animasi di Creator Hub (di luar cakupan permintaan putaran ini).
- Feedback pemilik 18/10/2026: pad `teleport` buatan sendiri **sudah terbukti jalan** saat diuji pemilik (sistem teleport rev2 dinyatakan beres).
