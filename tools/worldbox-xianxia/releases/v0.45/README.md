# WorldBox 万界仙侠 v0.45：虚拟超大地图跨存档隔离

本项目是独立的 WorldBox 0.51.4 安卓 MOD 测试，与苍岚 main 完全隔离。

本次实现 WorldGridSaveScopeV45：每个经过明确验证的 WorldBox 存档 ID 单独分配 SHA256 派生的私有分区数据目录；切换世界会保存已修改的区块，旧的全局 v41 目录不再自动共享。身份未能从真实游戏读取时仅使用本次运行的临时预览命名空间，不自动当作某个已保存的WorldBox世界。新增两份独立存档的切换、重启、错误ID和冲突种子单元测试。

运行时接口 BindAuthoritativeWorldSave 已编译，但尚未找到并绑定真实游戏的稳定存档唯一ID。逻辑区块数据不是原版可探索的10000×10000 WorldTile地图。

GitHub Actions 39573487066 三项构建成功。私有v0.45完整签名APK以v0.44用户私有安装包为基础，仅替换自有WorldBoxXianxiaStreamGrid.dll和build token，保留原版游戏、原有经济、图标、MOD导入和v0.44清理器。APK字节数188056990，SHA256 0153da4ce0dbc3fda0aef7fc7583e013bb0795c294797783e4080bf950fea131。同lab31测试签名的v1/v2/v3验证、ZIP CRC全部通过，**尚未通过Android16手机实机启动/加载测试**。

另：用户此前v41日志中Observer FAILED和动态编译CS0009属P0；v0.45未证明该问题解决。凡人修仙传v1.1.16.zip没有提供真实原件，不能宣称导入成功。私人APK和静态验收报告在ChatGPT文件库 /WorldBox-万界仙侠/Work交接/，公开仓库不含WorldBox商业APK及测试私钥。
