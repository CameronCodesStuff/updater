# ◈ Update Hub

A PowerShell app that scans your **drivers**, **Windows updates**, and **apps** (via winget) — then lets you pick exactly what to update, or update everything in one click. Dark, borderless WPF GUI with a live install console.

## Demo
<img src="https://github.com/CameronCodesStuff/updater/raw/main/example.gif" alt="Updater Demo" width="100%">

## Features

- 🔍 **Full scan on launch** — drivers + Windows updates (Windows Update Agent) + apps (winget)
- ✅ **Pick & choose** — checkbox per update, filter by Drivers / Windows / Apps
- ⚡ **Update Everything** — one button, walks the lot silently
- 🖥️ **Live console** — timestamped log with per-update success/fail results
- 🔁 **Auto rescan** after installing, with reboot detection
- 📦 **Single file** — no modules, no dependencies, self-elevates to admin

## Usage

```
powershell -ExecutionPolicy Bypass -File UpdateHub.ps1
```

Or right-click `UpdateHub.ps1` → **Run with PowerShell**. Accept the UAC prompt and it scans automatically.

## Requirements

- Windows 10 / 11
- PowerShell 5.1+ (built in)
- [winget](https://aka.ms/getwinget) for app updates (optional — skipped if missing)

## Notes

- Driver and Windows updates come straight from the Windows Update Agent COM API — same source as Settings → Windows Update.
- Some updates require a restart; you'll get a prompt when one does.
- winget may truncate long app names in the list — cosmetic only, updates still work.

## License

MIT
