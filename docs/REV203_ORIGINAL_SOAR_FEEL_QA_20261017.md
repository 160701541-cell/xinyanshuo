# 《苍岚》原APK176 rev203 御剑操作与空间感增量（2026-10-17）

## 项目基线
- 唯一正式仓库：`160701541-cell/xinyanshuo`。
- 已签名发布且经真实官网HTTPS验签：rev202 / 原APK versionCode1176 / 完整PCK SHA256 `4a9376cf922c0e213481e78cec170b4995f24c5e84b4ff0184e28df0ec5d94de`。
- 本轮在相同的原APK主游戏控制器修复，不建独立APK、独立小游戏，也不修改原有玩家存档或世界时间比例。

## 本轮真实代码
- `game-source/apk176-ota177-candidate/scripts/apk176_player_controller_rev187.gd`：
  1. 升高/下降触屏键使用 `BaseButton.ACTION_MODE_BUTTON_PRESS`，按下一次触发标准2.5米微调；按住0.25秒后持续以6米/秒调整真实高度目标；松开、菜单打开、降落、切视角均取消持续输入；无需连点20次；游戏100倍世界时间不改变真实的玩家操作速度。
  2. 实体人物转向时倾斜：依照角色当前与目标朝向误差及真实空中速度平滑产生最多约0.16弧度的侧倾，玩家停下自动归中；落地退出飞行模式清零倾斜，不影响行走。
  3. 复用原合法Quaternius CC0飞剑GLB，与真实人物实体同步侧倾而非增加伪贴图或把剑固定在相机。
  4. 镜头随离地高度自然、低速拉远最多6.5米，叠加玩家原有双指缩放，不强制修改镜头缩放设定；落地渐进恢复。
- 原引擎回归测试 `logic-qa/apk176-export-fixture/verify_original_main_quality_rev187.gd` 已新增按住/松开、镜头调节、人物+飞剑侧倾以及落地归正验证，继承历史rev201修仙、rev202安全降落的完整测试。
- 原Godot真渲染快照 `logic-qa/apk176-export-fixture/capture_original_main_rev187_compare.gd` 新增 `real_apk176_rev203_actual_bank_sword_ground_reference.png` 运行时帧（必须在真实Godot引擎生成并像素检查，不得以概念图替代）。
- 专用只读QA：`.github/workflows/canglan-rev203-qa-only.yml`。真实Godot 4.4.1与原APK176资源构建/主场景QA + Vulkan/Mesa引擎截图。工作流无密钥、无发布权限。
- 待官方QA完成后可合入发布的独立工作流 `.github/workflows/canglan-original-apk176-rev203-signed.yml`：只对main、只有其自身工作流文件变更触发，严格基线 `rev202 → rev203`，原RSA公钥签名、SHA256、PCK完整性和原Main动态玩法都通过才可以发布。
- 独立官网验收 `.github/workflows/canglan-rev203-real-pages-http-proof.yml`：真实公网完整下载、原RSA+SHA256、HTTP Range 206。

## QA质量门禁
- [ ] rev203独立只读Godot 4.4.1运行（含匹配原APK的Terrain3D动态库、历史Godot场景）。
- [ ] 严格实物场景证据：人物与持有的授权GLB飞剑同步侧倾、至少一张1280×720真Godot运行帧、无脚本错误。
- [ ] 游戏原已发布rev201灵根、12名修士、真实NPC碰撞/作息、修为、体力、存档回归全通过。
- [ ] 正式原APK176固定公钥RSA签名和安全更新；不得修改rev202已经签名的旧PCK。
- [ ] 官方Pages联网RSA签名/全文件SHA256/HTTP Range 206。
- [ ] **Android手机实机**：人物仍需核对脸部、头发、倾斜是否怪异、飞剑与脚跟对齐、操作键是否挡住聊天、帧率与发热。自动Godot PASS不等于此项PASS。

状态：隔离源码增量已提交；未完成最终验收时保持候选，不把GitHub上传冒充手机已热更新。

## 真实引擎运行结果与人工画面审核（更新于QA完成后）
- 专用完整原APK176 Actions #39029314179 **SUCCESS**，原APK导出主游戏、匹配Terrain3D、GDScript、角色/NPC、rev201修仙与rev202飞行回归全部通过。
- 工件 artifact #12099473727：至少包括两张1280×720原Godot同地点图、可见角色三视角、rev200头发/飞剑及rev203转向飞行帧 `real_apk176_rev203_actual_bank_sword_ground_reference.png`。该画面由**真实原Main引擎**渲染，不是手机录像，也不是国风概念美术。
- **人工美术验收 A级：FAIL**。实际逐帧查看画面，人物比例、肢体与飞行站姿仍僵硬（手臂抬起、脚下飞剑不够明确），NPC外形重复且局部灰色头顶不协调，场景草地散布重复、建筑低细节、头顶与中左HUD文案叠压。虽然功能逻辑验收成功，仍**不符合用户期望的高品质国风修仙视觉**；不能把全套Godot绿灯冒充画质达标。
- 本次发布候选范围**仅为操作与镜头增量修复**，不会宣称人物脸部、动画姿态或建筑美术已修好。下一个P0美术迭代先切换姿态/角色资产并进行截图肉眼对照；禁止用光效覆盖劣质模型。
