package com.xinyanshuo.zhiyin;

import android.app.*;
import android.content.*;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.*;
import android.provider.OpenableColumns;
import android.database.Cursor;
import android.view.*;
import android.widget.*;
import java.io.*;
import java.net.*;
import java.util.concurrent.*;

/** Native screen for genuine API/local GGUF selection. No HTML or third-party account. */
public final class AiSettingsActivity extends Activity {
  private static final int PICK_GGUF=90;
  // All network download activity is owned by the resumable foreground service.
  private AiGateway ai;
  private TextView state,downloadStatus;
  private EditText url,model,key;
  private RadioButton local,remote;
  private final ExecutorService io=Executors.newSingleThreadExecutor();
  private final Handler ui=new Handler(Looper.getMainLooper());
  private int ink=0xFF253343;
  private final Handler ticker=new Handler(Looper.getMainLooper());
  private final Runnable progressUpdate=new Runnable(){public void run(){
    if(downloadStatus!=null)downloadStatus.setText(ModelDownloadService.report(AiSettingsActivity.this));
    if(state!=null)status();
    ticker.postDelayed(this,1700);
  }};
  private int d(float n){return (int)(getResources().getDisplayMetrics().density*n+.5f);}
  private GradientDrawable rounded(int col,int r){GradientDrawable v=new GradientDrawable();v.setColor(col);v.setCornerRadius(d(r));return v;}
  private TextView label(String t,int sz){TextView v=new TextView(this);v.setText(t);v.setTextSize(sz);v.setTextColor(ink);v.setPadding(0,d(7),0,d(6));return v;}
  private EditText input(LinearLayout p,String hint,String txt){
    EditText e=new EditText(this);e.setText(txt);e.setHint(hint);e.setTextColor(ink);e.setTextSize(14);
    e.setBackground(rounded(0xFFE8EDF0,10));e.setPadding(d(12),d(11),d(12),d(11));
    LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-1,-2);lp.setMargins(0,d(7),0,d(7));p.addView(e,lp);return e;
  }
  private Button button(LinearLayout p,String text,Runnable action){
    Button b=new Button(this);b.setAllCaps(false);b.setText(text);b.setTextColor(ink);b.setTextSize(14);
    b.setBackground(rounded(0xFFC9E0DD,12));
    LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-1,d(47));lp.setMargins(0,d(5),0,d(5));p.addView(b,lp);
    b.setOnClickListener(v->action.run());return b;
  }
  private void report(String msg){ui.post(()->{if(downloadStatus!=null)downloadStatus.setText(msg);});}
  private void toast(String msg){ui.post(()->Toast.makeText(this,msg,Toast.LENGTH_LONG).show());}
  private void status(){
    String mode=AiGateway.MODE_API.equals(ai.mode())?"在线API":"本地GGUF";
    String loaded=ai.installed()?String.format(java.util.Locale.CHINA,"已有模型 %.1f MB",ai.modelBytes()/1048576f):"未安装本地模型";
    if(state!=null)state.setText("当前："+mode+"  ·  "+loaded+"  ·  原生推理："+(NativeLlm.SUPPORTED?"已打包":"不可用"));
  }
  @Override public void onCreate(Bundle saved){
    super.onCreate(saved);getWindow().setStatusBarColor(0xFF293745);getWindow().setNavigationBarColor(0xFF293745);
    ai=new AiGateway(this);
    ScrollView scroll=new ScrollView(this);scroll.setFillViewport(true);scroll.setBackgroundColor(0xFFF4F4F0);
    LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);
    root.setPadding(d(19),d(22),d(19),d(28));scroll.addView(root);
    TextView title=label("知音 · AI引擎",24);title.setTypeface(Typeface.DEFAULT,Typeface.BOLD);root.addView(title);
    state=label("",13);root.addView(state);
    root.addView(label("选择模式：离线优先，不填写API也可以使用本地模型。首次需下载或导入GGUF模型。",13));
    RadioGroup modes=new RadioGroup(this);modes.setOrientation(RadioGroup.HORIZONTAL);
    local=new RadioButton(this);local.setText("手机本地模型");local.setTextColor(ink);modes.addView(local);
    remote=new RadioButton(this);remote.setText("API接口");remote.setTextColor(ink);modes.addView(remote);root.addView(modes);
    if(ai.mode().equals(AiGateway.MODE_API))remote.setChecked(true);else local.setChecked(true);
    modes.setOnCheckedChangeListener((g,id)->{
      ai.setMode(remote.isChecked()?AiGateway.MODE_API:AiGateway.MODE_LOCAL);status();
    });
    Switch planner=new Switch(this);
    planner.setText("允许AI参与安排知音的业余活动（每15分钟最多一次建议）");
    planner.setTextSize(13);planner.setTextColor(ink);planner.setPadding(0,d(10),0,d(10));
    planner.setChecked(ai.plannerEnabled());
    root.addView(planner);
    root.addView(label("关闭时完全不产生后台AI调用。开启后仅当APP处于前台且已配置模型时尝试，API可能产生费用；AI只建议读书、练歌等兴趣活动，不能跳过打工、吃饭、睡眠与房租。",12));
    planner.setOnCheckedChangeListener((v,checked)->{ai.setPlannerEnabled(checked);toast(checked?"AI生活计划已开启":"AI生活计划已关闭");});

    root.addView(label("① 手机端离线模型  ·  GGUF (arm64 CPU)",19));
    root.addView(label("推荐：Qwen3-0.6B-Q4_K_M，约484 MB，Apache-2.0。首次下载需要联网；安装后推理可断网。小模型中文效果有限。",13));
    downloadStatus=label(ModelDownloadService.report(this),13);root.addView(downloadStatus);
    ProgressBar progressBar=new ProgressBar(this,null,android.R.attr.progressBarStyleHorizontal);
    progressBar.setMax(100);root.addView(progressBar,new LinearLayout.LayoutParams(-1,d(7)));
    ticker.post(new Runnable(){public void run(){
      if(isFinishing()||isDestroyed())return;
      android.content.SharedPreferences p=getSharedPreferences(ModelDownloadService.PREF,MODE_PRIVATE);
      File part=ModelDownloadService.partial(AiSettingsActivity.this);
      long total=p.getLong("total",-1),got=part.isFile()?part.length():0;
      progressBar.setProgress(total>0?(int)Math.min(100,100L*got/total):0);
      ticker.postDelayed(this,1500);
    }});
    button(root,"⬇ 开始 / 继续下载（断点续传）",()->downloadModel());
    button(root,"Ⅱ 暂停下载（保留已下载部分）",()->{
      ModelDownloadService.command(this,ModelDownloadService.PAUSE);
      toast("正在暂停。缓存不会因退出APP或断网删除。");
    });
    button(root,"清理损坏缓存（需再次确认）",()->{
      new AlertDialog.Builder(this).setTitle("确认删除尚未完成的模型缓存？")
        .setMessage("此操作会清除已经下载的文件，只有缓存确实损坏或服务器无法续传时才需要。先暂停下载，再清理。")
        .setNegativeButton("取消",null).setPositiveButton("删除缓存",(d,w)->{
          // Do not reset a running foreground service; request pause first.
          ModelDownloadService.command(this,ModelDownloadService.PAUSE);
          android.os.Handler h=new Handler(Looper.getMainLooper());
          h.postDelayed(()->{
            File p=ModelDownloadService.partial(this);
            if(p.exists()&&!p.delete())toast("清理失败，文件仍在");
            else{
              getSharedPreferences(ModelDownloadService.PREF,MODE_PRIVATE)
                .edit().remove("etag").remove("sha256").remove("total").putString("state","缓存已主动清理").apply();
              toast("旧缓存已清理，可重新下载");
            }
          },900);
        }).show();
    });
    button(root,"📂 从手机下载已有 GGUF 文件",()->{
      Intent i=new Intent(Intent.ACTION_OPEN_DOCUMENT);i.addCategory(Intent.CATEGORY_OPENABLE);
      i.setType("*/*");startActivityForResult(i,PICK_GGUF);
    });
    button(root,"🧪 用本地模型生成测试回复",()->{
      ai.setMode(AiGateway.MODE_LOCAL);local.setChecked(true);test();
    });

    root.addView(label("② API 接口（兼容 OpenAI Chat Completions）",19));
    root.addView(label("支持DeepSeek、OpenAI及兼容服务。请填写完整 /chat/completions 路径，不仅是域名。",12));
    url=input(root,"https://…/chat/completions",ai.endpoint());
    model=input(root,"模型ID，比如 deepseek-chat",ai.model());
    key=input(root,"API密钥（留空保留旧密钥）","");
    key.setInputType(android.text.InputType.TYPE_CLASS_TEXT|android.text.InputType.TYPE_TEXT_VARIATION_PASSWORD);
    button(root,"保存API设置",()->{
      try{
        ai.configure(url.getText().toString().trim(),model.getText().toString().trim(),key.getText().toString().trim());
        ai.setMode(AiGateway.MODE_API);remote.setChecked(true);
        key.setText("");status();toast("API设置已保存，密钥由Android Keystore加密");
      }catch(Exception e){toast("配置失败："+e.getMessage());}
    });
    button(root,"🧪 测试API真实回复",()->{
      try{
        ai.configure(url.getText().toString().trim(),model.getText().toString().trim(),key.getText().toString().trim());
        key.setText("");ai.setMode(AiGateway.MODE_API);remote.setChecked(true);test();
      }catch(Exception e){toast("接口无效："+e.getMessage());}
    });
    button(root,"清除本机保存的API密钥",()->{ai.clearKey();toast("密钥已清除");});

    root.addView(label("安全说明",18));
    root.addView(label("本地模式无需账号，内容不会因为模型推理自动上传。API模式会向你配置的服务发送当前提问、有限聊天历史和角色设定；请自行确认接口服务的隐私政策。"
      +" 密钥使用安卓系统密钥库保护，不包含在记忆JSON导出中。当前APK仍是公开实验签名，不建议保存真实敏感信息。",13));
    setContentView(scroll);status();
  }
  private void test(){
    downloadStatus.setText("正在获取模型真实回答，请稍等…");
    MemoryStore db=new MemoryStore(this);
    ai.ask("简单介绍一下你自己，40字以内。","知音",db,(text,error)->ui.post(()->{
      db.close();
      downloadStatus.setText(error==null?"AI真实回复："+text:"推理失败："+error);
    }));
  }
  private void installStream(InputStream in, long expected)throws Exception {
    File finalFile=ai.modelFile();File folder=finalFile.getParentFile();
    if(!folder.exists()&&!folder.mkdirs())throw new IOException("无法创建模型目录");
    if(expected>0 && folder.getUsableSpace()<expected+64*1024*1024L)throw new IOException("磁盘剩余空间不足");
    File tmp=new File(folder,"active.gguf.importing");long total=0;
    try(OutputStream out=new BufferedOutputStream(new FileOutputStream(tmp))){
      byte[] buffer=new byte[256*1024];int n;
      while((n=in.read(buffer))!=-1){
        if(Thread.currentThread().isInterrupted())throw new IOException("下载/复制已取消");
        total+=n;
        if(total>4L*1024*1024*1024)throw new IOException("模型超过4GB安全上限");
        out.write(buffer,0,n);
        if(total%(10*1024*1024)<n)report("接收 "+(total/1048576)+" MB "+(expected>0?("/ "+(expected/1048576)+" MB"):""));
      }
      out.flush();
    }catch(Exception err){tmp.delete();throw err;}
    if(total<10000000L || (expected>0&&total!=expected)){tmp.delete();throw new IOException("模型大小不正确或下载未完整："+total+"字节");}
    try(FileInputStream check=new FileInputStream(tmp)){
      byte[] magic=new byte[4];
      if(check.read(magic)!=4 || magic[0]!='G'||magic[1]!='G'||magic[2]!='U'||magic[3]!='F'){
        tmp.delete();throw new IOException("下载内容不是GGUF模型文件");
      }
    }
    if(NativeLlm.SUPPORTED)NativeLlm.unload();
    if(finalFile.exists()&&!finalFile.delete()){tmp.delete();throw new IOException("旧模型文件无法替换");}
    if(!tmp.renameTo(finalFile))throw new IOException("模型安装失败");
    report("已安装本地模型："+(total/1048576)+" MB。现在可选本地模式聊天。");
    ui.post(this::status);
  }
  private void importFile(Uri uri){
    report("正在导入GGUF，较大模型需要一段时间…");
    io.execute(()->{
      try(InputStream in=getContentResolver().openInputStream(uri)){
        if(in==null)throw new IOException("无法读取本地文件");
        long size=-1;try(Cursor c=getContentResolver().query(uri,new String[]{OpenableColumns.SIZE},null,null,null)){
          if(c!=null&&c.moveToFirst()&&!c.isNull(0))size=c.getLong(0);
        }
        installStream(in,size);
      }catch(Exception e){report("导入失败："+e.getMessage());}
    });
  }
  private void downloadModel(){
    if(ai.installed()){toast("模型已安装，无需再次下载；如要换模型请使用文件导入");return;}
    try{
      ModelDownloadService.command(this,ModelDownloadService.START);
      report("已交给安卓前台下载服务；你可以切到其他页面，下载不会因为关掉设置界面而自动放弃。
"+
        ModelDownloadService.report(this));
    }catch(Exception e){report("启动下载服务失败："+e.getMessage());}
  }
  @Override protected void onActivityResult(int req,int code,Intent data){
    super.onActivityResult(req,code,data);
    if(req==PICK_GGUF&&code==RESULT_OK&&data!=null&&data.getData()!=null)importFile(data.getData());
  }
  @Override protected void onResume(){
    super.onResume();ticker.removeCallbacks(progressUpdate);ticker.post(progressUpdate);
  }
  @Override protected void onPause(){ticker.removeCallbacks(progressUpdate);super.onPause();}
  @Override protected void onDestroy(){ticker.removeCallbacksAndMessages(null);io.shutdownNow();if(ai!=null)ai.close();super.onDestroy();}
}
