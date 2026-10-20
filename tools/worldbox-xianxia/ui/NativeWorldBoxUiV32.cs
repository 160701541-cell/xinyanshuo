using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;

namespace XianxiaWorldBox
{
    // Uses installed WorldBox/NML prefabs. No textures, fonts or game art bundled.
    // Reflection keeps the legacy Mono build independent of public IL2CPP wrappers.
    public static class NativeWorldBoxUiV32
    {
        const string Id = "xys_wanjie_native_v32";
        const BindingFlags All = BindingFlags.Public | BindingFlags.NonPublic |
            BindingFlags.Instance | BindingFlags.Static;
        static object window, status, bridge;
        static float retryAt, refreshAt;
        static string notice = "";
        static readonly List<object> created = new List<object>();
        static readonly List<MethodBase> patched = new List<MethodBase>();
        static object harmony;
        static readonly string[] Labels = {
            "选取人物", "寻找灵根", "检测灵根", "传授功法", "吐纳修炼",
            "尝试突破", "采集灵草", "采集灵石", "炼制丹药", "服用丹药"
        };
        static readonly string[][] Icons = {
            new[]{"iconInspect","iconSteam"}, new[]{"iconBlessing","iconSteam"},
            new[]{"iconBlessing","iconSteam"}, new[]{"iconBook","iconSteam"},
            new[]{"iconMana","iconSteam"}, new[]{"iconArrowUP"},
            new[]{"iconFlower","iconSteam"}, new[]{"iconStone","iconArmor"},
            new[]{"iconFire","iconAttack"}, new[]{"iconBlessing","iconArmor"}
        };
        public static bool Ready { get; private set; }
        public static Action<string> Report = delegate { };
        // Tests substitute runtime types; production leaves this resolver unchanged.
        internal static Func<string,Type> Resolve = FindType;

