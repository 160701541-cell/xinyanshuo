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

## v0.15 (latest WorldBox functionality; Work APK handoff)

**New WorldBox-only branch is `worldbox/external-mod-lab-v15-giant-qa`**; when integrating the original third-party WorldBox MOD candidate into a privately built APK, use **this** latest source and avoid cherry-picking stale v13/v14 files. Absolutely do not merge this experimental other-game branch with the original 《苍岚·人生世界》 main game or its Android update system.

New feature: the observer has a **「尺寸API自检」** button. In a compatible loaded WorldBox Android runtime, it prints `[XIANXIA-V15] MAP_API_READY/FAIL` plus `titanic.size` and map registry method parameter information. It only READS the game's actual map-size API metadata and does not mutate saves or world size. Collect logs from actual Android 0.51.4 to diagnose whether the experimental **2048×2048 (32×32 chunk)** size can even be registered. The existing 2048² button is a separate *registration experiment only*, not proof that maps will generate, load or save.

Preserve the v13 Chinese readability settings (100%–175%, optional reversible tiny labels on some third-party MODs) and v12 frame guard. Work remains exclusively responsible for private APK packaging, signing and real-device launch tests; GitHub CI passing is not APK runtime certification.

## v0.16 WorldBox-only update — actual generated-world dimensions

Use branch `worldbox/external-mod-lab-v16-diagnostics` as latest source. New `GiantMapOptionsV11.DiagnoseActualWorld()` checks live `MapBox.width` and `MapBox.height` via read-only reflection and reports `WORLD_SIZE_MATCH`, `WORLD_SIZE_DIFFERENT`, or `WORLD_SIZE_FAIL`, with actual tile count vs target 2048×2048. The same in-game 「尺寸API自检」 button now logs both registry compatibility and **actual generated world dimensions** prefixed `[XIANXIA-V16]`. This still does not prove successful world save/load or sustained simulation. Work remains responsible only for private APK assembly/signing and Android device proof. This is exclusively a third-party WorldBox MOD experiment, never the original 《苍岚·人生世界》 game.

## v0.17 Work packaging/Android QA sync — latest isolated WorldBox branch
Use `worldbox/external-mod-lab-v17-world-proof` (not older v13/v14/v15/v16) for the **other-game WorldBox MOD test**, completely unrelated to original 《苍岚·人生世界》. User requested assistant build MOD and Work alone handle local signed APK.
New `tools/worldbox-xianxia/qa/verify_android_world_evidence.py` parses **actual Android logcat** privately and emits JSON with distinct outcomes: API present, 2048x2048 generated-world dimension readback, crashes, and *unverified* device-install/save-reload/FPS. Example: `python tools/worldbox-xianxia/qa/verify_android_world_evidence.py --log path/to/real-logcat.txt --out path/to/result.json`. Never upload user's private logs, game APK, third-party binaries or keystore to this public GitHub branch. Only after Work has real APK/device evidence claim installable/playable; passing dimension readback is not save/load certification. Remain at 2048×2048 target.

## v0.18 REAL CULTIVATION GAMEPLAY SLICE (latest branch)

**Use `worldbox/external-mod-lab-v18-xianxia-data` for the latest other-game WorldBox MOD build, not v17 or earlier.** This is strictly separate from the original 《苍岚·人生世界》 and MUST NOT be merged with main or the original game's APK/PCK/hot-update.

- New `tools/worldbox-xianxia/gameplay/CultivationV18.cs` implements a first playable **in-memory** actor-linked cultivation slice: button `吐纳修炼` in the observation UI, spirit-Qi accumulation, two-second cooldown, staged realm breakthroughs from 炼气 to 筑基/结丹/元婴/化神/炼虚/合体/大乘/渡劫, max 256 actor records, and death cleanup. It does **NOT** modify vanilla actor combat stats, add cultivation buffs, provide full sect combat systems, or persist cultivation records across game restart; do not claim otherwise.
- This source is compiled into the Android NML observer assembly **and** included in the alternate legacy Mono source candidate. Work must check the user-provided actual WorldBox 0.51.4 runtime and NML path before choosing which candidate integrates into the private signed APK.
- Dedicated `CultivationScenarioV18.csproj` C# executable simulates cooldown, Qi and real breakthrough. The huge-map 2048×2048 candidate remains experimental; font scaling 100-175% retained.
- Work owns private single-APK assembly, signature, installation and Android16 real-device QA; do not post commercial APK or third-party DLL to public GitHub.

