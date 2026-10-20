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
  private static final String DEMO_MODEL="https://huggingface.co/QuantFactory/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B.Q4_K_M.gguf";
  private AiGateway ai;
  private TextView state,downloadStatus;
  private EditText url,model,key;
  private RadioButton local,remote;
  private final ExecutorService io=Executors.newSingleThreadExecutor();
  private final Handler ui=new Handler(Looper.getMainLooper());
  private int ink=0xFF253343;
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

    root.addView(label("① 手机端离线模型  ·  GGUF (arm64 CPU)",19));
    root.addView(label("推荐：Qwen3-0.6B-Q4_K_M，约484 MB，Apache-2.0。首次下载需要联网；安装后推理可断网。小模型中文效果有限。",13));
    downloadStatus=label("本地模式仅支持 GGUF，模型文件保存在APP私有目录。",13);root.addView(downloadStatus);
    button(root,"⬇ 下载推荐模型（约484 MB）",()->downloadModel());
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
    File tmp=new File(folder,"active.gguf.part");long total=0;
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
    report("正在连接公开GGUF资源仓库，下载约484MB。请使用Wi-Fi并保持应用前台。");
    io.execute(()->{
      HttpURLConnection conn=null;
      try{
        URL url=new URL(DEMO_MODEL);
        conn=(HttpURLConnection)url.openConnection();
        conn.setConnectTimeout(25000);conn.setReadTimeout(60000);
        conn.setInstanceFollowRedirects(true);
        conn.setRequestProperty("User-Agent","ZhiYin-Android-GGUF/0.5");
        int code=conn.getResponseCode();
        if(code!=200)throw new IOException("模型下载HTTP "+code);
        long size=conn.getContentLengthLong();
        if(size<10000000L)throw new IOException("模型文件异常，实际响应长度："+size);
        try(InputStream in=conn.getInputStream()){installStream(in,size);}
      }catch(Exception e){report("下载失败："+e.getMessage()+"。可使用浏览器下载GGUF后在这里导入。");}
      finally{if(conn!=null)conn.disconnect();}
    });
  }
  @Override protected void onActivityResult(int req,int code,Intent data){
    super.onActivityResult(req,code,data);
    if(req==PICK_GGUF&&code==RESULT_OK&&data!=null&&data.getData()!=null)importFile(data.getData());
  }
  @Override protected void onDestroy(){io.shutdownNow();if(ai!=null)ai.close();super.onDestroy();}
}
