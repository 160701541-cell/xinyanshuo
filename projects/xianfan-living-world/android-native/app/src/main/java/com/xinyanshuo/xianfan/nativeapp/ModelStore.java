package com.xinyanshuo.xianfan.nativeapp;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.RandomAccessFile;
import java.net.HttpURLConnection;
import java.net.URL;

/**
 * 本地模型：首次启动按需下载 GGUF，落到 files/models/。
 * 只负责「取到文件」；推理在 LlmBridge 里，取不到模型就回落模板对白。
 */
public final class ModelStore {
    public static final String DEFAULT_URL =
        "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf";
    public static final long EXPECT_BYTES = 398_000_000L;   // 约 398 MB
    public static final String FILE = "qwen05-q4_k_m.gguf";

    public volatile boolean downloading = false;
    public volatile int percent = 0;
    public volatile String error = null;
    private final Context ctx;
    private final Handler ui = new Handler(Looper.getMainLooper());

    public ModelStore(Context ctx) { this.ctx = ctx.getApplicationContext(); }

    public File file() {
        File dir = new File(ctx.getFilesDir(), "models");
        //noinspection ResultOfMethodCallIgnored
        dir.mkdirs();
        return new File(dir, FILE);
    }

    public boolean ready() {
        File f = file();
        return f.exists() && f.length() > EXPECT_BYTES * 0.9;
    }

    /** 断点续传：已有部分就带 Range 接着下 */
    public void download(String url, Runnable onDone) {
        if (downloading) return;
        downloading = true; error = null; percent = 0;
        new Thread(() -> {
            HttpURLConnection conn = null;
            try {
                File f = file();
                long have = f.exists() ? f.length() : 0;
                conn = (HttpURLConnection) new URL(url).openConnection();
                conn.setConnectTimeout(20000);
                conn.setReadTimeout(30000);
                conn.setRequestProperty("User-Agent", "xianfan-native");
                if (have > 0) conn.setRequestProperty("Range", "bytes=" + have + "-");
                conn.connect();
                int code = conn.getResponseCode();
                if (code / 100 != 2) throw new IllegalStateException("HTTP " + code);
                long total = conn.getContentLengthLong() + have;
                InputStream in = conn.getInputStream();
                FileOutputStream out = new FileOutputStream(f, have > 0);
                byte[] buf = new byte[64 * 1024];
                long got = have, last = 0;
                int n;
                while ((n = in.read(buf)) > 0) {
                    out.write(buf, 0, n);
                    got += n;
                    if (got - last > 2_000_000L) {
                        last = got;
                        final int p = (int) Math.min(100, got * 100 / Math.max(1, total));
                        ui.post(() -> percent = p);
                    }
                }
                out.close(); in.close();
                percent = 100;
                ui.post(onDone);
            } catch (Exception e) {
                error = e.getClass().getSimpleName() + ": " + e.getMessage();
            } finally {
                downloading = false;
                if (conn != null) conn.disconnect();
            }
        }, "model-download").start();
    }

    /** 模型文件大小（MB），给设置页显示 */
    public String sizeText() {
        File f = file();
        if (!f.exists()) return "未下载";
        return String.format("%.0f MB", f.length() / 1048576.0);
    }
}
