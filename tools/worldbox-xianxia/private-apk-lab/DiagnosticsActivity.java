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
import java.util.List;
import java.util.ArrayList;

/** Original private-test launcher. Runs without loading Unity or accessing old saves. */
public final class DiagnosticsActivity extends Activity {
    private TextView status;
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
    private static final int EXPORT_LOGS=2901;
    private static final int IMPORT_MODS=2902;
    private File[] diagnosticFiles() {
        File external=getExternalFilesDir(null);
        File root=external==null?null:new File(external,"WorldBoxXianxiaLogs");
        return new File[]{bootFile(),new File(getFilesDir(),"worldbox_boot.previous.log"),
            root==null?null:new File(root,"session.log"),
            root==null?null:new File(root,"previous.log")};
    }
    private static final String[] LOG_NAMES={
        "android_current.log","android_previous.log","unity_current.log","unity_previous.log"};
    private String header() {
        return "WorldBox·万界仙侠 MOD实测\n包名："+getPackageName()+
            "\n安卓："+android.os.Build.VERSION.RELEASE+" / "+android.os.Build.MODEL;
    }
    private String logs() {
        return DiagnosticReport.summary(header(),diagnosticFiles(),LOG_NAMES);
    }
    private void exportLogs() {
        Intent intent=new Intent(Intent.ACTION_CREATE_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("application/zip");
        intent.putExtra(Intent.EXTRA_TITLE,"WorldBox_logs_"+
            new SimpleDateFormat("yyyyMMdd_HHmmss",Locale.US).format(new Date())+".zip");
        startActivityForResult(intent,EXPORT_LOGS);
    }
    private void requestModSelection() {
        new android.app.AlertDialog.Builder(this)
          .setTitle("导入第三方MOD（测试）")
          .setMessage("只选择你信任的MOD。未知MOD可能包含恶意代码或与0.51.4冲突；导入后需要重启游戏才可能加载。先备份存档。")
          .setNegativeButton("取消",null)
          .setPositiveButton("选择ZIP", (dialog,which)->{
              Intent i=new Intent(Intent.ACTION_OPEN_DOCUMENT);
              i.addCategory(Intent.CATEGORY_OPENABLE);
              i.setType("*/*");
              // Many Android providers label genuine ZIPs as application/octet-stream
              // or arbitrary MIME. Select via SAF and verify ZIP magic via ZipFile.
              // Never hide legitimate user ZIPs based solely on provider MIME.
              i.putExtra(Intent.EXTRA_ALLOW_MULTIPLE,true);
              startActivityForResult(i,IMPORT_MODS);
          }).show();
    }
    private void importSelectedMods(final Intent data) {
        final List<android.net.Uri> picked=new ArrayList<>();
        if(data.getClipData()!=null)for(int i=0;i<data.getClipData().getItemCount();i++)
            picked.add(data.getClipData().getItemAt(i).getUri());
        else if(data.getData()!=null)picked.add(data.getData());
        if(picked.size()==0||picked.size()>8){status.setText("一次最多选择8个MOD ZIP。");return;}
        status.setText("正在逐个校验并导入："+picked.size()+"个ZIP；请勿退出。");
        new Thread(()->{
            final StringBuilder report=new StringBuilder();
            int installed=0;
            for(android.net.Uri uri:picked) {
                try {
                    List<ExternalModImporterV32.Result> imported=ExternalModImporterV32.importZip(this,uri);
                    for(ExternalModImporterV32.Result result:imported) {
                        if(result.target!=null&&!result.target.isEmpty()){
                            installed++;
                            report.append("已导入 ").append(result.id).append(" [")
                                .append(result.layout).append("]\n");
                            stage("USER_MOD_IMPORTED "+result.id+" "+result.layout);
                        }else{
                            report.append(result.id).append("\n");
                            stage("USER_MOD_SKIPPED "+result.id);
                        }
                    }
                }catch(Exception e){
                    report.append("导入失败：").append(e.getMessage()).append("\n");
                    stage("USER_MOD_IMPORT_FAILED "+android.util.Log.getStackTraceString(e));
                }
            }
            final int count=installed;
            runOnUiThread(()->status.setText("成功安装 "+count+" 个个MOD目录。重新启动游戏才可能被加载。\n"+
                "部分旧DLL/BepInEx包不兼容安卓NML；详细原因如下。\n"+report.toString()));
        },"WorldBox-SAF-MOD-Import").start();
    }
    @Override protected void onActivityResult(int request,int result,Intent data) {
        super.onActivityResult(request,result,data);
        if(request==IMPORT_MODS){
            if(result==RESULT_OK&&data!=null)importSelectedMods(data);
            return;
        }
        if(request!=EXPORT_LOGS||result!=RESULT_OK||data==null||data.getData()==null)return;
        final android.net.Uri uri=data.getData();
        status.setText("正在导出完整日志……");
        new Thread(new Runnable(){public void run(){
            try {
                OutputStream out=getContentResolver().openOutputStream(uri,"wt");
                if(out==null)throw new IOException("无法打开导出文件");
                DiagnosticReport.zip(out,header(),diagnosticFiles(),LOG_NAMES);
                runOnUiThread(new Runnable(){public void run(){
                    status.setText("完整日志ZIP已导出，可作为聊天附件发送。");
                    try {
                        Intent share=new Intent(Intent.ACTION_SEND);
                        share.setType("application/zip");
                        share.putExtra(Intent.EXTRA_STREAM,uri);
                        share.setClipData(ClipData.newRawUri("WorldBox完整日志",uri));
                        share.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                        startActivity(Intent.createChooser(share,"分享完整日志ZIP"));
                    } catch(Exception e) {
                        status.setText("日志ZIP已导出。分享未打开："+e.toString());
                    }
                }});
            } catch(final Exception e) {
                stage("LOG_EXPORT_FAILED "+android.util.Log.getStackTraceString(e));
                runOnUiThread(new Runnable(){public void run(){
                    status.setText("日志导出失败："+e.toString());
                }});
            }
        }},"WorldBox-Log-Export").start();
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
                            stage("MOD_DEPLOY_BEGIN v18");stage(ModDeployment.install(DiagnosticsActivity.this));
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
                    Toast.makeText(DiagnosticsActivity.this,"关键错误摘要已复制；完整日志请导出ZIP",Toast.LENGTH_LONG).show();
                } else if(action==2) {
                    exportLogs();
                } else if(action==3) {
                    requestModSelection();
                } else {
                    status.setText("已安装MOD需以运行日志确认载入；不从本界面删除MOD或存档。");
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
        TextView title=new TextView(this);title.setText("WorldBox·万界仙侠\n整合测试 v0.32 · ZIP模组导入");title.setTextSize(27);root.addView(title);
        TextView note=new TextView(this);note.setText("内置：原创人物修仙、采集炼丹、8种原创建筑图鉴；战斗之神1.0.5、合理的世界2.0.1。\n点击启动会自动安装，无需文件管理器。\n旧修仙及人物控制包版本不兼容，未混入本包。\n\n若闪退或模组没出现，重新打开入口复制关键摘要，或导出完整日志ZIP。存档保留在本测试应用中，与原版独立。\n");note.setTextSize(18);root.addView(note);
        button(root,"启动游戏测试",0);button(root,"导入第三方MOD ZIP（支持多选）",3);
        button(root,"复制关键错误摘要",1);button(root,"导出并分享完整日志ZIP",2);
        status=new TextView(this);status.setTextSize(17);
        status.setPadding(8,18,8,20);status.setTextIsSelectable(true);
        root.addView(status,new LinearLayout.LayoutParams(-1,-2));
        ScrollView scroll=new ScrollView(this);scroll.addView(root);setContentView(scroll);
    }
    @Override public void onResume(){super.onResume();if(status!=null)status.setText("入口正常。可直接选择第三方MOD ZIP多选导入；需要重新进入游戏测试。\n日志仅保存在本机。");}
}
