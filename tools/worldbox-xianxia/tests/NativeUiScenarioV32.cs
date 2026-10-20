using System;
using System.Collections.Generic;
using XianxiaWorldBox;

public static class NativeUiScenario
{
    static void Check(bool ok, string message) { if (!ok) throw new Exception(message); }
    public static void Main()
    {
        var game = XianxiaMonoBridge.CultivationBridgeV18.Instance;
        NativeWorldBoxUiV32.Tick(0);
        Check(!NativeWorldBoxUiV32.Ready && NativeWorldBoxUiV32.AllowLegacyGui(), "Never hide legacy before replacement exists");
        Check(NeoModLoader.General.PowerButtonCreator.Entries == 0, "No partial toolbar entry");
        Check(UnityEngine.Object.Destroyed > 0, "Failed build removes its cloned controls");
        NeoModLoader.General.PowerButtonCreator.Fail = false;
        NativeWorldBoxUiV32.Tick(16);
        Check(NativeWorldBoxUiV32.Ready && !NativeWorldBoxUiV32.AllowLegacyGui(), "Replacement gates old GUI only after success");
        Check(HarmonyLib.Harmony.Targets.Count == 2, "Exactly two own GUI methods intercepted");
        foreach (var m in HarmonyLib.Harmony.Targets)
            Check(m.DeclaringType.Namespace == "XianxiaMonoBridge" && m.Name == "OnGUI", "Original game is never intercepted");
        Check(NeoModLoader.General.WindowCreator.Calls == 2, "Native window factory reused after failure");
        Check(NeoModLoader.General.PowerButtonCreator.Entries == 1, "Single native toolbar entry");
        var buttons = NeoModLoader.General.PowerButtonCreator.Successful;
        Check(buttons.Count == 10, "All cultivation actions use original power button factory");
        buttons[0].Click(); Check(!game.Rooted && game.Picks == 1, "Nearby selection reaches real bridge");
        buttons[1].Click(); Check(game.Rooted && game.Picks == 2, "Root selection reaches real bridge");
        for (int i = 2; i < 10; i++) {
            buttons[i].Click(); Check(game.LastAction == i - 2, "Action index maps to persisted gameplay");
        }
        foreach (var b in buttons) {
            Check(b.transform.parent == NeoModLoader.General.WindowCreator.Window.transform_content, "Buttons belong to original scroll window");
            Check(b.icon.Original, "Icons come from installed game loader");
        }
        Check(UnityEngine.UI.Text.Clones.TrueForAll(t => t.font == "original-worldbox-font"), "Original font preserved");
        Check(UnityEngine.UI.Text.Clones.Exists(t => t.text.Contains("测试修士") && t.text.Contains("灵草 3")), "Status uses actual bridge state");
        NativeWorldBoxUiV32.Tick(17);
        Check(NeoModLoader.General.PowerButtonCreator.Entries == 1, "No duplicate toolbar per frame");
        Console.WriteLine("PASS_NATIVE_UI_REFLECTION_SCENARIO: original factories, callback routing, cleanup and own GUI gate; MOCK APIs, NOT phone visual acceptance");
    }
}
namespace UnityEngine {
    public enum TextAnchor { MiddleCenter }
    public enum HorizontalWrapMode { Wrap }
    public enum VerticalWrapMode { Truncate }
    public struct Vector2 { public float x,y; public Vector2(float a,float b){x=a;y=b;} }
    public struct Vector3 { public float x,y,z; public Vector3(float a,float b,float c){x=a;y=b;z=c;} }
    public class Object {
        public static int Destroyed;
        public static Object Instantiate(Object original) {
            var text = original as UI.Text;
            if(text == null) throw new Exception("Only native text cloning expected");
            var clone = new UI.Text {font=text.font};
            UI.Text.Clones.Add(clone);return clone;
        }
        public static void Destroy(Object value) { Destroyed++; }
    }
    public class GameObject : Object { public bool active;public void SetActive(bool value){active=value;} }
    public class Transform {
        public Transform parent;
        public Vector3 localScale;
        public Vector2 anchorMin,anchorMax,pivot,sizeDelta,anchoredPosition;
        public void SetParent(Transform target,bool worldPositionStays){parent=target;}
    }
    public class Component : Object {
        public Transform transform = new Transform();
        public GameObject gameObject = new GameObject();
        public object GetComponent(Type type) {
            if(type == typeof(LocalizedText)) return new LocalizedText();
            return null;
        }
    }
    public class Sprite { public bool Original=true; }
    public static class Resources {
        public static Object[] FindObjectsOfTypeAll(Type type) {
            return type==typeof(XianxiaMonoBridge.CultivationBridgeV18)
                ?new Object[]{XianxiaMonoBridge.CultivationBridgeV18.Instance}:new Object[0];
        }
    }
}
namespace UnityEngine.UI {
    public class Text : UnityEngine.Component {
        public static List<Text> Clones = new List<Text>();
        public string text,font="original-worldbox-font";
        public int fontSize;
        public bool resizeTextForBestFit,raycastTarget;
        public UnityEngine.TextAnchor alignment;
        public UnityEngine.HorizontalWrapMode horizontalOverflow;
        public UnityEngine.VerticalWrapMode verticalOverflow;
    }
}
public class LocalizedText { public bool enabled; }
public static class SpriteTextureLoader {
    public static UnityEngine.Sprite getSprite(string path) {return new UnityEngine.Sprite();}
}
public class ScrollWindow : UnityEngine.Component {
    public UnityEngine.UI.Text titleText = new UnityEngine.UI.Text();
    public UnityEngine.Transform transform_content = new UnityEngine.Transform();
}
namespace NeoModLoader.General {
    public static class LM {
        public static Dictionary<string,string> Labels = new Dictionary<string,string>();
        public static void AddToCurrentLocale(string key,string value){Labels[key]=value;}
    }
    public static class WindowCreator {
        public static ScrollWindow Window=new ScrollWindow(); public static int Calls;
        public static ScrollWindow CreateEmptyWindow(string id,string title,string icon="neomodloader"){Calls++;return Window;}
    }
    public class PowerButton : UnityEngine.Component {
        public Action Callback;
        public UnityEngine.Sprite icon;
        public void Click(){Callback();}
    }
    public static class PowerButtonCreator {
        public static bool Fail=true;public static int Entries;
        public static List<PowerButton> Successful=new List<PowerButton>();
        public static object GetTab(string id){if(id!="other")throw new Exception("Wrong tab");return new object();}
        public static PowerButton CreateSimpleButton(string id,Action action,UnityEngine.Sprite icon,
            UnityEngine.Transform parent=null,UnityEngine.Vector2 position=default(UnityEngine.Vector2)) {
            if(Fail && id.EndsWith("_3")) {Successful.Clear();throw new Exception("Factory unavailable");}
            var b=new PowerButton{Callback=action,icon=icon};Successful.Add(b);return b;
        }
        public static PowerButton CreateWindowButton(string id,string window,UnityEngine.Sprite icon,
            UnityEngine.Transform parent=null,UnityEngine.Vector2 position=default(UnityEngine.Vector2)){return new PowerButton{icon=icon};}
        public static void AddButtonToTab(PowerButton b,object tab,int? siblingIndex=null){Entries++;}
    }
}
namespace XianxiaMonoBridge {
    public class Overlay { private void OnGUI(){} }
    public class Actor { public bool isAlive(){return true;} public string getName(){return "测试修士";} }
    public class State { public int Layer=2,Herbs=3,Stones=4,Pills=1; public float Qi=24; }
    public class CultivationBridgeV18 : UnityEngine.Object {
        public static CultivationBridgeV18 Instance=new CultivationBridgeV18();
        private Actor selected=new Actor();
        private string message="修行中";
        public bool Rooted;public int Picks,LastAction=-1;
        private void Pick(bool rooted){Rooted=rooted;Picks++;}
        private void Action(int code){LastAction=code;}
        private static float Now(){return 3;}
        private static State Read(Actor actor,float time){return new State();}
        private void OnGUI(){}
    }
}
namespace HarmonyLib {
    public class HarmonyMethod {public HarmonyMethod(System.Reflection.MethodInfo method){}}
    public class Harmony {
        public static List<System.Reflection.MethodBase> Targets=new List<System.Reflection.MethodBase>();
        public Harmony(string id){}
        public void Patch(System.Reflection.MethodBase original,HarmonyMethod prefix=null,
            HarmonyMethod postfix=null,HarmonyMethod transpiler=null,HarmonyMethod finalizer=null){Targets.Add(original);}
    }
}
