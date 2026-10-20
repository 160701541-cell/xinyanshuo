package com.xinyanshuo.worldbox.lab13;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;
import java.util.zip.*;

public final class DiagnosticReportScenario {
    static void check(boolean ok,String why){if(!ok)throw new AssertionError(why);}
    public static void main(String[] args)throws Exception {
        Path dir=Files.createTempDirectory("worldbox-diagnostic-test");
        try {
            File boot=dir.resolve("boot.log").toFile(), session=dir.resolve("session.log").toFile();
            StringBuilder raw=new StringBuilder("FIRST_LOG_BYTE\nException EARLY_OBSERVER_COMPILE_FAILED\n");
            raw.append("  at XianxiaObserverV07.OnModLoad\n");
            for(int i=0;i<12000;i++)raw.append("LocalizedTextManager: missing text: sakuga_title_测试_"+i+"\n");
            raw.append("Warning System.DllNotFoundException: libsteam_api\n");
            raw.append("Log System.Exception: Steam is not available\n");
            raw.append("NML_STAGE initialized_successfully=True\n");
            raw.append("MOD_STATE XINYANSHUO_WORLD_BOX_OBSERVER_V07=FAILED reason=\n");
            raw.append("USER_MOD_IMPORT_BEGIN name=中文名模组.zip\n");
            raw.append("USER_MOD_IMPORT_FAILED name=中文名模组.zip java.util.zip.ZipException: zip END header not found\n");
            raw.append("LAST_LOG_BYTE\n");
            byte[] bytes=raw.toString().getBytes(StandardCharsets.UTF_8);
            Files.write(session.toPath(),bytes);
            Files.write(boot.toPath(),"MOD_DEPLOY_CACHED v28-zh-TEST\n".getBytes(StandardCharsets.UTF_8));
            Files.write(dir.resolve("world-save.json"),"PRIVATE_SAVE_MUST_NOT_EXPORT".getBytes(StandardCharsets.UTF_8));
            File[] files={boot,session,dir.resolve("absent.log").toFile()};
            String[] names={"android_current.log","unity_current.log","unity_previous.log"};
            String summary=DiagnosticReport.summary("设备：安卓16",files,names);
            check(summary.length()<=DiagnosticReport.COPY_LIMIT,"clipboard bounded");
            check(summary.contains("EARLY_OBSERVER_COMPILE_FAILED"),"first failure must survive noise");
            check(summary.contains("=FAILED"),"latest failure retained");
            check(summary.contains("万界观察MOD最近状态"),"observer FAILED visible even without reason");
            check(summary.contains("NML加载器最近状态"),"NML initialized separately from failed observer");
            check(summary.contains("最后ZIP导入记录"),"filename and failing ZIP shown");
            check(summary.contains("zip END header not found"),"corrupt archive diagnosis retained");
            check(summary.contains("已折叠安卓Steam缺库警告"),"desktop Steam warning not top fatal");
            check(!summary.contains("Steam is not available"),"Steam warning must not hide relevant loader error");
            check(summary.contains("12000"),"missing text count retained");
            check(!summary.contains("sakuga_title_测试_"),"noise is aggregated");
            check(summary.contains("v28-zh-TEST"),"deployment build visible");
            ByteArrayOutputStream out=new ByteArrayOutputStream();
            DiagnosticReport.zip(out,"设备：安卓16",files,names);
            HashMap<String,byte[]> entries=new HashMap<String,byte[]>();
            try(ZipInputStream zip=new ZipInputStream(new ByteArrayInputStream(out.toByteArray()),StandardCharsets.UTF_8)){
                ZipEntry e;byte[] buf=new byte[4096];
                while((e=zip.getNextEntry())!=null){
                    ByteArrayOutputStream b=new ByteArrayOutputStream();int n;
                    while((n=zip.read(buf))!=-1)b.write(buf,0,n);
                    entries.put(e.getName(),b.toByteArray());
                }
            }
            check(entries.size()==3,"only summary and existing diagnostic files");
            check(Arrays.equals(entries.get("unity_current.log"),bytes),"entire original bytes, no 60KB/180KB truncation");
            check(Arrays.equals(Files.readAllBytes(session.toPath()),bytes),"source log untouched");
            check(!entries.containsKey("world-save.json"),"saves excluded");
            check(new String(entries.get("summary.txt"),StandardCharsets.UTF_8).contains("EARLY_OBSERVER_COMPILE_FAILED"),"ZIP includes readable summary");
            File[] absent={dir.resolve("absent.log").toFile()};
            check(DiagnosticReport.summary("设备",absent,new String[]{"missing.log"}).contains("暂无记录"),"missing logs handled");
            System.out.println("PASS_DIAGNOSTIC_EXPORT: bounded summary, early failure, noise count, complete UTF-8 ZIP, logs unchanged, saves excluded");
        } finally {
            try(java.util.stream.Stream<Path> paths=Files.walk(dir)){
                paths.sorted(Comparator.reverseOrder()).forEach(p->{try{Files.delete(p);}catch(IOException e){throw new UncheckedIOException(e);}});
            }
        }
    }
}
