package com.xinyanshuo.worldbox.lab13;

import android.app.Activity;
import android.os.Bundle;
import android.content.Intent;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.widget.*;
import android.view.View;
import java.io.*;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/** Original private-test launcher. Runs without loading Unity or accessing old saves. */
public final class DiagnosticsActivity extends Activity {
    private TextView status;
    private static final int LIMIT = 60000;
    private File bootFile() { return new File(getFilesDir(), "worldbox_boot.log"); }
    private synchronized void stage(String message) {
        try {
            File f=bootFile();
            if(f.length()>512000) {
                File previous=new File(getFilesDir(),"worldbox_boot.previous.log");
                if(previous.exists()) previous.delete();
                f.renameTo(previous);
            }
            FileWriter w=new FileWriter(f,true);
            w.write(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss",Locale.US).format(new Date())+" "+message+"\n");
            w.close();
        } catch(Exception ignored) { }
    }
    private String read(File f) {
        if(f==null||!f.isFile())return "(暂无记录)\n";
        try {
            RandomAccessFile r=new RandomAccessFile(f,"r");
            long size=r.length();r.seek(Math.max(0,size-LIMIT));
            byte[] data=new byte[(int)Math.min(size,LIMIT)];r.readFully(data);r.close();
            return new String(data,"UTF-8");
        } catch(Exception e) { return e.toString(); }
    }
    private String logs() {
        File external=getExternalFilesDir(null);
        File logRoot=external==null?null:new File(external,"WorldBoxXianxiaLogs");
        String report="WorldBox·万界仙侠 v17 MOD整合实测\n包名："+getPackageName()+
            "\n安卓："+android.os.Build.VERSION.RELEASE+" / "+android.os.Build.MODEL+
            "\n=== 安卓入口 ===\n"+read(bootFile())+
            "\n=== 上次安卓入口 ===\n"+read(new File(getFilesDir(),"worldbox_boot.previous.log"))+
            "\n=== Unity/Mono 本次 ===\n"+read(logRoot==null?null:new File(logRoot,"session.log"))+
            "\n=== Unity/Mono 上次 ===\n"+read(logRoot==null?null:new File(logRoot,"previous.log"));
        if(report.length()>180000)report=report.substring(report.length()-180000);
        return report;
    }
    private void button(LinearLayout root,String text,final int action) {
        Button b=new Button(this);b.setText(text);b.setTextSize(20);
        root.addView(b,new LinearLayout.LayoutParams(-1,-2));
        b.setOnClickListener(new View.OnClickListener(){public void onClick(View v){
            try {
                if(action==0){
                    int description=getResources().getIdentifier("game_view_content_description","string",getPackageName());
                    int surface=getResources().getIdentifier("unitySurfaceView","id",getPackageName());
                    stage("RESOURCE_PREFLIGHT description=0x"+Integer.toHexString(description)+" surface=0x"+Integer.toHexString(surface));
                    if(description==0||surface==0)throw new IllegalStateException("Unity资源名称未正确匹配。请复制日志反馈。");
                    getResources().getString(description);
                    v.setEnabled(false);status.setText("正在自动部署模组，首次启动需要稍等……");
                    final View launchButton=v;
                    new Thread(new Runnable(){public void run(){
                        try{
                            stage("MOD_DEPLOY_BEGIN v17");stage(ModDeployment.install(DiagnosticsActivity.this));
                            runOnUiThread(new Runnable(){public void run(){
                                launchButton.setEnabled(true);stage("START_UNITY_REQUEST");
                                Intent i=new Intent();i.setClassName(DiagnosticsActivity.this,"com.unity3d.player.UnityPlayerActivity");
                                startActivity(i);
                            }});
                        }catch(final Exception error){
                            stage("MOD_DEPLOY_FAILED "+android.util.Log.getStackTraceString(error));
                            runOnUiThread(new Runnable(){public void run(){launchButton.setEnabled(true);status.setText("模组部署失败："+error.toString()+"\n请复制日志反馈。");}});
                        }
                    }},"WorldBox-MOD-Installer").start();
                } else if(action==1) {
                    ((ClipboardManager)getSystemService(CLIPBOARD_SERVICE)).setPrimaryClip(ClipData.newPlainText("万界仙侠测试日志",logs()));
                    Toast.makeText(DiagnosticsActivity.this,"日志已复制，粘贴到聊天即可",Toast.LENGTH_LONG).show();
                } else {
                    Intent i=new Intent(Intent.ACTION_SEND);i.setType("text/plain");
                    i.putExtra(Intent.EXTRA_SUBJECT,"WorldBox万界仙侠测试日志");i.putExtra(Intent.EXTRA_TEXT,logs());
                    startActivity(Intent.createChooser(i,"发送测试日志"));
                }
            } catch(Exception e) {stage("ACTION_FAILED "+android.util.Log.getStackTraceString(e));status.setText(e.toString());}
        }});
    }
    @Override public void onCreate(Bundle saved) {
        super.onCreate(saved);
        final Thread.UncaughtExceptionHandler previous=Thread.getDefaultUncaughtExceptionHandler();
        Thread.setDefaultUncaughtExceptionHandler(new Thread.UncaughtExceptionHandler(){
            public void uncaughtException(Thread t,Throwable e){
                stage("JAVA_UNCAUGHT "+t.getName()+"\n"+android.util.Log.getStackTraceString(e));
                if(previous!=null)previous.uncaughtException(t,e);
                else {android.os.Process.killProcess(android.os.Process.myPid());System.exit(10);}
            }
        });
        stage("DIAGNOSTICS_READY Android="+android.os.Build.VERSION.RELEASE+" model="+android.os.Build.MODEL);
        LinearLayout root=new LinearLayout(this);root.setOrientation(1);root.setPadding(28,32,28,24);
        TextView title=new TextView(this);title.setText("WorldBox·万界仙侠\nMOD整合实测版 v17");title.setTextSize(27);root.addView(title);
        TextView note=new TextView(this);note.setText("内置：战斗之神1.0.5、合理的世界2.0.1、NeoModLoader1.2.1.1。\n点击启动会自动安装，无需文件管理器。\n旧修仙及人物控制包版本不兼容，未混入本包。\n\n若闪退或模组没出现，重新打开入口复制日志。存档保留在本测试应用中，与原版独立。\n");note.setTextSize(18);root.addView(note);
        button(root,"启动游戏测试",0);button(root,"复制报错日志",1);button(root,"分享报错日志",2);
        status=new TextView(this);status.setTextSize(14);root.addView(status);
        ScrollView scroll=new ScrollView(this);scroll.addView(root);setContentView(scroll);
    }
    @Override public void onResume(){super.onResume();if(status!=null)status.setText("入口正常。日志仅保存在本机，不会自动上传。\n"+read(bootFile()));}
}
