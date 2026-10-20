# WorldBox APK v13 — Work execution log

## 2026-10-20 — Private exact-APK compile, repack and signing

Scope: WorldBox third-party MOD experiment only. Branch
`worldbox/external-mod-lab-v13-font-apk`; base commit
`416caebcbccbf07354ff31c0cc3dedc1f5d3aa4d`. No main merge or changes to
Canglan source, website, development logs, RSA or OTA. User explicitly
authorized private APK modification and a new dedicated test certificate;
`project_scope.json` now records that narrow authorization.

### Starting evidence

- Read WORK_HANDOFF_APK_V13.md, project_scope.json, V10/V11/V12 logs,
  actual-APK loader profile, source, build workflow and root AGENTS.md.
- Latest starting CI run **39410297954 failed**: source QA and public Android
  SDK compile succeeded; private toolkit job **118586124431** failed with
  CS1061 at Program.cs:95 (`ModuleDefMD.AssemblyRefs` does not exist).
- Retrieved user's existing uploaded archive privately; original APK is
  168526010 bytes, SHA256
  `c39817efa21e539fe61f318dc1ad4050b424c6120ab8ed384d94148f869c4bdc`.
- Parsed manifest: `com.mkarpenko.worldbox`, version 0.51.4, code 725,
  minSdk 23, targetSdk 35, UnityPlayerActivity. ARM64 libraries present.
- Original certificate SHA256:
  `a40da80a59d170caa950cf15c18c454d47a39b26989d8b640ecd745ba71bf5dc`.
- Read actual Mono ModLoader IL: loads `<persistentDataPath>/mods/*.dll`,
  seeks `<filename>.WorldBoxMod`, and Update gates loading on game_loaded
  and experimental_mode. This proves that managed code's contract, **not**
  that Android actually enters it. Native libil2cpp contains Mono bootstrap
  strings; active runtime remains unverified without a device.

### Original source changes

1. Fixed invalid dnlib API usage. AssemblyRef is emitted via the TypeRef.
2. Fixed verification falsely rejecting shifted branch byte offsets. Compare
   normalized instruction targets, locals and exception regions, and audit
   **all** original method bodies rather than only startup.
3. Observer compiled against real user APK references initially failed:
   MapBox.camera is not publicly accessible in this APK. Changed camera
   access to reflection including private/static members; retained existing
   runtime checks and no direct simulation mutation.
4. Added `private-apk-lab/prepare_mono_bridge.py`: reproducible source adapter
   joining our existing observer, font UI, map options and frame guard to
   the original Mono bridge. This candidate uses **no NML bootstrap**, no
   LemonLoader and no mixed Mono/IL2CPP references. It is a private Mono
   entry-hook experiment, not certified loader compatibility.
5. Added `private-apk-lab/package_private_candidate.py`: private copy-only
   packaging; replaces Managed.zip's Assembly-CSharp.dll, removes its stale
   PDB, adds our original bridge, removes old signature entries, checks CRC,
   compares all other APK entries byte-for-byte and refuses input overwrite.
6. Workflow now includes zipalign's matching libc++.so dependency. The older
   downloaded helper lacked it; using a library from a different build-tools
   version also failed symbol resolution. A matched official build-tools 35
   zipalign/libc++ pair worked locally.
7. Added synthetic repacking regression covering original bytes, unchanged
   manifest/native/Dex entries, stale signatures/symbols and input/output
   protection. Added local output/key ignore rules; staged source only.

### Actual local commands and results

- `dotnet build .../private-apk-lab/GameAssemblyToolkit.csproj -c Release`:
  **success**, zero warnings/errors after fix, .NET SDK 8.0.426.
- `GameAssemblyToolkit compile` against **extracted original Mono game and
  Unity references**: font bridge success; observer+font+map+guard NML source
  success after camera fix; standalone integrated Mono bridge success.
  One existing unused-field warning in frame guard. No stub-based success
  substituted for these exact-reference compiles.
- `GameAssemblyToolkit patch` then `verify`: **success**;
  20597 original method bodies audited, 234 original startup instructions
  preserved, one original-plugin call added to MapBox.Start.
