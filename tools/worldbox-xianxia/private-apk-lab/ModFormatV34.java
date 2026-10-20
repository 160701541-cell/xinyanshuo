package com.xinyanshuo.worldbox.lab13;
import java.io.IOException;
import java.util.Collection;
import java.util.Locale;

/** Shared pure-JVM layout detector for WorldBox 0.51.4 source and mobile NML MOD ZIPs.
    A desktop BepInEx/Civilization ZIP is not silently installed. */
final class ModFormatV34 {
    static int infer(String prefix,Collection<String> paths)throws IOException {
        String dir=prefix.toLowerCase(Locale.ROOT);
        if(dir.startsWith("nmlmods/")||dir.contains("/nmlmods/"))return 1;
        if(dir.startsWith("mods/")||dir.contains("/mods/"))return 0;
        boolean source=false,compiled=false;
        for(String file:paths) {
            if(!file.startsWith(prefix))continue;
            String rel=file.substring(prefix.length()).toLowerCase(Locale.ROOT);
            if(rel.startsWith("code/")&&rel.endsWith(".cs"))source=true;
            if(rel.endsWith(".dll")&&rel.indexOf('/')<0)compiled=true;
        }
        if(source)return 0;
        if(compiled)return 1;
        throw new IOException("该MOD没有ModType，也没有可识别的Code/*.cs或NML DLL，可能是旧桌面MOD");
    }
}
