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
  private HomeWorldView world;
  private TextView activity,banner,stat,tip,inventory;
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
    life=new LifeEngine(this);memory=new MemoryStore(this);
    voice=new TextToSpeech(this,s->{if(s==TextToSpeech.SUCCESS){voiceReady=true;voice.setLanguage(Locale.SIMPLIFIED_CHINESE);}});
    FrameLayout screen=new FrameLayout(this);
    world=new HomeWorldView(this,life,this::onSceneTap);
    screen.addView(world,new FrameLayout.LayoutParams(-1,-1));

    // Overlay status is purposefully small: no button grid over the companion.
    LinearLayout hud=vertical();hud.setPadding(dp(16),dp(9),dp(16),dp(11));hud.setBackground(back(0xDD1A1D31,18));
    FrameLayout.LayoutParams top=new FrameLayout.LayoutParams(-1,-2,Gravity.TOP);
    top.setMargins(dp(12),dp(14),dp(12),0);screen.addView(hud,top);
    banner=text("知音  ·  她的日常",21,WHITE,true);hud.addView(banner);
    activity=text("",13,0xFFF5CDB2,false);hud.addView(activity);
    stat=text("",12,MUTED,false);hud.addView(stat);
    inventory=text("",11,0xFFE8DBCC,false);hud.addView(inventory);
    phaseBar=new ProgressBar(this,null,android.R.attr.progressBarStyleHorizontal);
    phaseBar.setMax(100);
    LinearLayout.LayoutParams pp=new LinearLayout.LayoutParams(-1,dp(4));
    pp.setMargins(0,dp(7),0,0);hud.addView(phaseBar,pp);
    hud.setOnClickListener(v->showNeeds());

    LinearLayout bottom=vertical();bottom.setPadding(dp(14),dp(12),dp(14),dp(13));
    bottom.setBackground(back(0xF5EFE4D9,22));
    FrameLayout.LayoutParams base=new FrameLayout.LayoutParams(-1,-2,Gravity.BOTTOM);
    base.setMargins(dp(11),0,dp(11),dp(13));screen.addView(bottom,base);
    tip=text("轻触她聊天  ·  点床、钢琴、书桌等互动",12,0xFF756A70,false);
    bottom.addView(tip);
    LinearLayout options=new LinearLayout(this);options.setOrientation(LinearLayout.HORIZONTAL);
    bottom.addView(options);
    Button talk=chip("💬  对话",this::talk);
    LinearLayout.LayoutParams big=new LinearLayout.LayoutParams(0,dp(51),1.5f);
    big.setMargins(0,dp(8),dp(5),0);options.addView(talk,big);
    Button mic=chip("🎙",this::listen);
    LinearLayout.LayoutParams micp=new LinearLayout.LayoutParams(dp(57),dp(51));
    micp.setMargins(0,dp(8),dp(5),0);options.addView(mic,micp);
    Button album=chip("🎵 音乐",()->openStudio("音乐"));
    LinearLayout.LayoutParams sp=new LinearLayout.LayoutParams(0,dp(51),1);
    sp.setMargins(0,dp(8),dp(6),0);options.addView(album,sp);
    Button misc=chip("☰",this::showMenu);
    LinearLayout.LayoutParams sm=new LinearLayout.LayoutParams(dp(55),dp(51));sm.setMargins(0,dp(8),0,0);options.addView(misc,sm);

    setContentView(screen);refresh();
  }
  private void refresh(){
    if(life==null)return;
    long now=System.currentTimeMillis();
    life.update(now);
    activity.setText("● "+life.label()+" · "+life.phaseName()+"（"+(life.phase+1)+"/"+LifeEngine.phaseCount(life.action)+"）");
    stat.setText("心情 "+Math.round(life.mood)+" · 精力 "+Math.round(life.energy)
      +" · 饱腹 "+Math.round(life.hunger)+" · 音乐 "+Math.round(life.skill));
    inventory.setText("食材 "+life.pantry+" · 餐食 "+life.meals+" · 脏碗 "+life.dirtyDishes
      +" · 阅读 "+life.readPages+"页 · 练歌 "+life.completedSongs+"次");
    phaseBar.setProgress((int)life.phaseProgress(now));
    ArrayList<String> updates=life.drainEvents();
    // Persist completed steps and their consequences; cap massive offline imports
    // and write one explicit summary instead of fabricating an unseen timeline.
    int written=0;
    for(String update:updates){
      if(written>=100)break;
      try{memory.addEvent("知音",update,"shared","","life");written++;}
      catch(Exception ex){break;}
    }
    if(updates.size()>100){
      try{memory.addEvent("系统","离线恢复中有"+(updates.size()-100)+"条中间模拟步骤未展开存入对话历史。","shared","","life_meta");}
      catch(Exception ignored){}
    }
    lastAction=life.action;lastSequence=life.sequence;
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
    paused=false;handler.removeCallbacks(ticker);handler.post(ticker);
  }
  @Override protected void onPause(){paused=true;handler.removeCallbacks(ticker);if(life!=null)life.save();super.onPause();}
  @Override protected void onDestroy(){
    paused=true;handler.removeCallbacks(ticker);if(voice!=null){voice.stop();voice.shutdown();}
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
      case "bed":interact("SLEEP","让她去床边休息一会儿？");break;
      case "kitchen":interact(life.meals>0?"EAT":life.pantry>0?"COOK":"SHOP","一起准备食物？");break;
      case "plant":interact("WATER","和她一起给植物浇水？");break;
      case "piano":interact("PIANO","邀请她弹一小段钢琴？");break;
      case "desk":interact("READ","让她在书桌前阅读？");break;
      case "window":interact("WINDOW","一起看看窗外？");break;
      case "wash":interact("WASH","让她整理仪容？");break;
      default:toast("轻触她，或点床铺、钢琴、书桌等物品。");
    }
  }
  private void interact(String goal,String question){
    new AlertDialog.Builder(this).setTitle(question)
      .setMessage("你可以提议活动，但她也会在无人操作时依据精力、饥饿和作息自行安排。")
      .setPositiveButton("好呀",(d,w)->{String note=life.request(goal);
        try{memory.addEvent("玩家","邀请知音："+LifeEngine.LABELS[indexOf(goal)],"shared","","interaction");}catch(Exception ignored){}
        refresh();speak(note);})
      .setNegativeButton("暂时不用",null).show();
  }
  private int indexOf(String action){for(int i=0;i<LifeEngine.ACTIONS.length;i++)if(action.equals(LifeEngine.ACTIONS[i]))return i;return 0;}
  private void openStudio(String part){
    Intent intent=new Intent(this,MainActivity.class);startActivity(intent);
    toast("已进入工具工作台，可切换到「"+part+"」标签。");
  }
  private void showMenu(){
    String[] items={"查看她的生活状态","查看生活时间线","今天一起做件事","角色 / 素材 / 声线","剧本杀 / 旁白","唱歌 / A-B对唱","长期记忆管理","生活模拟说明"};
    new AlertDialog.Builder(this).setTitle("知音 · 场景菜单").setItems(items,(d,which)->{
      switch(which){
        case 0:showNeeds();break;
        case 1:showLifeLog();break;
        case 2:showActivities();break;
        case 3:case 4:case 5:case 6:openStudio(items[which]);break;
        case 7:new AlertDialog.Builder(this).setTitle("当前版本行为说明")
          .setMessage("v0.3 实装：多阶段生活任务、真实阶段计时、食材与餐食消耗、收拾餐具、睡眠和音乐训练结果、场景位置移动、完整事件日志。"
            +"关闭后按上限回放离线时间，避免产生无限重复事件。"
            +"角色形象仍为临时程序绘制；这是一套有限规则驱动模拟，不是接入大模型的自主认知。"
            +"语音识别由安卓系统提供，可能需要安装语音服务，也可能通过网络处理。")
          .setPositiveButton("了解",null).show();break;
      }
    }).show();
  }
  private void showNeeds(){
    String h="每日作息（手机本地时间）\n早晨：洗漱、整理、阅读\n白天：学习、练歌、弹琴、浇花\n晚上：放松、写日记、休息\n夜间：优先睡眠\n\n"+
      "【状态】\n"+life.summary()+"\n\n"+
      "【当前目标】\n"+life.goal+"\n\n"+
      "【当前活动】\n"+life.note+"（已完成"+life.completedTasks+"件生活任务）\n\n"+
      "【生活机制】\n食材→清洗→切菜→烹饪→餐食→进食→碗碟→打扫，每一步独立计时。"
      +"读书增加阅读页数，练歌增加练习次数和熟练度。无人的时候依然会自己安排日常。";
    new AlertDialog.Builder(this).setTitle("知音的生活").setMessage(h)
      .setPositiveButton("明白",null).setNeutralButton("与她聊天",(d,w)->talk()).show();
  }
  private void showActivities(){
    final String[] names={"一起读书","一起练歌","弹琴","一起做饭","吃饭","休息","洗漱","打扫","浇花","写日记","看窗外","伸展运动"};
    final String[] actions={"READ","PRACTICE","PIANO","COOK","EAT","SLEEP","WASH","CLEAN","WATER","WRITE","WINDOW","STRETCH"};
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
    try{
      memory.addEvent("玩家",s,"shared","","dialogue");
      String reply=demoReply(s);
      memory.addEvent("知音",reply,"shared","","demo_reply");
      life.note=reply;life.social=LifeEngine.clamp(life.social+4);
      life.save();refresh();
      new AlertDialog.Builder(this).setTitle("知音 · 规则聊天演示")
        .setMessage(reply).setNegativeButton("关闭",null)
        .setNeutralButton("朗读",(d2,w2)->speak(reply))
        .setPositiveButton("继续聊",(d2,w2)->talk()).show();
    }catch(Exception e){toast("消息保存失败："+e.getMessage());}
  }
  private void talk(){talk("");}
  private void talk(String prefill){
    life.request("CHAT");refresh();
    LinearLayout wrapper=vertical();wrapper.setPadding(dp(20),dp(8),dp(20),dp(5));
    TextView introduction=text("你可以在这里直接跟知音说话。对话完整保存在本地；当前还没有接入AI对话模型。",13,0xFF65657A,false);
    wrapper.addView(introduction);
    EditText input=new EditText(this);input.setHint("想对她说些什么…");
    input.setMinLines(2);input.setMaxLines(5);
    input.setText(prefill);
    if(!prefill.isEmpty())input.setSelection(prefill.length());
    wrapper.addView(input);
    new AlertDialog.Builder(this).setTitle("💬  与知音聊天").setView(wrapper)
      .setPositiveButton("发送",(d,w)->sendMessage(input.getText().toString().trim()))
      .setNeutralButton("用语音说",(d,w)->listen())
      .setNegativeButton("取消",null).show();
  }
}
