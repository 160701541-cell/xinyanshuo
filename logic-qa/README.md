# 苍岚：公开的最小逻辑QA镜像

**此目录不是完整游戏工程，更不代表APK/PCK已经通过验收。**

- 源工程：私有 `160701541-cell/canglan-world`
- 源分支：`audit/legacy-v176-pck167-qa-20261015`
- 公开的真实逻辑文件：`godot3d/scripts/entity_codes.gd`
- 该源码在私有库的 Git Blob SHA：`7d82d7de396208c799d4e5bac23741d1d436a71e`
- 公开路径：`logic-qa/scripts/entity_codes.gd`
- 测试：`logic-qa/tests/entity_codes_test.gd`
- Godot版本：4.4.1；测试运行于GitHub公开仓库免费的标准Linux运行器。

每次编辑源码时必须重查与私有分支的差异，不能以这个测试通过代表世界系统、库存、动画、美术、Android存档或热更通过。完整游戏自动发布必须由**另一个具有真实全量QA、真机验收、合法授权资产与私密RSA签名能力的流水线**负责。这里不存放签名密钥、玩家存档或未明确许可公开的第三方资产。

这份隔离测试在用户允许的公开仓库内先打通真正的Godot执行：不再停留在只有脚本，没有任何可运行测试的状态。
