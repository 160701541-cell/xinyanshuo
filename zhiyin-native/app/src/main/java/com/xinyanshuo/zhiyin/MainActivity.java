package com.xinyanshuo.zhiyin;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.net.Uri;
import android.os.Bundle;
import android.os.Build;
import android.os.Environment;
import android.speech.tts.TextToSpeech;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.*;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.*;

public final class MainActivity extends Activity {
  private static final int BACKUP_SAVE=110, BACKUP_OPEN=111, SCRIPT_OPEN=112, B_OPEN=113, BEAT_OPEN=114, MIC_REQUEST=115;
  private static final int BG=0xFF0F1120, PANEL=0xFF1A1E30, TEXT=0xFFF0F2FA, MUTED=0xFFADB3CD, ACCENT=0xFF8F85FE, OUTLINE=0xFF303751;
  private MemoryStore store;
  private LinearLayout root,content,nav;
  private TextToSpeech tts; private boolean ttsReady=false;
  private String activeRole="知音",observer="导演";
  private String section="记忆"; private String stageScript="", stageTitle=""; private int stageLine=0;
  private MediaRecorder recorder; private File clipA; private Uri clipB,beatUri;
  private MediaPlayer voicePlayer,beatPlayer; private boolean recording=false;

  @Override public void onCreate(Bundle b){
    super.onCreate(b);
    getWindow().setStatusBarColor(BG);getWindow().setNavigationBarColor(BG);
    getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
    store=new MemoryStore(this);
    tts=new TextToSpeech(this,status->{ if(status==TextToSpeech.SUCCESS){ttsReady=true;tts.setLanguage(Locale.SIMPLIFIED_CHINESE);} });
    show("记忆");
  }
  private int dp(float n){return (int)(getResources().getDisplayMetrics().density*n+0.5f);}
  private GradientDrawable background(int color,int radius){
    GradientDrawable gd=new GradientDrawable();gd.setColor(color);gd.setCornerRadius(dp(radius));return gd;
  }
  private TextView text(String s,int size,int color,boolean bold){
    TextView v=new TextView(this);v.setText(s);v.setTextSize(size);v.setTextColor(color);
    if(bold)v.setTypeface(Typeface.DEFAULT,Typeface.BOLD);
    v.setPadding(0,dp(3),0,dp(3));v.setTextIsSelectable(true);return v;
  }
  private LinearLayout col(){
    LinearLayout v=new LinearLayout(this);v.setOrientation(LinearLayout.VERTICAL);return v;
  }
  private void addSpace(LinearLayout v,int height){View w=new View(this);v.addView(w,new LinearLayout.LayoutParams(1,dp(height)));}
  private void addText(LinearLayout dst,String title,String subtitle){
    dst.addView(text(title,21,TEXT,true));if(subtitle!=null){dst.addView(text(subtitle,13,MUTED,false));addSpace(dst,10);}
  }
  private LinearLayout card(LinearLayout into){
    LinearLayout c=col();c.setPadding(dp(15),dp(14),dp(15),dp(14));c.setBackground(background(PANEL,16));
    LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-1,-2);lp.setMargins(0,0,0,dp(12));into.addView(c,lp);return c;
  }
  private EditText field(LinearLayout into,String hint,boolean multi){
    EditText e=new EditText(this);e.setHint(hint);e.setTextColor(TEXT);e.setHintTextColor(MUTED);
    e.setTextSize(15);e.setSingleLine(!multi);e.setBackground(background(BG,9));
    e.setPadding(dp(12),dp(10),dp(12),dp(10));if(multi){e.setMinLines(3);e.setMaxLines(9);e.setGravity(Gravity.TOP);}
    LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,-2);p.setMargins(0,dp(8),0,dp(8));into.addView(e,p);return e;
  }
  private Button button(LinearLayout into,String label,Runnable action){
    Button b=new Button(this);b.setAllCaps(false);b.setText(label);b.setTextSize(13);b.setTextColor(TEXT);
    b.setBackground(background(OUTLINE,11));
    LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,dp(48));p.setMargins(0,dp(4),0,dp(5));into.addView(b,p);
    b.setOnClickListener(v->{try{action.run();}catch(Exception ex){notice("操作失败："+ex.getMessage());}});return b;
  }
  private Button smallButton(LinearLayout row,String label,Runnable action){
    Button b=new Button(this);b.setAllCaps(false);b.setText(label);b.setTextSize(12);b.setTextColor(TEXT);b.setBackground(background(OUTLINE,10));
    LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(0,dp(45),1);p.setMargins(dp(3),0,dp(3),0);row.addView(b,p);
    b.setOnClickListener(v->{try{action.run();}catch(Exception ex){notice("操作失败："+ex.getMessage());}});return b;
  }
  private LinearLayout row(LinearLayout into){LinearLayout l=new LinearLayout(this);l.setOrientation(LinearLayout.HORIZONTAL);into.addView(l,new LinearLayout.LayoutParams(-1,-2));return l;}
  private String timestamp(long ms){return new SimpleDateFormat("MM-dd HH:mm",Locale.CHINA).format(new Date(ms));}
  private void notice(String msg){Toast.makeText(this,msg,Toast.LENGTH_LONG).show();}
  private void show(String screen){
    section=screen;
    root=col();root.setBackgroundColor(BG);setContentView(root);
    LinearLayout head=col();head.setPadding(dp(20),dp(16),dp(20),dp(10));root.addView(head);
    head.addView(text("知音  /  ZHIYIN",25,TEXT,true));
    head.addView(text("原生 Android · 本地记忆实验版 0.1 · 无云端AI",12,MUTED,false));
    ScrollView scroll=new ScrollView(this);scroll.setFillViewport(false);root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
    content=col();content.setPadding(dp(16),dp(14),dp(16),dp(28));scroll.addView(content);
    nav=row(root);nav.setPadding(dp(8),dp(5),dp(8),dp(12));nav.setBackgroundColor(PANEL);
    for(String label:new String[]{"记忆","角色","剧场","音乐"}){
      Button tab=smallButton(nav,label,()->show(label));if(label.equals(section))tab.setBackground(background(ACCENT,10));
    }
    switch(section){
      case "记忆":memoryPage();break;
      case "角色":rolePage();break;
      case "剧场":stagePage();break;
      case "音乐":musicPage();break;
    }
  }
  private String[] roleNames(boolean includeDirector){
    try{
      JSONArray roles=store.roles();ArrayList<String> list=new ArrayList<>();
      if(includeDirector)list.add("导演");else list.add("玩家");
      for(int i=0;i<roles.length();i++)list.add(roles.getJSONObject(i).getString("name"));
      return list.toArray(new String[0]);
    }catch(Exception ex){return new String[]{"玩家","知音"};}
  }
  private Spinner spinner(LinearLayout into,String[] opts,String selected){
    Spinner s=new Spinner(this);ArrayAdapter<String> a=new ArrayAdapter<>(this,android.R.layout.simple_spinner_dropdown_item,opts);
    s.setAdapter(a);s.setBackground(background(OUTLINE,8));s.setPadding(dp(8),dp(4),dp(8),dp(4));
    into.addView(s,new LinearLayout.LayoutParams(-1,dp(48)));
    for(int i=0;i<opts.length;i++)if(opts[i].equals(selected)){s.setSelection(i);break;}
    return s;
  }
  private void memoryPage(){
    addText(content,"长期记忆库","完整事件保存在设备SQLite，不会因摘要而覆盖。当前共 "+store.count()+" 条原始记录。");
    LinearLayout c=card(content);c.addView(text("记下一段对话或事件",17,TEXT,true));
    Spinner speaker=spinner(c,roleNames(false),activeRole);
    EditText body=field(c,"把你或NPC刚说的话完整写在这里…",true);
    LinearLayout actions=row(c);
    smallButton(actions,"保存原文",()->{
      String name=speaker.getSelectedItem().toString();store.addEvent(name,body.getText().toString(),"shared","","dialogue");
      activeRole=name;notice("已写入完整历史");show("记忆");
    });
    smallButton(actions,"私有记忆",()->{
      String name=speaker.getSelectedItem().toString();if("玩家".equals(name)){notice("请选择NPC来保存私有记忆");return;}
      store.addEvent(name,body.getText().toString(),"private",name,"dialogue");
      activeRole=name;notice("仅角色本人和导演可以检索");show("记忆");
    });
    LinearLayout tools=card(content);tools.addView(text("记忆检索与事实版本",17,TEXT,true));
    Spinner perspective=spinner(tools,roleNames(true),observer);
    perspective.setOnItemSelectedListener(new android.widget.AdapterView.OnItemSelectedListener(){
      public void onNothingSelected(android.widget.AdapterView<?> parent){}
      public void onItemSelected(android.widget.AdapterView<?> parent,View v,int pos,long id){observer=perspective.getSelectedItem().toString();}
    });
    EditText query=field(tools,"输入关键词，如：青云宗 / 第一次唱歌 / 掌门",false);
    smallButton(row(tools),"搜索原始历史",()->presentEvents(store.search(query.getText().toString(),observer,80),"检索结果"));
    smallButton(row(tools),"查看检索快照",()->{
      try{String data=store.recall(observer,query.getText().toString());
        previewLarge("当前可供AI使用的记忆检索包（尚未接AI）",data);
      }catch(Exception e){notice(e.getMessage());}
    });
    smallButton(row(tools),"新增结构化事实",this::editFact);
    smallButton(row(tools),"查看事实档案",()->{
      try{previewLarge("事实时间线（原始版本不覆盖）",store.facts().toString(2));}catch(Exception e){notice(e.getMessage());}
    });
    LinearLayout archive=card(content);archive.addView(text("完整档案备份",17,TEXT,true));
    archive.addView(text("备份包含角色、剧本、事件和事实。纯JSON文件由你保管；导入会整体替换当前数据，请先备份。",12,MUTED,false));
    LinearLayout backupButtons=row(archive);
    smallButton(backupButtons,"导出JSON",()->{Intent i=new Intent(Intent.ACTION_CREATE_DOCUMENT);i.setType("application/json");i.addCategory(Intent.CATEGORY_OPENABLE);i.putExtra(Intent.EXTRA_TITLE,"知音-长期记忆-"+System.currentTimeMillis()+".json");startActivityForResult(i,BACKUP_SAVE);});
    smallButton(backupButtons,"恢复JSON",()->pick(BACKUP_OPEN,"application/json"));
    content.addView(text("最近历史（已遵守角色可见范围）",17,TEXT,true));
    showRecent(content,store.recent(35,observer));
  }
  private void editFact(){
    LinearLayout c=col();c.setPadding(dp(20),dp(10),dp(20),dp(8));
    EditText subject=field(c,"主体（例：墨染）",false),key=field(c,"属性（例：师门）",false),value=field(c,"值（例：青云宗）",false);
    new AlertDialog.Builder(this).setTitle("保存事实（保留历史版本）").setView(c)
      .setPositiveButton("保存",(d,w)->{try{store.remember(subject.getText().toString(),key.getText().toString(),value.getText().toString(),observer);show("记忆");}catch(Exception e){notice(e.getMessage());}})
      .setNegativeButton("取消",null).show();
  }
  private void showRecent(LinearLayout into,JSONArray events){
    if(events.length()==0){into.addView(text("暂无记录。先保存一段对话吧。",14,MUTED,false));return;}
    for(int i=0;i<events.length();i++){try{
      JSONObject o=events.getJSONObject(i);LinearLayout c=card(into);
      c.addView(text(o.optString("role")+"   ·   "+timestamp(o.optLong("stamp"))+("private".equals(o.optString("privacy"))?"  🔒":""),13,ACCENT,true));
      c.addView(text(o.optString("body"),15,TEXT,false));
      smallButton(row(c),"用此声线朗读",()->say(o.optString("role"),o.optString("body")));
    }catch(Exception ignored){}}
  }
  private void presentEvents(JSONArray a,String title){
    LinearLayout panel=col();panel.setPadding(dp(12),dp(10),dp(12),dp(4));
    ScrollView scroll=new ScrollView(this);scroll.addView(panel);showRecent(panel,a);
    new AlertDialog.Builder(this).setTitle(title+" · "+a.length()+" 条").setView(scroll).setPositiveButton("关闭",null).show();
  }
  private void rolePage(){
    addText(content,"角色工厂","不同角色保留自己的声音参数和人格设定。真正的多声线模型将在后续接入。");
    LinearLayout create=card(content);create.addView(text("新增 / 更新角色",17,TEXT,true));
    EditText name=field(create,"名字，如：青云长老",false),persona=field(create,"人格、身份、提示词、知识限制…",true);
    Spinner voice=spinner(create,new String[]{"柔和声线","明亮声线","低沉声线","旁白声线"},"柔和声线");
    button(create,"保存角色",()->{store.upsertRole(name.getText().toString(),persona.getText().toString(),voice.getSelectedItemPosition());notice("角色已保存");show("角色");});
    JSONArray roles=store.roles();
    for(int i=0;i<roles.length();i++)try{
      JSONObject obj=roles.getJSONObject(i);String character=obj.optString("name");LinearLayout c=card(content);
      c.addView(text(character,19,TEXT,true));c.addView(text(obj.optString("persona"),14,MUTED,false));
      LinearLayout r=row(c);
      smallButton(r,"试听声线",()->say(character,"你好，我是"+character+"。这是当前设备的系统语音示范。"));
      smallButton(r,"编辑设定",()->{name.setText(character);persona.setText(obj.optString("persona"));voice.setSelection(obj.optInt("voice"));notice("已载入上方编辑框");});
    }catch(Exception ignored){}
  }
  private void say(String name,String sentence){
    if(!ttsReady){notice("系统语音未准备好，或没有中文语音引擎");return;}
    int mode=0;
    try{JSONArray list=store.roles();for(int i=0;i<list.length();i++){JSONObject r=list.getJSONObject(i);if(name.equals(r.optString("name"))){mode=r.optInt("voice");break;}}}catch(Exception ignored){}
    float pitch=new float[]{1.0f,1.20f,0.82f,0.9f}[Math.max(0,Math.min(3,mode))];
    float rate=new float[]{0.98f,1.04f,0.91f,0.87f}[Math.max(0,Math.min(3,mode))];
    tts.setPitch(pitch);tts.setSpeechRate(rate);
    tts.speak(sentence,TextToSpeech.QUEUE_FLUSH,null,"speech_"+System.nanoTime());
  }
  private void stagePage(){
    addText(content,"AI剧场 / 配音工作台","导入剧本并用角色声线逐句演出。此版为手动剧本演绎，未连接生成式AI。");
    LinearLayout c=card(content);c.addView(text("建立剧本",17,TEXT,true));
    EditText title=field(c,"剧本标题",false), body=field(c,"格式示例：\n旁白：古寺的钟声响起。\n墨染：你终于来了。",true);
    button(c,"保存剧本",()->{
      String t=title.getText().toString(),b=body.getText().toString();store.addScript(t,b);
      stageScript=b;stageTitle=t;stageLine=0;notice("剧本已保存");show("剧场");
    });
    smallButton(row(c),"导入TXT剧本",()->pick(SCRIPT_OPEN,"text/*"));
    if(!stageScript.isEmpty()){
      LinearLayout playback=card(content);playback.addView(text("正在演绎："+stageTitle,18,TEXT,true));
      String[] lines=stageScript.split("\\R");playback.addView(text("第 "+Math.min(stageLine+1,lines.length)+" / "+lines.length+" 句",13,MUTED,false));
      smallButton(row(playback),"下一句并朗读",()->{
        if(stageLine>=lines.length){notice("剧本已结束");stageLine=0;return;}
        String l=lines[stageLine++].trim();if(l.isEmpty())return;
        int split=l.indexOf('：');if(split<0)split=l.indexOf(':');
        String who=split>0?l.substring(0,split).trim():"旁白",words=split>0?l.substring(split+1).trim():l;
        store.addEvent(who,words,"shared","","performance");
        say(who,words);show("剧场");
      });
      smallButton(row(playback),"重置演绎",()->{stageLine=0;show("剧场");});
    }
    JSONArray scripts=store.scripts();
    for(int i=0;i<scripts.length();i++){try{JSONObject o=scripts.getJSONObject(i);LinearLayout item=card(content);
      item.addView(text(o.optString("title"),16,TEXT,true));
      item.addView(text(o.optString("body").substring(0,Math.min(90,o.optString("body").length())),13,MUTED,false));
      smallButton(row(item),"载入剧本",()->{stageTitle=o.optString("title");stageScript=o.optString("body");stageLine=0;show("剧场");});
    }catch(Exception ignored){}}
  }
  private void musicPage(){
    addText(content,"音乐 · A/B 对唱录音台","A段用麦克风录制；B段可导入音频；可播放伴奏。真正AI唱歌与纠错尚未接入。");
    LinearLayout c=card(content);c.addView(text("A段 · 你的声音",18,TEXT,true));
    c.addView(text(recording?"🔴 正在录音":clipA==null?"尚未录制":("已录制："+clipA.getName()),13,MUTED,false));
    smallButton(row(c),recording?"停止录制":"开始录制",()->{if(recording)stopRecording();else askRecording();show("音乐");});
    smallButton(row(c),"回听A段",()->{if(clipA==null||!clipA.exists()){notice("请先录制A段");return;}playA();});
    LinearLayout b=card(content);b.addView(text("B段 · 音频接唱",18,TEXT,true));
    b.addView(text(clipB==null?"尚未导入B段":clipB.getLastPathSegment(),13,MUTED,false));
    smallButton(row(b),"导入B段音频",()->pick(B_OPEN,"audio/*"));
    smallButton(row(b),"播放B段",()->{if(clipB==null){notice("请先导入B段音频");return;}playUri(clipB,null);});
    LinearLayout acc=card(content);acc.addView(text("伴奏 · 独立音轨",18,TEXT,true));
    acc.addView(text(beatUri==null?"未加载伴奏":"已选择伴奏",13,MUTED,false));
    smallButton(row(acc),"选择伴奏",()->pick(BEAT_OPEN,"audio/*"));
    button(acc,"播放 A → B（伴奏同步启动）",()->playDuet());
    button(acc,"停止所有播放",()->stopPlayers());
    content.addView(text("注意：此版本不生成AI歌声，不冒充AI接唱；当前B段需要你导入现有音频。",12,MUTED,false));
  }
  private void askRecording(){
    if(Build.VERSION.SDK_INT>=23 && checkSelfPermission(Manifest.permission.RECORD_AUDIO)!=PackageManager.PERMISSION_GRANTED){
      requestPermissions(new String[]{Manifest.permission.RECORD_AUDIO},MIC_REQUEST);return;
    }startRecording();
  }
  private void startRecording(){
    try{
      stopPlayers();clipA=new File(getFilesDir(),"duet_A_"+System.currentTimeMillis()+".m4a");
      recorder=new MediaRecorder();
      recorder.setAudioSource(MediaRecorder.AudioSource.MIC);
      recorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4);
      recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC);
      recorder.setAudioEncodingBitRate(128000);recorder.setAudioSamplingRate(44100);
      recorder.setOutputFile(clipA.getAbsolutePath());recorder.prepare();recorder.start();recording=true;notice("正在录制 A 段");
    }catch(Exception e){recording=false;safeReleaseRecorder();notice("无法开始录音："+e.getMessage());}
  }
  private void safeReleaseRecorder(){
    if(recorder!=null){try{recorder.reset();}catch(Exception ignored){}try{recorder.release();}catch(Exception ignored){}recorder=null;}
  }
  private void stopRecording(){
    if(!recording)return;
    try{recorder.stop();notice("A段录音已保存");}catch(Exception e){if(clipA!=null)clipA.delete();clipA=null;notice("录音无效或过短，请重试");}
    finally{safeReleaseRecorder();recording=false;}
  }
  private void playA(){
    try{
      stopPlayers();voicePlayer=new MediaPlayer();voicePlayer.setDataSource(clipA.getAbsolutePath());voicePlayer.prepare();voicePlayer.start();
    }catch(Exception e){notice("播放失败："+e.getMessage());stopPlayers();}
  }
  private void playUri(Uri uri,Runnable onFinish){
    try{
      if(voicePlayer!=null){voicePlayer.release();voicePlayer=null;}
      voicePlayer=new MediaPlayer();voicePlayer.setDataSource(this,uri);
      voicePlayer.setOnCompletionListener(mp->{if(onFinish!=null)onFinish.run();});
      voicePlayer.prepareAsync();voicePlayer.setOnPreparedListener(MediaPlayer::start);
    }catch(Exception e){notice("音频无法播放："+e.getMessage());stopPlayers();}
  }
  private void playDuet(){
    if(clipA==null||!clipA.exists()){notice("请先录制A段");return;}
    stopPlayers();
    if(beatUri!=null)try{
      beatPlayer=new MediaPlayer();beatPlayer.setDataSource(this,beatUri);beatPlayer.setLooping(true);
      beatPlayer.prepareAsync();beatPlayer.setOnPreparedListener(MediaPlayer::start);
    }catch(Exception e){notice("伴奏加载失败："+e.getMessage());}
    try{
      voicePlayer=new MediaPlayer();voicePlayer.setDataSource(clipA.getAbsolutePath());
      voicePlayer.setOnCompletionListener(mp->{
        if(clipB!=null)playUri(clipB,()->{if(beatPlayer!=null)beatPlayer.pause();});
        else if(beatPlayer!=null)beatPlayer.pause();
      });
      voicePlayer.prepare();voicePlayer.start();
    }catch(Exception e){notice("A/B播放失败："+e.getMessage());stopPlayers();}
  }
  private void stopPlayers(){
    if(voicePlayer!=null){try{voicePlayer.stop();}catch(Exception ignored){}voicePlayer.release();voicePlayer=null;}
    if(beatPlayer!=null){try{beatPlayer.stop();}catch(Exception ignored){}beatPlayer.release();beatPlayer=null;}
  }
  private void pick(int request,String mime){
    Intent intent=new Intent(Intent.ACTION_OPEN_DOCUMENT);intent.addCategory(Intent.CATEGORY_OPENABLE);intent.setType(mime);
    startActivityForResult(intent,request);
  }
  private String readUri(Uri uri,int limit)throws IOException{
    try(InputStream in=getContentResolver().openInputStream(uri)){
      if(in==null)throw new IOException("无法读取文件");
      ByteArrayOutputStream out=new ByteArrayOutputStream();byte[] bytes=new byte[8192];int n;
      while((n=in.read(bytes))!=-1){if(out.size()+n>limit)throw new IOException("文件超过上限");out.write(bytes,0,n);}
      return new String(out.toByteArray(),StandardCharsets.UTF_8);
    }
  }
  private void writeUri(Uri uri,String body)throws IOException{
    try(OutputStream out=getContentResolver().openOutputStream(uri,"wt")){
      if(out==null)throw new IOException("无法写入目标文件");
      out.write(body.getBytes(StandardCharsets.UTF_8));out.flush();
    }
  }
  private void previewLarge(String title,String value){
    ScrollView sc=new ScrollView(this);TextView t=text(value.length()>25000?value.substring(0,25000)+"\n（预览已截断，原始记录仍在数据库）":value,13,TEXT,false);
    t.setPadding(dp(16),dp(15),dp(16),dp(16));sc.addView(t);
    new AlertDialog.Builder(this).setTitle(title).setView(sc).setPositiveButton("关闭",null).show();
  }
  @Override protected void onActivityResult(int req,int result,Intent data){
    super.onActivityResult(req,result,data);
    if(result!=RESULT_OK||data==null||data.getData()==null)return;
    Uri uri=data.getData();
    try{
      switch(req){
        case BACKUP_SAVE:writeUri(uri,store.archive().toString(2));notice("长期记忆JSON导出完成");break;
        case BACKUP_OPEN:
          final String raw=readUri(uri,32*1024*1024);
          new AlertDialog.Builder(this).setTitle("恢复会覆盖当前所有档案").setMessage("建议先导出备份。确认将导入的角色、对话、事实和剧本整体替换现有数据吗？")
            .setNegativeButton("取消",null).setPositiveButton("确认恢复",(d,w)->{
              try{store.restore(new JSONObject(raw));notice("档案恢复成功");show("记忆");}catch(Exception e){notice("恢复失败，事务已回滚："+e.getMessage());}
            }).show();break;
        case SCRIPT_OPEN:
          String script=readUri(uri,1500000);
          stageScript=script;stageTitle=uri.getLastPathSegment()==null?"导入剧本":uri.getLastPathSegment();
          stageLine=0;store.addScript(stageTitle,script);notice("TXT剧本已导入");show("剧场");break;
        case B_OPEN:clipB=uri;getContentResolver().takePersistableUriPermission(uri,Intent.FLAG_GRANT_READ_URI_PERMISSION);show("音乐");break;
        case BEAT_OPEN:beatUri=uri;getContentResolver().takePersistableUriPermission(uri,Intent.FLAG_GRANT_READ_URI_PERMISSION);show("音乐");break;
      }
    }catch(Exception e){notice("文件操作失败："+e.getMessage());}
  }
  @Override public void onRequestPermissionsResult(int request,String[] permissions,int[] grants){
    super.onRequestPermissionsResult(request,permissions,grants);
    if(request==MIC_REQUEST){if(grants.length>0&&grants[0]==PackageManager.PERMISSION_GRANTED){startRecording();show("音乐");}else notice("需要麦克风权限才能录音");}
  }
  @Override protected void onDestroy(){
    if(recording)stopRecording();
    stopPlayers();if(tts!=null){tts.stop();tts.shutdown();}
    if(store!=null)store.close();
    super.onDestroy();
  }
}
