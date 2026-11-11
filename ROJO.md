# Rojo — SUMMITKIT + FISHING

Status: **429 script tersinkron dan terverifikasi** (11 Nov 2026).

## Menjalankan

Dari folder proyek:

```powershell
rojo serve
```

Lalu di Studio: plugin **Rojo** → **Connect** → `localhost:34872`.

`aftman.toml` mengunci Rojo 7.7.0.

## Aturan kerja

- **Script**: edit hanya di `src/`. Perubahan script di Studio akan tertimpa saat sync berikutnya.
- **Model / GUI / Tool / Remote / part**: edit di Studio. Instance ini tidak dimapping, jadi aman.
- **Workspace tidak dimapping**. Script di Workspace tidak ada di `src/`.
- Jangan jalankan `rojo build` untuk publish place ini. Build hanya untuk preflight.
- Jangan hapus/rename `init.server.lua`, `init.client.lua`, `init.lua`, atau `*.meta.json` tanpa paham efeknya.
- Backup place tetap disimpan terpisah.

## Mapping

| Studio | Folder |
|---|---|
| ReplicatedFirst | `src/ReplicatedFirst` |
| ReplicatedStorage | `src/ReplicatedStorage` |
| ServerScriptService | `src/ServerScriptService` |
| ServerStorage | `src/ServerStorage` |
| StarterGui | `src/StarterGui` |
| StarterPlayer.StarterPlayerScripts | `src/StarterPlayerScripts` |
| Workspace | tidak dipetakan |

## Verifikasi

- 429 script, 1.782.873 byte, hash identik dengan Studio.
- Jumlah model, mesh, tool, remote, GUI, dan isi Workspace tidak berubah.
- `ServerStorage.__Rojo_SessionLock` adalah marker plugin Rojo, bukan data game.

## Kalau Studio ditutup

Buka place lagi, lalu klik **Rojo → Connect**. `rojo serve` harus tetap berjalan.
Kalau komputer restart, jalankan `rojo serve` lagi dari folder proyek.
