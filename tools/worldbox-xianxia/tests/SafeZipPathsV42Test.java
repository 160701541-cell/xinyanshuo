package com.xinyanshuo.worldbox.lab13;
import java.io.IOException;
public final class SafeZipPathsV42Test {
    static void eq(String a,String b) {if(!a.equals(b))throw new AssertionError(a+" != "+b);}
    static void rejects(String name) {
        try {SafeZipPathsV42.normalize(name);}
        catch(IOException expected){return;}
        throw new AssertionError("dangerous path accepted: "+name);
    }
    public static void main(String[] args)throws Exception {
        eq(SafeZipPathsV42.normalize("./凡人修仙传\\Code\\修仙.cs"),"凡人修仙传/Code/修仙.cs");
        eq(SafeZipPathsV42.normalize("pack//Code///Main.cs"),"pack/Code/Main.cs");
        eq(SafeZipPathsV42.normalize("pack/./mod.json"),"pack/mod.json");
        eq(SafeZipPathsV42.normalize("mod.json"),"mod.json");
        eq(SafeZipPathsV42.normalize("合法材料\\icon.png"),"合法材料/icon.png");
        eq(SafeZipPathsV42.normalize("Modules\\"),"Modules/");
        rejects("../secrets");rejects("a/../../a");rejects("/private/mod.json");
        rejects("\\\\windows\\share\\evil.dll");rejects("C:\\Windows\\evil");
        rejects("C:/Windows/a");rejects("a/\u0000/b");rejects("x/\n/code.cs");
        rejects("a:b/code.cs");
        System.out.println("PASS_V42_SAFE_ZIP_NORMALIZATION AND ZIP_SLIP_BLOCKED");
    }
}
