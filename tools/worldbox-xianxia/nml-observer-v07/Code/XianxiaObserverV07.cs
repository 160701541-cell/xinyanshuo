using System;
using System.Reflection;
using NeoModLoader.api;
using UnityEngine;

namespace XianxiaWorldBox
{
    // Read-only OTHER-GAME MOD derivative test. NEVER Canglan/ APK176/ Godot game code.
    // Source-only candidate: Android 0.51.4 / NML runtime remains DEVICE_PENDING.
    public sealed class XianxiaObserverV07 : BasicMod<XianxiaObserverV07>
    {
        const int MaxRadius = 9;
        readonly Color[,] colors = new Color[19,19];
        readonly int[] peopleX = new int[64], peopleY = new int[64];
        int peopleCount, centerX, centerY, radius = 4, angle;
        Actor target;
        bool open, follow = true, sampled, versionOK;
        float nextSample;
        Texture2D diamond;
        string summary = "尚未读取游戏地图", actorName = "未选中";
        string mapStatus = "实验地图默认关闭。大世界选项仅影响新建世界，需实机验证。";

        protected override void OnModLoad()
        {
            versionOK = Application.version.StartsWith("0.51.", StringComparison.Ordinal);
            diamond = new Texture2D(64,32,TextureFormat.RGBA32,false);
            diamond.filterMode = FilterMode.Point;
            diamond.wrapMode = TextureWrapMode.Clamp;
            for(int y=0;y<32;y++)
                for(int x=0;x<64;x++) {
                    float d = Mathf.Abs(x+.5f-32f)/32f + Mathf.Abs(y+.5f-16f)/16f;
                    diamond.SetPixel(x,y,d<.95f?Color.white:d<=1f?Color.black:Color.clear);
                }
            diamond.Apply(false,true);
            Debug.Log("[XIANXIA-V07] SOURCE_ONLY_LOAD "+Application.version+" supported="+versionOK);
        }