## v0.21 actual in-game Chinese MOD manager panel
Latest WorldBox-only branch: `worldbox/external-mod-lab-v21-mod-ui`. `ui/ChineseModManagerV21.cs` is now compiled into observer via NML SDK and exposed as 「中文模组管理器」 button. It shows private `Application.persistentDataPath/XianxiaModStaging` subdirectories and their explicitly unverified status, with refresh/close controls. It does NOT implement Android SAF document picker, actual ZIP installation, NML loader enable/disable, or real cross-mod compatibility. The separate `mod-manager/batch_import_v20.py` is an offline safe staging utility; do not claim the Android game can invoke it. Work owns private APK signing, actual game install, and real Android 16 UI verification. Keep this WorldBox experiment completely separate from original Canglan main game.


## 2026-10-20 v0.22 current branch — ACTIVE (overrides historical branch pointer)
**Branch `worldbox/external-mod-lab-v22-zh-localization` only. Read `DEVELOPMENT_LOG_V22.md` before any packaging.**
New sources included in both Android public SDK compiled candidate and legacy Mono source candidate:
- `localization/ChineseLocalizationV22.cs` exact-match vanilla/common-other-MOD Chinese dictionary + user overrides.
- `localization/RuntimeChineseOverlayV22.cs` opt-out reversible Unity UI.Text/TMPro runtime translation pass, throttled and bounded.
- `localization/OriginalMenuGuideV22.cs` in-game Chinese user guide for vanilla menus.
- `ui/ChineseModManagerV21.cs` private staging-only mod UI; no Android SAF file picker or actual MOD installation.
- `tests/RuntimeChineseScenarioV22.csproj` executable behavior QA for live labels, user overrides and safe restore.

**Work integration acceptance:** build user-owned APK privately, verify real Android 16 WorldBox 0.51.4 loads DLL (choose original Mono vs IL2CPP/NML only after verifying loader); actually open vanilla settings/kingdom/menu and other third-party MOD menu; record pre/post untranslated text counts and screenshots, test CJK font and FPS; verify language toggle returns untouched English; verify game saves unaffected. Do not label complete Chinese unless actual on-device menu/key coverage measured. Dynamic Chinese kingdom/city/person names may use the user-provided ChineseName 1.5.1 optional MOD; verify exact NML loader compatibility first and avoid clashing name patches. User goal includes future heaven placement, larger empires with capital imperial palace/building levels, multi-layer sky islands/netherworld; listed as UNIMPLEMENTED in `DEVELOPMENT_LOG_V22.md`. Work must not present them as APK-ready.


## v0.22 native localization continuation — 2026-10-20 (current branch)
Source code now includes **`localization/ChineseMenuGlossaryV23.cs` (580 candidate English→Chinese labels)** and **`localization/NativeLocaleBridgeV23.cs` (reflection reads live `LocalizedTextManager._localized_text` keys and registers matching English→Chinese values through original NML `LM.Add("cz",key,value)`). NML Simplified Chinese language ID is `cz`, not `zh-CN`. The former is confirmed by published WorldBoxOpenMods/AndroidModLoader/general/LM.cs and English official NML multilingual docs; its presence in this particular user-provided modified WorldBox 0.51.4 APK remains unverified. The overlay does NOT autonomously change user's chosen language or alter a save. In-game menu guide has 「登记原版中文」 and 「刷新简体中文」 buttons (the latter applies locale only if actual current language is `cz`). An SDK-only locale symbol inspector `inspector/LocaleTypes.csproj` and executable `tests/NativeLocaleScenarioV23.csproj` were added. CI artifacts should include `WORLDBOX_PUBLIC_LOCALE_TYPES.json` for checking the reference SDK. **No complete localization claim:** full original key table from user's APK and comprehensive game-page/third-party-MOD runtime screenshots must be checked and untranslated entries curated. Save and test UI character rendering, rollback, font sizes, frame time and vanilla WorldBox placement tools remain a required device QA gate. The imperial capital, scalable dynasty multiple cities, upgrading buildings, heavenly placement, sky islands and underworld are SPECIFICATIONS ONLY (all retained in `DEVELOPMENT_LOG_V22.md`), not delivered gameplay. WorldBox isolated branch only; do not touch original Canglan main project.



