package com.xinyanshuo.zhiyin;

import android.app.*;
import android.content.*;
import android.os.*;
import java.io.*;
import java.net.*;
import java.security.MessageDigest;
import java.util.Locale;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Android foreground download service: resume GGUF using HTTP byte ranges.
 * Progress survives Activity recreation / app process death. Never deletes valid
 * partial bytes due to network interruption. Uses the same private .part path
 * as v0.5/v0.6 so the user's previous download is reusable.
 */
public final class ModelDownloadService extends Service {
  public static final String START="com.xinyanshuo.zhiyin.MODEL_DOWNLOAD_START";
  public static final String PAUSE="com.xinyanshuo.zhiyin.MODEL_DOWNLOAD_PAUSE";
  public static final String RESTART="com.xinyanshuo.zhiyin.MODEL_DOWNLOAD_RESET";
  public static final String CHANNEL="zhiyin_model_downloads";
  public static final String SOURCE="https://huggingface.co/QuantFactory/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B.Q4_K_M.gguf";
  public static final String PREF="zhiyin_download_v2";
  private static final int NOTIF=4207;
  private static final long MAX_BYTES=4L*1024L*1024L*1024L;
  private final AtomicBoolean pause=new AtomicBoolean(false);
  private final Object lock=new Object();
  private volatile Thread worker;
  private volatile HttpURLConnection liveConnection;
  private volatile long bytes=0,total=-1;
  private volatile String state="等待下载";
  private NotificationManager notifications;
  private android.content.SharedPreferences prefs;

