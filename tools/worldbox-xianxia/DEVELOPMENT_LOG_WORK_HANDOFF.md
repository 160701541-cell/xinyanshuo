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
