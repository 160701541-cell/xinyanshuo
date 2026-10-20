# WorldBox·万界仙侠 v0.31 签名冲突修复：隔离安装测试包

## 错误来源：真实安卓16安装截图

安装器提示「安装失败：已安装了签名冲突的应用」。不能误写成 NML 故障，亦不是 APK ZIP CRC 失败。

已经真正从用户上传的**原有v14/v18 APK、我们生成的v0.28/v0.30 APK**验证 `apksigner verify --print-certs`：

| 包 | 实验包名 | 签名证书SHA256 |
| --- | --- | --- |
| 旧v14/v18（用户已安装版本参考） | `com.xinyanshuo.worldbox.lab13` | `a1fa2827668e11da772e9984f277623bb95fc7e0556622a755b7117b8c407104` |
| 我们重新签名的v0.28 | 同上 | `70d2cd47f69dc29d7126597b166521e68b4d7da3525ba44d070ad8e0137ea846` |
| 我们重新签名的v0.30 | 同上 | `20087dc8c210c7c6a35a4492500324f33f36f7c5eb3a77dc62040c21281c400e` |

**v0.28与v0.30由于使用不同临时私钥，均不能覆盖原先用a1fa…证书签名的同名包。** 签名的有效性≠可覆盖已安装APK。原有v18私钥尚未找到；没有它就不能生成同包名的正常覆盖安装包。不得建议无备份卸载原游戏，不能试图从APK恢复私钥。

## 已实际生成并私有上传的替代测试包

- `WorldBox_v031_Isolated_Install_DEVICE_PENDING.apk`：**187,840,198字节**；SHA256 `37c271ad006df570496231b777547c7a5ab57b36a193b5e16ff0ecf8d1766c1f`。
- **新包名**：`com.xinyanshuo.worldbox.lab31`，与旧`lab13`不同，以测试并排安装并保留旧应用/旧存档。
- 已按原包实况等长修改二进制AndroidManifest（11项包名）、resources.arsc（1项Android资源包名）和自有诊断classes5.dex（11项class package），重新计算DEX SHA1/Adler32、ZIP对齐及签名。
- 真正 `apksigner verify --verbose` 返回v1/v2/v3成功；ZIP CRC全通过；11+1+11包名字节实际回读通过。没有改WorldBox主游戏逻辑/存档，也没有绕过付费或授权机制。
- 新测试包使用v0.30私有测试证书 `20087dc8…`，它**不是旧版原签名的升级**，而是**全新独立应用**。旧版本、存档仍在旧包中；新包拥有隔离的数据目录，不自动继承世界/进度。
- **DEVICE_PENDING**：没有Android16真实安装/运行证据，不能保证安装成功、授权正常、NML加载或存档，特别是游戏/广告SDK可能内部依赖旧package ID。本轮仅修复已证实的签名冲突路径。

## 防止再次犯错

新增 `private_signing_gate_v31.py`、`test_v31_signer_gate.py`：同包名且签名不同必须判为SIGNATURE_CONFLICT，禁止对用户宣称可覆盖安装；异包名才允许提示独立安装且旧存档隔离。新增私有包名隔离工具 `private_side_by_side_v31.py`及合成测试`test_v31_side_by_side.py`。GitHub Actions继续只对原创工具做模拟测试，绝不上传商业APK、旧签名密钥或签名材料。

文件已上传到私有持久化Work文件库：`/WorldBox-万界仙侠/Work交接/`；在原ChatGPT对话也可下载APK。签名密钥仅限私有库，不推公开GitHub。

**下一步**：先保住原`lab13`存档，针对`lab31`安装、Unity启动、日志、中文、UI及游戏玩法逐项实机排错。若用户必须保持原安装与存档无缝升级，需取得**原v14/v18相同的签名私钥**且解决单一版本代码兼容，不能用任何新证书强行覆盖。
