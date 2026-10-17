# 一加 Ace 5 Pro 本地NPC大模型升级（rev201）
2026-10-17，正式用户要求：升级本地AI、可复现世界种子、更多修仙NPC、灵根检测台、可以修炼。

## 已核实的真实硬件、模型信息
一加 Ace5 Pro 配骁龙8至尊版、Adreno830、12GB或16GB LPDDR5X RAM，用户实际内存档位尚未获知；不能假定16GB。官方：https://www.oneplus.com/cn/ace-5-pro/specs

- **默认推荐：Qwen3-1.7B Q4_K_M，约1.28GB权重**。官方 llama.cpp 组织托管的 GGUF，Apache-2.0，详见 https://huggingface.co/ggml-org/Qwen3-1.7B-GGUF 。比原0.6B更能处理日常中文NPC对话、简单因果判断，理论上更适合开放场景的12GB RAM / 16GB RAM，但真机token/s、温度、FPS未验收，不能宣称稳定。
- **增强备选：Qwen3-4B Q4_K_M，2.497GB权重**。Qwen官方Apache-2.0：https://huggingface.co/Qwen/Qwen3-4B-GGUF 。复杂NPC宗门交涉、因果辩论更有潜力，但连续推理延迟及热量风险更大；12GB RAM尤其需要测试，应仅玩家主动对话时选用而非全图NPC同时推理。
- 原Qwen3 0.6B Q4_K_M（约0.48GB）保留低功耗/旧手机兼容，不冒称现有正式APK已经加载。

## 不允许假装已接入（P0）
原安装包org.canglan.ancient25d.preview（APK176/versionCode1176）尚无已验证的CanglanLocalLLM原生Android ARM64库，已有工具 tools/audit_original_apk176_npc_ai_native_bridge.py 明确当前 **NATIVE_AI_APK_UPDATE_OR_COMPATIBILITY_BRIDGE_REQUIRED**。仅通过PCK热更新加下载链接，**并不能安装原生llama.cpp动态库**，也不能让目前用户手机的NPC真正自由对话。本项目已有独立Godot源码并不等于原APK原生可执行。

要完成真正升级，必须在唯一公开仓库160701541-cell/xinyanshuo：
1. 复用已有game-source/godot3d/local_ai/native源代码构建、编译和审计Godot 4.4 Android ARM64 GDExtension/llama.cpp组件。
2. 合法取得**与原APK同一签名证书**的正式覆盖APK生产能力，仅涉及原生组件升级才需覆盖安装；绝不能使用新包名、独立QA安装包或不同证书代替旧手机游戏。
3. 更新后在游戏内由玩家主动选择1.7B或4B，WiFi条件下HTTPS Range断点下载，不预置约2.5GB权重；逐文件验证真实SHA256、长度和授权，限RAM与CPU线程，不下载成功时显示未加载。
4. 先一加Ace5Pro设备实际测时延、内存、FPS、发热、推理准确性以及异常取消。未经真机测过不得报告速度/发热为通过。
5. 一个共享模型轮流服务NPC，AI只提出意向，不能绕过真正世界库存/宗门权限/经脉/身份/作息/土地的规则校验。

## rev201已经进入源码的玩法性质
真实原游戏灵根检测台、隐藏且随机固定的根性、按世界小时吐纳、修为消耗与炼气1到13层突破、12个带实际GLB动画的修仙NPC及稳定生成种子是规则层；NPC缺本地AI运行库时由明确的时间/职业/精力规则自主运行，不能声称有真实Qwen对话。灵脉生成种子已作用于修士/根性/灵气属性并存档，但旧地形曾挖掘存档专用种子仍是20261017；**尚非完整新世界地形重新生成系统**。已打成正式RSA签名PCK与否必须以真实生产Godot QA日志及正式最新清单为准。
