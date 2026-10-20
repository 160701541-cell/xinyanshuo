// Personal-use WorldBox Mono overlay from user-provided APK. No entitlement changes.
// Only other-game derivative MOD lab; NEVER the unrelated Canglan game project.
// Standalone bridge booted from MapBox.Start via a strict, audited Cecil call.
using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;
namespace XianxiaMonoBridge {
public static class Entry {
    static bool installed;
    public static void Install() {
        if(installed)return;
        try {
            installed=true;
            var obj=new GameObject("WorldBoxXianxiaReadabilityBridge");
            UnityEngine.Object.DontDestroyOnLoad(obj);
            obj.AddComponent(typeof(Overlay));
            Debug.Log("[XIANXIA-MONO-V13] LOAD_BRIDGE_OK");
        } catch(Exception e) {
            installed=false;
            Debug.LogError("[XIANXIA-MONO-V13] LOAD_FAILED "+e);
        }
    }
}
public sealed class Overlay : MonoBehaviour {
    bool visible;
    bool fontsEnabled;
    int scaleIndex=1;
    Font font;
    GUIStyle buttonStyle,labelStyle,boxStyle;
    int applied;
    float nextCheck;
    string worldInfo="等待进入世界";
    readonly Dictionary<int,FontSnapshot> original=new Dictionary<int,FontSnapshot>();
    sealed class FontSnapshot {
        public object target;
        public PropertyInfo prop;
        public float value;
    }
    static readonly float[] Scales={1f,1.25f,1.5f,1.75f};
    void Start(){
        Debug.Log("[XIANXIA-MONO-V13] COMPONENT_STARTED");
        try{font=Font.CreateDynamicFontFromOSFont(
            new[]{"Noto Sans CJK SC","Droid Sans Fallback","sans-serif"},30);
        }catch(Exception e){Debug.LogWarning("[XIANXIA-MONO-V13] FONT_FALLBACK "+e.GetType().Name);}
    }
    static object Get(object obj,string name){
        if(obj==null)return null;
        Type t=obj is Type?(Type)obj:obj.GetType();
        var field=t.GetField(name,BindingFlags.Public|BindingFlags.NonPublic|BindingFlags.Instance|BindingFlags.Static);
        if(field!=null)return field.GetValue(obj is Type?null:obj);
        var prop=t.GetProperty(name,BindingFlags.Public|BindingFlags.NonPublic|BindingFlags.Instance|BindingFlags.Static);
        if(prop!=null&&prop.GetIndexParameters().Length==0)return prop.GetValue(obj is Type?null:obj,null);
        return null;
    }
    void ReadWorld(){
        try {
            Assembly game=typeof(Overlay).Assembly;
            foreach(Assembly a in AppDomain.CurrentDomain.GetAssemblies())
                if(a.GetName().Name=="Assembly-CSharp"){game=a;break;}
            Type worldType=game.GetType("World");
            Type mapType=game.GetType("MapBox");
            var world=worldType!=null?Get(worldType,"world"):null;
            if(world==null){worldInfo="世界尚未生成";return;}
            object w=mapType!=null?Get(mapType,"width"):null;
            object h=mapType!=null?Get(mapType,"height"):null;
            worldInfo="已进入WorldBox世界";
            if(w!=null&&h!=null)worldInfo+=" / "+w+"×"+h+"格";
        }catch(Exception e){worldInfo="地图读取待兼容："+e.GetType().Name;}
    }
    void Update(){
        if(Time.unscaledTime<nextCheck)return;
        nextCheck=Time.unscaledTime+5f;
        ReadWorld();
        if(fontsEnabled)TryApplySmallFonts();
    }
    void ResetStyles() {buttonStyle=null;labelStyle=null;boxStyle=null;}
    GUIStyle Styled(GUIStyle originalStyle,ref GUIStyle cached,int minSize) {
        if(cached==null){
            cached=new GUIStyle(originalStyle);
            cached.fontSize=Mathf.Max(minSize,Mathf.RoundToInt(minSize*Scales[scaleIndex]));
            if(font!=null)cached.font=font;
            cached.wordWrap=true;
        }
        return cached;
    }
    void OnGUI(){
        float u=Mathf.Clamp(Screen.height/720f,.92f,1.65f);
        var btn=Styled(GUI.skin.button,ref buttonStyle,19);
        var label=Styled(GUI.skin.label,ref labelStyle,18);
        var box=Styled(GUI.skin.box,ref boxStyle,18);
        float buttonW=242*u,buttonH=61*u;
        if(GUI.Button(new Rect(Screen.width-buttonW-14*u,14*u,buttonW,buttonH),
           visible?"关闭万界设置":"万界 · 清晰大字",btn))
           visible=!visible;
        if(!visible)return;
        float pw=Mathf.Min(Screen.width-32*u,780*u),ph=Mathf.Min(Screen.height-32*u,490*u);
        float px=(Screen.width-pw)/2f,py=(Screen.height-ph)/2f;
        GUI.Box(new Rect(px,py,pw,ph),"WorldBox / 万界仙侠 MOD 可读性设置",box);
        GUI.Label(new Rect(px+25*u,py+66*u,pw-50*u,73*u),
            worldInfo+"\n字体放大通过动态字体渲染；不会提高原版低分辨率贴图精度。",label);
        float col=(pw-58*u)/2f;
        if(GUI.Button(new Rect(px+20*u,py+151*u,col,67*u),
            "字体："+Mathf.RoundToInt(Scales[scaleIndex]*100f)+"%",btn)) {
            scaleIndex=(scaleIndex+1)%Scales.Length;
            ResetStyles(); RestoreFonts();nextCheck=0;
        }
        if(GUI.Button(new Rect(px+38*u+col,py+151*u,col,67*u),
            fontsEnabled?"其他MOD小字：放大中":"其他MOD小字：点击开启",btn)){
            fontsEnabled=!fontsEnabled;
            if(!fontsEnabled)RestoreFonts();
            nextCheck=0;
        }
        GUI.Label(new Rect(px+25*u,py+241*u,pw-50*u,134*u),
          "字太小的第三方MOD：可尝试放大原有Unity UI文字。\n"+
          "已调整："+applied+"处；可关闭并恢复原字体大小。\n"+
          "更大的世界和战斗等功能需要继续验证兼容；此版为只读桥接实验。",label);
        GUI.Label(new Rect(px+25*u,py+ph-84*u,pw-50*u,66*u),
          "【实验版本】未经过用户手机启动与存档测试。与《苍岚》原创游戏无关。",label);
    }
    void TryApplySmallFonts(){
        try{
            foreach(var tName in new[]{"TMPro.TMP_Text","UnityEngine.UI.Text"}){
                Type found=null;
                foreach(var a in AppDomain.CurrentDomain.GetAssemblies()) {
                    found=a.GetType(tName,false);
                    if(found!=null)break;
                }
                if(found==null)continue;
                var prop=found.GetProperty("fontSize",BindingFlags.Public|BindingFlags.Instance);
                if(prop==null||!prop.CanRead||!prop.CanWrite)continue;
                var all=Resources.FindObjectsOfTypeAll(found);
                foreach(var item in all) {
                    if(item==null||original.Count>=500)break;
                    int key=item.GetInstanceID();
                    if(original.ContainsKey(key))continue;
                    try{
                        if(item is Behaviour && !((Behaviour)item).isActiveAndEnabled)continue;
                        float originalSize=Convert.ToSingle(prop.GetValue(item,null));
                        if(originalSize<=0||originalSize>=24)continue;
                        float next=Mathf.Min(34f,Mathf.Max(19f,originalSize*Scales[scaleIndex]));
                        prop.SetValue(item,Convert.ChangeType(next,prop.PropertyType),null);
                        original.Add(key,new FontSnapshot{target=item,prop=prop,value=originalSize});
                        applied++;
                    }catch {}
                }
            }
        }catch(Exception e){Debug.LogWarning("[XIANXIA-MONO-V13] FONT_SCAN "+e.GetType().Name);}
    }
    void RestoreFonts(){
        foreach(var v in original.Values)try{
            v.prop.SetValue(v.target,Convert.ChangeType(v.value,v.prop.PropertyType),null);
        }catch{}
        original.Clear();applied=0;
    }
    void OnDestroy(){
        RestoreFonts();
        if(font!=null)UnityEngine.Object.Destroy(font);
        Debug.Log("[XIANXIA-MONO-V13] COMPONENT_DESTROYED");
    }
}
}