package com.xinyanshuo.zhiyin;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.speech.tts.TextToSpeech;
import android.speech.RecognizerIntent;
import android.content.ActivityNotFoundException;
import java.util.ArrayList;
import android.view.Gravity;
import android.view.View;
import android.view.WindowManager;
import android.widget.*;
import org.json.JSONArray;
import org.json.JSONObject;
import java.util.Locale;

public final class HomeActivity extends Activity {
  private final int WHITE=0xFFF8F5EF, MUTED=0xFFC9CBD6, INK=0xFF20263A;
  private LifeEngine life;
  private MemoryStore memory;
  private Neighborhood neighborhood;
  private AiGateway ai;
  private volatile boolean waitingForAI=false;
  private volatile boolean aiPlanPending=false;
  private long lastPlannerRequest=0;
  private HomeWorldView world;
  private TextView activity,banner,stat,tip,inventory,chatReply;
  private EditText chatInput;
  private LinearLayout chatSheet;
  private FrameLayout stageRoot;
  private ProgressBar phaseBar;
  private static final int RECOGNIZE_SPEECH=501;
  private TextToSpeech voice;
  private boolean voiceReady=false,paused=true;
  private Handler handler=new Handler(Looper.getMainLooper());
  private String lastAction="",lastNote="";
  private int lastSequence=-1;
  private int dp(float v){return (int)(getResources().getDisplayMetrics().density*v+.5f);}
  private GradientDrawable back(int clr,int radius){
    GradientDrawable d=new GradientDrawable();d.setColor(clr);d.setCornerRadius(dp(radius));return d;
  }
  private TextView text(String text,int size,int color,boolean bold){
    TextView t=new TextView(this);t.setText(text);t.setTextColor(color);t.setTextSize(size);
    t.setGravity(Gravity.CENTER_VERTICAL);
    if(bold)t.setTypeface(Typeface.DEFAULT,Typeface.BOLD);
    return t;
  }
  private LinearLayout vertical(){LinearLayout v=new LinearLayout(this);v.setOrientation(LinearLayout.VERTICAL);return v;}
  private Button chip(String txt,Runnable callback){
    Button b=new Button(this);b.setAllCaps(false);b.setText(txt);b.setTextSize(13);b.setTextColor(INK);
    b.setBackground(back(0xFFF9EDE1,19));b.setElevation(dp(2));
    b.setOnClickListener(v->callback.run());return b;
  }
  private void toast(String msg){Toast.makeText(this,msg,Toast.LENGTH_SHORT).show();}
  @Override public void onCreate(Bundle state){
    super.onCreate(state);
    getWindow().setStatusBarColor(0xFF282A3D);getWindow().setNavigationBarColor(0xFF3C3C50);
    getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
    life=new LifeEngine(this);memory=new MemoryStore(this);neighborhood=new Neighborhood(this);ai=new AiGateway(this);
    lastPlannerRequest=getSharedPreferences("zhiyin_ai_settings",MODE_PRIVATE).getLong("last_planner_request",0);
    voice=new TextToSpeech(this,s->{if(s==TextToSpeech.SUCCESS){voiceReady=true;voice.setLanguage(Locale.SIMPLIFIED_CHINESE);}});
    FrameLayout screen=new FrameLayout(this);stageRoot=screen;
    world=new HomeWorldView(this,life,this::onSceneTap);
    screen.addView(world,new FrameLayout.LayoutParams(-1,-1));

    // Overlay status is purposefully small: no button grid over the companion.
    LinearLayout hud=vertical();hud.setPadding(dp(14),dp(7),dp(14),dp(8));hud.setBackground(back(0xE5293545,15));
    hud.setElevation(dp(4));
    FrameLayout.LayoutParams top=new FrameLayout.LayoutParams(-1,-2,Gravity.TOP);
    top.setMargins(dp(9),dp(9),dp(9),0);screen.addView(hud,top);
    banner=text("知音   ·   临河巷  •  10.24㎡",17,WHITE,true);hud.addView(banner);
    activity=text("",12,0xFFF5CDB2,false);hud.addView(activity);
    stat=text("",11,MUTED,false);hud.addView(stat);
    inventory=text("",11,0xFFE8DBCC,false);hud.addView(inventory);
    phaseBar=new ProgressBar(this,null,android.R.attr.progressBarStyleHorizontal);
    phaseBar.setMax(100);
    LinearLayout.LayoutParams pp=new LinearLayout.LayoutParams(-1,dp(4));
    pp.setMargins(0,dp(5),0,0);hud.addView(phaseBar,pp);
    hud.setOnClickListener(v->showNeeds());

    LinearLayout bottom=vertical();bottom.setPadding(dp(9),dp(7),dp(9),dp(8));
    bottom.setBackground(back(0xF4F2EBDF,17));bottom.setElevation(dp(5));
    FrameLayout.LayoutParams base=new FrameLayout.LayoutParams(-1,-2,Gravity.BOTTOM);
    base.setMargins(dp(8),0,dp(8),dp(8));screen.addView(bottom,base);
    tip=text("单指拖动镜头  ·  双指缩放  ·  点击家具",11,0xFF706C75,false);
    bottom.addView(tip);
    LinearLayout options=new LinearLayout(this);options.setOrientation(LinearLayout.HORIZONTAL);
    bottom.addView(options);
    Button talk=chip("💬 对话",this::talk);
    LinearLayout.LayoutParams big=new LinearLayout.LayoutParams(0,dp(44),1.35f);
    big.setMargins(0,dp(5),dp(4),0);options.addView(talk,big);
    Button mic=chip("🎙",this::listen);
    LinearLayout.LayoutParams micp=new LinearLayout.LayoutParams(dp(47),dp(44));
    micp.setMargins(0,dp(5),dp(4),0);options.addView(mic,micp);
    Button album=chip("♪ 音乐",()->openStudio("音乐"));
    LinearLayout.LayoutParams sp=new LinearLayout.LayoutParams(0,dp(44),1.05f);
    sp.setMargins(0,dp(5),dp(4),0);options.addView(album,sp);
    Button district=chip("⌖ 地图",this::openDistrict);
    LinearLayout.LayoutParams mapP=new LinearLayout.LayoutParams(0,dp(44),1.05f);
    mapP.setMargins(0,dp(5),dp(4),0);options.addView(district,mapP);
    Button misc=chip("☰",this::showMenu);
    LinearLayout.LayoutParams sm=new LinearLayout.LayoutParams(dp(41),dp(44));
    sm.setMargins(0,dp(5),0,0);options.addView(misc,sm);

    // Non-modal native conversation panel; the room remains visible.
    chatSheet=vertical();chatSheet.setVisibility(View.GONE);
    chatSheet.setPadding(dp(14),dp(11),dp(14),dp(12));
    chatSheet.setBackground(back(0xF7FFF9F0,17));chatSheet.setElevation(dp(11));
    LinearLayout head=new LinearLayout(this);head.setOrientation(LinearLayout.HORIZONTAL);
    chatSheet.addView(head);
    TextView who=text("知音  ·  对话",16,0xFF344457,true);
    head.addView(who,new LinearLayout.LayoutParams(0,dp(30),1));
    Button close=chip("×",()->{chatSheet.setVisibility(View.GONE);});
    head.addView(close,new LinearLayout.LayoutParams(dp(39),dp(33)));
    chatReply=text("在听呢。选择本地模型或者API后，就能真正对话。",13,0xFF506273,false);
    chatReply.setMaxLines(3);chatReply.setPadding(0,dp(4),0,dp(5));chatSheet.addView(chatReply);
    LinearLayout compose=new LinearLayout(this);compose.setOrientation(LinearLayout.HORIZONTAL);chatSheet.addView(compose);
    chatInput=new EditText(this);chatInput.setSingleLine(true);chatInput.setTextSize(14);
    chatInput.setTextColor(0xFF30445A);chatInput.setHint("跟她说点什么…");chatInput.setHintTextColor(0xFF8090A2);
    chatInput.setPadding(dp(10),dp(2),dp(8),dp(2));chatInput.setBackground(back(0xFFE9F0EB,12));
    compose.addView(chatInput,new LinearLayout.LayoutParams(0,dp(45),1));
    Button send=chip("发送",()->{
      String text=chatInput.getText().toString().trim();
      chatInput.setText("");
      sendMessage(text);
    });
    LinearLayout.LayoutParams sendP=new LinearLayout.LayoutParams(dp(64),dp(45));sendP.setMargins(dp(7),0,0,0);compose.addView(send,sendP);
    FrameLayout.LayoutParams chatP=new FrameLayout.LayoutParams(-1,-2,Gravity.BOTTOM);
    chatP.setMargins(dp(10),0,dp(10),dp(97));screen.addView(chatSheet,chatP);

    setContentView(screen);refresh();
  }
  private void refresh(){
    if(life==null)return;
    long now=System.currentTimeMillis();
    life.update(now);
    activity.setText("● "+life.label()+" · "+life.phaseName()+"  "+(life.phase+1)+"/"+LifeEngine.phaseCount(life.action));
    stat.setText("心情 "+Math.round(life.mood)+" · 精力 "+Math.round(life.energy)
      +" · 饱腹 "+Math.round(life.hunger)+" · 关系 "+neighborhood.tier("zhiyin"));
    inventory.setText("存款 ¥"+life.money+"  ·  周租 ¥"+LifeEngine.WEEKLY_RENT+
      "  ·  "+life.daysUntilRent(now)+"天后交租  ·  "+life.employment);
    phaseBar.setProgress((int)life.phaseProgress(now));
    maybePlanDay(now);
    ArrayList<String> updates=life.drainEvents();
    // LifeEngine itself bounds offline simulation; no additional event loss here.
    try{memory.appendLifeEvents(updates);}
    catch(Exception ex){toast("生活记录保存失败："+ex.getMessage());}
    lastAction=life.action;lastSequence=life.sequence;
  }
  private void maybePlanDay(long now){
    if(paused||waitingForAI||aiPlanPending||!ai.plannerEnabled()||!ai.ready())return;
    if(now<lastPlannerRequest || now-lastPlannerRequest<15L*60000L)return;
    if(life.energy<28 || life.hunger<45 || life.hygiene<25)return;
    if("WORK".equals(life.action)||"SLEEP".equals(life.action)||"COOK".equals(life.action)
      ||"EAT".equals(life.action)||"SHOP".equals(life.action)||"CHAT".equals(life.action))return;
    aiPlanPending=true;lastPlannerRequest=now;
    getSharedPreferences("zhiyin_ai_settings",MODE_PRIVATE).edit().putLong("last_planner_request",now).apply();
    String situation=life.summary()+"；当前正在："+life.phaseName()+
      "；本地时间："+new java.text.SimpleDateFormat("HH:mm",java.util.Locale.CHINA).format(new java.util.Date(now));
    ai.proposeAction(situation,(response,error)->runOnUiThread(()->{
      aiPlanPending=false;
      if(isFinishing()||isDestroyed())return;
      if(error!=null){
        try{memory.addEvent("系统","AI生活计划无法生成："+error,"shared","","ai_plan_status");}
        catch(Exception ignored){}
        return;
      }
      try{
        String clean=response.trim();
        // The model is untrusted: only a standalone JSON object may be parsed.
        int left=clean.indexOf('{'),right=clean.lastIndexOf('}');
        if(left<0||right<=left||right-left>1000)throw new IllegalArgumentException("未返回有效JSON");
        JSONObject plan=new JSONObject(clean.substring(left,right+1));
        String choice=plan.optString("action","");
        String reason=plan.optString("reason","");
        if(!life.scheduleAiHobby(choice,reason))throw new IllegalArgumentException("动作不在安全白名单："+choice);
        refresh();toast("AI给知音安排了业余活动："+choice);
      }catch(Exception ex){
        try{memory.addEvent("系统","AI生活计划未通过校验："+ex.getMessage(),"shared","","ai_plan_status");}
        catch(Exception ignored){}
      }
    }));
  }
  private final Runnable ticker=new Runnable(){
    @Override public void run(){
      if(paused)return;
      refresh();handler.postDelayed(this,1000);
    }
  };
  @Override protected void onResume(){
    super.onResume();
    if(life!=null){life=new LifeEngine(this);if(world!=null)world.setLife(life);}
    if(chatReply!=null && !waitingForAI)chatReply.setText("当前："+(AiGateway.MODE_API.equals(ai.mode())?"API联网模式":"手机本地模式")+"。可以开始说话。");
    paused=false;handler.removeCallbacks(ticker);handler.post(ticker);
  }
  @Override protected void onPause(){paused=true;handler.removeCallbacks(ticker);if(life!=null)life.save();super.onPause();}
  @Override protected void onDestroy(){
    paused=true;handler.removeCallbacks(ticker);if(voice!=null){voice.stop();voice.shutdown();}
    if(ai!=null)ai.close();
    if(memory!=null)memory.close();super.onDestroy();
  }
  private void speak(String s){
    if(!voiceReady){toast("系统语音未准备好，文字仍可使用");return;}
    voice.setPitch(1.12f);voice.setSpeechRate(.96f);
    voice.speak(s,TextToSpeech.QUEUE_FLUSH,null,"life_"+System.nanoTime());
  }
  private void onSceneTap(String thing){
    switch(thing){
      case "character":talk();break;
      case "lamp":
        boolean on=world.toggleLamp();
        try{memory.addEvent("玩家",on?"打开出租屋吊灯":"关掉出租屋吊灯","shared","","room");}catch(Exception ignored){}
        toast(on?"她把灯打开了。":"灯熄灭了，房间安静下来。");break;
      case "bed":interact("SLEEP","让她去床边休息一会儿？");break;
      case "wardrobe":interact("DRESS","整理衣柜和换装");break;
      case "books":interact("READ","从书架选本书");break;
      case "sofa":interact("REST","坐下来休息");break;
      case "door":openDistrict();break;
      case "kitchen":interact(life.meals>0?"EAT":life.pantry>0?"COOK":"SHOP","一起准备食物？");break;
      case "plant":interact("WATER","和她一起给植物浇水？");break;
      case "piano":interact("PIANO","邀请她弹一小段钢琴？");break;
      case "desk":interact("READ","让她在书桌前阅读？");break;
      case "window":interact("WINDOW","一起看看窗外？");break;
      case "wash":interact("WASH","让她整理仪容？");break;
      default:toast("可拖动/缩放场景；轻触床、衣柜、钢琴、厨房、书架、绿植或房门。");
    }
  }
  private void interact(String goal,String question){
    String note=life.request(goal);
    try{memory.addEvent("玩家","在出租屋互动："+question,"shared","","interaction");}catch(Exception ignored){}
    refresh();toast(question+" · "+note);
  }
  private void openDistrict(){startActivity(new Intent(this,DistrictActivity.class));}
  private void openAiSettings(){startActivity(new Intent(this,AiSettingsActivity.class));}
  private int indexOf(String action){for(int i=0;i<LifeEngine.ACTIONS.length;i++)if(action.equals(LifeEngine.ACTIONS[i]))return i;return 0;}
  private void openStudio(String part){
    Intent intent=new Intent(this,MainActivity.class);
    String tab=part.contains("音乐")||part.contains("唱歌")?"音乐":
      part.contains("剧本")?"剧场":part.contains("角色")?"角色":"记忆";
    intent.putExtra("section",tab);
    startActivity(intent);
  }
  private void showMenu(){
    String[] items={"🤖 AI 模型 / API 接口","⌖ 社区地图","查看她的生活状态","房租 / 工作 / 账目","生活时间线","今天一起做件事","角色与素材","剧本杀与旁白","音乐与对唱","永久记忆备份","版本说明"};
    new AlertDialog.Builder(this).setTitle("知音 · 场景菜单").setItems(items,(d,which)->{
      switch(which){
        case 0:openAiSettings();break;
        case 1:openDistrict();break;
        case 2:showNeeds();break;
        case 3:showFinances();break;
        case 4:showLifeLog();break;
        case 5:showActivities();break;
        case 6:openStudio("角色");break;
        case 7:openStudio("剧本");break;
        case 8:openStudio("音乐");break;
        case 9:openStudio("记忆");break;
        case 10:new AlertDialog.Builder(this).setTitle("知音 v0.5 · AI模型实验版")
          .setMessage("3.2m×3.2m出租房（10.24㎡），支持拖动和双指缩放、原生2.5D等轴测房间、家具物件交互。"
            +"新增居民独立住处及社交档案，生活资金来自咖啡馆打工，每周需交房租，音乐属于个人爱好。"
            +"此版增加OpenAI兼容API和llama.cpp手机端GGUF推理。首次使用需要在AI设置下载模型或填写API配置；不是预设回复。"
            +"程序生成图形仍是占位美术，后续需使用许可合规的高质量素材包与动画。")
          .setPositiveButton("了解",null).show();break;
      }
    }).show();
  }
  private void showNeeds(){
    String h="生活作息（手机本地时间）\n早晨：洗漱、整理、阅读\n白天：学习、练歌、弹琴、浇花\n晚上：放松、写日记、休息\n夜间：优先睡眠\n\n"+
      "【状态】\n"+life.summary()+"\n\n"+
      "【当前目标】\n"+life.goal+"\n\n"+
      "【当前活动】\n"+life.note+"（已完成"+life.completedTasks+"件生活任务）\n\n"+
      "【生活机制】\n食材→清洗→切菜→烹饪→餐食→进食→碗碟→打扫，每一步独立计时。"
      +"读书增加阅读页数，练歌增加练习次数和熟练度。无人的时候依然会自己安排日常。";
    h+="\n\n【与你的关系】"+neighborhood.tier("zhiyin")+" · 熟悉度"+neighborhood.closeness("zhiyin")+"/100";
    new AlertDialog.Builder(this).setTitle("10.24㎡ · 她的生活").setMessage(h)
      .setPositiveButton("明白",null).setNeutralButton("与她聊天",(d,w)->talk()).show();
  }
  private void showFinances(){
    long now=System.currentTimeMillis();
    String bill="【房屋】临河巷单间，3.2×3.2米（10.24㎡）\\n"+
      "【职业】"+life.employment+"\\n"+
      "【存款】"+life.money+"\\n"+
      "【周租】"+LifeEngine.WEEKLY_RENT+"\\n"+
      "【距离下次交租】"+life.daysUntilRent(now)+"天\\n"+
      "【目前欠租】"+life.rentArrears+"\\n"+
      "【累计已交】"+life.rentPaid+"\\n"+
      "【已完成班次】"+life.workShifts+"\\n"+
      "【食材/餐食】"+life.pantry+"/"+life.meals+"\\n\\n"+
      "收入来自咖啡馆的普通工作。唱歌只是她的爱好，不会凭空增加收入。每天只结算一次有工资的班次。";
    new AlertDialog.Builder(this).setTitle("生活账本")
      .setMessage(bill.replace("\\n","\n"))
      .setPositiveButton("去社区", (d,w)->openDistrict())
      .setNeutralButton("查看日志",(d,w)->showLifeLog())
      .setNegativeButton("关闭",null).show();
  }
  private void showActivities(){
    final String[] names={"一起读书","一起练歌","弹琴","去咖啡馆上班","一起做饭","吃饭","休息","洗漱","整理衣柜","打扫","浇花","写日记","看窗外","伸展运动"};
    final String[] actions={"READ","PRACTICE","PIANO","WORK","COOK","EAT","SLEEP","WASH","DRESS","CLEAN","WATER","WRITE","WINDOW","STRETCH"};
    new AlertDialog.Builder(this).setTitle("邀请知音做一件事")
      .setItems(names,(dialog,which)->interact(actions[which],"邀请她"+names[which]+"？"))
      .setNegativeButton("取消",null).show();
  }
  private void listen(){
    Intent intent=new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
    intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL,RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
    intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE,"zh-CN");
    intent.putExtra(RecognizerIntent.EXTRA_PROMPT,"和知音说句话（设备语音服务可能联网）");
    intent.putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE,true);
    try{startActivityForResult(intent,RECOGNIZE_SPEECH);}
    catch(ActivityNotFoundException ex){toast("设备没有可用语音识别服务，仍可文字聊天。");talk();}
  }
  @Override protected void onActivityResult(int requestCode,int resultCode,Intent data){
    super.onActivityResult(requestCode,resultCode,data);
    if(requestCode==RECOGNIZE_SPEECH&&resultCode==RESULT_OK&&data!=null){
      ArrayList<String> lines=data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS);
      if(lines!=null&&!lines.isEmpty()){talk(lines.get(0));}
    }
  }
  private void showLifeLog(){
    try{
      JSONArray a=memory.search("","导演",60);
      StringBuilder sb=new StringBuilder("最近事件（含你的对话）\n\n");
      for(int i=0;i<a.length();i++){
        JSONObject j=a.getJSONObject(i);
        sb.append(j.optString("role")).append("：").append(j.optString("body")).append("\n\n");
        if(sb.length()>14000)break;
      }
      ScrollView sc=new ScrollView(this);TextView tx=text(sb.toString(),13,INK,false);
      tx.setPadding(dp(18),dp(16),dp(18),dp(16));sc.addView(tx);
      new AlertDialog.Builder(this).setTitle("生活回忆 · 已写入长期记忆").setView(sc)
        .setPositiveButton("关闭",null).show();
    }catch(Exception e){toast("读取历史失败："+e.getMessage());}
  }
  private String demoReply(String user){
    if(user.contains("记得")||user.contains("以前")||user.contains("上次")){
      String key=user.replace("还","").replace("记得","").replace("以前","").replace("上次","").replace("吗","").replace("？","").trim();
      JSONArray matches=memory.search(key,"知音",10);
      for(int i=0;i<matches.length();i++){
        JSONObject j=matches.optJSONObject(i);
        if(j!=null&&!"生活".equals(j.optString("kind"))&&!"life".equals(j.optString("kind"))
          &&!j.optString("body").equals(user)){
          return "我查到了这条历史记录：「"+j.optString("body").substring(0,Math.min(100,j.optString("body").length()))+"」。这是原文回忆。";
        }
      }
      return "我没找到能确认的历史记录，还不能说自己真的记得。";
    }
    if(user.contains("唱")||user.contains("歌"))return "我正想练唱！目前只能打开录音与伴奏工作台，真正的AI唱歌还没有接入。";
    if(user.contains("剧本")||user.contains("故事"))return "我们可以去剧场，用不同的声线演绎你导入的剧本。";
    if(user.contains("饿")||user.contains("做饭")||user.contains("吃饭")){
      String next=life.meals>0?"EAT":life.pantry>0?"COOK":"SHOP";
      life.request(next);return "好，我们去厨房。我会一步步处理食材，准备好才能开饭。";
    }
    if(user.contains("浇花")){life.request("WATER");return "好，植物也需要照料，我们去窗边。";}
    if(user.contains("弹琴")){life.request("PIANO");return "我这就走到钢琴旁边练习。";}
    if(user.contains("练歌")||user.contains("练唱")){life.request("PRACTICE");return "先从呼吸和音阶开始，记录本次练习。";}
    if(user.contains("打扫")){life.request("CLEAN");return "我先整理床铺，然后清扫房间。";}
    if(user.contains("看书")||user.contains("读书")){life.request("READ");return "挑本书安静读一会儿吧。";}
    if(user.contains("休息")){life.request("REST");return "好，坐下来放松一下。";}
    if(user.contains("睡觉")||user.contains("晚安"))return "晚安。我们可以明天接着聊，我会保留今天的聊天记录。";
    return "我听到你说：「"+user.substring(0,Math.min(38,user.length()))+"」。"+
      "这条消息已经保存。现在是规则回复演示；接入真正的大模型后，我才能自然理解和继续讨论。";
  }
  private void sendMessage(String s){
    if(s.isEmpty())return;
    if(waitingForAI){toast("知音还在生成上一条回复，请稍等");return;}
    try{memory.addEvent("玩家",s,"shared","","dialogue");}
    catch(Exception e){toast("消息写入失败："+e.getMessage());return;}
    if(chatSheet!=null)chatSheet.setVisibility(View.VISIBLE);
    chatReply.setText("知音正在"+(AiGateway.MODE_API.equals(ai.mode())?"通过API":"使用手机本地模型")+"思考…");
    waitingForAI=true;
    ai.ask(s,"知音",memory,(answer,error)->runOnUiThread(()->{
      if(isFinishing()||isDestroyed())return;
      waitingForAI=false;
      if(error!=null){
        chatReply.setText("AI推理未成功："+error+"。请打开AI设置检查模型和API。");
        // User original has been saved, no pretend response or fallback.
        return;
      }
      try{
        memory.addEvent("知音",answer,"shared","","ai_reply");
        neighborhood.meet("zhiyin","聊天交流");
        life.note=answer;life.social=LifeEngine.clamp(life.social+4);
        life.save();refresh();
        chatReply.setText(answer);
        if(voiceReady)speak(answer);
      }catch(Exception e){chatReply.setText("回答已生成，但保存失败："+e.getMessage());}
    }));
  }
  private void talk(){talk("");}
  private void talk(String prefill){
    life.request("CHAT");refresh();
    chatSheet.setVisibility(View.VISIBLE);
    if(!ai.installed()&&AiGateway.MODE_LOCAL.equals(ai.mode())){
      chatReply.setText("首次离线聊天，请先安装GGUF模型。打开菜单 → AI模型/API接口。");
    }
    chatInput.setText(prefill);
    if(!prefill.isEmpty())chatInput.setSelection(prefill.length());
  }
  @Override public void onBackPressed(){
    if(chatSheet!=null&&chatSheet.getVisibility()==View.VISIBLE){chatSheet.setVisibility(View.GONE);return;}
    super.onBackPressed();
  }

}
