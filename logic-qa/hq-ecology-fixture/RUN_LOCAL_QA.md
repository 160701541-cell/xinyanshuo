# rev208 HQ-Ecology 本机真实 Godot QA

本目录是一个**只做验证**的 Godot 4.4.1 工程，不产出 APK，不代表正式发布。

```bash
# 1. 入库清单离线自校验（不联网）
node tools/asset_factory/rev208_ecology_polyhaven_intake.mjs --verify

# 2. 把资产与脚本装进本工程（逐文件 SHA256 校验）
python3 tools/stage_rev208_hq_ecology.py --dest logic-qa/hq-ecology-fixture

# 3. 真实 Godot 4.4.1 导入（Linux arm64 / x86_64 皆可）
GODOT=/path/to/Godot_v4.4.1-stable_linux.arm64
$GODOT --headless --editor --path logic-qa/hq-ecology-fixture --import

# 4. 真实引擎断言
$GODOT --headless --path logic-qa/hq-ecology-fixture \
  --script res://verify_rev208_hq_ecology_pbr.gd
```

最后一行必须打印
`PASS_REV208_HQ_ECOLOGY_REAL_GODOT441_TWO_SCALE_PBR_GROUND_AND_GROUNDCOVER`，
任何一项不成立都会以退出码 1 结束。

**这不是美术验收**：它只证明资产真的在引擎里解析、贴图真的有细节、
面数与清单一致、两级地表材质真的挂在 `natural_ground` 上。
真实手机审美与 30 分钟性能仍是 `PENDING_PHONE`。
