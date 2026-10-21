package com.xinyanshuo.worldbox.lab13;

import java.io.IOException;
import java.util.ArrayList;

/** WorldBox v0.42 ZIP entry policy: tolerate safe archive layouts while
 * always rejecting Zip Slip, rooted drives/UNC paths, controls and collisions.
 * Does not grant any MOD permission or promise executable compatibility. */
final class SafeZipPathsV42 {
    static String normalize(String input) throws IOException {
        if(input==null || input.length()==0 || input.length()>500)
            throw new IOException("ZIP条目路径为空或过长");
        if(input.charAt(0)=='/' || input.charAt(0)=='\\' ||
           input.matches("(?i)^[A-Z]:.*"))
            throw new IOException("ZIP包含绝对路径（已阻止）：" + brief(input));
        if(input.indexOf('\u0000')>=0)
            throw new IOException("ZIP包含空字符（已阻止）");
        String unix=input.replace('\\','/');
        boolean directory=unix.endsWith("/");
        String[] parts=unix.split("/",-1);
        ArrayList<String> safe=new ArrayList<String>();
        for(String part:parts) {
            if(part.isEmpty() || part.equals("."))continue;
            if(part.equals(".."))
                throw new IOException("ZIP目录穿越 '..'（已阻止）：" + brief(input));
            if(part.length()>120 || part.indexOf(':')>=0)
                throw new IOException("ZIP包含不安全路径组件：" + brief(input));
            for(int i=0;i<part.length();i++)
                if(Character.isISOControl(part.charAt(i)))
                    throw new IOException("ZIP包含控制字符：" + brief(input));
            safe.add(part);
        }
        if(safe.isEmpty())throw new IOException("ZIP条目无文件名");
        StringBuilder full=new StringBuilder();
        for(String part:safe) {
            if(full.length()>0)full.append('/');
            full.append(part);
        }
        if(directory)full.append('/');
        if(full.length()>240)throw new IOException("ZIP标准化路径超过240字符");
        return full.toString();
    }
    private static String brief(String raw) {
        String cleaned=raw.replace('\n',' ').replace('\r',' ').replace('\t',' ');
        return cleaned.length()<=95?cleaned:cleaned.substring(0,95)+"…";
    }
    private SafeZipPathsV42(){}
}
