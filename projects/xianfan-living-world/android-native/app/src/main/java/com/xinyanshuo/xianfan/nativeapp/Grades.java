package com.xinyanshuo.xianfan.nativeapp;

/** 品阶：凡品/下品/中品/上品/极品，价格与战力都乘这个系数。 */
public final class Grades {
    public static final String[] IDS = {"mortal", "low", "mid", "high", "peak"};
    public static final String[] NAMES = {"凡品", "下品", "中品", "上品", "极品"};
    public static final double[] MULT = {1.0, 1.6, 2.8, 5.2, 11.0};
    /** 粗制品出货：下 55% / 中 30% / 上 12% / 极 3% */
    public static final double[] CUM = {0.55, 0.85, 0.97, 1.00};

    public static int indexOf(String id) {
        for (int i = 0; i < IDS.length; i++) if (IDS[i].equals(id)) return i;
        return 0;
    }

    public static String name(String id) { return NAMES[Math.max(0, Math.min(4, indexOf(id)))]; }
    public static double mult(String id) { return MULT[Math.max(0, Math.min(4, indexOf(id)))]; }

    public static String roll(double r) {
        for (int i = 0; i < CUM.length; i++) if (r < CUM[i]) return IDS[i];
        return "peak";
    }

    public static int price(int base, String id) { return (int) Math.round(base * mult(id)); }
}
