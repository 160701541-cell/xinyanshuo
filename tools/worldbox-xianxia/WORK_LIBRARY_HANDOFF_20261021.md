# WorldBox·万界仙侠 / Work文件库交接（2026-10-21）

**这份文档为公开源码交接指针，不含商业APK。**

### 持久化文件库真实路径
`/WorldBox-万界仙侠/Work交接/`

该私有文件库目录的以下文件已实际上传成功，并通过重新列目录确认，Work应使用ChatGPT文件库查找/提取原始字节；`/mnt/data`是当前普通聊天的临时容器路径，不能直接假定Work云电脑拥有。

- `WorldBox_WanjieXianxia_v0.28_Private_Android16_DEVICE_PENDING.apk`：189,287,005字节；SHA256 `9efa49f98e92921f7ee8b9341f14b68b39d426323bc0a8cf25d8acc41e6cc822`。
- `WorldBox_Xianxia_v18_Cultivation_Test.apk`：187,773,264字节；SHA256 `b415bf01ccb17c4503cdb51f544127caa8afe28de99ade6d8580b57463b937c5`；重建基线。
- `WorldBox_万界仙侠_v0.27_传统Mono源码MOD_待实机.zip`：v0.28所嵌入原始MOD。
- `WorldBox_万界仙侠_v0.27_安卓NML预编译MOD_待实机.zip`：其他加载器路线备选。
- `private_stage_mono_v28.py`、`test_v28_private_stage.py`：本轮本地曾执行的打包器与单元测试。
- `WorldBox_v028_APK私有整合静态验收报告.json`：离线证据。
- `WorldBox_Work_交接_2026-10-21.md`：私有文件目录内完整Work交接说明。

### Work开工
1. 先读本分支`DEVELOPMENT_LOG_V22.md`、`WORK_HANDOFF_APK_V13.md`与这个目录；从文件库真正提取APK，核验SHA256。若Work当前会话未授权访问文件库，应让用户在Work聊天中明确附加此文件，而不能根据文件名凭空模拟。
2. 用真实用户手机日志确认v18/v0.28有没有启动Unity与NML动态加载。过去`MOD_DEPLOY_OK`仅说明文件部署，不证明MOD加载。验证简中菜单及存档，修复引导链后才扩展玩法。
3. 所有源码修改继续在专用WorldBox分支，不碰`main`/苍岚正式发布。每次更新开发日志。**Work不可将完整商业WorldBox APK、他人MOD或签名私钥上传公开GitHub**。

### 设备状态
v0.28 APK实际签名完毕，未有Android16安装/可玩证据：`SIGNED_PRIVATE_APK_DEVICE_PENDING`。

### 后续实测纠正与日志入口修复
用户实际Android16 PKR110日志已证明v0.28进入Unity；CombatGods和Frontiers已加载，观察模块V07报告FAILED；检测灵根按钮有一次ACTION记录。特性编辑器groupsBuilder两次空键异常。不能继续写“完全没有安装/运行证据”，也不能称完整修仙系统通过。

2026-10-21用户明确反馈手机复制不完长日志。入口修复在当前WorldBox分支的：
- private-apk-lab/DiagnosticsActivity.java
- private-apk-lab/DiagnosticReport.java
- private-apk-lab/ModDeployment.java（接续原实现）
复制≤6000字符关键摘要；导出分享ZIP包含四份现存日志原字节及摘要。使用系统文件保存器和content URI附件，不再发送180000字符EXTRA_TEXT。
CI私人打包工具工件增加原创WorldBoxDiagnostics_classes5.dex及SHA256；必须等对应CI成功再取用。只含自有Java入口/部署器，无商业游戏字节。

Work需检查原classes5.dex仅包含对应自有入口与部署器后替换/重建；若其中有其他必要类必须保留后合并，不能盲目覆盖。原生DEX更新与MOD源码升级是两步；private_stage_mono_v28.py --replace-own-module只更新MOD源码，不更新DEX。完成后zipalign、使用既有正确测试证书签名，并测试保存取消、ZIP导出、附件分享、复制摘要和启动游戏。不可仅更新MOD就宣称日志按钮已修复。用户无需再复制超长日志、无需MT手动操作。