- Syntax contract project: **build success**. FrameGuardScenarioV12:
  **PASS**. FontAccessibilityScenarioV13: **PASS**.
- `python3 -m unittest discover -s tools/worldbox-xianxia -p 'test_v*.py' -v`:
  **38 passed**. Python compileall and git diff --check succeeded.
- Some `dotnet run` invocations hit a host `/proc` process-stat exception;
  building and directly executing scenario DLLs completed successfully.
- Host had no dotnet/Android SDK initially. Retrieved generic toolkit from
  earlier successful CI 39391226846, installed SDK locally, and used official
  Android build-tools locally. System apt failed due host UID/cache permissions;
  no escalation or changes to game files were used to solve this.

### Private signed build — NOT delivered or certified playable

- Private candidate bytes: **167719100**.
- SHA256: `071b9299518e0724dbc0adedde54edf75db5c39c0cd541c5f2ced12655a7004b`.
- `apksigner verify --verbose --print-certs`: **v1/v2/v3 true**.
- `zipalign -c -P 16 4`: **exit 0**. ZIP alignment does not prove native ELF
  segment page-size compatibility or Snapdragon performance.
- New test certificate SHA256:
  `a1fa2827668e11da772e9984f277623bb95fc7e0556622a755b7117b8c407104`.
  Private key/password remain outside the repository and are never published.
- Manifest/package/version/permissions, native libraries and DEX unchanged.
  APK diff limited to managed archive plus required signature replacement.
  Original APK retained unchanged. No device storage accessed or modified.

### Release blockers and remaining acceptance work

**Status: SIGNED_DEVICE_PENDING_NOT_FOR_INSTALL. No downloadable release.**

1. No adb, connected Android phone, emulator, system image or /dev/kvm in this
   environment. No launch, touch, CJK glyph, font-layout, world generation,
   follow/pseudo-3D, 12x12/16x16, save/load or sustained FPS device test.
2. The new certificate differs from the original. Same-package replacement
   will not be a valid update. No safe side-by-side package migration has
   been implemented/tested; never instruct uninstall or clear-data.
3. Existing phone-world saves are unavailable here and **not backed up**.
   Preserving uploaded APK bytes is not a backup of phone saves.
4. Other uploaded third-party MODs have **not** been integrated into this
   candidate; their runtime/API and licenses still require individual audit.
5. Observer/map/font code compiles, but active Mono startup/extraction and
   live API behavior still need runtime logs. Existing extracted managed
   files may require migration on an already-installed device; untested.
6. No payment/unlock/DRM modification made. Commercial APK and third-party
   DLLs are private intermediate inputs/outputs, never public GitHub content.

Next required environment capability: Android device/emulator access with
backup/import/export validation, then loader/feature QA and private release.
Do not mark any Android acceptance item passed from these static results.

### Concurrent handoff update preserved

Before publishing this work, the branch advanced to
`c0a6c7380069819015f09f41a9cce15e06a7d137`: handoff now sets a 2000x2000 tile
target, with an opt-in 2048x2048 chunk-aligned stress preset to investigate.
Preserve that update when writing this source commit. This build does not
implement or certify 2000/2048-square maps; that acceptance item remains open.

## 2026-10-20 — v14 user-authorized Android install test + diagnostic logs

User follow-up explicitly authorized receiving a test APK and doing device QA
personally: “你打包我安装不就行了，写个报错日志”. This supersedes withholding
all APKs until in-session device testing. Status is **USER_DEVICE_TEST_CANDIDATE**,
never a claim of successful phone launch or complete MOD integration.

### Original changes and save isolation

- Added an original Java `DiagnosticsActivity` launcher, independent of Unity.
  It shows Start Game / Copy Error Log / Share Error Log. It records entry and
  Unity-start requests before loading Unity, captures Java uncaught exceptions,
  reads current/previous Mono logs and shares text through Android's chooser.
  Logs stay on-device unless the user explicitly copies/shares them.
