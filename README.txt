WL Simplistic SnowRunner Mod Editor v1.2.0L
Creator: Wicked Lord
Discord: wickedlord69

Simple Edits. Bigger Adventures.

============================================================
WHAT IS v1.2.0L?
============================================================

v1.2.0L is the multilingual interface refresh of the proven v1.2.0 release.
The "L" identifies Language Support. The SnowRunner editing engine remains the
v1.2.0 engine; this refresh adds localization-aware interface improvements and
WL branding without changing the underlying game-editing behavior.

15 interface languages are included:
English, Russian, German, French, Spanish, Polish, Brazilian Portuguese,
Simplified Chinese, Japanese, Korean, Italian, Turkish, Ukrainian, Czech,
and Hindi.

Language selection changes editor display text only. It does NOT translate or
alter SnowRunner XML identifiers, internal truck IDs, file names, PAK contents,
game paths, or modification logic. English is the safe fallback for any
untranslated interface string.

============================================================
INSTALL / RUN
============================================================

1. Download WL-Simplistic-SnowRunner-Mod-Editor.exe.
2. Place the EXE anywhere you want to keep it.
3. Close SnowRunner before applying or restoring changes.
4. Run the EXE.
5. If needed, browse to your SnowRunner initial.pak.
6. Use Scan Trucks for official trucks or Scan Mods for installed third-party mod trucks.
7. Choose a Truck target, select the changes you want, and use Preview Changes first.
8. Click APPLY MODS when you are satisfied with the preview.
9. Launch SnowRunner and test your changes.

Typical Epic Games initial.pak location:
C:\Program Files\Epic Games\SnowRunner\en_us\preload\paks\client\initial.pak

Third-party Mod.io trucks are discovered under SnowRunner's local .modio mods folder.

============================================================
LANGUAGE SUPPORT
============================================================

Use the Language selector at the top of the editor. After changing language,
restart the editor when prompted so the selected interface can be applied.
The language choice is remembered for future launches.

The multilingual UI includes translated main controls, headings, buttons,
status/helper text, restart prompts, and localization-aware layout spacing.
The WL logo is now integrated into the editor header.

============================================================
v1.2.0 / v1.2.0L FEATURE HIGHLIGHTS
============================================================

- Editable third-party mod trucks with exact per-truck targeting.
- Shared multi-truck PAK cumulative editing support.
- Feature-level compatibility: unsupported/inherited features can be skipped
  without rejecting the entire truck.
- Protected per-mod backup and Restore Original support.
- Third-party mod-local crane strength support where safely discoverable.
- Service resource tuning for fuel, water, repair points, and spare wheels.
- All Tires Ignore Ice using SnowRunner's native IsIgnoreIce property.
- Power, fuel, gearing, tires, suspension, steering, durability, stability,
  cranes, winches, economy and other supported tuning controls.
- Quick presets, truck/mod scanning, Preview Changes, protected backup/restore,
  and built-in update checking.

Custom mod crane speed is intentionally left stock when no known-safe universal
control is available.

============================================================
SHARED SNOWRUNNER COMPONENTS
============================================================

SnowRunner reuses some engine, suspension, gearbox, wheel and winch families across
multiple trucks. When a selected truck uses a shared family, changing that component
can also affect other trucks that reference the same family. WL does not clone or
redirect shared game components because doing so can create compatibility and update
risks. Preview Changes reports shared component scope when it is detected.

Truck-local values stored in the selected truck XML remain independently targetable
where supported.

============================================================
BACKUP / RESTORE SAFETY
============================================================

The editor creates and verifies protected backups before modifying supported files.
Use Restore Original to return the selected official game PAK or third-party mod
PAK to its verified pristine baseline.

Third-party mod backups are stored outside SnowRunner's mod scan tree under:
%LOCALAPPDATA%\WL Simplistic SnowRunner Mod Editor\Mod Backups\

Do not manually replace WL backup files with edited PAKs. If a third-party mod is
updated or re-downloaded, the editor may require its baseline to be re-established
rather than silently treating an unknown PAK as original.

============================================================
COMPATIBILITY / TESTING
============================================================

v1.2.0 compatibility testing covered 792 third-party truck definitions across
497 mod PAKs totaling 57.5 GB, with all 792 tested definitions safely handled in
full or through feature-level compatibility during Preview testing.

A selected 39-truck regression library completed 39/39 real Apply testing.
In-game testing, individual Restore Original testing, shared multi-truck PAK
restore testing, and final Apply/gameplay/Restore smoke testing passed.

IMPORTANT COMPATIBILITY NOTICE:
These results describe the tested library and are not a claim of universal
compatibility with every SnowRunner mod.

============================================================
IMPORTANT
============================================================

This utility modifies SnowRunner game/mod XML inside PAK archives. It does not
edit career save data, money, rank, mission progress, or achievements.

Always close SnowRunner before applying or restoring changes.

============================================================
VERIFIED DEVELOPMENT BASELINE - 2026-09-15
============================================================

This source package contains the verified Category Preservation FIX 2E baseline.
Category operations calculate requested values from WL's protected pristine backup
while merging only requested changes into the current live PAK. This preserves
previous WL edits and prevents category multiplier stacking. Literal-safe XML writes,
pre-swap corruption checks, truck-price baseline protection, and shared service
capacity baseline protection are retained as permanent safety behavior.
