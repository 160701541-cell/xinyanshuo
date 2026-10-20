package com.xinyanshuo.worldbox.lab13;

import android.content.Context;
import android.content.res.AssetManager;
import java.io.*;
import java.security.MessageDigest;
import java.util.zip.*;
import org.json.*;

/** Installs only bundled technical files into THIS test app. Never imports/deletes worlds. */
final class ModDeployment {
    static final String ASSETS="worldbox-xianxia/v18/";
    static String install(Context context) throws Exception {
        File external=context.getExternalFilesDir(null);
        if(external==null)throw new IOException("应用外部存储不可用");
        File root=external.getParentFile().getCanonicalFile();
        if(!root.getName().equals(context.getPackageName()))throw new IOException("应用目录隔离检查失败");
        String index=readText(context.getAssets().open(ASSETS+"install.json"));
        JSONObject manifest=new JSONObject(index);
        String build=manifest.getString("build_token");
        String previous=context.getSharedPreferences("worldbox_mod_deployment",0).getString("build","");
        if(build.equals(previous) && new File(external,"mods/NeoModLoader.dll").isFile()
            && new File(external,"mono/WorldBoxXianxiaMonoBridge.dll").isFile())
            return "MOD_DEPLOY_CACHED "+build+"; 战斗之神1.0.5 / 合理的世界2.0.1";
        int managed=0;
        // Synchronize the APK's exact Mono assemblies before the engine starts.
        // This also updates the original entry hook when upgrading v15 -> v18.
        ZipInputStream zip=new ZipInputStream(context.getAssets().open("Mono/Managed.zip"));
        try {
            ZipEntry entry;
            while((entry=zip.getNextEntry())!=null){
                String n=entry.getName();
                if(entry.isDirectory() || n.contains("/") || n.contains("\\") || n.contains(".."))continue;
                if(!n.endsWith(".dll")&&!n.endsWith(".pdb"))continue;
                atomicCopy(zip,new File(external,"mono/"+n),null);
                managed++;
                zip.closeEntry();
            }
        } finally { zip.close(); }
        JSONArray files=manifest.getJSONArray("files");
        for(int i=0;i<files.length();i++){
            JSONObject f=files.getJSONObject(i);String target=f.getString("target");
            if(!(target.startsWith("files/mods/")||target.startsWith("Mods/")) || target.contains("..") || target.contains("\\"))
                throw new IOException("禁止的模组目标路径");
            File out=new File(root,target).getCanonicalFile();
            if(!out.getPath().startsWith(root.getPath()+File.separator))throw new IOException("目标路径越界");
            InputStream in=context.getAssets().open(ASSETS+target);
            try { atomicCopy(in,out,f.getString("sha256")); } finally { in.close(); }
        }
        if(!context.getSharedPreferences("worldbox_mod_deployment",0).edit().putString("build",build).commit())
            throw new IOException("模组安装状态保存失败");
        return "MOD_DEPLOY_OK build="+build+" managed="+managed+" payloadFiles="+files.length()+
            "; NeoModLoader1.2.1.1 / CombatGods1.0.5 / Frontiers2.0.1; runtime load still pending";
    }
    private static void atomicCopy(InputStream in,File out,String expected) throws Exception {
        if(!out.getParentFile().isDirectory()&&!out.getParentFile().mkdirs())throw new IOException("无法建立模组目录");
        File temp=new File(out.getParentFile(),out.getName()+".installing");
        MessageDigest digest=MessageDigest.getInstance("SHA-256");
        FileOutputStream stream=new FileOutputStream(temp);
        try {
            byte[] buffer=new byte[65536];int n;
            while((n=in.read(buffer))!=-1){stream.write(buffer,0,n);digest.update(buffer,0,n);}
            stream.flush();stream.getFD().sync();
        } finally {stream.close();}
        StringBuilder hash=new StringBuilder();for(byte b:digest.digest())hash.append(String.format(java.util.Locale.US,"%02x",b&255));
        if(expected!=null&&!expected.equals(hash.toString())){temp.delete();throw new IOException("模组文件校验失败："+out.getName());}
        if(!temp.renameTo(out)){temp.delete();throw new IOException("模组文件更新失败："+out.getName());}
    }
    private static String readText(InputStream in) throws IOException {
        try { ByteArrayOutputStream out=new ByteArrayOutputStream();byte[] b=new byte[8192];int n;
            while((n=in.read(b))!=-1)out.write(b,0,n);return out.toString("UTF-8");
        } finally {in.close();}
    }
}
