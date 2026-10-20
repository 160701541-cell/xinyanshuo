using System;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

namespace XianxiaWorldBox
{
    /// <summary>
    /// Optional readability layer for the user's WorldBox + independently loaded
    /// mod GUIs. No game asset/font redistribution, no save mutation, no APK hook.
    ///
    /// All changes are reversible. Disabled for other mods by default until user
    /// enables it in the observation UI; the observation UI itself is enlarged.
    /// </summary>
    public static class ModTextAccessibilityV13
    {
        static readonly BindingFlags All = BindingFlags.Instance | BindingFlags.Public;
        static readonly float[] Sizes = { 1.0f, 1.25f, 1.5f, 1.75f };
        static readonly Dictionary<int, OriginalText> Originals = new Dictionary<int, OriginalText>();
        static int step = 2;
        static bool globalEnabled;
        static float nextScan;
        static Font dynamicCjkFont;
        static readonly string[] FontFamilies = { "Noto Sans CJK SC", "Droid Sans Fallback", "sans-serif" };
        static GUIStyle accessibleButton, accessibleLabel, accessibleBox;
        static bool styleDirty = true;
        static int modifiedCount;
        const int MaxTracked = 480;

        sealed class OriginalText
        {
            public object component;
            public PropertyInfo fontProperty;
            public float originalSize;
        }

        public static float Scale { get { return Sizes[step]; } }
        public static int ModifiedCount { get { return modifiedCount; } }
        public static bool GlobalEnabled { get { return globalEnabled; } }
        public static string Status
        {
            get { return "界面文字 " + Math.Round(Scale * 100) + "% | 其他MOD放大：" +
                         (globalEnabled ? "开" : "关") + " | 已调整 " + modifiedCount; }
        }
        public static void CycleScale()
        {
            step = (step + 1) % Sizes.Length;
            styleDirty = true;
            Restore();
            nextScan = 0f;
        }
        public static void ToggleGlobal()
        {
            globalEnabled = !globalEnabled;
            styleDirty = true;
            if (!globalEnabled) Restore();
            nextScan = 0f;
        }
        static Font TryFont()
        {
            if (dynamicCjkFont != null) return dynamicCjkFont;
            try { dynamicCjkFont = Font.CreateDynamicFontFromOSFont(FontFamilies, 28); }
            catch (Exception e) { Debug.LogWarning("[XIANXIA-FONT] CJK fallback: " + e.GetType().Name); }
            return dynamicCjkFont;
        }
        public static GUIStyle ButtonStyle()
        {
            EnsureStyles();
            return accessibleButton;
        }
        public static GUIStyle LabelStyle()
        {
            EnsureStyles();
            return accessibleLabel;
        }
        public static GUIStyle BoxStyle()
        {
            EnsureStyles();
            return accessibleBox;
        }
        static void EnsureStyles()
        {
            if (!styleDirty && accessibleButton != null) return;
            if (GUI.skin == null) return;
            var os = TryFont();
            accessibleButton = new GUIStyle(GUI.skin.button);
            accessibleLabel = new GUIStyle(GUI.skin.label);
            accessibleBox = new GUIStyle(GUI.skin.box);
            int px = Mathf.Clamp(Mathf.RoundToInt(17f * Scale), 17, 31);
            accessibleButton.fontSize = px;
            accessibleLabel.fontSize = px;
            accessibleBox.fontSize = px;
            accessibleLabel.wordWrap = true;
            accessibleButton.wordWrap = true;
            if (os != null)
            {
                accessibleButton.font = os;
                accessibleLabel.font = os;
                accessibleBox.font = os;
            }
            styleDirty = false;
        }
        public static void Tick()
        {
            if (!globalEnabled || Time.unscaledTime < nextScan) return;
            nextScan = Time.unscaledTime + 6f;
            try
            {
                int remain = MaxTracked - Originals.Count;
                if (remain <= 0) return;
                // Both legacy Unity.UI.Text and TextMeshPro support fontSize.
                ApplyToClass("UnityEngine.UI.Text", "UnityEngine.UI", remain);
                remain = MaxTracked - Originals.Count;
                if (remain > 0) ApplyToClass("TMPro.TMP_Text", "Unity.TextMeshPro", remain);
            }
            catch (Exception e)
            {
                Debug.LogWarning("[XIANXIA-FONT] scan failed " + e.GetType().Name);
                nextScan = Time.unscaledTime + 20f;
            }
        }
        static void ApplyToClass(string fullName, string assembly, int maxNew)
        {
            if (maxNew <= 0) return;
            Type type = Type.GetType(fullName + ", " + assembly, false);
            if (type == null)
            {
                foreach (Assembly a in AppDomain.CurrentDomain.GetAssemblies())
                {
                    type = a.GetType(fullName, false);
                    if (type != null) break;
                }
            }
            if (type == null) return;
            PropertyInfo font = type.GetProperty("fontSize", All);
            if (font == null || !font.CanRead || !font.CanWrite) return;
            var results = Resources.FindObjectsOfTypeAll(type) as IEnumerable;
            if (results == null) return;
            int seen = 0;
            foreach (object component in results)
            {
                if (component == null || ++seen > 1500 || maxNew <= 0) break;
                try
                {
                    int key = component.GetHashCode();
                    if (Originals.ContainsKey(key)) continue;
                    if (!IsActive(component)) continue;
                    float oldSize = Convert.ToSingle(font.GetValue(component, null));
                    if (oldSize <= 0.1f || oldSize > 128f) continue;
                    // Only patch genuinely small on-screen UI text; leave big titles alone.
                    if (oldSize >= 24f) continue;
                    float requested = Mathf.Clamp(Mathf.Max(19f, oldSize * Scale), oldSize, 34f);
                    if (requested <= oldSize) continue;
                    font.SetValue(component, Convert.ChangeType(requested, font.PropertyType), null);
                    Originals[key] = new OriginalText {
                        component = component, fontProperty = font, originalSize = oldSize
                    };
                    maxNew--;
                    modifiedCount++;
                }
                catch { /* unloaded or IL2CPP-only wrapper; skip safely */ }
            }
        }
        static bool IsActive(object component)
        {
            PropertyInfo goProp = component.GetType().GetProperty("gameObject", All);
            var go = goProp == null ? null : goProp.GetValue(component, null);
            if (go == null) return false;
            var activeProp = go.GetType().GetProperty("activeInHierarchy", All);
            return activeProp == null || Convert.ToBoolean(activeProp.GetValue(go, null));
        }
        public static void Restore()
        {
            foreach (var item in Originals.Values)
            {
                try
                {
                    item.fontProperty.SetValue(item.component,
                        Convert.ChangeType(item.originalSize, item.fontProperty.PropertyType), null);
                }
                catch { }
            }
            Originals.Clear();
            modifiedCount = 0;
        }
        public static void Shutdown()
        {
            Restore();
            if (dynamicCjkFont != null)
            {
                UnityEngine.Object.Destroy(dynamicCjkFont);
                dynamicCjkFont = null;
            }
            accessibleButton = null; accessibleLabel = null; accessibleBox = null;
            styleDirty = true;
        }
    }
}