- Added original `DiagnosticLog.cs`: Unity threaded log callback, managed
  unhandled exception capture, device/GPU/startup context, lifecycle messages,
  bounded files and rotation. Added in-game copy-log button. Native SIGSEGV,
  OS kills, or failures before app code executes may lack a full stack trace.
- New application ID **com.xinyanshuo.worldbox.lab13**; name
  **WorldBox·万界仙侠 测试v14**. Android grants a separate app identity/data area.
  Existing WorldBox installation is retained; no uninstall, clear-data, old
  world access, automatic save import or format conversion is performed.
- Added original AXML clone script preserving resource IDs and original class
  names, changing package-specific provider authorities/custom permission,
  retaining Unity activity and adding our diagnostic activity as launcher.
  Added a separate classes5.dex containing only our three diagnostic classes.
- Native libraries, original classes.dex/classes2/3/4.dex and resources.arsc
  compare byte-for-byte equal to uploaded APK. No paid-content code altered.
- Exact managed references compile succeeds; MapBox.Start hook verified again
  across 20597 original method bodies. Java compiled with Eclipse ECJ 3.39.0,
  Android platform35 android.jar, D8/build-tools35, min-api23; no game Java code
  recompilation. All original source remains in WorldBox-only paths.

### Build and actual verification

- Output: `WorldBox_Xianxia_v14_Android_Test.apk`, **167723254 bytes**.
- SHA256: `2403a65c7c476f46866993e972a41c5818b020d3b68fb9a921339bfe39f8dcb2`.
- Dedicated v13 test key reused locally; v1/v2/v3 signatures verify; 16KB ZIP
  alignment check exits 0. Test certificate unchanged from preceding record.
- Parsed final manifest with Androguard: clone app ID/name and diagnostic main
  activity correct; all eight provider authorities differ from original;
  Android permission set unchanged except package-scoped custom permission;
  exactly one additional activity, and no authority collision with old APK.
- Inspected generated DEX: only DiagnosticsActivity plus two listener classes.
- APK CRC and strict per-entry diff verification succeeded. Only original
  AndroidManifest.xml and assets/Mono/Managed.zip changed, plus added diagnostic
  DEX and new signatures. Original APK retained unchanged.
- Python regression suite: **38 passed**; git diff --check passed.
- **Android launch/UI/CJK/font sizing/world generation/follow/pseudo-3D/map
  sizes/save-load/FPS remain USER_PENDING**, to be checked after installation.
- Third-party MODs and 2000/2048-square map target remain incomplete. The APK
  is a baseline logging/observer test candidate, not the promised final all-MOD
  integrated edition. No commercial game or third-party DLL published to GitHub.

User flow: install side by side, tap Start Game; if launch fails, reopen the
diagnostic launcher and Copy Error Log, then paste it into this conversation.
If Android refuses installation, send its displayed error; do not uninstall old
WorldBox. Phone save migration remains a separate unimplemented acceptance item.

- Delivery integrity: host-upload initially truncated the APK central directory; caught by post-upload SHA/signature verification. Rebuilt signed bytes from aligned input and switched to exact-size prepared transfer; do not distribute the invalid intermediate.

- Prepared transfer saved the full 167723254-byte APK; downloaded it back for SHA256/v1-v2-v3 signature and alignment verification before providing the user link. Final status: USER_DEVICE_TEST_CANDIDATE, no Android runtime pass claim.

## 2026-10-20 — v15 fixes device-reported resource namespace crash

### Real device failure (v14 acceptance FAIL)

User installed v14 on OnePlus PKR110 / Android16 and returned the diagnostic
report. Native launcher works and records START_UNITY_REQUEST, then Unity
2022.3.62f3 crashes in `com.unity3d.player.i0.a(Context)` with
`Resources$NotFoundException: String resource ID #0x0`. No Mono log yet.
This is a pre-MOD startup failure, not evidence of MOD load success.

Root cause: v14 manifest application ID was changed for side-by-side installation
but the fixed package name field in resources.arsc remained
`com.mkarpenko.worldbox`. Read the actual classes3.dex method: Unity calls
getIdentifier("game_view_content_description", "string", context.getPackageName())
then getString(id) without checking zero. The v14 parser confirms the string
exists under the original resource package and is absent under the cloned one.
The same mismatch also affected unitySurfaceView ID lookup. This was a packaging
oversight in v14, not a user installation error.

