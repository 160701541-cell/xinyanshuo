# 知音 v0.1 · Android 原生 APK
独立安卓工程：Java + Android SDK 原生组件 + SQLite，无 WebView，无浏览器壳。
包名 com.xinyanshuo.zhiyin，不影响苍岚或WorldBox。
现有可运行范围：本地历史事件存储、角色及剧本档案、关键词检索、基础故事演绎、系统TTS声线、语音录制和本机回放、JSON档案备份和恢复。
限制：未接AI大模型、未实现真正AI歌声合成和音准纠错。系统TTS是朗读，不是唱歌。声线数量与能力因安卓设备语音引擎而异。
安全：日记仅保存在本地数据库；云端无服务；手动导出的JSON由用户管理。剧本导入仅作纯文本保存，不执行文本指令。
构建：使用 GitHub Actions 产出可安装debug APK；未通过用户安卓实机验证不能写“通过”。