  public static void command(Context ctx,String action) {
    Intent intent=new Intent(ctx,ModelDownloadService.class).setAction(action);
    if(PAUSE.equals(action))ctx.startService(intent);
    else ctx.startForegroundService(intent);
  }
  public static File partial(Context ctx){return new File(new File(ctx.getFilesDir(),"models"),"active.gguf.part");}
  public static String report(Context ctx){
    android.content.SharedPreferences p=ctx.getSharedPreferences(PREF,MODE_PRIVATE);
    File partial=partial(ctx);
    long got=partial.exists()?partial.length():p.getLong("bytes",0);
    long expected=p.getLong("total",-1);
    String desc=p.getString("state",got>0?"可继续下载":"尚未下载");
    String count=String.format(Locale.CHINA,"%.1f MB",got/1048576d);
    if(expected>0) count+=" / "+String.format(Locale.CHINA,"%.1f MB",expected/1048576d)+
      "（"+Math.min(100,100*got/expected)+"%）";
    return desc+"\n已保存："+count+"\n"+(got>0?"断网后仍保留已下载字节；重新点击继续即可接上。":"下载数据存入APP私有目录。");
  }
  @Override public void onCreate(){
    super.onCreate();
    prefs=getSharedPreferences(PREF,MODE_PRIVATE);
    notifications=(NotificationManager)getSystemService(NOTIFICATION_SERVICE);
    if(Build.VERSION.SDK_INT>=26){
      NotificationChannel channel=new NotificationChannel(CHANNEL,"知音模型下载",NotificationManager.IMPORTANCE_LOW);
      channel.setDescription("在后台持续下载与断点续传GGUF模型");
      notifications.createNotificationChannel(channel);
    }
  }
  @Override public int onStartCommand(Intent intent,int flags,int startId){
    String action=intent==null?START:intent.getAction();
    if(PAUSE.equals(action)){
      pause.set(true);
      HttpURLConnection current=liveConnection;if(current!=null)current.disconnect();
      Thread t=worker;if(t!=null)t.interrupt();
      setState("已暂停，下载进度保留");
      // Don't stop until the worker has closed its output.
      if(t==null||!t.isAlive())stopForegroundAndSelf();
      return START_NOT_STICKY;
    }
    if(RESTART.equals(action)){
      // Explicitly handled in UI after consent; don't delete while a thread runs.
      if(worker!=null&&worker.isAlive()){
        setState("下载进行中，请先暂停再清理");return START_NOT_STICKY;
      }
      File p=partial(this);
      if(p.exists()&&!p.delete()){setState("无法清理下载缓存");return START_NOT_STICKY;}
      prefs.edit().remove("etag").remove("total").remove("sha256").apply();
    }
    if(worker!=null&&worker.isAlive()){showNotification();return START_STICKY;}
    pause.set(false);
    startForeground(NOTIF,notification());
    worker=new Thread(this::work,"zhiyin-resumable-gguf");
    worker.start();
    return START_REDELIVER_INTENT;
  }
  @Override public android.os.IBinder onBind(Intent i){return null;}
  @Override public void onDestroy(){
    pause.set(true);Thread t=worker;if(t!=null)t.interrupt();
    HttpURLConnection con=liveConnection;if(con!=null)con.disconnect();
    super.onDestroy();
  }
  private Notification notification(){
    int percentage=total>0?(int)Math.min(100,100*bytes/total):0;
    Intent pi=new Intent(this,ModelDownloadService.class).setAction(PAUSE);
    PendingIntent stop=PendingIntent.getService(this,2,pi,PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
    Notification.Builder builder=new Notification.Builder(this,CHANNEL)
      .setContentTitle("知音 · 本地AI模型")
      .setContentText(state+" · "+(bytes/1048576)+"MB")
      .setSmallIcon(android.R.drawable.stat_sys_download)
      .setOngoing(true)
      .setOnlyAlertOnce(true)
      .setProgress(total>0?100:0,percentage,total<=0)
      .addAction(android.R.drawable.ic_media_pause,"暂停并保留",stop);
    return builder.build();
  }
  private void showNotification(){try{notifications.notify(NOTIF,notification());}catch(Exception ignored){}}
  private void setState(String v){
    state=v;
    prefs.edit().putString("state",v).putLong("bytes",bytes).putLong("total",total).apply();
    showNotification();
  }
  private void stopForegroundAndSelf(){
    if(Build.VERSION.SDK_INT>=24)stopForeground(STOP_FOREGROUND_REMOVE);
    else stopForeground(true);
    stopSelf();
  }
  private void work(){
    File p=partial(this);
    try{
      File folder=p.getParentFile();
      if(!folder.isDirectory()&&!folder.mkdirs())throw new IOException("创建目录失败");
      File destination=new File(folder,"active.gguf");
      if(destination.exists()&&destination.length()>10000000L){
        setState("已安装GGUF，无需重复下载");return;
      }
      bytes=p.exists()?p.length():0;
      if(bytes>0&&!validMagic(p)){
        // A prior failed/captive-portal request may have saved HTML.
        // Preserve it as evidence instead of blindly appending or deleting.
        throw new IOException("旧缓存文件不是GGUF，需手动清理后重试；原缓存仍保留");
      }
      if(bytes>MAX_BYTES)throw new IOException("缓存超过4GB限制");
      String etag=prefs.getString("etag","");
      int attempt=0;
      while(!pause.get()&&attempt<12){
        attempt++;
        HttpURLConnection con=null;
        try{
          setState(bytes>0?"正在从已保存位置续传":"开始下载");
          con=(HttpURLConnection)new URL(SOURCE).openConnection();
          liveConnection=con;
          con.setConnectTimeout(20000);con.setReadTimeout(25000);
          con.setInstanceFollowRedirects(true);
          con.setRequestProperty("User-Agent","ZhiYin-Resumable-GGUF/0.7");
          con.setRequestProperty("Accept-Encoding","identity");
          if(bytes>0) {
            con.setRequestProperty("Range","bytes="+bytes+"-");
            if(!etag.isEmpty())con.setRequestProperty("If-Range",etag);
          }
          int code=con.getResponseCode();
          long remoteSize=-1;
          if(code==416&&bytes>0){
            String range=con.getHeaderField("Content-Range");
            if(range!=null&&range.matches("bytes \\\\*/[0-9]+")){
              remoteSize=Long.parseLong(range.substring(range.indexOf('/')+1));
              if(remoteSize==bytes){total=bytes;finalizeFile(p,destination,etag);return;}
            }
            throw new IOException("服务器认为本地已超出文件长度，保留缓存等待处理");
          }
          if(bytes>0&&code!=206){
            // CRITICAL: If-Range may return 200 because source changed.
            // Never append an HTTP 200 body to an existing .part.
            throw new IOException("服务器未返回206断点数据（实际HTTP "+code+"）。已保存"+
              (bytes/1048576)+"MB，请勿重复点击清理；稍后继续尝试。");
          }
          if(bytes==0&&code!=200&&code!=206)throw new IOException("下载服务器HTTP "+code);
          if(code==206){
            String contentRange=con.getHeaderField("Content-Range");
            if(contentRange==null||!contentRange.startsWith("bytes "+bytes+"-")){
              throw new IOException("续传响应起点不匹配，保留原文件");
            }
            int slash=contentRange.lastIndexOf('/');
            if(slash>0&&contentRange.charAt(slash+1)!='*')
              remoteSize=Long.parseLong(contentRange.substring(slash+1).trim());
          } else remoteSize=con.getContentLengthLong();
          if(remoteSize>MAX_BYTES)throw new IOException("模型超过4GB上限");
          String responseEtag=con.getHeaderField("ETag");
          String hfLinked=con.getHeaderField("X-Linked-Etag");
          String newEtag=responseEtag!=null?responseEtag:etag;
          String maybeSha=(hfLinked!=null?hfLinked:newEtag).replace("\"","");
          if(maybeSha.matches("(?i)[a-f0-9]{64}"))
            prefs.edit().putString("sha256",maybeSha.toLowerCase(Locale.ROOT)).apply();
          if(bytes==0&&responseEtag!=null)etag=responseEtag;
          if(bytes>0&&!etag.isEmpty()&&responseEtag!=null&&!etag.equals(responseEtag)){
            throw new IOException("续传的模型版本不一致，缓存已保护");
          }
          if(remoteSize>0)total=remoteSize;
          prefs.edit().putString("etag",etag).putLong("total",total).apply();
          if(total>0&&p.getUsableSpace()<Math.max(0,total-bytes)+48L*1024*1024L)
            throw new IOException("手机剩余空间不足，请腾出空间后继续");
          long lastDisplay=0;
          try(InputStream in=new BufferedInputStream(con.getInputStream());
              OutputStream out=new BufferedOutputStream(new FileOutputStream(p,bytes>0))){
            byte[] buffer=new byte[128*1024];int n;
            while((n=in.read(buffer))!=-1){
              if(pause.get()||Thread.currentThread().isInterrupted())throw new InterruptedIOException("用户暂停");
              bytes+=n;
              if(bytes>MAX_BYTES)throw new IOException("下载超过模型大小安全上限");
              out.write(buffer,0,n);
              long now=System.currentTimeMillis();
              if(now-lastDisplay>1200){
                out.flush();setState("下载中");lastDisplay=now;
              }
            }
            out.flush();
          }
          if(pause.get())throw new InterruptedIOException("用户暂停");
          if(total>0&&bytes!=total)throw new IOException("下载长度不足：已收到"+bytes+"，预期"+total);
          finalizeFile(p,destination,etag);return;
        }catch(InterruptedIOException interrupted){
          setState("已暂停，缓存保留");return;
        }catch(IOException e){
          if(pause.get()){setState("已暂停，缓存保留");return;}
          setState("网络中断，保留"+(bytes/1048576)+"MB；等待自动重连（"+attempt+"/12）");
          if(e.getMessage()!=null&&(
            e.getMessage().contains("服务器未返回206")||
            e.getMessage().contains("版本不一致")||
            e.getMessage().contains("缓存文件不是GGUF")||
            e.getMessage().contains("超出文件长度")||
            e.getMessage().contains("剩余空间不足")))throw e;
          // Automatic retries are bounded; each new request sends Range.
          try{Thread.sleep(Math.min(60000L,2000L*(1L<<Math.min(attempt,5))));}
          catch(InterruptedException ex){Thread.currentThread().interrupt();setState("暂停，缓存保留");return;}
        }finally{
          if(con!=null)con.disconnect();liveConnection=null;
        }
      }
      if(!pause.get())throw new IOException("重试次数已用尽，可随时从"+(bytes/1048576)+"MB处继续");
    }catch(Exception e){
      setState("下载未完成："+e.getMessage()+"。已保留断点");
    }finally{
      worker=null;stopForegroundAndSelf();
    }
  }
  private static boolean validMagic(File f)throws IOException{
    if(f.length()<4)return false;
    try(FileInputStream in=new FileInputStream(f)){
      byte[] magic=new byte[4];if(in.read(magic)!=4)return false;
      return magic[0]=='G'&&magic[1]=='G'&&magic[2]=='U'&&magic[3]=='F';
    }
  }
  private void finalizeFile(File part,File done,String etag)throws Exception {
    setState("下载完成，正在校验模型");
    if(part.length()<10000000L||!validMagic(part))throw new IOException("GGUF头部或文件长度异常");
    if(total>0&&part.length()!=total)throw new IOException("总长度校验失败");
    String expected=prefs.getString("sha256","");
    // Hugging Face LFS linked ETag is SHA256 of the exact blob; verify when provided.
    if(expected.matches("(?i)[a-f0-9]{64}")){
      MessageDigest digest=MessageDigest.getInstance("SHA-256");
      try(InputStream in=new BufferedInputStream(new FileInputStream(part))){
        byte[] b=new byte[256*1024];int n;while((n=in.read(b))!=-1)digest.update(b,0,n);
      }
      StringBuilder hex=new StringBuilder();
      for(byte b:digest.digest())hex.append(String.format(Locale.ROOT,"%02x",b&255));
      if(!hex.toString().equalsIgnoreCase(expected))
        throw new IOException("SHA256校验失败。部分文件保留，暂不安装");
    }
    if(done.exists()&&!done.delete())throw new IOException("无法替换已安装的旧模型");
    if(!part.renameTo(done))throw new IOException("模型复制完成但安装失败，数据仍在.part中");
    prefs.edit().putLong("bytes",done.length()).putLong("total",done.length()).remove("etag").remove("sha256").apply();
    setState("已下载并安装GGUF模型");
  }
}