### Fix and checks

- Added original `clone_resource_table.py`; changes only ResTable_package's
  UTF16[128] package name field. Exactly **25 bytes** differ in the real
  table; table length, package numeric ID, resource IDs, offsets, values,
  translations and all configurations remain byte-for-byte intact.
- Packaging now synchronizes both manifest and compiled resource identity.
  Manifest/app remains `com.xinyanshuo.worldbox.lab13`, same test certificate
  as v14. versionCode raised **725 → 726**; label and diagnostics now v15.
  User can update v14 without uninstall/clear-data; no original app access.
- Added native launcher preflight resolving both critical resources using
  Android getResources/getIdentifier before requesting Unity. It logs the
  IDs; missing IDs now yield a readable diagnostic rather than knowingly
  calling into the same failing Unity path.
- Recompiled Java diagnostics and original Mono bridge against exact APK
  references; entry-hook verification again passes across 20597 method bodies.
- Python regression: **41 tests passed**, including new synthetic fixed-field
  preservation and missing/duplicate/oversized/truncated table rejection.
- Final APK resource parser: package name matches cloned manifest;
  game_view_content_description resolves to **0x7f0e0053** and unitySurfaceView
  to **0x7f07017e**, exactly matching their original numeric IDs. This same
  cloned-package lookup returns absent in v14, reproducing the static defect.
- Original native libraries and classes.dex/classes2/3/4.dex remain unchanged.
  Permission set matches v14. No billing/entitlement changes.
- v1/v2/v3 verification succeeds. Dedicated test certificate unchanged;
  build uses atomic publication from a fully signed temporary file to avoid
  exposing partially-written large artifacts. ZIP alignment verified.

### User test candidate

- `WorldBox_Xianxia_v15_Android_Test.apk`: **167723254 bytes**.
- SHA256: `162c2bcc2146b59cc65730bdf544de58cd0a486d9fb66a5ee4b66ea46258f87c`.
- Android runtime status: **USER_PENDING**. The package defect is statically
  corrected; a new phone launch is still required before marking startup passed.
- Full third-party MOD integration, huge-map pressure tests, gameplay and
  save-load QA remain open. No claim that v15 is the final integrated edition.
- User flow: update the existing test app directly, tap Start Game. If it fails,
  reopen diagnostics, Copy Error Log and return it; preserve old WorldBox.

## 2026-10-20 19:23 Asia/Shanghai — user-confirmed v15 launch

User reports “可以进” after receiving v15. Record **USER_CONFIRMED_STARTUP_PASS**
on the previously reported OnePlus PKR110 / Android16. This confirms entering
the game following the resource-package fix; it is user testimony, not an
in-session adb test. No new screenshot or Unity/Mono loading log supplied.

Still UNVERIFIED: original bridge execution/MOD load, font scaling and CJK
layout, observer/actor follow/pseudo-3D, large-map generation, save/read,
performance/thermal behavior and complete third-party MOD integration. Do not
promote this narrow startup confirmation to full gameplay acceptance.

Next device acceptance: check whether the in-game 万界·清晰大字 and observer
controls appear, exercise font sizes, and return diagnostic logs if missing.

## 2026-10-20 — v16 first actual compatible third-party MOD integration

User explicitly requested integrating the MODs rather than continuing launcher-only tests. Preserved v15 user-confirmed startup and the separate test app identity. v16 is a new user-device test candidate, NOT a full final xianxia edition or a phone-verified MOD pass.

### Uploaded file audit (actual contents)

