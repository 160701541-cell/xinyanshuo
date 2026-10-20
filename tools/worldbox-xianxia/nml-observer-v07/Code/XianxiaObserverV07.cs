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
            const BindingFlags flags=BindingFlags.Public|BindingFlags.NonPublic|BindingFlags.Instance;
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
            if(!open||!versionOK)return;
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
            if(World.world==null||World.world.camera==null){summary="请先打开一个世界";return;}
            if(target!=null&&!target.isAlive()){target=null;follow=false;actorName="人物已死亡";}
            Vector2 p=follow&&target!=null?target.current_position:
                new Vector2(World.world.camera.transform.position.x,World.world.camera.transform.position.y);
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
            float ui=Mathf.Clamp(Screen.width/900f,.66f,1.25f);
            if(GUI.Button(new Rect(Screen.width-182*ui,9,174*ui,44*ui),open?"关闭万界观察":"进入万界观察")){
                open=!open;nextSample=0;
                Debug.Log("[XIANXIA-V07] VIEW_"+(open?"OPEN":"CLOSE"));
            }
            if(!open)return;
            float pw=Mathf.Min(Screen.width-18,690*ui),ph=Mathf.Min(Screen.height-58,610*ui);
            Rect panel=new Rect((Screen.width-pw)/2,(Screen.height-ph)/2,pw,ph);
            GUI.Box(panel,"第三方 WorldBox MOD 实验 · 微观伪3D（只读）");
            GUI.Label(new Rect(panel.x+12,panel.y+26*ui,pw-24,54*ui),
                "人物: "+actorName+"  "+summary+"\n角度:"+angle*90+"°   观察层: "+Mathf.RoundToInt(ObserverFrameGuardV12.SmoothedFps)+" FPS");
            if(GUI.Button(new Rect(panel.x+12,panel.y+73*ui,143*ui,30*ui),
                GiantMapOptionsV11.Armed ? "再次确认大地图" : "实验大地图 10-20"))
                mapStatus=GiantMapOptionsV11.OnTap();
            GUI.Label(new Rect(panel.x+158*ui,panel.y+76*ui,pw-170*ui,29*ui),mapStatus);
            Rect map=new Rect(panel.x+10,panel.y+109*ui,pw-20,Mathf.Max(110,ph-208*ui));
            GUI.Box(map,"");
            if (ObserverFrameGuardV12.Paused)
            {
                GUI.Label(new Rect(map.x+12,map.y+20,map.width-24,120*ui),
                    ObserverFrameGuardV12.Reason+"\n世界仍在模拟；只暂停万界观察绘制。");
                return;
            }
            int useRadius = ObserverFrameGuardV12.ClampRadius(radius);
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
                float sx=p.x+useRadius,sy=p.y+useRadius;
                GUI.color=new Color(1,.85f,.28f);
                GUI.DrawTexture(new Rect(ox+(sx-sy)*hw+hw-3,oy+(sx+sy)*hh-4,7,7),Texture2D.whiteTexture);
            }
            GUI.color=previous;
            float by=panel.y+ph-88*ui,bw=(pw-20)/5;
            if(GUI.Button(new Rect(panel.x+10,by,bw-2,34*ui),"选取人物"))PickPerson();
            if(GUI.Button(new Rect(panel.x+10+bw,by,bw-2,34*ui),follow?"停跟随":"跟随")){
                follow=!follow;nextSample=0;
            }
            if(GUI.Button(new Rect(panel.x+10+2*bw,by,bw-2,34*ui),"放大")){
                radius=Math.Max(3,radius-1);nextSample=0;
            }
            if(GUI.Button(new Rect(panel.x+10+3*bw,by,bw-2,34*ui),"缩小")){
                radius=Math.Min(9,radius+1);nextSample=0;
            }
            if(GUI.Button(new Rect(panel.x+10+4*bw,by,bw-2,34*ui),"转90°")){
                angle=(angle+1)%4;nextSample=0;
            }
            GUI.Label(new Rect(panel.x+12,by+39*ui,pw-24,40*ui),
                "地图扩容只影响新建世界。低FPS自动降采样、暂停绘制。Android实机仍待验收。");
        }
        void OnDestroy(){if(diamond!=null)Destroy(diamond);target=null;}
    }
}