        static object Field(object obj,string key)
        {
            if(obj==null)return null;
            Type t=obj.GetType();
            const BindingFlags flags=BindingFlags.Public|BindingFlags.NonPublic|BindingFlags.Instance|BindingFlags.Static;
            FieldInfo f=t.GetField(key,flags);
            if(f!=null)return f.GetValue(obj);
            PropertyInfo p=t.GetProperty(key,flags);
            return p!=null && p.GetIndexParameters().Length==0?p.GetValue(obj,null):null;
        }
        static Color Ground(WorldTile tile)
        {
            if(tile==null)return new Color(.06f,.09f,.15f,.3f);
            try{
                object kind=Field(tile,"top_type")??Field(tile,"main_type");
                object color=Field(kind,"color");
                if(color is Color)return (Color)color;
                string name=Convert.ToString(Field(kind,"id"))??"";
                if(name.Contains("water")||name.Contains("ocean"))return new Color(.15f,.42f,.70f);
                if(name.Contains("rock")||name.Contains("mountain"))return new Color(.45f,.48f,.5f);
                if(name.Contains("sand"))return new Color(.77f,.67f,.41f);
                if(name.Contains("snow"))return new Color(.79f,.86f,.92f);
                if(name.Contains("lava"))return new Color(.94f,.35f,.13f);
            }catch{}
            return new Color(.32f,.56f,.36f);
        }
        void PickPerson()
        {
            if(World.world==null)return;
            try{
                Actor selected=World.world.getActorNearCursor();
                if(selected==null||!selected.isAlive()){
                    float best=float.MaxValue;
                    foreach(Actor a in World.world.units.getSimpleList()){
                        if(a==null||!a.isAlive())continue;
                        Vector2 p=a.current_position;
                        float dist=(p.x-centerX)*(p.x-centerX)+(p.y-centerY)*(p.y-centerY);
                        if(dist<best){best=dist;selected=a;}
                    }
                }
                target=selected;
                actorName=selected==null?"附近没有人物":selected.getName();
                follow=target!=null;nextSample=0;
            }catch(Exception e){summary="选取失败 "+e.GetType().Name;}
        }
        void Update()
        {
            if(!versionOK)return;
            ModTextAccessibilityV13.Tick();
            if(!open)return;
            ObserverFrameGuardV12.Tick();
            if(ObserverFrameGuardV12.Paused||Time.unscaledTime<nextSample)return;
            nextSample=Time.unscaledTime+ObserverFrameGuardV12.SampleInterval();
            try{Sample();}
            catch(Exception e){
                summary="地图采样失败 "+e.GetType().Name;
                nextSample=Time.unscaledTime+5f;
                Debug.LogWarning("[XIANXIA-V07] SAMPLE_ERROR "+e.GetType().Name);
            }
        }
        void Sample()
        {
            Camera camera=Field(World.world,"camera") as Camera;
            if(World.world==null||camera==null){summary="请先打开一个世界";return;}
            if(target!=null&&!target.isAlive()){target=null;follow=false;actorName="人物已死亡";}
            Vector2 p=follow&&target!=null?target.current_position:
                new Vector2(camera.transform.position.x,camera.transform.position.y);
            centerX=Mathf.Clamp(Mathf.RoundToInt(p.x),0,Math.Max(0,MapBox.width-1));
            centerY=Mathf.Clamp(Mathf.RoundToInt(p.y),0,Math.Max(0,MapBox.height-1));
            for(int dy=-radius;dy<=radius;dy++)
                for(int dx=-radius;dx<=radius;dx++){
                    int x=centerX+dx,y=centerY+dy;
                    WorldTile t=x<0||x>=MapBox.width||y<0||y>=MapBox.height?null:World.world.GetTile(x,y);
                    colors[dx+MaxRadius,dy+MaxRadius]=Ground(t);
                }
            peopleCount=0;
            foreach(Actor a in World.world.units.getSimpleList()){
                if(a==null||!a.isAlive())continue;
                Vector2 v=a.current_position;
                int dx=Mathf.RoundToInt(v.x)-centerX,dy=Mathf.RoundToInt(v.y)-centerY;
                if(Math.Abs(dx)>radius||Math.Abs(dy)>radius)continue;
                if(peopleCount>=peopleX.Length)break;
                peopleX[peopleCount]=dx;peopleY[peopleCount]=dy;peopleCount++;
            }
            summary="世界 "+MapBox.width+"x"+MapBox.height+" / 地图 "+centerX+","+centerY+" / NPC "+peopleCount;
            if(!sampled){sampled=true;Debug.Log("[XIANXIA-V07] REAL_MAP_SAMPLE "+centerX+","+centerY);}
        }
        Vector2 Rot(int x,int y)
        {
            switch(angle){
                case 1:return new Vector2(y,-x);
                case 2:return new Vector2(-x,-y);
                case 3:return new Vector2(-y,x);
                default:return new Vector2(x,y);
            }
        }
        Vector2 Unrot(int x,int y)
        {
            switch(angle){
                case 1:return new Vector2(-y,x);
                case 2:return new Vector2(-x,-y);
                case 3:return new Vector2(y,-x);
                default:return new Vector2(x,y);
            }
        }
        void OnGUI()
        {
            if(!versionOK||diamond==null)return;
            GUIStyle button = ModTextAccessibilityV13.ButtonStyle();
            GUIStyle label = ModTextAccessibilityV13.LabelStyle();
            GUIStyle box = ModTextAccessibilityV13.BoxStyle();
            if (button==null || label==null || box==null) return;
            float ui=Mathf.Clamp(Screen.width/900f,.8f,1.35f);
            float x=Screen.width-230*ui;
            if(GUI.Button(new Rect(x,9,220*ui,52*ui),open?"收起万界观察":"万界观察 · 大字",button)){
                open=!open;nextSample=0;
                Debug.Log("[XIANXIA-V13] VIEW_"+(open?"OPEN":"CLOSE"));
            }
            if(!open)return;
            float pw=Mathf.Min(Screen.width-16,755*ui),ph=Mathf.Min(Screen.height-16,645*ui);
            Rect panel=new Rect((Screen.width-pw)/2,(Screen.height-ph)/2,pw,ph);
            GUI.Box(panel,"WorldBox 万界观察 / 非官方 MOD 实验",box);
            GUI.Label(new Rect(panel.x+12,panel.y+33*ui,pw-24,60*ui),
                "人物："+actorName+" / "+summary+"\n方向："+angle*90+"° | 观察层FPS "+Mathf.RoundToInt(ObserverFrameGuardV12.SmoothedFps),label);
            float firstY=panel.y+94*ui;
            if(GUI.Button(new Rect(panel.x+12,firstY,172*ui,45*ui),
                 GiantMapOptionsV11.Armed?"再次确认大地图":"大地图实验",button))
                mapStatus=GiantMapOptionsV11.OnTap();
            GUI.Label(new Rect(panel.x+192*ui,firstY+3*ui,pw-207*ui,45*ui),mapStatus,label);
            float secondY=panel.y+142*ui;
            if(GUI.Button(new Rect(panel.x+12,secondY,180*ui,46*ui),
                          "字体 "+Mathf.RoundToInt(ModTextAccessibilityV13.Scale*100f)+"%",button))
                ModTextAccessibilityV13.CycleScale();
            if(GUI.Button(new Rect(panel.x+202*ui,secondY,205*ui,46*ui),
                          ModTextAccessibilityV13.GlobalEnabled?"其他MOD字体：开":"其他MOD字体：关",button))
                ModTextAccessibilityV13.ToggleGlobal();
            GUI.Label(new Rect(panel.x+417*ui,secondY+4*ui,pw-430*ui,44*ui),
                "已增大："+ModTextAccessibilityV13.ModifiedCount+"处",label);
            Rect map=new Rect(panel.x+10,panel.y+199*ui,pw-20,Mathf.Max(90,ph-315*ui));
            GUI.Box(map,"",box);
            if (ObserverFrameGuardV12.Paused)
            {
                GUI.Label(new Rect(map.x+16,map.y+18,map.width-32,140*ui),
                    ObserverFrameGuardV12.Reason+"\n原游戏继续运行，只有额外观察层暂停。",label);
            }
            else
            {
                int useRadius=ObserverFrameGuardV12.ClampRadius(radius);
                float tw=Mathf.Min((map.width-16)/(2f*useRadius+1),(map.height-20)/(useRadius+1));
                tw=Mathf.Max(7f,tw);
                float hw=tw*.5f,hh=tw*.25f;
                float ox=map.x+map.width*.5f-hw,oy=map.y+11;
                Color previous=GUI.color;
                for(int sum=0;sum<=4*useRadius;sum++)
                    for(int sy=0;sy<=2*useRadius;sy++){
                        int sx=sum-sy;
                        if(sx<0||sx>2*useRadius)continue;
                        Vector2 w=Unrot(sx-useRadius,sy-useRadius);
                        GUI.color=colors[(int)w.x+MaxRadius,(int)w.y+MaxRadius];
                        GUI.DrawTexture(new Rect(ox+(sx-sy)*hw,oy+(sx+sy)*hh,tw,tw*.5f),diamond);
                    }
                for(int i=0;i<peopleCount;i++){
                    Vector2 p=Rot(peopleX[i],peopleY[i]);
                    if(Mathf.Abs(p.x)>useRadius||Mathf.Abs(p.y)>useRadius)continue;
                    float sx=p.x+useRadius,sy=p.y+useRadius;
                    GUI.color=new Color(1,.85f,.28f);
                    GUI.DrawTexture(new Rect(ox+(sx-sy)*hw+hw-3,oy+(sx+sy)*hh-4,7,7),Texture2D.whiteTexture);
                }
                GUI.color=previous;
            }
            float by=panel.y+ph-99*ui,bw=(pw-20)/5f;
            if(GUI.Button(new Rect(panel.x+10,by,bw-2,48*ui),"选择人物",button))PickPerson();
            if(GUI.Button(new Rect(panel.x+10+bw,by,bw-2,48*ui),follow?"停止跟随":"跟随",button)){
                follow=!follow;nextSample=0;
            }
            if(GUI.Button(new Rect(panel.x+10+2*bw,by,bw-2,48*ui),"放大",button)){
                radius=Math.Max(3,radius-1);nextSample=0;
            }
            if(GUI.Button(new Rect(panel.x+10+3*bw,by,bw-2,48*ui),"缩小",button)){
                radius=Math.Min(9,radius+1);nextSample=0;
            }
            if(GUI.Button(new Rect(panel.x+10+4*bw,by,bw-2,48*ui),"旋转90°",button)){
                angle=(angle+1)%4;nextSample=0;
            }
            GUI.Label(new Rect(panel.x+12,by+54*ui,pw-24,36*ui),
                "高清字仅作用UI；不会凭空提升原游戏贴图分辨率。Android真机待测。",label);
        }
        void OnDestroy(){ModTextAccessibilityV13.Shutdown();if(diamond!=null)Destroy(diamond);target=null;}
    }
}