- NeoModLoader 1.2.1.1: legacy Mono loader, not NeoModLoader_mobile/LemonLoader. Exact game metadata audit: 380 referenced game/NML members checked, zero missing. Read official source tag 1.2.1.1 (f6017bdcb6a3cfd4855d634e41b274f013463092), MIT license; included license privately with payload. Original uploaded APK's external loader had been 1.2.0.1.
- Combat Gods 1.0.5 (Turbo, GUID TURBO_SAKUGA): user archive contains 305 C# files, assets and 36 cz.json Chinese locale files. Compiled all 305 against the exact original APK's reference-only publicized game API plus uploaded NML1.2.1.1/dependencies. Successful. Additional metadata audit: 691 referenced game/NML members, zero missing.
- Frontiers 2.0.1 (MidNight, GUID MIDNIGHT_FRONTIERS): user-supplied precompiled module. All 150 direct game type references present; 521 referenced game/NML members resolve, zero missing. Retained original binary and default configuration.
- Uploaded vassal5.1 ZIP is a Civilization VI Lua/SQL/modinfo package, not a WorldBox module: excluded.
- TWrecks character-control guide explicitly targets WorldBox0.10.3/BepInEx and WASD keyboard: excluded from0.51.4, requires porting.
- Chinese0.10.3 patch contains old Assembly-CSharp replacement ZIPs for0.9.1/0.9.6/0.10.3: excluded; never replace current game assembly with it.
- More-powers/map/GUI bundle is an old Windows/BepInEx whole-game package: excluded fromAndroid0.51.4.
- Cultivation0.078.6 complete ZIP was retrieved on retry and inspected: old Windows game, BepInEx, replacement game DLLs and Unity2019-era logs from2021. It is not a ready-compatible0.51.4 source MOD. Not merged or falsely called working. Upstream Cultivation-Way-Core main also declares build558, so was not silently substituted for725.

### Actual APK integration

- Original build_mod_payload.py stages private files only: ONE legacy NML1.2.1.1, its matching embedded dependencies, compiled Combat Gods, Frontiers, icons/Forge/game resources/locales/default configurations. Each mod root has exactly one DLL and ModType=COMPILED_NEOMOD(1); normalized stale Windows FolderPath. Third-party names/author/GUID retained.
- 701 payload files, 45341531 uncompressed bytes. Token v16-8f37e6f55455468e. Every file SHA256 verified both in staging and final APK. No NML mobile, LemonLoader, BepInEx runtime, old whole-game DLLs or publicized SDK reference bundled as a MOD.
- Added original Android ModDeployment.java: first launch automatically extracts exact APK Mono DLLs/PDBs into THIS app's files/mono and verifies/deploys the checksummed NML and Mods assets. Runs off the UI thread; uses temporary files, hash checks and atomic rename. Version marker avoids repeating successful installation. Targets only this package's files/mods and Mods folders; no worlds/settings import, no uninstall or data wipe.
- Added original IntegratedModBootstrap.cs to existing exact-APK entry bridge. Waits for Config.game_loaded, instantiates the standard NeoModLoader.WorldBoxMod entry, disables the duplicate native-loader pass, supplies an assembly resolver, and logs ACTUAL LoadedMods entries/states. File deployment and runtime registration are logged separately; neither is falsely called gameplay acceptance.
- Retained fonts/observer/pseudo-3D/map candidate code. Expanded bounded diagnostic logs to retain NML/module messages. Native entry lists the included modules and still offers copy/share logs.
- Same app ID com.xinyanshuo.worldbox.lab13 and dedicated test certificate; versionCode727 permits updatingv15. Retained v15 resource-namespace fix. Native game libraries and original classes.dex/classes2/3/4.dex unchanged. No added Android permissions or paid-content changes.
- Toolkit now has compile-tree, reference-only publicizer and metadata API audit commands. The publicized reference is compile-only; shipping original game bodies still verified across20597 methods with only the isolated entry hook. Python suite42 tests pass, including private payload checksums/layout/no-source/no-SDK-reference regression. Original Java compiled with Android35+ECJ/D8; original bridge compiles against exact original Mono references.

### Signed candidate and open acceptance

