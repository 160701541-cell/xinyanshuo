package com.xinyanshuo.xianfan.nativeapp;

/** 战力的完整公式，与 JS 端 combat.mjs 同一套系数。 */
public final class Power {
    public static final String[] REALM_IDS = {"mortal", "qi", "found", "core", "nascent", "spirit"};
    public static final String[] REALM_NAMES = {"凡人", "炼气", "筑基", "金丹", "元婴", "化神"};
    public static final int[] REALM_BASE = {10, 60, 260, 1100, 4200, 16000};

    /** 灵根对战力：天灵根 1.45，无灵根 0.55 */
    public static double rootFactor(String rootId) {
        switch (rootId == null ? "" : rootId) {
            case "tian": return 1.45;
            case "dan": return 1.32;
            case "shuang": return 1.20;
            case "san": return 1.10;
            case "si": return 1.03;
            case "wu": return 1.00;
            default: return 0.55;   // none
        }
    }

    /** 层数：炼气 1–13，每层 +6% */
    public static double layerFactor(int layer) {
        int l = Math.max(0, Math.min(13, layer));
        return 1 + l * 0.06;
    }

    /** 装备：武器 0.22、护甲 0.12、法宝 0.16，按品阶乘数（凡品 1 … 极品 11） */
    public static double gearFactor(double weaponMult, double armorMult, double talismanMult) {
        return 1 + weaponMult * 0.22 + armorMult * 0.12 + talismanMult * 0.16;
    }

    /** 状态：气血、体力、士气、伤势 */
    public static double stateFactor(double hp, double stamina, double morale, boolean wounded) {
        double h = hp / 100.0, s = stamina / 100.0, m = morale / 100.0;
        double v = (0.45 + 0.35 * h + 0.2 * s) * (0.8 + 0.3 * m) * (wounded ? 0.75 : 1);
        return Math.max(0.25, Math.min(1.35, v));
    }

    /** 道心：业力压战力，道心正略加成 */
    public static double daoFactor(int karma, int bias) {
        double v = 1 - Math.min(120, Math.max(0, karma)) / 400.0 + Math.max(0, bias) / 500.0;
        return Math.max(0.55, Math.min(1.2, v));
    }

    public static double pillFactor(int pills) { return 1 + Math.min(0.5, pills * 0.08); }

    public static int total(int realm, int layer, String root, double weapon, double armor, double talisman,
                            double hp, double stamina, double morale, boolean wounded, int karma, int bias, int pills) {
        double v = REALM_BASE[Math.max(0, Math.min(5, realm))]
            * layerFactor(layer) * rootFactor(root)
            * gearFactor(weapon, armor, talisman)
            * stateFactor(hp, stamina, morale, wounded)
            * daoFactor(karma, bias) * pillFactor(pills);
        return (int) Math.round(v);
    }
}
