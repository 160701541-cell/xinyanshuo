# WorldBox 万界仙侠·微观观察 v0.6
游戏对象：用户上传的 WorldBox Android 0.51.4，不是《苍岚》正式内容包。

基于上传的 Combat Gods 1.0.5 中已证实的 `World.world.GetTile`, `World.world.units.getSimpleList()`, `Actor.current_position`, `World.world.camera`, `World.world.getActorNearCursor()` 等API开发。使用 NeoModLoader `BasicMod<T>`，Unity IMGUI 提供触屏入口。

只读模式：真实游戏地图小范围取样 → 倾斜等距伪3D图、人物跟随、高分辨率窗口显示；不修改世界/存档，不替代Worldfall的可移动第一人称。Worldfall只做程序集检测。

目标 `targetGameBuild=725`（用户Android0.51.4）；Combat Gods 1.0.5自带的`targetGameBuild=719`属于旧0.51.2，**不得自动修改这一字段假装兼容**。NeoModLoader 1.2.1.1上传ZIP为桌面DLL，尚无实际Android bootstrap验证。

导出候选不等于真正已经在手机上运行。Android NML 实机启动、第三方MOD共存与实际可显示的原版UI仍标红。

私有交付包 `WorldBox_万界仙侠_微观观察_v0.6.zip` 包含全量源码、源材质校验、QA和上一版整合包；公开GitHub只发布独立原创源码/规范，不重新分发上传的第三方MOD或安装包。
