using System;
using System.Collections.Generic;

namespace XianxiaWorldBox
{
    /// <summary>
    /// Exact allowlist of game/MOD dynamic stat labels such as Population: 300.
    /// Translate only the field label and ASCII numeric value, never generated
    /// kingdom/city/person names, free text, code, or other private strings.
    /// </summary>
    public static class ChineseTextTemplatesV24
    {
        static readonly Dictionary<string,string> NumericLabels=
            new Dictionary<string,string>(StringComparer.OrdinalIgnoreCase)
        {
            {"Population","人口"},{"Level","等级"},{"Age","年龄"},
            {"Health","生命"},{"Max Health","最大生命"},{"HP","生命值"},
            {"Mana","法力"},{"MP","法力值"},{"Max Mana","最大法力"},
            {"Experience","经验"},{"XP","经验"},{"Gold","金币"},
            {"Food","粮食"},{"Buildings","建筑"},{"Cities","城市"},
            {"Villages","村庄"},{"Units","单位"},{"Armies","军队"},
            {"Wars","战争"},{"Kills","击杀"},{"Deaths","死亡"},
            {"Attack","攻击"},{"Defense","防御"},{"Damage","伤害"},
            {"Speed","速度"},{"Move Speed","移动速度"},
            {"Armor","护甲"},{"Dodge","闪避"},
            {"Loyalty","忠诚度"},{"Happiness","幸福度"},
            {"Morale","士气"},{"Wealth","财富"},{"Income","收入"},
            {"Expenses","支出"},{"Capacity","容量"},{"Stock","库存"},
            {"Quantity","数量"},{"Trade","贸易"},{"Tax","税收"},
            {"Mods","模组"},{"Active Mods","已启用模组"},
            {"Installed Mods","已安装模组"},{"Spirit Stones","灵石"},
            {"Qi","灵气"},{"Cultivation","修为"},{"FPS","帧率"},
            {"Frame Rate","帧率"},{"Years","年数"},{"Days","天数"}
        };

        static bool IsSafeNumberOrUnit(string value)
        {
            if(string.IsNullOrEmpty(value)||value.Length>35)return false;
            bool digit=false;
            for(int i=0;i<value.Length;i++)
            {
                char c=value[i];
                if(c>='0'&&c<='9'){digit=true;continue;}
                if(c==' '||c=='.'||c==','||c=='/'||c=='%'||
                    c=='-'||c=='+'||c=='×'||c=='x'||c=='s'||
                    c=='m'||c=='H'||c=='z'||c=='K'||c=='M'||
                    c=='k'||c=='∞')continue;
                return false;
            }
            return digit;
        }
        public static string Translate(string source)
        {
            if(string.IsNullOrEmpty(source)||source.Length>90)return source;
            int colon=source.IndexOf(':');
            if(colon<0)colon=source.IndexOf('：');
            if(colon<1)return source;
            string key=source.Substring(0,colon).Trim();
            string val=source.Substring(colon+1).Trim();
            string translated;
            if(!NumericLabels.TryGetValue(key,out translated)||
                !IsSafeNumberOrUnit(val))
                return source;
            return translated+"："+val;
        }
    }
}
