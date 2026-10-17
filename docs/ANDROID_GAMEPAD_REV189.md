# 《苍岚·人生世界》Android 游戏手柄适配（rev189，原APK176热更新）

## 交付原则
- **唯一正式安装包**：原 `org.canglan.ancient25d.preview`（APK176，versionCode 1176）。通过 `android-preview/latest.json` 发布 RSA 签名增量 PCK；不要求重新安装或清除存档。
- 使用 Godot 4.4 内置标准 `InputEventJoypadButton`、`Input.get_connected_joypads()`、`Input.get_joy_axis()`，适配 Android 蓝牙／USB OTG 标准游戏手柄。Xbox/PlayStation/Switch 手柄按**标准化的物理位置映射**；廉价非标准手柄可能需要单独的 GUID 映射，不能宣称全球手柄全兼容。
- **触控依旧可用**。使用手机手柄时无需触摸屏，松开手柄／拔线自动回退原移动摇杆、右滑镜头和触摸菜单。左手持续触摸虚拟摇杆时不被手柄左摇杆抢夺输入；UI打开后避免手柄方向输入导致后台角色乱跑。

## 操作映射
| 手柄输入 | 在游戏中的行为 |
| --- | --- |
| 左摇杆 | 玩家移动，上帝视角下移动观察中心，自由飞行时平移 |
| 右摇杆 | 旋转/俯仰真实3D镜头；不受帧率影响，径向死区处理 |
| A / × / Nintendo 底键 | 互动：NPC、仓库、资源 |
| X / □ / Nintendo 左键 | 采集：实际物资入玩家背包，遵守资源库存及采集CD |
| Y / △ / Nintendo 顶键 | 挖掘：真实地形/土层（受地形规则约束） |
| B / ○ / Nintendo 右键 | 疾步：消耗8体力，实际2m移动，3s冷却，障碍检测；打开面板时关闭 |
| LT / L2 | 互动；RT / R2 | 采集（模拟量扳机按下阈值只触发一次） |
| LB / L1 | 切第一/第三视角；菜单打开时切角色页 |
| RB / R1 | 背包页面 |
| 左摇杆按下 L3 | 疾步；右摇杆按下 R3 | 重置镜头 |
| START / OPTIONS / + | 游戏设置菜单，重复按关闭 |
| BACK / SELECT / − | 角色面板，打开时关闭 |
| 十字键 ↑ ↓ | 场景放大缩小；自由飞行时升高/降低；面板打开时选项上/下 |
| 十字键 ← → | 角色／修炼页面 |
| 面板内 A | 确认当前聚焦的按钮 |
| 面板内 B | 返回游戏 |

## 游戏中设置
- 游戏右上角「菜单」中可调节：右摇杆视角灵敏度0.7/1.0/1.3/1.6，Y轴反转、双摇杆死区0.12/0.19/0.27/0.35。
- 配置保存在 `user://canglan_controller_v1.cfg`，不修改玩家旧存档、NPC实体ID或世界资源。
- 连接成功显示手柄名称及操作提示；默认允许同时保留触摸HUD以备手柄断连。

## 必须区分的验收证据
1. **Godot自动化可验证**：真实Android原APK176编译Main与签名PCK、GDScript解析、模拟`InputEventJoypadButton`按键、左/右摇杆死区数学与镜头逻辑、菜单焦点交互/热插拔处理代码、触摸原逻辑不回归。此阶段不是物理手柄实测。
2. **真实手机必须再验收**：在一加Ace5 Pro蓝牙或OTG连接实际游戏手柄，启动原游戏完成热更新；同时连续移动＋转镜头、交互与采集、背包菜单选项确认、切换第一/第三人称、拔线后继续触控，检查延迟、断连卡输入、按钮位置映射以及帧率。
3. **已知限制**：部分 Android 系统或廉价手柄在“键鼠映射模式”中不会作为标准Joypad被Godot识别；触觉震动、触摸板和陀螺仪、可视化逐键重映射未完成；这次不宣称实现了不存在的灵力技能与战斗招式。原有地形、人物、建筑的P0实机问题独立存在，不能因手柄QA通过改为绿灯。

## 原版OTA校验
- 正式签发只能从rev188递增到rev189，构建复用`tools/stage_original_next_ota.py`与`tools/ota_release_gate.py`的APK176固定公钥。
- 工作流：`.github/workflows/canglan-original-apk176-rev189-android-gamepad-signed.yml`。
- 发行后另以真实公网HTTPS校验manifest RSA、PCK SHA-256及HTTP Range 206。
