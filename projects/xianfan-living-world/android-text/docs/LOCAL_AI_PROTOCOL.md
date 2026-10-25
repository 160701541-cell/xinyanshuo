# 《仙凡·苍岚》本机推理接口 · 设计约束（非已经集成的模型）

目前 APK **尚未集成真实的本地 LLM**。可采用 Godot Android Plugin v2（AAR/Kotlin/JNI）封装 llama.cpp GGUF 或 LiteRT-LM，按设备能力下载 0.5B/1.5B 量化权重后才启用。

模型仅做自然语言到动作意图：

```json
{"kind":"propose_action","intent":"collect","target":"枯枝","quantity":1,"npc_id":null,"text":"去林边拾一根枯枝"}
```

游戏接受的 intent 须加入白名单；存在地点、工具、精力、合法资源归属、库存与 NPC 同意的验证，所有数量和时间由规则引擎重新计算。模型输出未经核验一律不改变世界。若解析不出动作，提示玩家补充或展示邻近环境，不擅自行动。

接口要求：本地运行，不使用 ChatGPT 账户或远程 API；启动不下载大文件；玩家手动同意下载/导入模型；支持限流、取消生成、低内存自动关闭、推理异常无损回退；用户私有对话默认不外传。安卓包先维持轻量。真实集成必须经过 APK 内模型加载、生成和状态变更全链测试后才标注完成。

参考：Godot Android Plugin v2 https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html ； LiteRT-LM https://developers.google.com/edge/litert-lm/android
