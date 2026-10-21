package com.xinyanshuo.xianfan.nativeapp;

/**
 * 本地推理桥。JNI 库没编进包时 available()=false，调用方自动回落模板对白。
 * 这样「下载了模型但 JNI 还没编译」也不会崩，更不会假装会生成。
 */
public final class LlmBridge {
    private static boolean loaded = false;

    static {
        try {
            System.loadLibrary("xf_llm");
            loaded = true;
        } catch (Throwable ignored) {
            loaded = false;
        }
    }

    public static boolean available() { return loaded; }

    /** 没装 JNI 时恒返回 null；装了之后由 native 端实现 */
    public static String generate(String modelPath, String prompt) {
        if (!loaded) return null;
        try {
            return nativeGenerate(modelPath, prompt, 160);
        } catch (Throwable e) {
            return null;
        }
    }

    private static native String nativeGenerate(String modelPath, String prompt, int maxTokens);
}
