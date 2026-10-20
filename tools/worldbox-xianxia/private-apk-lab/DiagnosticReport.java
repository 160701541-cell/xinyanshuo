package com.xinyanshuo.worldbox.lab13;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.zip.*;

/** Diagnostic export only: no world/save files are read or modified. */
final class DiagnosticReport {
    static final int COPY_LIMIT=6000;
    private DiagnosticReport() {}

    static String summary(String header,File[] files,String[] names) {
        StringBuilder out=new StringBuilder(header);
        out.append("\n这是关键错误摘要，完整堆栈请导出日志ZIP。\n");
        for(int i=0;i<files.length;i++) {
            out.append("\n=== ").append(names[i]).append(" ===\n");
            File file=files[i];
            if(file==null||!file.isFile()){out.append("(暂无记录)\n");continue;}
            LinkedHashSet<String> first=new LinkedHashSet<String>();
            ArrayDeque<String> recent=new ArrayDeque<String>();
            int missing=0;String build=null;
            try(BufferedReader reader=new BufferedReader(new InputStreamReader(
                    new FileInputStream(file),StandardCharsets.UTF_8))) {
                String line; int context=0;
                while((line=reader.readLine())!=null) {
                    if(line.contains("missing text:")){missing++;context=0;continue;}
                    if(line.contains("MOD_DEPLOY_OK")||line.contains("MOD_DEPLOY_CACHED"))build=shortLine(line);
                    String lower=line.toLowerCase(Locale.ROOT);
                    boolean error=lower.contains("exception")||lower.contains("failed")||
                        lower.contains("error cs")||lower.contains("error:")||lower.contains("fatal");
                    boolean state=line.contains("LOADED_ENTRY")||line.contains("NML_ACTUALLY_LOADED_COUNT")||
                        line.contains("initialized_successfully")||line.contains("INIT_BEGIN")||
                        line.contains("SOURCE_ONLY_LOAD")||line.contains("CULTIVATION_READY")||
                        line.contains("[XIANXIA-V18] ACTION")||line.contains("STYLE_COPY_UNAVAILABLE");
                    if(error||state||context>0) {
                        String item=shortLine(line);
                        if(error&&first.size()<4)first.add(item);
                        if(!item.trim().isEmpty()) {
                            if(recent.size()>=8)recent.removeFirst();
                            recent.addLast(item);
                        }
                        if(error)context=4;else if(context>0)context--;
                    }
                }
            } catch(IOException e){out.append("读取失败：").append(e.toString()).append("\n");}
            if(build!=null)out.append(build).append("\n");
            for(String line:first)out.append(line).append("\n");
            for(String line:recent)if(!first.contains(line))out.append(line).append("\n");
            if(missing>0)out.append("重复缺词记录：").append(missing).append("条（原文保存在ZIP）\n");
        }
        String text=out.toString();
        if(text.length()<=COPY_LIMIT)return text;
        return text.substring(0,COPY_LIMIT-60)+"\n[摘要达到长度上限，完整错误及原始日志请导出ZIP]\n";
    }
    private static String shortLine(String line) {
        return line.length()>220?line.substring(0,220)+"…":line;
    }
    static void zip(OutputStream stream,String header,File[] files,String[] names)throws IOException {
        try(ZipOutputStream zip=new ZipOutputStream(stream,StandardCharsets.UTF_8)) {
            zip.putNextEntry(new ZipEntry("summary.txt"));
            zip.write(summary(header,files,names).getBytes(StandardCharsets.UTF_8));
            zip.closeEntry();
            byte[] buffer=new byte[65536];
            for(int i=0;i<files.length;i++) {
                File file=files[i];
                if(file==null||!file.isFile())continue;
                // Archive fixed diagnostic names only, never absolute device paths.
                String name=names[i];
                if(!name.matches("[A-Za-z0-9_.-]+"))throw new IOException("Invalid diagnostic filename");
                zip.putNextEntry(new ZipEntry(name));
                try(InputStream in=new FileInputStream(file)) {
                    int n;while((n=in.read(buffer))!=-1)zip.write(buffer,0,n);
                }
                zip.closeEntry();
            }
        }
    }
}
