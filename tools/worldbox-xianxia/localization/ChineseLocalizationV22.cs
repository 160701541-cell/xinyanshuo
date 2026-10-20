using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

// Nonofficial WorldBox 0.51.4 third-party MOD. Chinese strings are opt-in.
// This never patches another MOD's assemblies or edits original game assets.
namespace XianxiaWorldBox
{
    public static class ChineseLocalizationV22
    {
        static readonly Dictionary<string,string> Terms = new Dictionary<string,string>(StringComparer.OrdinalIgnoreCase) {
            {"World","世界"},{"Kingdom","王国"},{"Kingdoms","王国列表"},
            {"Village","村庄"},{"Villages","村庄列表"},{"City","城市"},
            {"Capital","都城"},{"King","国王"},{"Queen","女王"},
            {"Army","军队"},{"War","战争"},{"Peace","和平"},
            {"Alliance","联盟"},{"Diplomacy","外交"},{"Population","人口"},
            {"Culture","文化"},{"Religion","信仰"},{"Human","人类"},
            {"Elf","灵族"},{"Dwarf","山民"},{"Orc","蛮族"},
            {"Animals","动物"},{"Traits","特质"},{"Level","等级"},
            {"Age","年龄"},{"Health","生命"},{"Inventory","背包"},
            {"Create World","创建世界"},{"Save","保存"},{"Load","读取"},
            {"Settings","设置"},{"Mods","模组"},{"Mod Manager","模组管理器"},
            {"Import Mods","批量导入模组"},{"Dependencies","依赖"},
            {"Conflicts","冲突"},{"Enable","启用"},{"Disable","禁用"},
            {"Cultivation","修炼"},{"Spirit Stones","灵石"},
            {"Sect","宗门"},{"Formation","阵法"},{"Attack","攻击"},
            {"Defense","防御"},{"Speed","速度"},{"Damage","伤害"},
            {"Food","食物"},{"Gold","金币"},{"Resources","资源"},
            {"Buildings","建筑"},{"Construction","建造"},
            {"Technology","科技"},{"Research","研究"},{"Trade","贸易"},
            {"Rebellion","叛乱"},{"Revolution","革命"},{"Age of Hope","希望纪元"},
            {"Age of Chaos","混沌纪元"},{"Age of Sun","太阳纪元"},
            {"Age of Dark","黑暗纪元"},{"Age of Tears","泪水纪元"},
            {"Age of Moon","月亮纪元"},{"Age of Wonders","奇迹纪元"},
            {"Age of Ice","冰雪纪元"},{"Age of Ash","灰烬纪元"},
            {"Age of Despair","绝望纪元"},{"Age of Madness","疯狂纪元"},
            {"Age of Death","死亡纪元"},{"Age of Order","秩序纪元"},
            {"Age of Magic","魔法纪元"},{"Age of Ruin","毁灭纪元"},
            {"Pause","暂停"},{"Resume","继续"},{"Exit","退出"},
            {"Back","返回"},{"Confirm","确认"},{"Cancel","取消"},
            {"Yes","是"},{"No","否"},{"Close","关闭"},{"Open","打开"},
            {"Name","名称"},{"Description","说明"},{"Version","版本"},
            {"Author","作者"},{"Installed","已安装"},{"Update","更新"},
            {"Download","下载"},{"Install","安装"},{"Uninstall","卸载"},
            {"Compatible","兼容"},{"Incompatible","不兼容"},
            {"Missing Dependencies","缺少依赖"},{"Conflict Detected","检测到冲突"},
            {"Unknown Compatibility","兼容性未知"},{"Loading","正在加载"},
            {"Error","错误"},{"Warning","警告"},{"Success","成功"},
            {"Search","搜索"},{"Filter","筛选"},{"Sort","排序"},
            {"Next","下一页"},{"Previous","上一页"},{"Start","开始"},
            {"Stop","停止"},{"Language","语言"},{"Chinese","中文"},
            {"English","英文"},{"Mod Settings","模组设置"},
            {"Mod List","模组列表"},{"Mod Details","模组详情"},
            {"Enabled","已启用"},{"Disabled","已禁用"},
            {"Restart Required","需要重启"},{"Failed to load","加载失败"}
        };
        static readonly Dictionary<string,string> UserTerms=new Dictionary<string,string>(StringComparer.OrdinalIgnoreCase);
        public static bool Enabled = true;
        public static int DictionarySize { get {return Terms.Count+UserTerms.Count;} }
        public static string Translate(string original)
        {
            if(!Enabled||string.IsNullOrEmpty(original))return original;
            string translated;
            if(UserTerms.TryGetValue(original,out translated))return translated;
            return Terms.TryGetValue(original,out translated)?translated:original;
        }
        public static string LoadUserTranslations()
        {
            try {
                string file=Path.Combine(Application.persistentDataPath,"XianxiaModStaging","zh_cn_overrides.txt");
                if(!File.Exists(file))return "未找到用户中文覆盖词库，使用内置词库。";
                int loaded=0;
                foreach(string line in File.ReadAllLines(file)){
                    if(loaded>=2000)break;
                    if(string.IsNullOrWhiteSpace(line)||line.StartsWith("#"))continue;
                    int split=line.IndexOf('=');
                    if(split<=0||split>=line.Length-1)continue;
                    string key=line.Substring(0,split).Trim();
                    string value=line.Substring(split+1).Trim();
                    if(key.Length>0&&key.Length<=180&&value.Length>0&&value.Length<=500){
                        UserTerms[key]=value;loaded++;
                    }
                }
                return "已载入 "+loaded+" 条自定义中文词条（仅精确匹配）。";
            }catch(Exception e){return "中文词库读取失败："+e.GetType().Name;}
        }
    }
}
