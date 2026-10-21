package com.xinyanshuo.worldbox.lab13;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.security.MessageDigest;
import java.util.Locale;

/** Delete ONLY exactly-matching historical files from OUR old observer source
 * folder after transitioning its own ModType=1 module. Never touch unknown,
 * edited, other third-party or player data. */
final class OwnedModSourceCleanupV44 {
    static boolean removeOriginal(File appRoot,String target,String expectedSha) throws Exception {
        if(target==null || !target.matches(
          "Mods/WorldBoxXianxiaObserver/Code/[A-Za-z0-9_.-]{1,80}\\.cs"))
            throw new IOException("拒绝删除不属于本项目的文件");
        if(expectedSha==null || !expectedSha.matches("[0-9a-f]{64}"))
            throw new IOException("拒绝没有原始SHA256的清理条目");
        File canonicalRoot=appRoot.getCanonicalFile();
        File folder=new File(canonicalRoot,"Mods/WorldBoxXianxiaObserver/Code").getCanonicalFile();
        File victim=new File(canonicalRoot,target).getCanonicalFile();
        if(!victim.getParentFile().equals(folder))throw new IOException("禁止越界清理");
        if(!victim.isFile())return false;
        if(victim.length()>2*1024*1024)return false;
        MessageDigest digest=MessageDigest.getInstance("SHA-256");
        try(FileInputStream in=new FileInputStream(victim)){
            byte[] buf=new byte[32768];int read;
            while((read=in.read(buf))!=-1)digest.update(buf,0,read);
        }
        StringBuilder hex=new StringBuilder();
        for(byte x:digest.digest())hex.append(String.format(Locale.ROOT,"%02x",x&0xff));
        if(!expectedSha.equals(hex.toString()))return false;
        if(!victim.delete())throw new IOException("无法移除本项目旧版本源码："+victim.getName());
        return true;
    }
    private OwnedModSourceCleanupV44(){}
}
