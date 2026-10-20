using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEngine;

namespace XianxiaWorldBox
{
    /// <summary>
    /// Opt-in, local-only review queue of untranslated visible English UI labels.
    /// No background upload, no automatic export, and no scanning user files.
    /// Strings can still contain generated names: review before sharing.
    /// </summary>
    public static class UntranslatedMenuAuditV23
    {
        const int MaxPhrases=160;
        static readonly HashSet<string> Keys=new HashSet<string>(StringComparer.Ordinal);
        static readonly List<string> Missing=new List<string>();
        public static bool Enabled {get;private set;}
        public static int Count {get{return Missing.Count;}}
        public static string Status {get;private set;}="漏译采集：关闭（只在主动开启后于本机收集）。";

        public static void SetEnabled(bool value)
        {
            Enabled=value;
            Status=value?"漏译采集：开启；仅本机内存，不会自动上传或导出。"+
                "可能包含人物名称，导出前请自行检查。":
                "漏译采集：关闭；已采集内容仍只保留在本机内存。";
        }

        static bool LooksLikeEnglishUiLabel(string text)
        {
            if(string.IsNullOrEmpty(text)||text.Length<3||text.Length>64)return false;
            bool hasLetter=false,hasSpace=false;
            int punctuation=0;
            for(int i=0;i<text.Length;i++)
            {
                char c=text[i];
                if(c>='A'&&c<='Z'||c>='a'&&c<='z'){hasLetter=true;continue;}
                if(c==' '){hasSpace=true;continue;}
                if(c=='-'||c=='/'||c=='?'||c=='!'||c==':'||c=='&')
                {
                    punctuation++;
                    if(punctuation>3)return false;
                    continue;
                }
                // Deny usernames, email addresses, URLs, IDs, numeric data,
                // generated chat, code syntax and all non-ASCII by default.
                return false;
            }
            return hasLetter&&(hasSpace||text.Length<=26);
        }

        public static void Observe(string displayedText)
        {
            if(!Enabled||Missing.Count>=MaxPhrases)return;
            if(!LooksLikeEnglishUiLabel(displayedText))return;
            if(ChineseLocalizationV22.Translate(displayedText)!=displayedText)return;
            if(Keys.Add(displayedText))Missing.Add(displayedText);
        }

        public static string ExportLocalReport()
        {
            try
            {
                if(!Enabled)
                {
                    Status="请先主动开启漏译采集；默认不保存任何英文文本。";
                    return Status;
                }
                if(Missing.Count==0)
                {
                    Status="当前没有可导出的疑似漏译英文菜单。";
                    return Status;
                }
                string folder=Path.Combine(Application.persistentDataPath,"XianxiaModStaging");
                Directory.CreateDirectory(folder);
                string dest=Path.Combine(folder,"missing_chinese_ui_v23.txt");
                string temp=dest+".part";
                var text=new StringBuilder();
                text.AppendLine("# WorldBox疑似漏译菜单——本机生成，不是完整原版键表");
                text.AppendLine("# 可能含游戏生成的名字；人工检查后再分享。");
                foreach(string line in Missing)text.AppendLine(line);
                File.WriteAllText(temp,text.ToString(),new UTF8Encoding(false));
                if(File.Exists(dest))File.Delete(dest);
                File.Move(temp,dest);
                Status="已将 "+Missing.Count+" 条疑似漏译写入本机私有目录，不会自动上传。";
                return Status;
            }
            catch(Exception e)
            {
                Status="漏译导出失败："+e.GetType().Name+"，内存记录仍保留。";
                return Status;
            }
        }

        public static void Clear()
        {
            Missing.Clear();Keys.Clear();
            Status="已清除内存中疑似漏译的条目，不会清理其他游戏文件。";
        }
    }
}
