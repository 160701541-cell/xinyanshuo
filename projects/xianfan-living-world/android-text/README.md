# 《仙凡·苍岚》第一世 · 红尘问仙（Godot 4.4.1）

## 版本定位

离线单机、竖屏、原生 Android 文字生活与修仙游戏。**不是 HTML 套壳**，不需要登录 ChatGPT、网络或 API。

开局复制了公开主线的 **EV000105（第103回合，第29日06:00）** 已知事实；移动端产生的事件仅属于独立体验存档，绝不改写 GitHub 权威事件链，也不重新抽取原始灵根承诺。

## 游戏可玩内容

- 石桥村家中、溪边、临安东市、青云山门，可沿真实登记道路通行。
- 保留游方道人交易、残旧功法被鉴定为伪诀的历史；主角当前拥有53文、4条小河鱼和一根鱼竿。
- 阅读、静坐、疲劳、睡眠、粮食，自动跨天日结。
- 孙成明、父母有日程和自主行为；送饭失约留待自然解释。
- 制作鱼竿、摆放双鱼笼、渔获来源守恒、售卖河鱼。
- 第三日播种的青菜按月生长，收菜、东市售卖均有来源记账。
- 一键完成日程，连续修炼一天或十天，NPC成长，完整事件日记。
- 离线保存/加载、本地备份、v0.3 存档迁移、基础损坏存档检查。
- 手机汉字字体采用系统字体；竖屏 HUD、行动栏、背包与记事页。

## 为什么目前不能引气突破

此角色的**灵根承诺不可篡改**，但真实揭示原文和算法未在公开交接中公布。已知残卷为伪诀。本版本保留修行经历与测灵旅途，不能凭用户期待或概率擅自突破。这不是任意抽取的新人生。

## 本地操作

用 Godot 4.4.1 打开 `project.godot`，运行主场景。

测试：

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_world.gd
```

导出：`godot --headless --path . --export-debug Android build/xianfan-canglan-debug.apk`；需 Godot Android 导出模板、Android SDK/JDK 与 debug keystore。

CI 发布：工程放入仓库 `projects/xianfan-living-world/android-text/`，工作流复制到仓库**根** `.github/workflows/xianfan-text-android.yml`。触发分支 push 后进入 GitHub Actions 构建；**只有实际 Actions 成功、产出可下载 APK，才算已打包**。

注意：Debug APK 使用临时调试签名，仅供本地测试，正式商用发行需要专用签名、真实设备 QA 和长期密钥保管策略。

## 同步注意

本版制作时分支已经从 EV000016 推进到 **EV000105**，使用后者开局；同一分支有其他AI继续开发时，应以后续权威记录为准，不覆盖事件历史。安卓本地进度不自动与GitHub合并。