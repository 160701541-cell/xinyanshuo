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

## 2026-10-17 rev203首次正式签名流水线阻断（必须先修复）
- 所有先前独立原APK176 Godot引擎测试：#39029314179 SUCCESS，且独立真引擎飞行照片已生成；**但正式签名/发布工作流 #39029641825 = FAILURE**。
- 真正失败阶段：原Main rev199历史飞行回归 `REV199_STILL_HAS_GHOST_FLIGHT_EFFECTS_AFTER_ACTUAL_SOFT_LANDING`。这项测试在前一独立QA成功，但正式Runner运行时失败，意味着降落时刻可能存在场景物理碰撞、载入/帧边界或测试随机状态差异。暂时**不能认定是纯测试误报**；rev203绝对没有RSA发布。
- 正式最新 `android-preview/latest.json` 仍为rev202。新rev203工作流尚未执行签名阶段，原有手机安全。
- 新增源脚本：多帧(12×0.12秒)降落门禁，输出真正剩余离地高度、下降目标、状态、粒子/投影显示和碰撞拒绝计数；若超过1.44秒仍未恢复第三视角则继续FAIL，不能移除门禁蒙混。
- 改用独立诊断分支 `fix/rev203-landing-qa-reliability` 与只读QA工作流确定故障，成功后再在main重新触发同证书原PCK签名。

## rev203最终正式发布证据（后续状态，保留上文失败记录）
- 第二次正式原APK176签名流水线 **39030030956 SUCCESS**，主游戏Godot4.4.1完整QA、授权人形/飞剑场景、真实1280×720渲染帧及原固定RSA签名通过；本次已发布，不再停留候选分支。
- 线上清单revision=203、Android versionCode1176、PCK 22040608字节、SHA256 `07b9e52426f1eb7e22e4c49bba35bd9f6d589660a08d861f564c15717512b295`。签名发布源commit可追溯，原rev202 PCK未覆盖，已有玩家存档未主动删除。
- 独立真实官网HTTPS完整下载与RSA/SHA256/HTTP Range206测试 **39030295747 SUCCESS**；公开网络已经具备原APK176在游戏里下载更新的条件。网页CDN缓存max-age600秒，客户端可能需要稍后再检查更新。
- 原版实际截图公开到 `art/actual-engine-capture/` 并由官网“真实游戏画面”展示，图片不是手机实机；画质/玩家UI仍为**人工审美 FAIL**。用户真实Android安装、持手操作、发热和性能未验收。