## v0.22 latest: opt-in missing-translation review and CI gate fixes
- Include `localization/UntranslatedMenuAuditV23.cs` in BOTH legacy Mono source and compiled mobile NML candidates. The original menu guide exposes 「开启/停止漏译采集」 and 「导出漏译清单」. It is **off by default**, stores at most 160 possible unrecognized short English labels in RAM, and writes only to `Application.persistentDataPath/XianxiaModStaging/missing_chinese_ui_v23.txt` on explicit user action. It does not network/upload. The exported report may contain names; review before sharing.
- `tests/UntranslatedMenuScenarioV23.csproj` must PASS along with `NativeLocaleScenarioV23.csproj`, `RuntimeChineseScenarioV22.csproj`, all Python tests, actual public SDK compile, compiled + Mono source candidate structure checks and project scope gate.
- The earlier `MapTypes.csproj` default glob accidentally incorporated new `LocaleTypes.cs`, causing a duplicate top-level program compile; now restricted to `Program.cs`. Earlier private Mono source packaging guard rejects ANY `File.Write` token to prevent save mutation; safe audit source now uses `StreamWriter` in the MOD's own private directory, maintaining the original guard unchanged. These are CI build fixes, **not** verified device installation.
- Work needs to open **all** common vanilla WorldBox 0.51.4 menu pages and at least one other MOD; record actual translated/untranslated strings, loader errors and whether on-device `LocalizedTextManager._localized_text` exposes readable keys. Build an accurate per-page coverage report, then curate the missing terms. A source ZIP / Unity SDK compilation must not be misreported as a signed playable APK or 100% Chinese localization.


## 2026-10-20 FINAL CURRENT WORK HANDOFF — Chinese-first v0.24 on v0.22 branch
**Actual active branch** `worldbox/external-mod-lab-v22-zh-localization`, supersedes all historical branch pointers embedded earlier in this accumulating document. Current development log `tools/worldbox-xianxia/DEVELOPMENT_LOG_V22.md` is authoritative. This is an independent WorldBox third-party MOD experiment, NEVER original Canglan main-game work.

### Concrete sources ready for PRIVATE integration
- The prior 580 original menu, state, god-power, dynasty, building, diplomacy and MOD English→Chinese terms remain in `localization/ChineseMenuGlossaryV23.cs`.
- User-click 「一键选择简中」 attempts the original `LocalizedTextManager.setLanguage(string)` after exact runtime API inspection; chooses NML code `cz`, not fabricated `zh-CN`. No forced background language switch.
- `localization/ChineseTextTemplatesV24.cs` translates safe dynamic numbers like `Population: 1200`→「人口：1200」 across accessible vanilla and other-MOD Text/TMP controls, without rewriting proper names.
- `localization/ChineseKeyPackV24.cs` and `NativeLocaleBridgeV23.RegisterExplicitKeys` import a UTF-8 NML key→简中 translation map at private game path `XianxiaModStaging/zh_cn_keymap_v24.txt` only when the in-game button is pressed, checking 512KiB/4000-entry/duplicate and avoiding registered other MOD translations. **There is still no Android system bulk-ZIP file picker**, only this private per-key adapter.
- `localization/REAL_APK_AND_TRANSLATIONS_V24.md` records real user-provided file hashes, MIT ChineseName source and publicly indexed native-chinese translation alternatives.

### Actual user-uploaded files present in model's current conversation working container
- `WorldBox_0.51.4_用户上传安装包_未整合仙侠MOD.apk`, SHA256 `c39817efa21e539fe61f318dc1ad4050b424c6120ab8ed384d94148f869c4bdc`.
- `0.51.+中文名模组ChineseName_1.5.1.zip`, SHA256 `094b856262a93f24f639774ae235058d2e5c035a8bf8e465264406e397094470`, bundled MIT license from 一米/Inmny, real source code for city, kingdom, actor, culture etc Chinese name generation.
- NOTE: User APK contains `assets/Mono/Managed.zip` with `Assembly-CSharp.dll`, plus both ARM64 `libil2cpp.so` and `libmonosgen-2.0.so`. NML DLL is not present inside top-level `Managed.zip` and **loader compatibility is not yet proven**.