        static Type FindType(string name)
        {
            foreach (var a in AppDomain.CurrentDomain.GetAssemblies()) {
                var t = a.GetType(name, false);
                if (t != null) return t;
            }
            return null;
        }
        static Type Need(string name)
        {
            var t = Resolve(name);
            if (t == null) throw new TypeLoadException(name);
            return t;
        }
        internal static object Get(object value, string name)
        {
            if (value == null) return null;
            var type = value as Type ?? value.GetType();
            object owner = value is Type ? null : value;
            for (var t = type; t != null; t = t.BaseType) {
                var f = t.GetField(name, All | BindingFlags.DeclaredOnly);
                if (f != null) return f.GetValue(owner);
                var p = t.GetProperty(name, All | BindingFlags.DeclaredOnly);
                if (p != null) return p.GetValue(owner, null);
            }
            return null;
        }
        static void Set(object value, string name, object data)
        {
            if (value == null) throw new ArgumentNullException(name);
            for (var t = value.GetType(); t != null; t = t.BaseType) {
                var f = t.GetField(name, All | BindingFlags.DeclaredOnly);
                if (f != null) { f.SetValue(value, data); return; }
                var p = t.GetProperty(name, All | BindingFlags.DeclaredOnly);
                if (p != null && p.CanWrite) { p.SetValue(value, data, null); return; }
            }
            throw new MissingMemberException(value.GetType().FullName, name);
        }
        internal static object Call(object target, string name, params object[] input)
        {
            if (target == null) throw new ArgumentNullException(name);
            var type = target as Type ?? target.GetType();
            foreach (var m in type.GetMethods(All)) {
                if (m.Name != name || m.ContainsGenericParameters ||
                    m.IsStatic != (target is Type)) continue;
                var ps = m.GetParameters();
                if (ps.Length < input.Length) continue;
                var args = new object[ps.Length];
                bool match = true;
                for (int i = 0; i < ps.Length; i++) {
                    if (i >= input.Length) {
                        if (!ps[i].IsOptional) { match = false; break; }
                        var d = ps[i].DefaultValue;
                        args[i] = d == null && ps[i].ParameterType.IsValueType
                            ? Activator.CreateInstance(ps[i].ParameterType) : d;
                        continue;
                    }
                    var v = input[i];
                    if (v is Action && typeof(Delegate).IsAssignableFrom(ps[i].ParameterType)) {
                        var a = (Action)v;
                        args[i] = Delegate.CreateDelegate(ps[i].ParameterType, a.Target, a.Method);
                    }
                    else if (v == null || ps[i].ParameterType.IsInstanceOfType(v)) args[i] = v;
                    else { match = false; break; }
                }
                if (match) return m.Invoke(target is Type ? null : target, args);
            }
            throw new MissingMethodException(type.FullName, name);
        }
        static object Vec(string type, params object[] args)
        { return Activator.CreateInstance(Need("UnityEngine." + type), args); }
        static object Transform(object value) { return Get(value, "transform"); }
        static void Active(object value, bool active)
        { Call(Get(value, "gameObject"), "SetActive", active); }
        static void Place(object value, object parent, float x, float y, float width, float height)
        {
            var t = Transform(value);
            Call(t, "SetParent", parent, false);
            Set(t, "localScale", Vec("Vector3", 1f, 1f, 1f));
            Set(t, "anchorMin", Vec("Vector2", .5f, 1f));
            Set(t, "anchorMax", Vec("Vector2", .5f, 1f));
            Set(t, "pivot", Vec("Vector2", .5f, .5f));
            Set(t, "sizeDelta", Vec("Vector2", width, height));
            Set(t, "anchoredPosition", Vec("Vector2", x, y));
        }
        static void Locale(string key, string text)
        { Call(Need("NeoModLoader.General.LM"), "AddToCurrentLocale", key, text); }
        static object Icon(string[] candidates)
        {
            foreach (var name in candidates)
                foreach (var root in new[]{"ui/icons/", "ui/Icons/"}) {
                    var sprite = Call(Need("SpriteTextureLoader"), "getSprite", root + name);
                    if (sprite != null) return sprite;
                }
            throw new InvalidOperationException("Original icon unavailable: " + candidates[0]);
        }
        static object NativeText(object parent, string text, float x, float y, float w, float h)
        {
            var prefab = Get(window, "titleText");
            var textType = Need("UnityEngine.UI.Text");
            if (!textType.IsInstanceOfType(prefab)) prefab = Call(prefab, "GetComponent", textType);
            if (prefab == null) throw new InvalidOperationException("Original title text unavailable");
            var clone = Call(Need("UnityEngine.Object"), "Instantiate", prefab);
            created.Add(clone);
            var local = Call(clone, "GetComponent", Need("LocalizedText"));
            if (local != null) Set(local, "enabled", false);
            Place(clone, parent, x, y, w, h);
            // Preserve original font/material/color; only fit text within native scroll content.
            Set(clone, "fontSize", 11);
            Set(clone, "resizeTextForBestFit", false);
            Set(clone, "alignment", Enum.Parse(Need("UnityEngine.TextAnchor"), "MiddleCenter"));
            Set(clone, "raycastTarget", false);
            Set(clone, "horizontalOverflow", Enum.Parse(Need("UnityEngine.HorizontalWrapMode"), "Wrap"));
            Set(clone, "verticalOverflow", Enum.Parse(Need("UnityEngine.VerticalWrapMode"), "Truncate"));
            Set(clone, "text", text);
            Active(clone, true);
            return clone;
        }
        static object[] Existing(Type type)
        {
            var values = Call(Need("UnityEngine.Resources"), "FindObjectsOfTypeAll", type) as IEnumerable;
            var list = new List<object>();
            if (values != null) foreach (var v in values) if (v != null) list.Add(v);
            return list.ToArray();
        }
        static void BindBridge()
        {
            var type = Need("XianxiaMonoBridge.CultivationBridgeV18");
            // Exact original gameplay methods are required before replacing its menu.
            if (type.GetMethod("Pick", All, null, new[]{typeof(bool)}, null) == null ||
                type.GetMethod("Action", All, null, new[]{typeof(int)}, null) == null)
                throw new MissingMethodException(type.FullName, "Pick/Action");
            foreach (var value in Existing(type)) { bridge = value; break; }
            if (bridge == null) throw new InvalidOperationException("Cultivation gameplay component not ready");
        }
        static void InvokeAction(int index)
        {
            try {
                if (index < 2) Call(bridge, "Pick", index == 1);
                else Call(bridge, "Action", index - 2);
                notice = "";
            } catch (Exception e) { notice = "操作失败，请导出诊断日志"; Report("[XIANXIA-NATIVE-UI] ACTION_FAILED " + e); }
            Refresh();
        }
        static void Refresh()
        {
            if (status == null) return;
            var actor = Get(bridge, "selected");
            if (actor != null && !Convert.ToBoolean(Call(actor, "isAlive"))) actor = null;
            string title = actor == null ? "未选取人物" : Convert.ToString(Call(actor, "getName"));
            string info = "";
            if (actor != null) {
                var state = Call(bridge.GetType(), "Read", actor, Call(bridge.GetType(), "Now"));
                int layer = Convert.ToInt32(Get(state, "Layer"));
                info = "\n" + (layer == 0 ? "凡人" : "炼气" + layer + "层") +
                    " · 修为 " + Math.Round(Convert.ToDouble(Get(state, "Qi"))) +
                    "\n灵草 " + Get(state, "Herbs") + " · 灵石 " + Get(state, "Stones") + " · 丹药 " + Get(state, "Pills");
            }
            Set(status, "text", title + info + "\n" +
                (notice.Length > 0 ? notice : Convert.ToString(Get(bridge, "message"))));
        }
        // Only our old immediate-mode drawers are suppressed; their Update keeps running.
        public static bool AllowLegacyGui() { return !Ready; }
        static void InstallLegacyGuards()
        {
            var ht = Need("HarmonyLib.Harmony");
            var hm = Need("HarmonyLib.HarmonyMethod");
            if (harmony == null) harmony = Activator.CreateInstance(ht, new object[]{Id});
            foreach (var name in new[]{"XianxiaMonoBridge.Overlay", "XianxiaMonoBridge.CultivationBridgeV18"}) {
                var method = Need(name).GetMethod("OnGUI", All);
                if (method == null) throw new MissingMethodException(name, "OnGUI");
                if (patched.Contains(method)) continue;
                var prefix = Activator.CreateInstance(hm,
                    new object[]{typeof(NativeWorldBoxUiV32).GetMethod("AllowLegacyGui")});
                Call(harmony, "Patch", method, prefix);
                patched.Add(method);
            }
        }
        static void Build()
        {
            BindBridge();
            var factory = Need("NeoModLoader.General.PowerButtonCreator");
            var tab = Call(factory, "GetTab", "other");
            if (tab == null) throw new InvalidOperationException("Original other powers tab unavailable");
            Locale(Id, "万界仙侠");
            window = Call(Need("NeoModLoader.General.WindowCreator"), "CreateEmptyWindow",
                Id, Id, "iconBlessing");
            var content = Get(window, "transform_content");
            if (content == null) content = Call(Transform(window), "Find", "Background/Scroll View/Viewport/Content");
            if (content == null) throw new InvalidOperationException("Original scroll content unavailable");
            Set(content, "sizeDelta", Vec("Vector2", 220f, 356f));
            status = NativeText(content, "选取人物后开启修行", 0, -52, 212, 96);
            for (int i = 0; i < Labels.Length; i++) {
                int action = i;
                string key = Id + "_action_" + i;
                Locale(key, Labels[i]);
                Locale(key + " Description", Labels[i]);
                float x = i % 2 == 0 ? -84 : 24;
                float y = -128 - 44 * (i / 2);
                var button = Call(factory, "CreateSimpleButton", key,
                    (Action)(() => InvokeAction(action)), Icon(Icons[i]), content);
                created.Add(button);
                Place(button, content, x, y, 32, 32);
                NativeText(content, Labels[i], x + 49, y, 64, 30);
            }
            Refresh();
            InstallLegacyGuards();
            // The only entry is an original WorldBox toolbar button, added last.
            var entry = Call(factory, "CreateWindowButton", Id, Id,
                Icon(new[]{"iconBlessing","iconSteam"}));
            created.Add(entry);
            Call(factory, "AddButtonToTab", entry, tab);
            Ready = true;
            AppDomain.CurrentDomain.SetData("xys.worldbox.native_ui.v32", true);
            Report("[XIANXIA-NATIVE-UI] READY original window / toolbar / buttons; device visual review pending");
        }
        public static void Tick(float time)
        {
            if (!Ready) {
                if (time < retryAt) return;
                retryAt = time + 15;
                try { Build(); }
                catch (Exception e) {
                    foreach (var value in created) {
                        try { Call(Need("UnityEngine.Object"), "Destroy", Get(value, "gameObject")); }
                        catch { }
                    }
                    created.Clear(); status = null;
                    Report("[XIANXIA-NATIVE-UI] BUILD_FAILED " + e);
                }
                return;
            }
            if (time < refreshAt) return;
            refreshAt = time + .5f;
            try { Refresh(); }
            catch (Exception e) { refreshAt = time + 15; Report("[XIANXIA-NATIVE-UI] REFRESH_FAILED " + e); }
        }
    }
}
