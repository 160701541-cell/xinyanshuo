# 原版《苍岚》rev201 → rev202 飞行输入修复记录（2026-10-17）

## 纠正真实工程定位
正式原APK176热更源码及签名补丁实际存于 `160701541-cell/xinyanshuo`，而不是旧的 `canglan-world` Godot实验项目。官方仓库当前 `android-preview/latest.json` 的 revision=201，minimum_android_code=maximum_android_code=1176，且仓库已包含rev199、rev200、rev201的PCK和发布工作流。此前在旧工程的PR#23 **不得合并为原游戏热更新**。未进行公网HTTPS/实机核验。

## 本轮实际代码修复（原版控制器）
- 代码：`game-source/apk176-ota177-candidate/scripts/apk176_player_controller_rev187.gd`
- 修复 P0：真实角色御风飞行模式 `soar` 下，`FlyUpButton` 原先只在摄影机飞行 `fly` 可见，导致手机上升按钮被隐藏；现在御风中升高/降低均有可见按钮，降落时同时禁用。
- 修复 P0：在空中直接切换上帝/摄影机/第三人称时，旧代码直接把 `_soar_altitude` 清零；现改为先启动受控降落并拒绝即时切换，直到落地才允许换镜头。
- 处理起飞瞬间角色高度直接跳变0.90米问题：从0.0逐步朝3米起飞。
- 测试脚本：`tools/verify_rev202_soar_source.py`，仅源码静态保护，不代表引擎验证。

## 发布门槛（均未达成）
- [ ] 运行 Python 静态回归检查。
- [ ] 运行与官方导出APK176资源一致的Godot 4.4.x 场景加载和脚本检查。
- [ ] 运行飞行起降、换镜头中断、触摸操作、UI安全区、建筑碰撞和存档回归。
- [ ] 与当前rev201 PCK基线对比；**不得减少rev201修仙、灵根或角色美术功能**。
- [ ] 签名rev202 PCK并验证旧APK176公钥、SHA256及HTTPS Range。
- [ ] 手机实际执行更新与飞行测试。
- [ ] 官网与正式更新日志在签名发布成功以后再同步。

状态：已提交源代码修复至独立分支；**未完成运行测试、签名、发布或真机验收**。
