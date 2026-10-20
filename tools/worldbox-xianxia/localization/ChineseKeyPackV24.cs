using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using UnityEngine;

namespace XianxiaWorldBox
{
    /// <summary>
    /// Import per-key Chinese translations from a privately owned, user editable
    /// UTF-8 .txt file. Actual WorldBox/NML key, not just visible English words.
    /// This is an import adapter, NOT a distributed third-party translation pack.
    /// </summary>
    public static class ChineseKeyPackV24
    {
        const long MaxBytes=512*1024;
        const int MaxEntries=4000;
        static readonly Dictionary<string,string> Parsed=new Dictionary<string,string>(StringComparer.Ordinal);
        public static int KeyCount {get{return Parsed.Count;}}
        public static string Status {get;private set;}="未导入按键名匹配的中文翻译包。";
        public static string PackPath
        {
            get{return Path.Combine(Application.persistentDataPath,
                "XianxiaModStaging","zh_cn_keymap_v24.txt");}
        }

        static bool IsValidKey(string key)
        {
            if(string.IsNullOrEmpty(key)||key.Length>160)return false;
            foreach(char c in key)
                if(!((c>='A'&&c<='Z')||(c>='a'&&c<='z')||
                      (c>='0'&&c<='9')||c=='_'||c=='-'||c=='.'||
                      c==':'||c==' '||c=='/'))
                    return false;
            return true;
        }
        static bool IsValidTranslation(string value)
        {
            if(string.IsNullOrEmpty(value)||value.Length>380)return false;
            foreach(char c in value)
                if(c=='\0'||(char.IsControl(c)&&c!='\n'&&c!='\t'))
                    return false;
            return true;
        }

        public static string ImportPrivatePack()
        {
            try
            {
                var file=new FileInfo(PackPath);
                if(!file.Exists)
                {
                    Status="未找到专用中文键值包："+file.Name+
                        "；已内置基础菜单翻译，不需要你手动操作。";
                    return Status;
                }
                if(file.Length>MaxBytes)
                {
                    Status="翻译包超过512KB安全上限；拒绝导入。";
                    return Status;
                }
                var candidate=new Dictionary<string,string>(StringComparer.Ordinal);
                using(var reader=new StreamReader(file.FullName))
                {
                    string line;
                    int count=0;
                    while((line=reader.ReadLine())!=null)
                    {
                        if(++count>12000)
                        {
                            Status="翻译文件行数超过上限；拒绝导入。";
                            return Status;
                        }
                        line=line.Trim();
                        if(line.Length==0||line.StartsWith("#"))continue;
                        int i=line.IndexOf('=');
                        if(i<1||i==line.Length-1)
                        {
                            Status="翻译包第"+count+"行不是原版键=中文格式；整包拒绝。";
                            return Status;
                        }
                        string key=line.Substring(0,i).Trim();
                        string value=line.Substring(i+1).Trim();
                        if(!IsValidKey(key)||!IsValidTranslation(value))
                        {
                            Status="翻译包第"+count+"行包含非法键或过长/不安全文本；整包拒绝。";
                            return Status;
                        }
                        if(candidate.ContainsKey(key))
                        {
                            Status="翻译包存在重复键 "+key+"；整包拒绝以免冲突。";
                            return Status;
                        }
                        if(candidate.Count>=MaxEntries)
                        {
                            Status="翻译包超过4000条安全上限；整包拒绝。";
                            return Status;
                        }
                        candidate.Add(key,value);
                    }
                }
                if(candidate.Count==0)
                {
                    Status="翻译包没有有效条目；未执行任何变更。";
                    return Status;
                }
                string result=NativeLocaleBridgeV23.RegisterExplicitKeys(candidate);
                if(!NativeLocaleBridgeV23.LastPackOk)
                {
                    Status=result;
                    return Status;
                }
                Parsed.Clear();
                foreach(var pair in candidate)Parsed[pair.Key]=pair.Value;
                Status="载入翻译包 "+candidate.Count+" 条；"+result;
                return Status;
            }
            catch(Exception e)
            {
                Status="翻译文件读取失败："+e.GetType().Name+"；保持原版正常运行。";
                return Status;
            }
        }
    }
}