- File WorldBox_Xianxia_v16_Integrated_Test.apk, 185612979 bytes.
- SHA256 d1cf154f65e1f1f89db269b896844ce39e8d0c33aded95938c493c103e6d8ec9.
- v1/v2/v3 signatures verified; 16KB ZIP alignment verified. Final APK manifest/resources/app identity, same-certificate update, original native/Dex preservation and all701 embedded payload hashes checked.
- Actual Android deployment/NML boot/MOD registration and gameplay remain USER_PENDING. Next phone log should show MOD_DEPLOY_OK followed by NML_ACTUALLY_LOADED_COUNT and Sakuga.SakugaMod / Frontiers.FrontiersMod entries. A populated mod list is still not proof all combat/kingdom features, saves or performance work.
- The full xianxia cultivation/roots/ascension/world systems, old control-mod port, vassal feature port and huge-map device QA remain incomplete. This is a real two-module integration candidate, not a claim all uploaded files or the full design are compatible.
- Public repository receives ONLY original integration source/tests/log. Uploaded game, third-party DLLs, assets and APK stay private user artifacts.

## 2026-10-20 — v17 Android Discord guard and visible MOD registration status

- User screenshot shows generation of 65536 tiles, World Loaded / Loading finished, and the managed 万界 font button. This confirms world generation and bridge visibility by user evidence, not MOD registration or full gameplay acceptance.
- Screenshot's explicit exception is DllNotFoundException: discord_game_sdk in DiscordTracker.Start. Original code catches it and destroys the tracker; this is not evidence of a fatal Android process crash or the cause of missing MODs. No readable NML registration proof was supplied.
- Inspected exact original IL. DiscordTracker.Start unconditionally calls desktop DiscordCreate; its Update exits when _initiated is false, and other activity calls guard _instance. Added exactly three prologue instructions: call original bridge SkipDesktopDiscord(), branch to original first instruction when false, return when true. The bridge returns true only on RuntimePlatform.Android. This prevents initiating the desktop SDK on Android while leaving the original body and exception regions intact.
- Full verifier passed across 20597 original method bodies: permitted changes are ONLY MapBox.Start's one bootstrap call and DiscordTracker.Start's three-instruction Android guard. All other original game bodies/locals/exception regions match. No entitlement or save-format changes.
- Mobile loading console defaults are disabled during startup; after world initialization and SmoothLoader completion its existing Hide() is invoked once. It is not permanently disabled, and Unity errors continue to the bounded copyable session log.
- Added visible actual NML LoadedMods registration count and entry names to 万界·MOD与字体, explicit bootstrap failure status, loader location and initialized/initialized_successfully stage logs. This diagnoses registration; it does not claim that registered features all work.
- Retained the same two private MODs and 701 checksummed payload files from v16. Deployment token and asset prefix now v17, forcing extraction of the updated Mono bridge on an in-place upgrade; no save/config deletion or importing old app data.
- Built original bridge against exact original APK references; Android launcher compiled with ECJ/Android35 then D8. Local SDK MSBuild failed to inspect its own process in this runtime; invoking the installed SDK Roslyn compiler directly successfully rebuilt the toolkit. This is a tooling workaround, not an Android runtime pass.
- Python source regression: 42/42 PASS. Exact Unity resource lookups retain game_view_content_description=0x7f0e0053 and unitySurfaceView=0x7f07017e. Final app manifest/permissions, original native libraries and original four DEX files unchanged except the already-authorized cloned package identity. All 701 payload SHA256 values and embedded patched assembly/bridge bytes checked.
- Dedicated branch baseline f89630c11caf4353ff7169f53a3866c7ee0c505f CI completed success, run https://github.com/160701541-cell/xinyanshuo/actions/runs/39416976819. This result is for v16 source; v17 CI is separate from local checks and phone QA.
- Candidate WorldBox_Xianxia_v17_Integrated_Test.apk: 185612979 bytes, SHA256 bf56741889989da311ddd51e763a94c6a2e9338e1a825bfa28ab8b0a00e27352. App ID com.xinyanshuo.worldbox.lab13, versionCode728. Same dedicated test certificate SHA256 a1fa2827668e11da772e9984f277623bb95fc7e0556622a755b7117b8c407104; v1/v2/v3 verification and 16KB ZIP alignment PASS. Updates v15/v16 without requiring uninstall; never instruct data wipe to bypass signing mismatch.
- Phone validation remains USER_PENDING: Discord suppression, console behavior, actual NML and both MOD initialization, touch input, fonts, observer/follow/pseudo-3D, map generation, saving/loading and Snapdragon 8 Elite performance. No connected adb device/emulator. Full cultivation, incompatible old MOD ports and 12x12/16x16 runtime acceptance remain incomplete.
- Commercial APK, third-party MODs/assets and signing secrets remain private; only original source and truthful development results go to the isolated branch.


