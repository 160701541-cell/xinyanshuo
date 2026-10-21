package com.xinyanshuo.xianfan.nativeapp;

/** 灵根：七个档次，决定吐纳速度（speed）与同境界战力（见 Power.rootFactor）。 */
public final class Roots {
    public static final String[] IDS = {"tian", "dan", "shuang", "san", "si", "wu", "none"};
    public static final String[] NAMES = {"天灵根", "单灵根", "双灵根", "三灵根", "四灵根", "五灵根", "无灵根"};
    public static final double[] P = {0.0006, 0.006, 0.03, 0.09, 0.18, 0.32, 0.3734};
    public static final double[] SPEED = {3.2, 2.4, 1.8, 1.45, 1.2, 1.05, 0.0};

    public static String roll(double r) {
        double x = r;
        for (int i = 0; i < P.length; i++) { if (x < P[i]) return IDS[i]; x -= P[i]; }
        return "none";
    }

    public static String name(String id) {
        for (int i = 0; i < IDS.length; i++) if (IDS[i].equals(id)) return NAMES[i];
        return NAMES[6];
    }

    public static double speed(String id) {
        for (int i = 0; i < IDS.length; i++) if (IDS[i].equals(id)) return SPEED[i];
        return 0;
    }
}
