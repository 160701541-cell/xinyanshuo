using System;
using System.IO;
using System.Reflection;
using System.Collections.Generic;
using UnityEngine;

namespace XianxiaMonoBridge {
// Additive WorldBox implementation. Never reads/writes Canglan runtime data.
public sealed class CultivationBridgeV18 : MonoBehaviour {
    const string K="xys_wanjie_v18_";
    Actor selected;
    bool open,assetsTab,ready;
    int cursor,assetPage;
    float nextTick;
    GUIStyle label,button,box;
    Font font;
    string message="选取人物后检测灵根；修炼和炼丹随世界时间推进";
    readonly Dictionary<string,Texture2D> textures=new Dictionary<string,Texture2D>();
    static readonly string[] RootNames={"无灵根","金灵根","木灵根","水灵根","火灵根","土灵根"};
    static readonly string[] ArtIds={"CL_BUILDING_001","CL_BUILDING_002","CL_BUILDING_003","CL_BUILDING_004","CL_BUILDING_005","CL_BUILDING_006","CL_PROP_LANTERN_001","CL_BUILDING_007"};
    static readonly string[] ArtNames={"城门","酒楼","商铺","民居","院门","石桥","灯笼","屋顶组件"};
    static readonly FieldInfo ActorDataField=FindField(typeof(Actor),"data");
    static readonly FieldInfo BuildingDataField=FindField(typeof(Building),"data");
    static readonly FieldInfo BuildingAssetField=FindField(typeof(Building),"asset");
    static FieldInfo FindField(Type type,string name){
        for(Type t=type;t!=null;t=t.BaseType){
            var f=t.GetField(name,BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic|BindingFlags.DeclaredOnly);
            if(f!=null)return f;
        }
        throw new MissingFieldException(type.FullName,name);
    }
    static ActorData Data(Actor a){return (ActorData)ActorDataField.GetValue(a);}
    static BaseSystemData Data(Building b){return (BaseSystemData)BuildingDataField.GetValue(b);}
    static BuildingAsset Asset(Building b){return (BuildingAsset)BuildingAssetField.GetValue(b);}
    static int Int(BaseSystemData d,string key,int fallback=0){int v;d.get(K+key,out v,fallback);return v;}
    static float Float(BaseSystemData d,string key,float fallback=0){float v;d.get(K+key,out v,fallback);return v;}
    static bool Person(Actor a){return a!=null&&a.isAlive()&&Data(a)!=null&&a.asset!=null&&a.asset.civ;}
    static float Now(){return World.world==null?0:(float)World.world.getCurWorldTime();}
    static int Root(Actor a){
        int r=Int(Data(a),"root",-1);
        return r<0?CultivationRulesV18.BornRoot(Data(a).id+"|"+Data(a).created_time.ToString("R",System.Globalization.CultureInfo.InvariantCulture)):Math.Max(0,Math.Min(5,r));
    }
    static CultivationState Read(Actor a,float now){return new CultivationState{
        Root=Root(a),Layer=Math.Max(0,Math.Min(13,Int(Data(a),"layer"))),
        Herbs=Int(Data(a),"herbs"),Stones=Int(Data(a),"stones"),Pills=Int(Data(a),"pills"),
        Qi=Float(Data(a),"qi"),Stress=Float(Data(a),"stress"),LastTime=Float(Data(a),"last",now),CraftAt=Float(Data(a),"craft"),
        Tested=Int(Data(a),"tested")!=0,Method=Int(Data(a),"method")!=0,Training=Int(Data(a),"training")!=0};}
    static void Write(Actor a,CultivationState s){
        var d=Data(a);d.set(K+"root",s.Root);d.set(K+"layer",s.Layer);
        d.set(K+"herbs",s.Herbs);d.set(K+"stones",s.Stones);d.set(K+"pills",s.Pills);
        d.set(K+"qi",s.Qi);d.set(K+"stress",s.Stress);d.set(K+"last",s.LastTime);d.set(K+"craft",s.CraftAt);
        d.set(K+"tested",s.Tested?1:0);d.set(K+"method",s.Method?1:0);d.set(K+"training",s.Training?1:0);
    }
    void Initialize(){
        for(int i=1;i<=13;i++){
            string id=K+"qi_"+i;
            if(AssetManager.traits.get(id)!=null)continue;
            var t=new ActorTrait{id=id,path_icon="ui/Icons/iconBlessing",type=TraitType.Positive,
                can_be_given=false,can_be_removed=true,rate_birth=0,rate_inherit=0,
                spawn_random_trait_allowed=false,is_mutation_box_allowed=false,base_stats=new BaseStats()};
            t.base_stats["health"]=12*i;t.base_stats["damage"]=3*i;
            t.base_stats["mana"]=9*i;t.base_stats["lifespan"]=4*i;
            AssetManager.traits.add(t);
        }
        ready=true;
        DiagnosticLog.Write("[XIANXIA-V18] CULTIVATION_READY: own actor data, 13 additive traits, original art; device acceptance pending");
    }
    static void SyncTrait(Actor a,int layer){
        for(int i=1;i<=13;i++){
            string id=K+"qi_"+i;
            if(i!=layer){if(a.hasTrait(id))a.removeTrait(id);}
            else if(!a.hasTrait(id))a.addTrait(id,true);
        }
    }
    void Update(){
        if(World.world==null||!Config.game_loaded||Time.unscaledTime<nextTick)return;
        nextTick=Time.unscaledTime+.3f;
        try{
            if(!ready)Initialize();
            var units=World.world.units.getSimpleList();
            if(units.Count==0)return;
            float now=Now();
            for(int i=0;i<Math.Min(64,units.Count);i++){
                if(cursor>=units.Count)cursor=0;
                Actor a=units[cursor++];if(!Person(a))continue;
                bool enrolled=Int(Data(a),"tested")!=0;
                // Rare rule-driven NPC opportunities; never described as an LLM.
                if(!enrolled&&PlayerPrefs.GetInt(K+"npc",1)!=0&&CultivationRulesV18.Hash(Data(a).id.ToString())%32==0&&Root(a)>0){
                    var born=Read(a,now);born.Tested=true;born.Method=true;born.Training=true;Write(a,born);enrolled=true;
                }
                if(!enrolled)continue;
                var s=Read(a,now);CultivationRulesV18.Advance(s,now);
                if(a!=selected&&s.Method&&s.Root>0&&s.Stress<=20&&s.Layer<13)s.Training=true;
                if(a!=selected&&s.Training&&s.Stress<=70&&s.Qi>=CultivationRulesV18.BreakthroughCost(s.Layer))
                    CultivationRulesV18.Breakthrough(s);
                Write(a,s);SyncTrait(a,s.Layer);
            }
        }catch(Exception e){message="修仙接口异常："+e.GetType().Name+"，请复制日志";DiagnosticLog.Write("[XIANXIA-V18] CULTIVATION_ERROR "+e);nextTick=Time.unscaledTime+5;}
    }
    void Pick(bool rooted){
        if(World.world==null){message="请先进入世界";return;}
        Actor best=null;float distance=float.MaxValue;
        Vector2 center=Camera.main==null?Vector2.zero:(Vector2)Camera.main.transform.position;
        foreach(Actor a in World.world.units.getSimpleList()){
            if(!Person(a)||(rooted&&Root(a)==0))continue;
            float dist=(a.current_position-center).sqrMagnitude;
            if(dist<distance){distance=dist;best=a;}
        }
        selected=best;message=best==null?"当前世界没有可选文明人物":"已选取镜头附近人物："+best.getName();
    }
    void Action(int action){
        if(!Person(selected)){message="请先选取一个活着的文明人物";return;}
        float now=Now();var s=Read(selected,now);CultivationRulesV18.Advance(s,now);
        if(action==0){s.Tested=true;message="检测结果："+RootNames[s.Root]+"（结果固定，重新检测不会重抽）";}
        if(action==1){if(!s.Tested||s.Root==0)message="需先检测出灵根";else{s.Method=true;message="传授《纳元吐息法》；由你为该人物提供修行机缘";}}
        if(action==2){if(!s.Tested||s.Root==0||!s.Method)message="检测灵根并传授功法后才能吐纳";else{s.Training=!s.Training;message=s.Training?"开始吐纳，暂停世界不会增长修为":"停止吐纳，经脉负荷随世界时间恢复";}}
        if(action==3)message=CultivationRulesV18.Breakthrough(s);
        if(action==4||action==5)message=Gather(s,action==4,now);
        if(action==6)message=CultivationRulesV18.Craft(s,now);
        if(action==7)message=CultivationRulesV18.TakePill(s);
        Write(selected,s);SyncTrait(selected,s.Layer);
        DiagnosticLog.Write("[XIANXIA-V18] ACTION actor="+Data(selected).id+" code="+action+" layer="+s.Layer+" qi="+s.Qi+" result="+message);
    }
    string Gather(CultivationState s,bool herb,float now){
        if((herb?s.Herbs:s.Stones)>=CultivationRulesV18.MaxStack)return "背包已满";
        int x=Mathf.RoundToInt(selected.current_position.x),y=Mathf.RoundToInt(selected.current_position.y);
        bool found=false;
        for(int dx=-3;dx<=3;dx++)for(int dy=-3;dy<=3;dy++){
            if(dx*dx+dy*dy>9)continue;
            if(x+dx<0||x+dx>=MapBox.width||y+dy<0||y+dy>=MapBox.height)continue;
            var tile=World.world.GetTile(x+dx,y+dy);var b=tile==null?null:tile.building;
            if(b==null||!b.isAlive()||Asset(b)==null)continue;
            string id=Asset(b).id.ToLowerInvariant();
            bool matches=herb?(Asset(b).flora||Asset(b).is_vegetation):(id.Contains("stone")||id.Contains("ore")||id.Contains("metal"));
            if(!matches)continue;found=true;
            string key=herb?"herb_stock":"ore_stock";
            int stock=Int(Data(b),key,-1);float at=Float(Data(b),key+"_time",now);
            if(stock<0){stock=3;at=now;}
            float period=herb?60:240;
            int elapsed=(int)Math.Max(0,(now-at)/period);
            if(elapsed>0){stock=Math.Min(3,stock+elapsed);at+=elapsed*period;}
            if(stock==0)continue;
            Data(b).set(K+key,stock-1);Data(b).set(K+key+"_time",now);
            if(herb)s.Herbs++;else s.Stones++;
            return (herb?"采得灵草1":"采得灵石1")+"，此处余量"+(stock-1)+"；原地资源会随世界时间再生";
        }
        return found?"附近灵性资源已采空，需等待再生":"人物三格内没有"+(herb?"植物":"矿石")+"，移动镜头选取资源附近人物";
    }
    Texture2D Texture(string name){
        Texture2D t;if(textures.TryGetValue(name,out t))return t;
        try{
            string path=Path.Combine(Application.persistentDataPath,"mods/WorldBoxXianxia/"+name);
            if(!File.Exists(path))return null;
            t=new Texture2D(2,2,TextureFormat.RGBA32,false);t.LoadImage(File.ReadAllBytes(path));t.filterMode=FilterMode.Point;
            textures[name]=t;return t;
        }catch(Exception e){DiagnosticLog.Write("[XIANXIA-V18] ART_LOAD_FAILED "+name+" "+e.GetType().Name);return null;}
    }
    void Styles(){
        if(label!=null)return;
        try{font=Font.CreateDynamicFontFromOSFont(new[]{"Noto Sans CJK SC","Droid Sans Fallback","sans-serif"},24);}catch{}
        label=new GUIStyle(GUI.skin.label){fontSize=22,wordWrap=true};
        button=new GUIStyle(GUI.skin.button){fontSize=23,wordWrap=true};
        box=new GUIStyle(GUI.skin.box){fontSize=24};
        if(font!=null){label.font=font;button.font=font;box.font=font;}
    }
    void OnGUI(){
        if(!Config.game_loaded)return;Styles();
        // Shared logical canvas keeps touch targets readable in either orientation.
        Matrix4x4 previous=GUI.matrix;float u=Mathf.Clamp(Math.Min(Screen.width/800f,Screen.height/720f),.65f,2f);
        GUI.matrix=Matrix4x4.Scale(new Vector3(u,u,1));
        float sw=Screen.width/u,sh=Screen.height/u;
        if(GUI.Button(new Rect(12,12,228,58),open?"收起修仙":"万界 · 修仙",button))open=!open;
        if(!open){GUI.matrix=previous;return;}
        float w=Math.Min(sw-20,900),h=Math.Min(sh-20,700),px=(sw-w)/2,py=(sh-h)/2;
        GUI.Box(new Rect(px,py,w,h),"万界仙侠 · 原创修仙与素材",box);
        if(GUI.Button(new Rect(px+10,py+40,220,46),assetsTab?"返回人物修仙":"原创建筑图鉴",button))assetsTab=!assetsTab;
        if(GUI.Button(new Rect(px+w-100,py+40,90,46),"关闭",button))open=false;
        if(assetsTab){
            int page=assetPage%ArtIds.Length;
            var tex=Texture("icons/"+ArtIds[page]+".png");
            if(tex!=null)GUI.DrawTexture(new Rect(px+(w-320)/2,py+98,320,320),tex,ScaleMode.ScaleToFit,true);
            GUI.Label(new Rect(px+24,py+426,w-48,100),ArtNames[page]+" · 原创独立素材 "+(page+1)+"/8\n本页为图鉴，尚未替换地图原版建筑；施工与破损状态仍待制作。",label);
            if(GUI.Button(new Rect(px+24,py+h-90,w-48,60),"下一件原创素材",button))assetPage++;
        }else{
            if(GUI.Button(new Rect(px+12,py+96,(w-36)/2,48),"选取镜头附近人物",button))Pick(false);
            if(GUI.Button(new Rect(px+24+(w-36)/2,py+96,(w-36)/2,48),"寻找有灵根者",button))Pick(true);
            string info="尚未选取人物";
            if(Person(selected)){
                var s=Read(selected,Now());
                info=selected.getName()+" · "+(s.Layer==0?"凡人":"炼气"+s.Layer+"层")+" · 年龄"+selected.getAge()+"\n"+
                    "灵根："+(s.Tested?RootNames[s.Root]:"未检测")+" | 功法："+(s.Method?"纳元吐息法":"未获得")+"\n"+
                    "修为 "+Mathf.FloorToInt(s.Qi)+"/"+CultivationRulesV18.BreakthroughCost(s.Layer)+" | 经脉负荷 "+Mathf.RoundToInt(s.Stress)+"%\n"+
                    "灵草 "+s.Herbs+" | 灵石 "+s.Stones+" | 聚气丹 "+s.Pills+
                    (s.CraftAt>0?"（炼制中）":"")+" | 延寿加成 +"+(s.Layer*4)+"年";
            }
            GUI.Label(new Rect(px+16,py+152,w-32,158),info,label);
            string[] actions={"检测灵根","传授功法","吐纳 / 休息","尝试突破","近身采灵草","近身采灵石","炼丹：3草1石10修为","服用聚气丹"};
            for(int i=0;i<actions.Length;i++){
                float bw=(w-36)/2;
                if(GUI.Button(new Rect(px+12+(i%2)*(bw+12),py+316+(i/2)*55,bw,50),actions[i],button))Action(i);
            }
            int f=(int)(Time.unscaledTime*3)%4;var herb=Texture("vegetation/spirit_grass/mature/iso_0"+f+".png");
            if(herb!=null)GUI.DrawTexture(new Rect(px+14,py+h-134,50,50),herb,ScaleMode.ScaleToFit,true);
            GUI.Label(new Rect(px+70,py+h-134,w-86,78),message,label);
            bool npc=PlayerPrefs.GetInt(K+"npc",1)!=0;
            if(GUI.Button(new Rect(px+14,py+h-51,w-28,42),npc?"NPC自动获得机缘：开（规则驱动）":"NPC自动获得机缘：关",button)){
                PlayerPrefs.SetInt(K+"npc",npc?0:1);PlayerPrefs.Save();
                message="此开关控制新人物获得修行机缘；已传授功法者继续修行";
            }
        }
        GUI.matrix=previous;
    }
    void OnDestroy(){foreach(var t in textures.Values)if(t!=null)UnityEngine.Object.Destroy(t);}
}
}