## 2026-10-20 — v18 original assets and Canglan gameplay reuse authorized

The user requested reusing our own cultivation asset library and Canglan gameplay. This authorizes reading/reusing original assets and mechanics for WorldBox, NOT modifying or merging Canglan source, website, changelog, RSA or hot updates. All new implementation remains in this dedicated WorldBox branch.

### Actual source/asset audit

- Retrieved and CRC-checked the existing v0.11 integration archive and its nested v0.4 art/rule archive. The v0.4 README explicitly identifies 1794 prototype sprite frames (including 1584 early placeholder building frames), not finished high-resolution art. Those are not falsely promoted to final architecture.
- Retrieved Canglan_Approved_Assets_Batch02.zip: eight approved independent original RGBA building/prop assets, each with an icon. Read its actual manifest and README: state variants remain missing. Reused the eight existing icons in a real in-game catalog; NOT a native map-building replacement.
- Added four original v0.4 spirit-grass mature frames as an animated illustration used by the cultivation/harvest panel. No new image generation and no atlas crops claimed. Actual new art deployment: 12 PNG files plus provenance catalog.json. Image decode and source frame SHA256 checks passed. Other library contents remain available for later native adaptation rather than dumped into the APK as unused assets.
- Read Canglan's original cultivation rev201 and spirit-resource rev206 implementation as references: hidden/tested roots, learned method requirement, world-clock progress, 13-layer gate, stress limits, conserved recipe inputs and renewable resources. Reimplemented these mechanics in original portable C#; no Godot source/assets/save paths were altered.

### What is actually compiled into v18

- Original CultivationRulesV18.cs and CultivationBridgeV18.cs automatically attached to the existing Mono entry. This original module does not require either third-party MOD to finish NML registration.
- The in-game 万界·修仙 panel selects an actual living civilized actor near the camera, or finds one with a fixed latent root. Detection records its result; repeated tests do not reroll roots. A manual god-action can transmit 纳元吐息法, then toggle training/rest and attempt breakthroughs.
- Game world time controls Qi, stress, rest and delayed crafting; paused or reversed clocks cannot duplicate earned progress. Five elemental root types exist in this slice, not the full Canglan root-quality taxonomy.
- Registers exactly 13 namespaced native ActorTraits. At layer n, only that layer's own trait is active: +12n health, +3n damage, +9n mana, +4n lifespan. Prior own layer trait is removed, other mods' traits are retained. These are additive bonuses rather than replacing original maximum age or combat rules. Native effect/runtime acceptance remains pending.
- Near-body gathering searches only real living vegetation/mineral buildings within radius three tiles of the selected actor. Namespaced stock on BuildingData is shared by actors, depleted by gathering and regenerates on world time (herbs one year, minerals four years). This is a supplemental spiritual stock; native kingdom resource stocks and model rendering are unchanged. Actor inventory has no initial free material grant.
- Portable alchemy slice: at least Qi layer1 plus learned method; spend three herbs, one spirit stone and ten Qi before a half-world-year wait, then deliver exactly one 聚气丹. Consuming a pill removes it and grants35 Qi plus3 stress. No material/queue duplication. No cauldron/sect construction animation or native kingdom production chain is claimed.
- Namespaced ActorData custom fields hold root, detection, method, Qi, layer, stress, inventory, training time and pending craft. Namespaced BuildingData fields hold spiritual stock and timestamps. Uses the game's existing get/set custom-data methods; private Actor.data / Building.data / Building.asset accessed via cached exact fields verified in original metadata. Original actor IDs, names, ages, world files and external app data are not replaced or deleted. Actual save/reload proof still requires the phone.
- Rare, deterministic rule-driven NPC opportunities teach eligible actors; enrolled NPCs train, rest and attempt Qi breakthroughs. UI clearly says rules, not an installed LLM. The opportunity switch affects new enrollment, preserving existing actor progress.
- Retained Combat Gods1.0.5, Frontiers2.0.1, legacy Mono NML1.2.1.1 and v17 Android Discord guard/diagnostics. Moved observer button below the font button to address the visible overlap. Original asset catalog clearly labels missing map replacement and missing construction/damage states.

