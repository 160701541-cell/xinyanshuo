package com.xinyanshuo.zhiyin;

/** JNI for built-in llama.cpp Android CPU GGUF inference. Model bytes are not bundled in APK. */
public final class NativeLlm {
  public static final boolean SUPPORTED;
  static {
    boolean available;
    try { System.loadLibrary("zhiyin_llm"); available=true; }
    catch (UnsatisfiedLinkError | SecurityException err) { available=false; }
    SUPPORTED=available;
  }
  private NativeLlm(){}
  public static native boolean load(String modelPath, int context);
  public static native String generate(String prompt,int maxTokens);
  public static native void unload();
  public static native String lastError();
}
