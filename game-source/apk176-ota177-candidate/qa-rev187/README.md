# rev187 可安装独立测试包（用户本轮明确指定测试包名）

- 唯一测试 Android `applicationId`: `com.xinyanshuo.canglan.rev187.qa`，显示为「苍岚·rev187独立测试」。
- 编译 **相同rev187游戏子场景源码、相同Kenney/Quaternius CC0原GLB**，适合真实测试画质开关/镜头操控/地形/P0错误/截图；不带原apk176旧HTML/2D世界、更新器、原存档，数据完全隔离。
- 原正式APK176 `org.canglan.ancient25d.preview` 和 `android-preview/latest.json` 未由QA包替换，**不得宣称QA APK就是旧游戏，或在QA包测试成功就替原版手机验收打勾**。
- 纯Godot4.4.1/mobile/Vulkan/arm64 debug签名；个人桌面CI生成临时debug签名，不能当生产签名替代安装包。
- 从公开GitHub Actions已验收的源码工程生成；详细命令在`.github/workflows/canglan-rev187-independent-qa-apk.yml`。无后门、无额外混用私有仓库，不捆绑模型权重。
