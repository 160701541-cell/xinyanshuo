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
        static string oneTapStatus="简体中文需使用原版语言管理器；不会修改游戏存档。";
        public static void Draw(float scale,GUIStyle button,GUIStyle label,GUIStyle box)
        {
            if(!Open)return;
            float w=Mathf.Min(Screen.width-16,790f*scale);
            float h=Mathf.Min(Screen.height-16,610f*scale);
            Rect r=new Rect((Screen.width-w)/2f,(Screen.height-h)/2f,w,h);
            GUI.Box(r,OwnLocaleLabelsV25.Get("language_panel","中文操作说明 / 汉化控制台（实验版）"),box);
            if(GUI.Button(new Rect(r.x+w-102f*scale,r.y+11f*scale,90f*scale,42f*scale),OwnLocaleLabelsV25.Get("close","关闭"),button))
                Open=false;

            float margin=10f*scale, gap=6f*scale;
            float x=r.x+margin;
            float quarter=(w-2f*margin-3f*gap)/4f;
            float top=r.y+57f*scale;
            if(GUI.Button(new Rect(x,top,quarter,43f*scale),
                RuntimeChineseOverlayV22.Enabled?OwnLocaleLabelsV25.Get("toggle_chinese_on","实时中文：开"):OwnLocaleLabelsV25.Get("toggle_chinese_off","实时中文：关"),button))
                RuntimeChineseOverlayV22.SetEnabled(!RuntimeChineseOverlayV22.Enabled);
            x+=quarter+gap;
            if(GUI.Button(new Rect(x,top,quarter,43f*scale),OwnLocaleLabelsV25.Get("one_tap_chinese","一键选择简中"),button))
            {
                // The actual user-owned WorldBox APK already indexes many
                // native locales/cz groups. Prefer them FIRST: never
                // pre-register guessed English fallback values that could
                // shadow official Simplified Chinese translations.
                oneTapStatus=NativeLocaleBridgeV23.SwitchToChineseByUserTap();
            }
            x+=quarter+gap;
            if(GUI.Button(new Rect(x,top,quarter,43f*scale),OwnLocaleLabelsV25.Get("register_native_chinese","补齐简中漏译"),button))
                oneTapStatus=NativeLocaleBridgeV23.RegisterActualKeys();
            x+=quarter+gap;
            if(GUI.Button(new Rect(x,top,quarter,43f*scale),OwnLocaleLabelsV25.Get("refresh_chinese","刷新简体中文"),button))
                oneTapStatus=NativeLocaleBridgeV23.ActivateChinese();

            // Five buttons on the second row; original controls retained.
            x=r.x+margin;
            float second=r.y+107f*scale;
            float fifth=(w-2f*margin-4f*gap)/5f;
            if(GUI.Button(new Rect(x,second,fifth,43f*scale),OwnLocaleLabelsV25.Get("import_keypack","导入中文键值包"),button))
                oneTapStatus=ChineseKeyPackV24.ImportPrivatePack();
            x+=fifth+gap;
            if(GUI.Button(new Rect(x,second,fifth,43f*scale),
                UntranslatedMenuAuditV23.Enabled?OwnLocaleLabelsV25.Get("stop_missing_scan","停止漏译采集"):OwnLocaleLabelsV25.Get("start_missing_scan","开启漏译采集"),button))
                UntranslatedMenuAuditV23.SetEnabled(!UntranslatedMenuAuditV23.Enabled);
            x+=fifth+gap;
            if(GUI.Button(new Rect(x,second,fifth,43f*scale),OwnLocaleLabelsV25.Get("export_missing","导出漏译清单"),button))
                UntranslatedMenuAuditV23.ExportLocalReport();
            x+=fifth+gap;
            if(GUI.Button(new Rect(x,second,fifth,43f*scale),OwnLocaleLabelsV25.Get("clear_missing","清空漏译记录"),button))
                UntranslatedMenuAuditV23.Clear();
            x+=fifth+gap;
            if(GUI.Button(new Rect(x,second,fifth,43f*scale),"核验简中",button))
                oneTapStatus=NativeLocaleBridgeV23.VerifyCurrentLocale();

            GUI.Label(new Rect(r.x+margin,r.y+155f*scale,w-2f*margin,47f*scale),
                oneTapStatus,label);
            GUI.Label(new Rect(r.x+margin,r.y+204f*scale,w-2f*margin,42f*scale),
                NativeLocaleBridgeV23.Status+" | 总词条："+ChineseLocalizationV22.DictionarySize,label);
            GUI.Label(new Rect(r.x+margin,r.y+249f*scale,w-2f*margin,44f*scale),
                UntranslatedMenuAuditV23.Status+" [记录 "+UntranslatedMenuAuditV23.Count+" 项]",label);

            const int perPage=3;
            int pages=(Entries.Length+perPage-1)/perPage;
            int first=page*perPage;
            float rowsTop=r.y+298f*scale;
            float available=Mathf.Max(45f,h-385f*scale);
            float rowH=available/perPage;
            for(int i=first;i<Entries.Length&&i<first+perPage;i++)
                GUI.Label(new Rect(r.x+margin,rowsTop+(i-first)*rowH,
                    w-2f*margin,rowH-3f*scale),Entries[i],label);
            if(GUI.Button(new Rect(r.x+margin,r.y+h-64f*scale,118f*scale,46f*scale),OwnLocaleLabelsV25.Get("page_previous","上一页"),button))
                page=(page+pages-1)%pages;
            GUI.Label(new Rect(r.x+148f*scale,r.y+h-58f*scale,130f*scale,35f*scale),
                (page+1)+"/"+pages+" 页",label);
            if(GUI.Button(new Rect(r.x+280f*scale,r.y+h-64f*scale,118f*scale,46f*scale),OwnLocaleLabelsV25.Get("page_next","下一页"),button))
                page=(page+1)%pages;
            GUI.Label(new Rect(r.x+414f*scale,r.y+h-56f*scale,w-425f*scale,35f*scale),
                "未知英文保留原文；真机尚待检验。",label);
        }
    }
}
