# 《苍岚·人生世界》本地模型和推理引擎许可证说明

**本功能只对从已校验的本地 GGUF 文件读取权重，未向任何在线服务上传玩家聊天。** 独立 Android 调试版将在 GitHub CI 中下载并用 SHA-256 校验后打包模型；未实际编译、推理和安卓验收前不得宣传“已经在你手机里启用”。

## 权重：Qwen3-0.6B，Apache License 2.0

- 模型版权/官方权利人：Qwen Team / Alibaba Cloud
- 官方模型页（许可和约束）：https://huggingface.co/Qwen/Qwen3-0.6B
- 实际量化文件提供方：QuantFactory，https://huggingface.co/QuantFactory/Qwen3-0.6B-GGUF
- 本版本准确文件：`Qwen3-0.6B.Q4_K_M.gguf`
- **SHA-256：** `7af3fdf842f87b24672f8a7f1dd50404043f0bfb71093ff91c31d2b49df4631d`
- 模型用于 **离线 NPC 简短中文对话**，权威库存、造物、数值和交易仍必须由游戏的 `WorldState` 执行。
- 构建导出时应附带上游官方 Apache-2.0 正文；如模型仓库要求额外 NOTICE，必须保留。模型输出可能不准确，不等于 NPC 拥有真实世界知识。

## 推理引擎：llama.cpp (MIT)

- 来源：https://github.com/ggml-org/llama.cpp
- 固定源码标签：`b6000`
- 授权：https://github.com/ggml-org/llama.cpp/blob/b6000/LICENSE
- 实现路径：`local_ai/native/`，Linux 与 Android ARM64 编译后才会形成 `.gdextension` 动态库。
- 不提供云推理回退；缺少权重或 C++ 动态库时游戏必须明确报告不可用，不能生成假的AI回复。

## Godot / godot-cpp (MIT)

- Godot 4.4.1 授权：https://godotengine.org/license/
- GDExtension C++ 绑定：https://github.com/godotengine/godot-cpp（固定 `godot-4.4-stable`）。
- 正式分发需随软件附上第三方软件许可和版权文本，参见 `../opensource/THIRD_PARTY_NOTICES.md`。

## 私有数据与资源隔离

- 用户聊天与 NPC 记忆只放在运行时本机内存，本代码不自动向网络提交。
- 没有任何公开模型密钥、账号凭证、游戏存档、Android 签名证书或玩家地址被传入第三方。
- 一个独立 0.6B 模型供附近 NPC 轮流复用；不是80个模型常驻。
- 当前低端 Android 的 RAM、设备温度、耗时和耗电均未通过实机测量。
