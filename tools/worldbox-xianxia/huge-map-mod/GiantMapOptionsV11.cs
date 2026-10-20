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
        public static bool ExtremeArmed { get; private set; }
        public static bool ExtremeRegistered { get; private set; }
        public const int ExtremeChunks = 32;
        public const int ExtremeTiles = 2048;
        public const long ExtremeTileCount = 4194304L;
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
        // Explicit post-generation evidence check, no mutation. Distinguishes a
        // registered UI preset from an actually loaded 2048x2048 world.
        public static string DiagnoseActualWorld()
        {
            try
            {
                var asm=typeof(World).Assembly;
                var mapType=asm.GetType("MapBox");
                if(mapType==null) return "WORLD_SIZE_FAIL MapBox unavailable";
                object width=Member(mapType,"width");
                object height=Member(mapType,"height");
                if(width==null||height==null)
                    return "WORLD_SIZE_FAIL size members unavailable";
                int w=Convert.ToInt32(width), h=Convert.ToInt32(height);
                if(w<=0||h<=0)return "WORLD_SIZE_FAIL world not generated";
                bool matched=w==2048&&h==2048;
                return "WORLD_SIZE_"+(matched?"MATCH":"DIFFERENT")+
                       " actual="+w+"x"+h+
                       " target=2048x2048"+
                       " tiles="+((long)w*h)+
                       " (save/load and simulation still unverified)";
            }
            catch(Exception e){return "WORLD_SIZE_FAIL "+e.GetType().Name;}
        }

        // Read-only runtime diagnostics used by Work to confirm real Android 0.51.4
        // map size API before declaring the 2048-square preset playable.
        public static string DiagnoseMapApi()
        {
            try
            {
                var asm=typeof(World).Assembly;
                var mapType=asm.GetType("MapSizeAsset");
                var manager=asm.GetType("AssetManager");
                var libraryType=asm.GetType("MapSizeLibrary");
                if(mapType==null||manager==null||libraryType==null)
                    return "MAP_API_FAIL missing type MapSizeAsset/AssetManager/MapSizeLibrary";
                var lib=Member(manager,"map_sizes");
                if(lib==null) return "MAP_API_FAIL AssetManager.map_sizes null";
                var titanic=Member(lib,"titanic");
                if(titanic==null) return "MAP_API_FAIL titanic missing";
                object presetSize=Member(titanic,"size");
                var add=lib.GetType().GetMethods(F)
                    .FirstOrDefault(m=>m.Name=="add"&&m.GetParameters().Length==1);
                if(add==null) return "MAP_API_FAIL no add(MapSizeAsset)";
                string message="MAP_API_READY titanic.size="+
                    (presetSize==null?"null":presetSize.ToString())+
                    " addParam="+add.GetParameters()[0].ParameterType.Name+
                    " candidate32=2048² (not generated)";
                return message;
            }
            catch(Exception e){return "MAP_API_FAIL "+e.GetType().Name;}
        }

        // Separate, explicit 32x32 test mode. Does NOT affect the standard 10/12/16 choices.
        // It only attempts registration of a NEW-world preset, never generation or save writes.
        public static string OnExtremeTap()
        {
            if (ExtremeRegistered) return "32×32 (2048×2048) 实验档已申请注册；实际生成仍需Work和实机验证。";
            if (!ExtremeArmed)
            {
                ExtremeArmed = true;
                return "风险确认：2048×2048有4194304格，可能内存不足。仅新建世界，先备份存档；再按一次。";
            }
            ExtremeArmed = false;
            try
            {
                return TryRegisterExtreme();
            }
            catch(Exception e)
            {
                return "2048实验地图未启用：" + e.GetType().Name + "；没有修改已有世界。";
            }
        }

        private static string TryRegisterExtreme()
        {
            var asm = typeof(World).Assembly;
            var manager = asm.GetType("AssetManager");
            var sizeType = asm.GetType("MapSizeAsset");
            if (manager == null || sizeType == null) return "游戏地图尺寸接口不匹配，停止实验。";
            var lib = Member(manager,"map_sizes");
            if (lib == null) return "地图尺寸库缺失，停止实验。";
            var add = lib.GetType().GetMethods(F)
                .FirstOrDefault(m=>m.Name=="add"&&m.GetParameters().Length==1);
            if (add == null) return "地图尺寸库不支持注册，停止实验。";
            var original=Member(lib,"titanic");
            if(original==null) return "缺少原版地图库模板，停止实验。";
            object asset=Activator.CreateInstance(sizeType);
            if(asset==null||!Set(asset,"id","xianxia_extreme_32")||
               !Set(asset,"size",ExtremeChunks))
                return "地图尺寸属性不兼容，未改动。";
            var icon=Member(original,"path_icon");
            if(icon!=null)Set(asset,"path_icon",icon);
            Set(asset,"show_warning",true);
            add.Invoke(lib,new[]{asset});
            ExtremeRegistered=true;
            return "已提交32×32候选（2048×2048），不是地图生成通过。需要Work实机测试和保存读取。";
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
                if (chunks > MaxExperimentalChunks || !ObserverFrameGuardV12.AcceptLargeMapCandidate(chunks)) continue;
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
            return "已向尺寸库申请注册" + installed + "档（10/12优先，16需要足够FPS，20暂禁）；" +
                   "但创建界面能否显示仍未设备验证，不能认为地图成功扩大。";
        }
    }
}
