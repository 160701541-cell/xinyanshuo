# 苍岚：公开的最小逻辑QA镜像

**此目录不是完整游戏工程，更不代表APK/PCK已经通过验收。**

- 源工程：私有 `160701541-cell/canglan-world`
- 源分支：`audit/legacy-v176-pck167-qa-20261015`
- 公开的真实逻辑模块：实体身份编码 `entity_codes.gd`、双手触控镜头路由 `touch_look_router.gd`、左手虚拟摇杆 `ancient_touch_joystick.gd`、骨骼行走 `character_locomotion.gd`。均从原私有仓库主分支逐字节镜像。
- 源代码原始 Git Blob SHA 清单：`source-provenance.json`；公开仓库与原私有工程对应文件 SHA 应完全相同。
- 公开路径：`logic-qa/scripts/entity_codes.gd`
- 测试：`logic-qa/tests/entity_codes_test.gd`、`touch_look_router_test.gd`、`character_locomotion_test.gd`、`two_thumb_input_test.gd`。
- Godot版本：4.4.1；测试运行于GitHub公开仓库免费的标准Linux运行器。

每次编辑源码时必须重查与私有分支的差异，不能以这个测试通过代表世界系统、库存、动画、美术、Android存档或热更通过。完整游戏自动发布必须由**另一个具有真实全量QA、真机验收、合法授权资产与私密RSA签名能力的流水线**负责。这里不存放签名密钥、玩家存档或未明确许可公开的第三方资产。

此前 GitHub Actions run `38698833693` 已真实通过实体码12项检查；后续扩展的触控/骨骼/双摇杆测试必须取得各自的 GitHub run 日志再判定 PASS，不能沿用此前实体码绿色报告。模块测试不会修改手机APK/PCK。
