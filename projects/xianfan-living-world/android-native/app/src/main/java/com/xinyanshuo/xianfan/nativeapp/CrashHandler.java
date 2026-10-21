package com.xinyanshuo.xianfan.nativeapp;

import android.content.Context;
import android.os.Build;

import java.io.File;
import java.io.FileOutputStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/**
 * 精准报错：把崩溃栈、时间、机型、最后几步操作写成一个 txt。
 * 下次启动时弹出来，一键复制（含 文件:行号），不用再猜"闪退在哪"。
 */
public final class CrashHandler implements Thread.UncaughtExceptionHandler {
    public static final String FILE = "crash-last.txt";
    private final Context ctx;
    private final Thread.UncaughtExceptionHandler prev;
    private static CrashHandler current;
    private Sim sim;

    public CrashHandler(Context ctx, Sim sim) {
        this.ctx = ctx.getApplicationContext();
        this.sim = sim;
        this.prev = Thread.getDefaultUncaughtExceptionHandler();
    }

    public void install() { current = this; Thread.setDefaultUncaughtExceptionHandler(this); }

    public void setSim(Sim s) { this.sim = s; }

    public static void setSimLater(Sim s) { if (current != null) current.sim = s; }

    @Override public void uncaughtException(Thread t, Throwable e) {
        try { write(t, e); } catch (Throwable ignored) { }
        if (prev != null) prev.uncaughtException(t, e);
    }

    /** 启动阶段打点：闪退在很早期也能知道走到哪一步 */
    private static final StringBuilder STAGE = new StringBuilder();
    public static void stage(String s) {
        STAGE.append(new SimpleDateFormat("HH:mm:ss", Locale.CHINA).format(new Date())).append(' ').append(s).append('\n');
    }

    private void write(Thread t, Throwable e) throws Exception {
        StringWriter sw = new StringWriter();
        PrintWriter pw = new PrintWriter(sw);
        e.printStackTrace(pw);
        pw.flush();
        StringBuilder b = new StringBuilder();
        b.append("时间　").append(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.CHINA).format(new Date())).append('\n');
        b.append("线程　").append(t.getName()).append('\n');
        b.append("机型　").append(Build.MANUFACTURER).append(' ').append(Build.MODEL)
         .append(" · Android ").append(Build.VERSION.RELEASE).append(" (API ").append(Build.VERSION.SDK_INT).append(")\n");
        String ver = "?", code = "?";
        try {
            android.content.pm.PackageInfo pi = ctx.getPackageManager().getPackageInfo(ctx.getPackageName(), 0);
            ver = pi.versionName;
            code = String.valueOf(pi.getLongVersionCode());
        } catch (Exception ignored) { }
        b.append("版本　").append(ver).append(" (").append(code).append(")\n");
        if (sim != null) b.append("现场　").append(sim.debugState()).append('\n');
        if (STAGE.length() > 0) b.append("\n--- 启动阶段 ---\n").append(STAGE);
        b.append("\n--- 最近操作 ---\n");
        if (sim != null) for (String s : sim.recentActions(12)) b.append(s).append('\n');
        b.append("\n--- 堆栈（第一行就是出错位置）---\n").append(sw);
        byte[] bytes = b.toString().getBytes("UTF-8");
        // 两份：应用私有目录 + 外部目录（后者插上电脑或文件管理器就能拿到，不需要 root）
        try (FileOutputStream out = new FileOutputStream(new File(ctx.getFilesDir(), FILE))) {
            out.write(bytes);
        }
        try {
            File ext = ctx.getExternalFilesDir(null);
            if (ext != null) {
                //noinspection ResultOfMethodCallIgnored
                ext.mkdirs();
                try (FileOutputStream out = new FileOutputStream(new File(ext, FILE))) { out.write(bytes); }
            }
        } catch (Throwable ignored) { }
    }

    public static String externalPath(Context ctx) {
        File ext = ctx.getExternalFilesDir(null);
        return ext == null ? "（外部目录不可用）" : new File(ext, FILE).getAbsolutePath();
    }

    public static String read(Context ctx) {
        try {
            File f = new File(ctx.getFilesDir(), FILE);
            if (!f.exists()) return null;
            byte[] buf = new byte[(int) f.length()];
            java.io.FileInputStream in = new java.io.FileInputStream(f);
            int n = in.read(buf);
            in.close();
            return new String(buf, 0, Math.max(0, n), "UTF-8");
        } catch (Exception e) { return null; }
    }

    public static void clear(Context ctx) {
        File f = new File(ctx.getFilesDir(), FILE);
        if (f.exists()) //noinspection ResultOfMethodCallIgnored
            f.delete();
    }
}
