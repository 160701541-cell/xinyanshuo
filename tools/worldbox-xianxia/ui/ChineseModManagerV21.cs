using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

// WorldBox-only experimental MOD. Never touches original Canglan game.
// This UI deliberately does not claim Android SAF picker or NML installation
// is ready; only displays already staged files in a dedicated private folder.
namespace XianxiaWorldBox
{
    public static class ChineseModManagerV21
    {
        const int MaxEntries=48;
        static readonly List<string> Names=new List<string>();
        public static bool Open;
        public static string Status="模组管理器：只读预览；暂存文件尚未安装或启用；手机批量选择与安装尚未接入。";
        static string dictionaryStatus="内置中文词库已就绪。";
        public static string Folder
        {
            get {return Path.Combine(Application.persistentDataPath,"XianxiaModStaging");}
        }
        public static void Refresh()
        {
            Names.Clear();
            try {
                if(!Directory.Exists(Folder)) {
                    Status="暂存目录为空；安卓文件多选与自动安装功能仍待接入。";
                    return;
                }
                string[] directories=Directory.GetDirectories(Folder);
                Array.Sort(directories,StringComparer.OrdinalIgnoreCase);
                int limit=Math.Min(MaxEntries,directories.Length);
                for(int i=0;i<limit;i++)Names.Add(Path.GetFileName(directories[i]));
                Status="已找到 "+directories.Length+" 个暂存目录；未执行安装或启用。";
            } catch(Exception e) {
                Status="无法读取暂存目录："+e.GetType().Name;
                Debug.LogWarning("[XIANXIA-V21] MOD_SCAN_FAILED "+e.GetType().Name);
            }
        }
        public static void Draw(float scale,GUIStyle button,GUIStyle label,GUIStyle box)
        {
            if(!Open)return;
            float w=Mathf.Min(Screen.width-24,670*scale);
            float h=Mathf.Min(Screen.height-24,560*scale);
            Rect panel=new Rect((Screen.width-w)/2,(Screen.height-h)/2,w,h);
            GUI.Box(panel,OwnLocaleLabelsV25.Get("mod_manager","中文模组管理器")+"（实验版）",box);
            if(GUI.Button(new Rect(panel.x+w-115*scale,panel.y+12*scale,100*scale,45*scale),OwnLocaleLabelsV25.Get("close","关闭"),button))
                Open=false;
            if(GUI.Button(new Rect(panel.x+200*scale,panel.y+65*scale,190*scale,48*scale),OwnLocaleLabelsV25.Get("mod_keypack","载入模组中文词库"),button))
                dictionaryStatus=ChineseLocalizationV22.LoadUserTranslations();
            if(GUI.Button(new Rect(panel.x+15*scale,panel.y+65*scale,170*scale,48*scale),OwnLocaleLabelsV25.Get("mod_reload","刷新暂存列表"),button))
                Refresh();
            GUI.Label(new Rect(panel.x+15*scale,panel.y+120*scale,w-30*scale,85*scale),
                Status+"\n"+dictionaryStatus+"（词条："+ChineseLocalizationV22.DictionarySize+"）",label);
            int maxRows=Math.Min(Names.Count,6);
            for(int i=0;i<maxRows;i++)
                GUI.Label(new Rect(panel.x+20*scale,panel.y+(213+i*48)*scale,w-40*scale,42*scale),
                    (i+1)+". "+Names[i]+"  [仅暂存，兼容性未知]",label);
            GUI.Label(new Rect(panel.x+15*scale,panel.y+h-47*scale,w-30*scale,40*scale),
                "下一阶段：安卓系统文件多选、解压、依赖检查、启停和回滚。",label);
        }
    }
}
