package com.xinyanshuo.worldbox.lab13;
import java.io.*;
import java.util.*;
import java.util.zip.*;

public final class ModFormatV34Test {
    static void check(boolean ok,String message) {
        if(!ok)throw new AssertionError(message);
    }
    static Set<String> synthetic(String... names)throws Exception {
        ByteArrayOutputStream bytes=new ByteArrayOutputStream();
        try(ZipOutputStream out=new ZipOutputStream(bytes)){
            for(String name:names) {
                out.putNextEntry(new ZipEntry(name));
                out.write("synthetic".getBytes("UTF-8"));
                out.closeEntry();
            }
        }
        Set<String> result=new LinkedHashSet<>();
        File temp=File.createTempFile("wb-format",".zip");
        try{
            try(FileOutputStream o=new FileOutputStream(temp)){o.write(bytes.toByteArray());}
            try(ZipFile zip=new ZipFile(temp)){
                for(Enumeration<? extends ZipEntry> en=zip.entries();en.hasMoreElements();)
                    result.add(en.nextElement().getName());
            }
        }finally{temp.delete();}
        return result;
    }
    public static void main(String[] args)throws Exception {
        Set<String> chinese=synthetic("ChineseName_1.5.1/mod.json",
            "ChineseName_1.5.1/Code/ModClass.cs",
            "ChineseName_1.5.1/Code/Patches/CityNamePatch.cs");
        check(ModFormatV34.infer("ChineseName_1.5.1/",chinese)==0,
            "actual ChineseName ZIP without ModType must recognize Mono source");
        Set<String> nml=synthetic("NMLMods/Observer/mod.json",
            "NMLMods/Observer/Observer.dll","NMLMods/Observer/Locales/cz.json");
        check(ModFormatV34.infer("NMLMods/Observer/",nml)==1,
            "mobile NML precompiled format inferred");
        Set<String> generic=synthetic("mod.json","Demo.dll");
        check(ModFormatV34.infer("",generic)==1,"bare compiled MOD with manifest inferred");
        Set<String> desktop=synthetic("BepInEx/plugins/old.dll");
        boolean rejected=false;
        try{ModFormatV34.infer("",desktop);}catch(IOException expected){rejected=true;}
        check(rejected,"desktop BepInEx is not Android NeoModLoader");
        System.out.println("PASS_V34_REAL_MODTYPE_MISSING_AND_NML_LAYOUT");
    }
}
