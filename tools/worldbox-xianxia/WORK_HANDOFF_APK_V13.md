# WORK HANDOFF — WorldBox third-party MOD packaging lab (NOT Canglan)
Date: 2026-10-20. Branch: `worldbox/external-mod-lab-v13-font-apk`.

## Absolute boundary
This branch experiments with **third-party WorldBox Android 0.51.4 mod derivatives**. It is entirely unrelated to the development, publishing, game source, art, changelog, RSA signing, or APK/PCK hot updates of **《苍岚·人生世界》**. Never merge into main or edit `game-source/`, `android-preview/`, `docs/CAC_CHANGELOG.md`, `AGENTS.md`, `art/`, `data/`, or the official game website.

## User acceptance target
One downloadable Android APK that installs and actually runs WorldBox with readable Chinese fonts and the xianxia observer mod; user is not a programmer and will not operate MT Manager. Snapdragon 8 Elite requested for larger maps. This is a **target, not completed**. Re-signing permitted; Android may refuse update of an existing install with a different signing certificate, and save backup is mandatory.

## Existing files in public branch
- `tools/worldbox-xianxia/README_V11.md`, `README_V12.md` and source history.
- `tools/worldbox-xianxia/README_V10.md`, `USER_APK_LOADER_PROFILE_20261020.md`, `READ_FIRST_APK_COMPAT_V10.md`: user's original APK appears Mono + IL2CPP; archived installation text describes legacy Mono NML; newer public Android NML is distinct.
- `tools/worldbox-xianxia/nml-observer-v07/Code/XianxiaObserverV07.cs`: observer touchscreen control, pseudo-3D tiles, actor-follow, experimental maps, live FPS.
- `tools/worldbox-xianxia/ui/ModTextAccessibilityV13.cs`: Chinese fonts 100%/125%/150%/175%; opt-in reversible scaling for some Unity UI/TextMeshPro small text. Not verified on target device.
- `tools/worldbox-xianxia/huge-map-mod/GiantMapOptionsV11.cs`: optional large-map registration candidates; not verified to work in game.
- `tools/worldbox-xianxia/huge-map-mod/ObserverFrameGuardV12.cs`: extra observer rendering suspends when FPS stays low.
- `tools/worldbox-xianxia/private-apk-lab/XianxiaMonoBridge.cs`: **original source** of optional Mono font accessibility bridge for a private local build.
- `tools/worldbox-xianxia/private-apk-lab/GameAssemblyToolkit.csproj` and `Program.cs`: work-in-progress generic C# assembly inspector and patcher. Do not assume it is build- or runtime-certified.
- `tools/worldbox-xianxia/tests/WorldBoxObserver.AndroidSdk.csproj`: SDK compile contract.
- `.github/workflows/worldbox-external-mod-lab-v13.yml`: separate source test/compiled candidate workflow. Inspect actual last run status first; earlier source C# tests passed, some private APK toolkit edits have failed CI and need fixing.

## Required Work steps
1. Read this note, all relevant development logs, and `project_scope.json`. Confirm independent branch and record current actual CI run status; do not edit main.
2. Identify locally uploaded **user-provided** archive `安卓版世界盒子(支持模组)_0.51.4 (1).zip` with nested `世界盒子_0.51.4(64位，支持模组).apk`; in earlier work this user APK was ~168MB and must not be uploaded to the public repo. If absent in Work environment, use the conversation attachment; never synthesize proprietary APK content.
3. Back up full APK and any existing user-world saves; inspect AndroidManifest, actual runtime loading implementation and managed DLLs, SHA256 and package application ID, and compare original 0.51.4 APIs against public SDK.
4. **Choose ONE confirmed loader path** compatible with the actual uploaded APK: legacy Mono source `Mods/` or newer LemonLoader/NML mobile `NMLMods/`. Never mix blindly. Check the included Chinese install directions but treat claims as unverified until static/runtime checks.
5. Compile the original UI/font/observer code against the exact managed game/Unity references of the chosen runtime; resolve all compiler and runtime issues. Existing public 2.1 SDK compiling does not prove the user's older modded APK can load it.
6. If modifying the user-owned game APK is technically and legally feasible, implement minimal reversible packaging locally, no paid-content unlock/DRM bypass. Do not redistribute third-party mods or APK in the public GitHub source branch. Keep proof of each APK diff, native lib changes, assets, manifest permissions and package ID. No unrelated patches.
7. APK build: use Android SDK `zipalign`, `apksigner` with a **dedicated new local test keystore**, align, sign, verify signatures (v2/v3 when applicable), verify split/ABI compatibility, compute APK SHA256. Never expose/upload private keys. On a signing mismatch, user may need to install side by side with a distinct package id if supported; never uninstall a live install without backed-up saves. Merely re-signing does not make an invalid loader work.
8. Actual Android device/emulator QA: launch into WorldBox world; assert font scaling and Chinese characters display without missing glyphs, other-mod tiny-text behavior, touch hit targets, observer on/off, real actor-map tile read, save/read and high-FPS stability. Test world sizes 12x12 then 16x16 before 20x20. If no device available, mark DEVICE_PENDING and *do not call it playable*.
9. Only after checks pass, provide the user a **single sandbox-linked signed installable APK** with SHA256, version/build, what is integrated, changes, install instructions requiring at most a tap, and how backups work. Otherwise explicitly report exact build blocker and provide compiled candidate files without claiming one-tap works.
10. Append actual command/test evidence and honest status into `tools/worldbox-xianxia/DEVELOPMENT_LOG_WORK_HANDOFF.md` on this isolated branch.