### Executed checks and honest limits

- Final bridge compiled against the exact original APK managed references (without shipping a publicized game replacement). Original game IL audit passed across20597 method bodies; only the existing single MapBox.Start call and three-instruction Android Discord guard differ.
- Python source suite42/42 PASS. Executed the actual new portable C# rules: paused-world progression, clock rewind nonduplication, failed-recipe conservation, delayed single output, double-craft prevention, item consumption, stress gate, fast-forward stress cutoff, no-root block, and closed foundation gate all PASS. Added this scenario to the independent CI workflow.
- Android Java entry compiled using ECJ/Android35 and D8. Payload714 files: prior701 plus13 own-art/provenance files. All hashes checked, native libraries/original four DEX files/permissions/resource IDs retained, exact final bridge and patched game assembly bytes checked.
- Current push-CI lookup hit HTTP403; no new remote-CI success claimed. Local compilation/tests are separate from Android runtime acceptance.
- DEVICE_PENDING: original core loading, real trait effects, selection/gather/crafting touch flow, reading saved actor/building custom data after reload, Chinese layout, NML third-party registration and performance. No connected Android device/emulator; user phone testing is authorized.
- Open work: native world building/character/weapon replacements; complete animation states; sect construction and production economy; higher realms and foundation resources; full root taxonomy; local LLM deployment; four linked worlds/ascension; 12x12/16x16 map and thermal/save QA. These are not labeled finished by showing a catalog or adding C# rules.

- Final signed candidate: WorldBox_Xianxia_v18_Cultivation_Test.apk,187773264 bytes, SHA256 b415bf01ccb17c4503cdb51f544127caa8afe28de99ade6d8580b57463b937c5. VersionCode729, appID com.xinyanshuo.worldbox.lab13, same dedicated test certificate. v1/v2/v3 and16KB ZIP alignment PASS. Actual Android gameplay and saved-data roundtrip remain DEVICE_PENDING.


## 2026-10-20 — 用户最终确认：十二层常规上限与逆天十三层

以下规则覆盖 v18 中“常规十三层”的旧设计，适用于每个大境界：

- 常规境界为一至十二层。十二层之后正常突破应进入下一大境界，十三层不是普通升级路线。
- 十三层只有一种来源：天赋极高者在十二层冲击下一大境界，表面突破失败，实质发生异变进入当前境界的隐藏十三层。不得让普通天赋、普通突破失败或反复点击直接产生十三层。
- 这一异变按相当于一次突破两层的异常跃升设计；在“一层修为一层天”的世界法则下，属于可轻松越阶杀敌的极罕见强者。具体战斗系数尚待实现与验证，不能把普通十三层加一点属性视作完成。
- 异变引来真实天劫，世界全体收到消息；事件须关联真实人物、当前境界及渡劫结果。示例文案：“【天道异象】某某冲关未入下一境，却踏入逆天十三层，天劫将临！”
- 天劫的触发、承受、存活和死亡应独立记录；天劫触发或世界消息出现本身不等于渡劫成功。玩家为天道观察与干预者。
- 存档迁移必须区分旧版常规十三层与真正的隐藏十三层，不能误删合法异变人物。具体迁移方案须测试后交付。

本轮实际检查：已读取交接规范、project_scope.json 和开发日志；远程 CelestialRulesV19.cs 返回404，当前工作目录无上一轮源码、私有APK或签名构建文件。上文是已确认设计要求，**不是 v19 已集成或已打包的证明**。v18既有结果维持原记录。v19编译、打包、签名、安卓玩法与存档验证均未在本轮完成，禁止声称已交付。
