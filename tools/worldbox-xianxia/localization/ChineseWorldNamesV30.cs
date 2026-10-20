using System;
using System.Collections;
using System.Reflection;
namespace XianxiaWorldBox {
    // Renames actual entities through their own setter, never a fake label.
    // Refuses mutation unless original-name persistence is supported by live data.
    public static class ChineseWorldNamesV30 {
        const string Backup="xys_original_name_v30";
        const BindingFlags F=BindingFlags.Public|BindingFlags.NonPublic|BindingFlags.Instance|BindingFlags.DeclaredOnly;
        static readonly string[] Surnames={"陈","林","苏","叶","沈","陆","韩","李","赵","秦","柳","白","顾","楚","萧","唐","宁","许","方","周","王","张","徐","杜","宋","莫","洛","谢","温","江","夏","云"};
        static readonly string[] Given={"云","清","玄","宁","承","昭","明","景","安","远","知","若","灵","长","怀","青","月","星","逸","天","寒","玉","川","山","雪","尘","秋","风","霜","澜","砚","书"};
        static readonly string[] End={"川","尘","舟","衡","宁","渊","霄","澜","歌","生","微","言","行","羽","华","岚","松","竹","棠","真","元","玉","光","辰","心","然","月","青","平","溪","瑶","兰"};
        static readonly string[] Places={"青溪","云陵","苍梧","临渊","玄水","宁川","望舒","归云","玉衡","清河","长宁","天璇","太华","灵溪","苍岚","赤霄","白鹿","寒江","碧落","栖霞","星河","南离","北辰","东华","西陵","紫阳","明州","昭阳","长乐","望海","松阳","青州"};
        static readonly string[] States={"宁","楚","周","齐","燕","秦","越","梁","晋","赵","魏","韩","吴","夏","陈","黎","炎","云","玄","昭","景","安","乾","坤","离","辰","苍","明","承","靖","盛","武"};
        public static Action<string> Report;
        sealed class Cursor { public string Kind; public object Library; public IEnumerator Iterator; public float Next; }
        static readonly Cursor[] Cursors={new Cursor{Kind="人物"},new Cursor{Kind="王朝"},new Cursor{Kind="城池"}};
        static object lastWorld;
        static float nextTick;
        static uint Hash(string text){unchecked{uint h=2166136261;foreach(char c in text){h^=c;h*=16777619;}return h;}}
        public static string Generate(string kind,string id) {
            uint h=Hash(kind+"|"+id);
            if(kind=="王朝")return "大"+States[h%32]+States[(h/32)%32]+"王朝";
            if(kind=="城池")return Places[h%32]+new[]{"城","州","郡","府"}[(h/32)%4];
            return Surnames[h%32]+Given[(h/32)%32]+End[(h/1024)%32];
        }
        public static bool NeedsChinese(string text) {
            if(string.IsNullOrWhiteSpace(text))return false;
            bool latin=false;
            foreach(char c in text){
                if((c>='\u3400'&&c<='\u9fff')||(c>='\uf900'&&c<='\ufaff'))return false;
                if((c>='A'&&c<='Z')||(c>='a'&&c<='z'))latin=true;
            }
            return latin;
        }
        static object Read(object obj,string key) {
            if(obj==null)return null;
            for(Type t=obj.GetType();t!=null;t=t.BaseType){
                var f=t.GetField(key,F);if(f!=null)return f.GetValue(obj);
                var p=t.GetProperty(key,F);
                if(p!=null&&p.CanRead&&p.GetIndexParameters().Length==0)return p.GetValue(obj,null);
            }
            return null;
        }
        static MethodInfo Method(object obj,string name,Type[] args) {
            if(obj==null)return null;
            for(Type t=obj.GetType();t!=null;t=t.BaseType){
                var m=t.GetMethod(name,F,null,args,null);if(m!=null)return m;
            }
            return null;
        }
        public static bool Rename(object entity,string kind) {
            if(entity==null)return false;
            var getName=Method(entity,"getName",Type.EmptyTypes);
            var setName=Method(entity,"setName",new[]{typeof(string)});
            if(getName==null||setName==null)return false;
            string old=getName.Invoke(entity,null) as string;
            if(!NeedsChinese(old))return false;
            object data=Read(entity,"data");if(data==null)return false;
            object id=Read(data,"id");if(id==null)return false;
            // Exact, checked live API. No guessed name field writes.
            var put=Method(data,"set",new[]{typeof(string),typeof(string)});
            var get=Method(data,"get",new[]{typeof(string),typeof(string).MakeByRefType(),typeof(string)});
            if(put==null||get==null)return false;
            object[] saved={Backup,null,""};
            get.Invoke(data,saved);
            if(string.IsNullOrEmpty(saved[1] as string)) {
                put.Invoke(data,new object[]{Backup,old});
                object[] verify={Backup,null,""};get.Invoke(data,verify);
                if(!string.Equals(verify[1] as string,old,StringComparison.Ordinal))return false;
            }
            string name=Generate(kind,Convert.ToString(id,System.Globalization.CultureInfo.InvariantCulture));
            setName.Invoke(entity,new object[]{name});
            return string.Equals(getName.Invoke(entity,null) as string,name,StringComparison.Ordinal);
        }
        public static bool Restore(object entity) {
            if(entity==null)return false;
            object data=Read(entity,"data");
            var get=Method(data,"get",new[]{typeof(string),typeof(string).MakeByRefType(),typeof(string)});
            var put=Method(data,"set",new[]{typeof(string),typeof(string)});
            var setName=Method(entity,"setName",new[]{typeof(string)});
            var getName=Method(entity,"getName",Type.EmptyTypes);
            if(get==null||put==null||setName==null||getName==null)return false;
            object[] args={Backup,null,""};get.Invoke(data,args);
            string old=args[1] as string;if(string.IsNullOrEmpty(old))return false;
            setName.Invoke(entity,new object[]{old});
            if(!string.Equals(getName.Invoke(entity,null) as string,old,StringComparison.Ordinal))return false;
            put.Invoke(data,new object[]{Backup,""});
            return true;
        }
        public static void Tick(object world,float now) {
            if(world==null)return;
            if(!object.ReferenceEquals(world,lastWorld)){
                lastWorld=world;nextTick=0;
                foreach(var c in Cursors){c.Library=null;c.Iterator=null;c.Next=0;}
            }
            if(now<nextTick)return;nextTick=now+1f;
            string[] libraries={"units","kingdoms","cities"};
            for(int i=0;i<Cursors.Length;i++){
                var c=Cursors[i];if(now<c.Next)continue;
                try {
                    object lib=Read(world,libraries[i]);
                    if(lib==null)continue;
                    if(!object.ReferenceEquals(lib,c.Library)){c.Library=lib;c.Iterator=null;}
                    if(c.Iterator==null){
                        var list=Method(lib,"getSimpleList",Type.EmptyTypes);
                        var items=list==null?null:list.Invoke(lib,null) as IEnumerable;
                        if(items==null)continue;
                        c.Iterator=items.GetEnumerator();
                    }
                    int changed=0;
                    for(int n=0;n<64;n++){
                        if(!c.Iterator.MoveNext()){
                            var disposable=c.Iterator as IDisposable;if(disposable!=null)disposable.Dispose();
                            c.Iterator=null;c.Next=now+2f;break;
                        }
                        if(Rename(c.Iterator.Current,c.Kind))changed++;
                    }
                    if(changed>0&&Report!=null)Report("[XIANXIA-NAMES] renamed "+c.Kind+" count="+changed);
                } catch(Exception e){
                    c.Iterator=null;c.Next=now+30f;
                    if(Report!=null)Report("[XIANXIA-NAMES] API_UNAVAILABLE "+c.Kind+" "+e.ToString());
                }
            }
        }
    }
}
