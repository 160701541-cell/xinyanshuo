using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;

// WorldBox OTHER-GAME nonofficial MOD LAB. NEVER related to Canglan development.
// Experimental and disabled unless the user explicitly presses a separate in-game button.
// Zero world modification or save writes. Adds candidate sizes to new-world choices only.
namespace XianxiaWorldBox
{
    public static class GiantMapOptionsV11
    {
        public static bool Enabled { get; private set; }
        public static string Report { get; private set; } = "未开启。8x8是原版Titanic尺寸。";
        public static bool Armed { get; private set; }
        public const int MaxExperimentalChunks = 20;
        public static readonly int[] CandidateChunks = { 10, 12, 16, 20 };
        static readonly BindingFlags F = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static | BindingFlags.Instance;
        static object Member(object obj, string name)
        {
            if (obj == null) return null;
            var t = obj as Type ?? obj.GetType();
            var flags = F;
            var f = t.GetField(name, flags);
            if (f != null) return f.GetValue(obj is Type ? null : obj);
            var p = t.GetProperty(name, flags);
            if (p != null && p.GetIndexParameters().Length == 0) return p.GetValue(obj is Type ? null : obj, null);
            return null;
        }
        static bool Set(object obj, string name, object value)
        {
            if (obj == null) return false;
            var t = obj.GetType();
            var p = t.GetProperty(name, F);
            if (p != null && p.CanWrite)
            {
                p.SetValue(obj, Convert.ChangeType(value, p.PropertyType), null);
                return true;
            }
            var f = t.GetField(name, F);
            if (f == null) return false;
            f.SetValue(obj, Convert.ChangeType(value, f.FieldType));
            return true;
        }
        public static string OnTap()
        {
            if (Enabled) return Report;
            if (!Armed)
            {
                Armed = true;
                return Report = "注意：超大世界可能卡顿/崩溃。请先备份存档，再点一次确认。";
            }
            Armed = false;
            try { return Report = TryRegister(); }
            catch (Exception ex) { return Report = "未注入，原因：" + ex.GetType().Name + "，请保留NML日志。"; }
        }
        private static string TryRegister()
        {
            // Do not call generateMap(), setMapSize() or any save/terrain mutations.
            // Only the game's map-size asset library is considered.
            var asm = typeof(World).Assembly;
            var manager = asm.GetType("AssetManager");
            var mapType = asm.GetType("MapSizeAsset");
            var libraryType = asm.GetType("MapSizeLibrary");
            if (manager == null || mapType == null || libraryType == null)
                return "当前WorldBox API没有地图尺寸类型；未启用。";
            var lib = Member(manager, "map_sizes");
            if (lib == null) return "未找到游戏地图尺寸库；未启用。";
            var add = lib.GetType().GetMethods(F)
                .FirstOrDefault(m => m.Name == "add" && m.GetParameters().Length == 1);
            if (add == null) return "地图尺寸库未暴露安全add方法；未启用。";
            var original = Member(lib, "titanic");
            if (original == null) return "原版Titanic资源缺失；未启用。";
            // Check all preconditions before adding any entries.
            object preview = Activator.CreateInstance(mapType);
            if (preview == null ||
                !Set(preview, "id", "xianxia_map10") ||
                !Set(preview, "size", 10))
                return "地图尺寸字段不兼容；未启用。";
            int installed = 0;
            foreach (int chunks in CandidateChunks)
            {
                if (chunks > MaxExperimentalChunks) continue;
                string uid = "xianxia_map" + chunks;
                try
                {
                    var asset = Activator.CreateInstance(mapType);
                    if (asset == null || !Set(asset, "id", uid) || !Set(asset, "size", chunks))
                        continue;
                    var icon = Member(original, "path_icon");
                    if (icon != null) Set(asset, "path_icon", icon);
                    Set(asset, "show_warning", chunks >= 16);
                    add.Invoke(lib, new[] { asset });
                    installed++;
                }
                catch(Exception) { /* report how many were accepted */ }
            }
            if (installed == 0) return "尺寸注册失败。可能需要适配此版本的游戏API。";
            // Some WorldBox builds cache preset names on initialization. We do NOT
            // blindly write private static caches because that could corrupt saves.
            Enabled = true;
            return "已向尺寸库申请注册" + installed + "档候选（10/12/16/20）；" +
                   "但创建界面能否显示仍未设备验证，不能认为地图成功扩大。";
        }
    }
}