## Safety and delivery
- Respect original WorldBox and third-party MOD redistribution licenses; do not publish uploaded commercial APK and user mod DLLs to the *public* GitHub repository. Public branch source only.
- APK and private test builds must remain private to user/Work artifacts.
- Do not claim on-device test without logs/device evidence.
- No Work plans, notes, or success claims may be copied into the original Canglan game's development log.

## 2026-10-20 user-approved giant map target (latest requirement)
- The user explicitly chose **2000 × 2000 terrain tiles** as the map target, superseding earlier 1024 × 1024 recommendations. This is a target, **not an implemented or proven playable size**.
- Existing experimental map planner treats one chunk as 64 × 64 tiles. Thus 2000 / 64 = 31.25 chunks per side; a chunk-aligned **32 × 32 map is 2048 × 2048 tiles = 4,194,304 tiles**, 16 × the area of the 512 × 512 baseline. The exact 2000 × 2000 size is only appropriate if the actual WorldBox map APIs support non-chunk-aligned dimensions; validate before promising either.
- This request specifically prioritizes a large map on Snapdragon 8 Elite. The Work integrator should attempt an **opt-in 2048 × 2048 stress-test preset**, without removing smaller defaults, and test world generation, memory, NPC simulation, save-load, battery/thermal behavior. Use conservative population/AI throttling and staged stress tests; do not pretend high-end SoC guarantees this can run.
- Never change existing saves or silently auto-upscale pre-existing maps. Keep experimental selection off by default until Android device QA passes. If 2048² fails, report measurements and fall back to the largest proven stable preset; do not mislabel smaller sizes as 2000².

## 2026-10-20 — v0.14 Work handoff: NEWER branch for game functionality

**Use `worldbox/external-mod-lab-v14-giant-map` for latest WorldBox-only functionality**; do not develop on superseded v13 in parallel without merging/rebasing intentionally. This is still **completely unrelated** to original 《苍岚·人生世界》 game development; never merge to `main`.

- Added a separate **2048 × 2048 (32 × 32 chunks; 4,194,304 tiles)** experimental new-world preset registration in `tools/worldbox-xianxia/huge-map-mod/GiantMapOptionsV11.cs`. It is **not automatically enabled** by the Snapdragon 8 Elite device, and must be explicitly selected with two taps in the `XianxiaObserverV07.cs` GUI.
- This is only a **candidate registration**, not proven to appear in the WorldBox world-creation menu, generate correctly, save/load, or run well on Android. Work must inspect exact WorldBox 0.51.4 `MapSizeLibrary` behavior and QA before claiming implementation.
- Added `tools/worldbox-xianxia/test_v14_giant.py` unit regression and added 32×32 to `world_size_planner.py` capacity analysis. Do NOT default 2048² on first launch. Keep existing saves unchanged; measure actual peak RAM, sustained frame time, thermal behavior, 5k–20k NPC pathfinding and world persistence on target Snapdragon 8 Elite phone.
- v13 font accessibility module `ui/ModTextAccessibilityV13.cs` remains in v14: 100/125/150/175% scales, opt-in scaling of other mods' tiny Unity UI labels; Android in-game font rendering and overall readability must still be validated.
- Continue separately testing/packing the mod in Work. Work owns end-to-end APK integration and signing **locally/private**, not in this public branch. An APK is **not delivered merely because the MOD compiler CI passes**.
