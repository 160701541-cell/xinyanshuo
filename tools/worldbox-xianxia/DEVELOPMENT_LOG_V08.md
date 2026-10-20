# 2026-10-20 — WorldBox独立第三方MOD实验 v0.8

**非《苍岚》游戏研发；只复用它的素材流水线。分支：`worldbox/external-mod-lab-v08`。禁止合并`main`、禁止修改原APK176 OTA。**

- 发现v0.7公开 Actions 多次失败且0 jobs，定位工作流步骤名未引用含英文冒号，引发 YAML 解析异常；v0.8修复，等待独立Actions真实结果。
- 对用户上传的原0.51.4 APK逐条静态检查，发现Mono/IL2CPP/Managed并存，但没有真正运行NML的日志；上传NeoModLoader ZIP没有`neomodloader_mobile.dll`。APK/loader文件未上传公开库。
- 官方Android NML有两条依赖外部运行时的引导路线（FusionCore或LemonLoader，视具体NML项目版本）；不盲目对用户手机安装或替换APK。
- 实装真实APK诊断脚本和真实日志验证工具；本地8个附加测试PASS，安卓运行和C#SDK构建PENDING。
- 保护 `tools/worldbox-xianxia/**` 路径和专用工作流权限，不操作 `game-source/` `android-preview/` `main` `AGENTS.md`。
