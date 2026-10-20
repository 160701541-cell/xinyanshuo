package com.xinyanshuo.worldbox.lab13;

import android.content.Context;
import android.net.Uri;
import android.content.ContentResolver;
import org.json.JSONObject;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.*;
import java.util.zip.*;

/** User-triggered Android SAF ZIP import. DOES NOT prove NML runtime compatibility. */
final class ExternalModImporterV32 {
    private static final long MAX_ZIP=48L*1024*1024,MAX_EXPANDED=128L*1024*1024;
    private static final int MAX_FILES=1200,MAX_MODS_PER_ZIP=12;
    static final class Result {
        final String id,layout,target;
        Result(String id,String layout,String target){this.id=id;this.layout=layout;this.target=target;}
    }
    private static String segment(String name)throws IOException {
        if(name==null||!name.matches("[A-Za-z0-9_.-]{1,80}")||name.equals(".")||name.equals(".."))
            throw new IOException("不安全的模组目录名："+name);
        return name;
    }
    static String safeEntry(String value)throws IOException {
        if(value==null||value.length()>240||value.startsWith("/")||value.contains("\\")||
           value.indexOf('\u0000')>=0||value.matches("^[A-Za-z]:.*"))
            throw new IOException("ZIP路径格式不安全");
        String[] parts=value.split("/",-1);
        for(int i=0;i<parts.length;i++)
            if(parts[i].equals(".")||parts[i].equals("..")||
               (parts[i].isEmpty()&&i<parts.length-1))
                throw new IOException("ZIP目录穿越被阻止");
        return value;
    }
    static String digest(byte[] bytes)throws Exception{
        byte[] hash=MessageDigest.getInstance("SHA-256").digest(bytes);
        StringBuilder out=new StringBuilder();
        for(byte b:hash)out.append(String.format(Locale.US,"%02x",b&255));
        return out.toString();
    }
    private static void copyLimited(InputStream in,File out,long limit)throws Exception {
        try(FileOutputStream dst=new FileOutputStream(out)){
            long count=0;
            byte[] buffer=new byte[32768];int len;
            while((len=in.read(buffer))!=-1){
                count+=len;if(count>limit)throw new IOException("MOD压缩包超出大小限制");
                dst.write(buffer,0,len);
            }
            dst.getFD().sync();
        }
    }
    private static void removeTree(File path){
        if(path.isDirectory()){
            File[] children=path.listFiles();
            if(children!=null)for(File child:children)removeTree(child);
        }
        path.delete();
    }
    static List<Result> importZip(Context context,Uri uri)throws Exception{
        ContentResolver resolver=context.getContentResolver();
        File temp=File.createTempFile("selected-", ".zip",context.getCacheDir());
        try{
            try(InputStream stream=resolver.openInputStream(uri)){
                if(stream==null)throw new IOException("无法读取所选ZIP");
                copyLimited(stream,temp,MAX_ZIP);
            }
            try(ZipFile archive=new ZipFile(temp)){
                ArrayList<? extends ZipEntry> entries=Collections.list(archive.entries());
                if(entries.isEmpty()||entries.size()>MAX_FILES)throw new IOException("MOD文件数量超限");
                Map<String,ZipEntry> all=new LinkedHashMap<>();
                long expanded=0;
                for(ZipEntry entry:entries){
                    String name=safeEntry(entry.getName());
                    if(all.put(name,entry)!=null)throw new IOException("MOD包存在重复文件："+name);
                    if(entry.isDirectory())continue;
                    if(entry.getSize()<0 || entry.getSize()>MAX_EXPANDED)
                        throw new IOException("MOD条目大小不明或异常："+name);
                    expanded+=entry.getSize();
                    if(expanded>MAX_EXPANDED)throw new IOException("MOD解压后总体积超过128MB");
                    if(name.endsWith(".apk")||name.endsWith(".dex")||name.endsWith(".so"))
                        throw new IOException("拒绝安装携带安卓原生可执行文件的MOD："+name);
                }
                List<String> manifests=new ArrayList<>();
                for(String name:all.keySet()){
                    if(name.endsWith("mod.json")&&!all.get(name).isDirectory() &&
                      (name.equals("mod.json")||name.endsWith("/mod.json")))
                        manifests.add(name);
                }
                if(manifests.size()==0||manifests.size()>MAX_MODS_PER_ZIP)
                    throw new IOException("未找到有效mod.json，或单包超过12个MOD");
                // Reject ambiguous nested module prefixes; never install half of an archive.
                for(String a:manifests)for(String b:manifests)
                    if(!a.equals(b)&&b.startsWith(a.substring(0,a.length()-8)))
                        throw new IOException("MOD嵌套目录有冲突");
                ArrayList<Result> result=new ArrayList<>();
                ArrayList<File> temporary=new ArrayList<>(),targets=new ArrayList<>();
                try {
                    for(String path:manifests){
                        String prefix=path.substring(0,path.length()-8);
                        ZipEntry meta=all.get(path);
                        if(meta.getSize()>64*1024)throw new IOException("模组描述超过64KB");
                        ByteArrayOutputStream buf=new ByteArrayOutputStream();
                        try(InputStream m=archive.getInputStream(meta)){
                            byte[] chunk=new byte[4096];int n;
                            while((n=m.read(chunk))!=-1){buf.write(chunk,0,n);if(buf.size()>64*1024)
                                throw new IOException("描述文件体积不正常");}
                        }
                        JSONObject desc=new JSONObject(buf.toString("UTF-8"));
                        int type=desc.optInt("ModType",-1);
                        if(type!=0&&type!=1)throw new IOException("仅支持ModType 0/1，实际："+type);
                        String candidate=prefix.replaceAll("/+$","");
                        int slash=candidate.lastIndexOf('/');
                        if(slash>=0)candidate=candidate.substring(slash+1);
                        if(candidate.isEmpty())candidate=desc.optString("GUID",desc.optString("name",""));
                        // Stable sanitized name: never trust ZIP entry as a filesystem target.
                        String modId=segment(candidate);
                        File appRoot=context.getExternalFilesDir(null);
                        if(appRoot==null)throw new IOException("外部应用专用目录不存在");
                        File parent=type==0?new File(appRoot.getParentFile(),"Mods"):
                            new File(appRoot,"mods");
                        if(!parent.isDirectory()&&!parent.mkdirs())throw new IOException("MOD安装目录不可写");
                        File dest=new File(parent,modId).getCanonicalFile();
                        if(!dest.getParentFile().equals(parent.getCanonicalFile()))
                            throw new IOException("目标文件越界");
                        if(dest.exists())throw new IOException("已安装同名MOD："+modId+"，禁止静默覆盖");
                        File staging=new File(parent,".import-"+System.nanoTime()+"-"+modId);
                        if(!staging.mkdir())throw new IOException("无法建立安装暂存目录");
                        temporary.add(staging);
                        long written=0;int fileCount=0;
                        for(Map.Entry<String,ZipEntry> kv:all.entrySet()){
                            if(!kv.getKey().startsWith(prefix))continue;
                            String rel=kv.getKey().substring(prefix.length());
                            if(rel.isEmpty()||kv.getValue().isDirectory())continue;
                            safeEntry(rel);
                            if(++fileCount>MAX_FILES)throw new IOException("MOD文件数超限");
                            File file=new File(staging,rel).getCanonicalFile();
                            if(!file.getPath().startsWith(staging.getCanonicalPath()+File.separator))
                                throw new IOException("MOD路径越界");
                            if(!file.getParentFile().isDirectory()&&!file.getParentFile().mkdirs())
                                throw new IOException("无法创建MOD子目录");
                            try(InputStream in=archive.getInputStream(kv.getValue());
                                FileOutputStream out=new FileOutputStream(file)){
                                byte[] chunk=new byte[32768];int n;long entryWritten=0;
                                while((n=in.read(chunk))!=-1){
                                    entryWritten+=n;written+=n;
                                    if(entryWritten>kv.getValue().getSize()||written>MAX_EXPANDED)
                                        throw new IOException("MOD压缩包内容超过声明大小");
                                    out.write(chunk,0,n);
                                }
                                if(entryWritten!=kv.getValue().getSize())
                                    throw new IOException("MOD文件大小校验失败");
                                out.getFD().sync();
                            }
                        }
                        if(!new File(staging,"mod.json").isFile())
                            throw new IOException("MOD结构缺失描述文件");
                        targets.add(dest);
                        result.add(new Result(modId,type==0?"传统Mono":"移动NML",
                            dest.getAbsolutePath()));
                    }
                    for(File t:targets)if(t.exists())throw new IOException("安装前发现目标MOD已经存在");
                    ArrayList<File> installed=new ArrayList<>();
                    try{
                        for(int i=0;i<temporary.size();i++){
                            if(!temporary.get(i).renameTo(targets.get(i)))
                                throw new IOException("MOD移动到加载目录失败");
                            installed.add(targets.get(i));
                        }
                    }catch(Exception ex){for(File f:installed)removeTree(f);throw ex;}
                    temporary.clear();
                    return result;
                }finally{for(File path:temporary)removeTree(path);}
            }
        }finally{temp.delete();}
    }
}