### Reuse before reinventing and verify permissions
The public Worldbox-OWL index has 0.51.x packages **简单汉化模组修正 v1.0.8** (game's normally translatable text, not names/other MODs), **上帝模式翻译 v1.2.2** (dev/god UI labels and descriptions), and **中文名模组 1.5.1** (the uploaded user ZIP, MIT). Refer to `REAL_APK_AND_TRANSLATIONS_V24.md` for exact links and ownership. Other Chinese translation binaries' redistribution license has not yet been checked; **do not post or commit any to public GitHub or bundle without applicable permission**. Test each one *privately* against user's 0.51.4 Android loader, version, saved worlds and conflicts; name mod should never be injected twice.

### Acceptance gate Work MUST perform
1. Read actual provided APK rather than assuming public SDK 2.1 = real WorldBox 0.51.4 runtime. Verify selected Mono/IL2CPP/NML bootstrap chain. No wrong-loader APK modifications.
2. Private-user install: if feasible integrate **authorized** original Chinese pack, uploaded MIT ChineseName and god UI Chinese mod plus our observer translation source in **one signed APK**, preserve package/install ability and backups, no bypassing payment checks.
3. On Android16 actually open and screenshot all original create-world/terrain/god powers/creature spawning/kingdom info/capital/diplomacy/buildings/settings/third-party MOD UIs. Report count translated/untranslated in every category. Verify native Chinese fonts, small-screen clipping, FPS and rollback.
4. Test simulated population dynamic numbers, foreign MOD text and actual Chinese names for creatures/cities/states, saving and reloading worlds; verify no double-name patch or crash.
5. If cannot get **real device boot**, do not call the source ZIP an integrated APK, and state the precise blocker. All green CI is PUBLIC SDK compilation only.
6. Append actual build attempts/errors/status to this branch dev log; never touch original `main`/Canglan APK/PCK/website.

### Current CI evidence
`https://github.com/160701541-cell/xinyanshuo/actions/runs/39440588704` — all 3 job groups green on functional sources including dynamic stat translator and private key importer; later documentation commits only, so check latest run separately. No Android16 device proof.


## CURRENT OVERRIDE v0.25 (2026-10-20): Use ORIGINAL Chinese assets first; packaged NML locale files are now real!
- Same active isolated WorldBox branch: `worldbox/external-mod-lab-v22-zh-localization`. Read authoritative `tools/worldbox-xianxia/DEVELOPMENT_LOG_V22.md` first.
- Actual **user-supplied WorldBox 0.51.4 APK** read-only Unity `globalgamemanagers` scan now confirms **38 languages**, **70 original `locales/cz/*` resource groups** corresponding exactly to 70 `locales/en/*` groups. This is proof of bundled Chinese asset category names **only**, not a full translation coverage test. Local generated user-private report is `WorldBox_0.51.4_原版简体中文资源_只读审计.json`, SHA256 of user APK unchanged; never publish the commercial APK or game strings.
- **On first run, favor vanilla built-in `LocalizedTextManager.setLanguage("cz")`**, exposed via in-game 「一键选择简中」. Prior sequence registered guessed English translations first and risked overriding the vanilla Chinese assets; **fixed** to switch native language first and use third-party fallback translation only for actual missing text. The mod should not silently override official translations.
- **v25 NML auto-load:** the compiled MOD candidate now actually includes `NMLMods/WorldBoxXianxiaObserver/Locales/cz.json` and `en.json` (38 *owned* keys under `xinyanshuo.wb.*`). Legacy Mono source candidate also includes `Mods/WorldBoxXianxiaObserver/Locales/cz.json` & `en.json`. Standard NML `BasicMod<T>` implements `ILocalizable` and resolves `Locales` automatically. Source `OwnLocaleLabelsV25.cs` reads NML `LM.Get` for actual user-visible game menu buttons with Chinese fallback.
- Updated MOD manifest version `0.25.0-chinese-test` still includes `DEVICE_PENDING`, 725 target build, same GUID. Both packers have validated `--locales` option and check owned-key namespace; CI package tests validate six-file compiled NML layout (was 4). 
- For Work private APK test: prioritize enabling and screenshotting native `cz` original game **before installing the old community translation MOD**, as installed game may already have localized original resources. Test other original MODs separately, verifying no name-patch conflict; third-party translations remain incomplete and no in-game SAF ZIP batch file picker exists yet.
- The public branch is source plus independently compiled NML MOD candidate, NOT a rebuilt signed commercial APK. Work must inspect actual user loader chain/Android16, then integrate and validate privately. The independent Canglan game, main branch, APK176, PCK and keys must remain untouched.
