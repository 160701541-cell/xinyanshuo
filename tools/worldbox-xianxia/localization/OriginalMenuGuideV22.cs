using UnityEngine;

namespace XianxiaWorldBox
{
    /// <summary>
    /// A readable in-game reference guide while full vanilla locale extraction
    /// is pending. Entries describe concepts; they are NOT a verified list of
    /// exact WorldBox 0.51.4 button labels.
    /// </summary>
    public static class OriginalMenuGuideV22
    {
        public static bool Open;
        static int page;
        static readonly string[] Entries = {
            "世界创建｜创建新地图，选择尺寸与世界生成参数。",
            "地形绘制｜修改土地、海洋、河流、山体和地貌。",
            "生灵放置｜选择人类、动物等单位，再点击地图放置。",
            "自然资源｜向地图添加树木、矿物及其他基础资源。",
            "文明观察｜查看国家、城池、人口、文化与发展情况。",
            "王国详情｜查看国家领土、统治者、关系与冲突。",
            "外交战争｜查看敌对、和平、联盟与战争动态。",
            "单位详情｜选择一个人物，阅读年龄、状态与特质。",
            "时间控制｜暂停、继续以及调整模拟推进速度。",
            "灾害事件｜触发自然灾害、战争环境与世界事件。",
            "世界法则｜调整世界运行的各种规则与限制。",
            "存档管理｜保存、读取已有世界，注意备份。",
            "模组管理｜查看第三方内容，检查依赖与启用状态。",
            "字体中文化｜辅助翻译已识别的英文标签，未知文本保留原文。",
            "王朝皇城｜规划中；目前并未作为真实建筑接入游戏。",
            "天道放置｜规划中；新增修仙单位和物品尚不能直接刷出。",
            "仙界浮岛｜规划中；多层世界尚未实现。",
            "地府幽冥｜规划中；轮回和地下空间尚未实现。"
        };
        public static void Draw(float scale,GUIStyle button,GUIStyle label,GUIStyle box)
        {
            if(!Open)return;
            float w=Mathf.Min(Screen.width-16,790f*scale);
            float h=Mathf.Min(Screen.height-16,600f*scale);
            Rect r=new Rect((Screen.width-w)/2f,(Screen.height-h)/2f,w,h);
            GUI.Box(r,"原版菜单中文说明 / 原生语言键登记（实验版）",box);
            if(GUI.Button(new Rect(r.x+w-108f*scale,r.y+12f*scale,96f*scale,43f*scale),"关闭",button))
                Open=false;
            if(GUI.Button(new Rect(r.x+12f*scale,r.y+60f*scale,180f*scale,44f*scale),
                 RuntimeChineseOverlayV22.Enabled?"实时中文：开":"实时中文：关",button))
                RuntimeChineseOverlayV22.SetEnabled(!RuntimeChineseOverlayV22.Enabled);
            GUI.Label(new Rect(r.x+207f*scale,r.y+65f*scale,w-219f*scale,40f*scale),
                RuntimeChineseOverlayV22.Status,label);
            if(GUI.Button(new Rect(r.x+12f*scale,r.y+112f*scale,185f*scale,44f*scale),
                "登记原版中文",button))
                NativeLocaleBridgeV23.RegisterActualKeys();
            if(GUI.Button(new Rect(r.x+203f*scale,r.y+112f*scale,185f*scale,44f*scale),
                "刷新简体中文",button))
                NativeLocaleBridgeV23.ActivateChinese();
            if(GUI.Button(new Rect(r.x+399f*scale,r.y+112f*scale,154f*scale,44f*scale),
                UntranslatedMenuAuditV23.Enabled?"停止漏译采集":"开启漏译采集",button))
                UntranslatedMenuAuditV23.SetEnabled(!UntranslatedMenuAuditV23.Enabled);
            if(GUI.Button(new Rect(r.x+563f*scale,r.y+112f*scale,148f*scale,44f*scale),
                "导出漏译清单",button))
                UntranslatedMenuAuditV23.ExportLocalReport();
            GUI.Label(new Rect(r.x+12f*scale,r.y+162f*scale,w-24f*scale,46f*scale),
                NativeLocaleBridgeV23.Status,label);
            GUI.Label(new Rect(r.x+12f*scale,r.y+209f*scale,w-24f*scale,43f*scale),
                UntranslatedMenuAuditV23.Status+" [记录 "+UntranslatedMenuAuditV23.Count+" 项]",label);
            const int perPage=3;
            int pages=(Entries.Length+perPage-1)/perPage;
            int first=page*perPage;
            float rowsTop=r.y+263f*scale;
            float available=Mathf.Max(55f,h-354f*scale);
            float rowH=available/perPage;
            for(int i=first;i<Entries.Length&&i<first+perPage;i++)
                GUI.Label(new Rect(r.x+15f*scale,rowsTop+(i-first)*rowH,
                    w-30f*scale,rowH-3f*scale),Entries[i],label);
            if(GUI.Button(new Rect(r.x+15f*scale,r.y+h-66f*scale,125f*scale,46f*scale),"上一页",button))
                page=(page+pages-1)%pages;
            GUI.Label(new Rect(r.x+156f*scale,r.y+h-59f*scale,145f*scale,35f*scale),
                (page+1)+"/"+pages+" 页",label);
            if(GUI.Button(new Rect(r.x+298f*scale,r.y+h-66f*scale,125f*scale,46f*scale),"下一页",button))
                page=(page+1)%pages;
            GUI.Label(new Rect(r.x+435f*scale,r.y+h-57f*scale,w-448f*scale,35f*scale),
                "不支持或未翻译的词条保留原样。",label);
        }
    }
}
