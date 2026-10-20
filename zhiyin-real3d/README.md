# 《知音》真实三维渲染技术迁移 · Godot 4.4.1

> **定位：原生Android Canvas方案的替换用三维场景模块，而非另一个正式游戏。**
> 当前测试的是可导入真实 GLB、PBR材质、三维场景、碰撞交互与镜头控制的最低验收门槛。
> 原v0.7的llama.cpp模型下载、Android Keystore/API、SQLite记忆、职业房租逻辑仍留在原生安卓工程中，
> 此场景**尚未完成接入**，不能给用户当作v0.8整合版APK交付。

## 为什么不继续在Canvas里画房间

Android Canvas画的2.5D PNG是预渲染图片，没有三维网格Mesh、UV材质、骨骼蒙皮、三维阴影、
灯光影响、碰撞物理或正规的动画状态机；继续叠图片不会自动获得这些能力。
Godot 4.4.1可作为真实的3D游戏渲染层；先做好10.24㎡房间，然后共享既有AI与生活存档服务。

## 已提交的真实游戏技术

- **3D引擎场景**：Godot 4.4.1 GL Compatibility移动端后备渲染。
- **真GLB模型**：17个从Kenney CC0公开模型库固定commit导入的二进制glTF。
  包括单人床、衣柜/书架、桌椅、冰箱、炉灶、水池、沙发、绿植、落地灯、
  地毯和一位临时角色。
- **模型验真**：解析glTF二进制头、Json段、mesh、material、skins/animations数量、SHA256，
  并下载GLB依赖的外部PNG纹理。每个模型的来源和SHA均记录在ASSET_MANIFEST.json。
- **材质纹理**：制作基于真实PBR材质参数的平铺木地板、墙面和石材三套素材；
  每套含独立的albedo色彩图、normal法线图和roughness粗糙度图。
  Godot StandardMaterial3D真正采样了这9张贴图，不是使用单纯的颜色方块。
- **三维光照**：太阳DirectionalLight3D与室内OmniLight3D、阴影与环境光。
- **房屋和物理**：3.2m × 3.2m 房间、真实3D地面/墙面和窗框、碰撞体、家具可点选的Area3D热点。
- **镜头UI**：3D正交俯视，单指拖动、双指缩放/鼠标滚轮，场景内菜单和交互按钮。
- **引擎实测**：GitHub Actions必须在真正Godot引擎里导入资源、启动场景，
  数出至少10个GLB资产、28个MeshInstance3D、2盏3D灯、15个具有法线/粗糙度的PBR材质实例。
  编译报错、资源缺失均不放行。

## **仍然不合格/必须继续**

1. Kenney人物只有作为临时验证的独立GLB，**不是符合目标的成品绑定骨骼/面部BlendShape/服装换装角色**。
   需采用高品质统一画风的可商用许可人物，例如Quaternius Universal Base Characters
   （请核对许可/具体标准包；素材有真正的人形骨骼，须独立导入并实机验证）。
2. 当前NPC按目标坐标移动，尚无完整的真实步行、坐卧、洗澡、做饭、拿放物品动画或完整NavMesh避障。
3. 此Godot模块尚未与v0.7 Android Java生活引擎、AI/本地GGUF、SQLite记忆、声线与歌唱系统桥接。
4. 当前没有正式 **Android安装APK** 输出，工程zip和QA报告不能当成已经装进手机的游戏。
5. 尚无真机60/90/120Hz性能、发热、材质表现、场景截屏、无穿模的完整QA结果。
6. 当前家具Kenney素材为低模风格，不等于用户所需的高细节写实/国风视觉效果。
7. 最终要用Godot 3D替代旧Canvas主场景，而不是两个APP并存让用户来回切换。

## 第三方资产/许可

Kenney 3D Furniture & Blocky Characters: CC0-1.0.
仓库 https://github.com/shorepine/kenney 固定commit `3694c6879e487c108f55677be7dd2ca75b07cc3b`。
原Kenney Furniture Kit https://opengameart.org/content/furniture-kit 亦载明CC0及3D模型+纹理。
工作流严格校验模型结构和SHA256。自己的墙/地板PBR贴图为程序算法原创生成。

## 版本边界

**完成“渲染技术底座”不等于完成“AI虚拟伴侣”。**
历史版本的Android API/LLM/记忆/租房逻辑必须无损保留并通过安卓桥接，
才能替换v0.7正式使用包。不能跳过实机验收。
