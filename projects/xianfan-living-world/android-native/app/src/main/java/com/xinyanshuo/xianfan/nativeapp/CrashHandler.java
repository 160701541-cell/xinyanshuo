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
    private final Sim sim;

    public CrashHandler(Context ctx, Sim sim) {
        this.ctx = ctx.getApplicationContext();
        this.sim = sim;
        this.prev = Thread.getDefaultUncaughtExceptionHandler();
    }

    public void install() { Thread.setDefaultUncaughtExceptionHandler(this); }

    @Override public void uncaughtException(Thread t, Throwable e) {
        try { write(t, e); } catch (Throwable ignored) { }
        if (prev != null) prev.uncaughtException(t, e);
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
        b.append("\n--- 最近操作 ---\n");
        if (sim != null) for (String s : sim.recentActions(12)) b.append(s).append('\n');
        b.append("\n--- 堆栈（第一行就是出错位置）---\n").append(sw);
        File f = new File(ctx.getFilesDir(), FILE);
        try (FileOutputStream out = new FileOutputStream(f)) {
            out.write(b.toString().getBytes("UTF-8"));
        }
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
