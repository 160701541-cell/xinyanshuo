package com.xinyanshuo.worldbox.lab13;

import java.io.File;
import java.nio.file.Files;
import java.security.MessageDigest;
import java.util.Locale;

public final class OwnedModSourceCleanupV44Test {
    static void check(boolean ok,String why){if(!ok)throw new AssertionError(why);}
    static String hash(byte[] data)throws Exception{
        byte[] dig=MessageDigest.getInstance("SHA-256").digest(data);
        StringBuilder s=new StringBuilder();
        for(byte b:dig)s.append(String.format(Locale.ROOT,"%02x",b&255));
        return s.toString();
    }
    public static void main(String[] args)throws Exception {
        File root=Files.createTempDirectory("wb-v44-owner-only-").toFile();
        File dir=new File(root,"Mods/WorldBoxXianxiaObserver/Code");
        check(dir.mkdirs(),"create own test folder");
        String filename="Mods/WorldBoxXianxiaObserver/Code/ObserverFrameGuardV12.cs";
        File path=new File(root,filename);
        byte[] baseline="v42-original".getBytes("UTF-8");
        Files.write(path.toPath(),baseline);
        check(!OwnedModSourceCleanupV44.removeOriginal(root,filename,hash("modified".getBytes("UTF-8"))),
          "different hash must preserve user edits");
        check(path.isFile(),"preserve edited/unknown file");
        check(OwnedModSourceCleanupV44.removeOriginal(root,filename,hash(baseline)),
          "matches original only then remove");
        check(!path.exists(),"verified old source deleted");
        File other=new File(root,"Mods/OtherMod/Code/Gameplay.cs");
        check(other.getParentFile().mkdirs(),"create another MOD folder");
        Files.write(other.toPath(),baseline);
        boolean denied=false;
        try{OwnedModSourceCleanupV44.removeOriginal(root,"Mods/OtherMod/Code/Gameplay.cs",hash(baseline));}
        catch(java.io.IOException ok){denied=true;}
        check(denied&&other.isFile(),"other MOD must never be deleted");
        denied=false;
        try{OwnedModSourceCleanupV44.removeOriginal(root,
          "Mods/WorldBoxXianxiaObserver/Code/../../../../private.cs",hash(baseline));}
        catch(java.io.IOException ok){denied=true;}
        check(denied,"disallow traversal in pruning manifest");
        System.out.println("PASS_V44_SHA256_PROTECTED_OWNED_OBSERVER_MIGRATION");
    }
}
