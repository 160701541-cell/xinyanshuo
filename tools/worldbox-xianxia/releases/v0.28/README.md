# WorldBox·万界仙侠 v0.28 — GitHub源码交付

本目录属于非官方WorldBox安卓MOD实验独立分支 `worldbox/external-mod-lab-v22-zh-localization`，与《苍岚·人生世界》main、官网和正式APK/PCK无关。

**已上传到GitHub的内容**：原创MOD源码和汉化系统、v0.28私有APK增量整合脚本 `tools/worldbox-xianxia/private_stage_mono_v28.py`、离线回归 `tools/worldbox-xianxia/test_v28_private_stage.py`、CI构建的原创MOD候选及这里的公开发布指纹。

**未公开上传的内容**：完整WorldBox游戏APK、非自有第三方MOD商业文件、Android签名密钥及玩家存档。仓库是public；没有获得WorldBox游戏本体的公开再分发许可，所以只能在用户自己的私有环境构建与取得完整APK，不能用Github公开Release或Artifacts承载完整APK。

用户私有签名v0.28安装包：`WorldBox_WanjieXianxia_v0.28_Private_Android16_DEVICE_PENDING.apk`。
- SHA256：`9efa49f98e92921f7ee8b9341f14b68b39d426323bc0a8cf25d8acc41e6cc822`
- 大小：189,287,005字节
- 包名：`com.xinyanshuo.worldbox.lab13`
- 状态：**SIGNED_PRIVATE_APK_DEVICE_PENDING**；签名完成≠已成功安装/可玩/全汉化。

在用户本地私有环境复用已存在启动桥的v18 APK和传统Mono原创MOD ZIP：

```bash
python tools/worldbox-xianxia/private_stage_mono_v28.py \
  --base-apk "<私有v18实验APK>" \
  --mono-zip "<v0.27传统Mono源码MOD.zip>" \
  --out "<私有未签名中间APK>"
```

生成的中间文件需要私下zipalign、签名及设备测试；不准在公开CI上传输入APK或任何密钥。签名不匹配时先备份世界存档，不要未经备份卸载。Android16真机安装/加载器/汉化与存档验收尚未完成。
