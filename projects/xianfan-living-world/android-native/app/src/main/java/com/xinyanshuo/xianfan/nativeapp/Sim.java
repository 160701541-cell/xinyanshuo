package com.xinyanshuo.xianfan.nativeapp;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

/**
 * 原生世界状态：坐标是米，时间是世界分钟，移动与讨伐都在这里结算。
 * 没有 DOM、没有 JS 引擎，数值再大也只是几个 double。
 */
public final class Sim {
    public static final double TIME_SCALE = 30.0; // 1 真实秒 = 30 世界秒
    public static final double WALK = 1.35;       // 米/秒

    public final JSONObject world;
    public final List<JSONObject> places = new ArrayList<>();
    public final List<JSONObject> structures = new ArrayList<>();
    public final List<JSONObject> dens = new ArrayList<>();
    public final List<JSONObject> landmarks = new ArrayList<>();
    public final Map<String, Integer> bag = new LinkedHashMap<>();
    public final List<String> log = new ArrayList<>();
    public final HashSet<String> cleared = new HashSet<>();

    public double px = 0, py = 0, tx = 0, ty = 0;
    public double stamina = 100, hp = 100, spirit = 90;
    public int silver = 170, karma = 0, men = 0, stones = 0, realmLevel = 0, layer = 0, pills = 0;
    public String rootId = "none";
    public String weaponGrade = "mortal", armorGrade = "mortal", talismanGrade = "mortal";
    public boolean wounded = false, tested = false;
    public int morale = 70, bias = 0;
    public boolean ship = false;
    public final List<String> visited = new ArrayList<>();
    public double clock = 7 * 60; // 第 0 天 07:00
    public String place = "东市";
    public String targetName = "";
    public boolean moving = false;
    public long seed = 20261022L;

    public Sim(JSONObject world) {
        this.world = world;
        JSONArray p = world.optJSONArray("places");
        if (p != null) for (int i = 0; i < p.length(); i++) places.add(p.optJSONObject(i));
        JSONArray s = world.optJSONArray("structures");
        if (s != null) for (int i = 0; i < s.length(); i++) structures.add(s.optJSONObject(i));
        JSONArray d = world.optJSONArray("dens");
        if (d != null) for (int i = 0; i < d.length(); i++) dens.add(d.optJSONObject(i));
        JSONArray l = world.optJSONArray("landmarks");
        if (l != null) for (int i = 0; i < l.length(); i++) landmarks.add(l.optJSONObject(i));
        visited.add("xuanhuang");
        rootId = Roots.roll(randDouble("root:" + seed));
        practiceProgress = 0;
        bag.put("干粮（凡品）", 3);
        note("落籍临安县城东市。");
    }

    public void note(String s) {
        log.add(String.format("第%d日 %02d:%02d · %s", day(), hour(), minute(), s));
        while (log.size() > 200) log.remove(0);
    }

    public int day() { return (int) (clock / 1440); }
    public int hour() { return (int) (clock % 1440) / 60; }
    public int minute() { return (int) (clock % 60); }

    public String timeText() { return String.format("第%d日 %02d:%02d", day(), hour(), minute()); }

    public void goTo(double x, double y, String name) {
        tx = x; ty = y; moving = true; targetName = name == null ? "目标" : name;
    }

    public void stop() { moving = false; targetName = ""; }

    /** 每帧推进：移动 + 体力 + 世界时钟 */
    public void tick(double dtReal) {
        double dt = Math.min(0.1, Math.max(0, dtReal));
        if (moving) {
            double dx = tx - px, dy = ty - py;
            double dist = Math.hypot(dx, dy);
            double step = WALK * dt * (stamina > 20 ? 1 : 0.6);
            if (dist <= step) {
                px = tx; py = ty; moving = false;
                note("到了" + targetName + "。");
                targetName = "";
            } else {
                px += dx / dist * step;
                py += dy / dist * step;
                stamina = Math.max(0, stamina - step * 0.09);
            }
        } else {
            stamina = Math.min(100, stamina + dt * 0.5);
        }
        clock += dt * TIME_SCALE;
    }

    /** 附近的建筑：40 米内取最近 */
    public JSONObject structureAt(double x, double y, double radius) {
        JSONObject best = null; double bd = radius;
        for (JSONObject s : structures) {
            double d = Math.hypot(s.optDouble("x") - x, s.optDouble("y") - y);
            if (d < bd) { bd = d; best = s; }
        }
        return best;
    }

    public JSONObject denAt(double x, double y, double radius) {
        JSONObject best = null; double bd = radius;
        for (JSONObject s : dens) {
            double d = Math.hypot(s.optDouble("x") - x, s.optDouble("y") - y);
            if (d < bd) { bd = d; best = s; }
        }
        return best;
    }

    /** 出兵讨伐：兵力（私兵 + 自身）对妖兽群，胜则按境界拿尸体材料 */
    public String hunt(JSONObject den) {
        String id = den.optString("id");
        if (cleared.contains(id)) return den.optString("name") + " 已经讨平过了。";
        double party = (men > 0 ? men * 2.6 : 0) + 60 + hp * 0.8 + (isXiu() ? 120 : 0);
        int count = den.optInt("count", 3);
        double pack = count * den.optDouble("hp", 400) * 0.05 + den.optDouble("dmg", 40) * 0.3;
        Random r = new Random(seed++);
        if (party * (0.85 + r.nextDouble() * 0.3) < pack) {
            hp = Math.max(1, hp - 22);
            note("讨伐" + den.optString("name") + "失利，负伤退回。");
            return "打不过：" + count + " 只" + den.optString("beast") + "，先招人再来。";
        }
        cleared.add(id);
        int realm = den.optInt("realm", 0);
        int[] per = {2, 4, 7, 11};
        int pieces = per[Math.min(3, realm)];
        String[] mats = {"妖皮", "妖骨", "妖肉", "妖筋", "妖牙", "妖鳞"};
        for (int i = 0; i < pieces; i++) {
            String m = mats[r.nextInt(mats.length)];
            String g = Grades.roll(r.nextDouble());
            String key = m + "（" + Grades.name(g) + "）";
            bag.put(key, bag.getOrDefault(key, 0) + 1);
        }
        StringBuilder sb = new StringBuilder();
        if (r.nextDouble() < (new double[]{0.30, 0.58, 0.82, 0.96})[Math.min(3, realm)]) {
            String g = Grades.roll(0.35 + r.nextDouble() * 0.55);   // 妖丹出货品阶偏高
            bag.put("妖丹（" + Grades.name(g) + "）", bag.getOrDefault("妖丹（" + Grades.name(g) + "）", 0) + 1);
            sb.append("妖丹·").append(Grades.name(g)).append(" ");
        }
        if (r.nextDouble() < (new double[]{0.08, 0.16, 0.26, 0.34})[Math.min(3, realm)]) {
            bag.put("精血", bag.getOrDefault("精血", 0) + 1); sb.append("精血×1 ");
        }
        if (realm >= 2 && r.nextDouble() < 0.22) { bag.put("妖卵", bag.getOrDefault("妖卵", 0) + 1); sb.append("妖卵×1 "); }
        if (realm >= 2 && r.nextDouble() < 0.10) { bag.put("幼崽", bag.getOrDefault("幼崽", 0) + 1); sb.append("幼崽×1 "); }
        int worth = pieces * 8 + (bagsWith("妖丹") > 0 ? 120 : 0);
        silver += worth / 3;
        karma += 1;
        String line = "讨平" + den.optString("name") + "：" + pieces + " 件材料 " + sb + "折银 " + (worth / 3);
        note(line);
        return line;
    }

    /** 完整战力：境界 × 层数 × 灵根 × 装备 × 状态 × 道心 × 丹药 */
    public int power() {
        return Power.total(realmLevel, layer, rootId,
            Grades.mult(weaponGrade), Grades.mult(armorGrade), Grades.mult(talismanGrade),
            hp, stamina, morale, wounded, karma, bias, pills);
    }

    public String powerBreakdown() {
        StringBuilder b = new StringBuilder();
        b.append("境界底数 ").append(Power.REALM_BASE[Math.max(0, Math.min(5, realmLevel))]).append("\n");
        b.append("层数 ×").append(String.format("%.2f", Power.layerFactor(layer))).append("\n");
        b.append("灵根 ×").append(String.format("%.2f", Power.rootFactor(rootId))).append("（").append(Roots.name(rootId)).append("）\n");
        b.append("装备 ×").append(String.format("%.2f", Power.gearFactor(Grades.mult(weaponGrade), Grades.mult(armorGrade), Grades.mult(talismanGrade)))).append("\n");
        b.append("状态 ×").append(String.format("%.2f", Power.stateFactor(hp, stamina, morale, wounded))).append("\n");
        b.append("道心 ×").append(String.format("%.2f", Power.daoFactor(karma, bias))).append("\n");
        b.append("丹药 ×").append(String.format("%.2f", Power.pillFactor(pills))).append("\n");
        b.append("合计战力 ").append(power());
        return b.toString();
    }

    /** 灵根检测：只有灵山或青云能测，一次定终身 */
    public String detectRoot() {
        if (tested) return "已测过：" + Roots.name(rootId) + "（吐纳速度 ×" + String.format("%.2f", Roots.speed(rootId)) + "）";
        if (!(place.contains("灵山") || place.contains("青云"))) return "县城测不了灵根，得去灵山或青云山门。";
        tested = true;
        note("测灵根：" + Roots.name(rootId));
        return "灵根：" + Roots.name(rootId) + "，吐纳速度 ×" + String.format("%.2f", Roots.speed(rootId));
    }

    /** 吐纳：只有测过灵根才有效，天灵根快三倍 */
    public String practice(int hours) {
        if (rootId.equals("none")) return "无灵根，吐纳不进。";
        if (!tested) return "还没测灵根，不知道该怎么引气。";
        if (stamina < 20) return "体力不够，先歇。";
        double gain = hours * Roots.speed(rootId) * 10;
        stamina = Math.max(0, stamina - hours * 2.5);
        clock += hours * 60.0;
        double need = 40 + layer * 30;
        double cur = practiceProgress + gain;
        int up = 0;
        while (cur >= need && layer < 13) { cur -= need; layer++; up++; need = 40 + layer * 30; }
        practiceProgress = cur;
        note("吐纳 " + hours + " 时辰" + (up > 0 ? "，突破 " + up + " 层" : ""));
        return "吐纳 " + hours + " 时辰，" + (up > 0 ? "连破 " + up + " 层（现炼气" + layer + "层）" : "修为 " + (int) cur + "/" + (int) need);
    }

    public double practiceProgress = 0;

    public String realmName() { return Power.REALM_NAMES[Math.max(0, Math.min(5, realmLevel))]; }

    /** 星域横渡：化神以上肉身过虚空，否则必须造星舰 */
    public String voidGateText() {
        if (realmLevel >= 5) return "化神：可以肉身横渡虚空";
        if (ship) return "有星舰：可以走航线";
        return "不过是" + realmName() + "，过不去——要么修行到化神，要么造一艘星舰";
    }

    public String buildShip() {
        if (ship) return "已有一艘星舰。";
        if (stones < 900 || silver < 2000000) return "星舰要 900 灵石 + 200 万银。";
        stones -= 900; silver -= 2000000; ship = true;
        note("星舰「玄黄一号」下水。");
        return "星舰下水，凡人也能过虚空了。";
    }

    /** 距离用万公里，消耗按距离算灵石；星舰省 65% 灵石，危险减半 */
    public String travelDomain(int idx) {
        JSONArray ds = world.optJSONArray("domains");
        if (ds == null || idx < 0 || idx >= ds.length()) return "没有这一域。";
        JSONObject d = ds.optJSONObject(idx);
        if (d.optBoolean("home")) return "你已经在本域。";
        boolean byShip = ship;
        if (realmLevel < 5 && !ship) return voidGateText();
        double wkm = d.optDouble("distWkm");
        int need = (int) Math.max(20, Math.round(wkm / 4e7) * (byShip ? 0.35 : 1));
        if (stones < need) return "灵石不够：需 " + need + " 块，你有 " + stones + " 块。";
        stones -= need;
        int years = (int) Math.max(1, Math.round(wkm / 1.2e9));
        clock += years * 360.0 * 1440;
        if (!visited.contains(d.optString("id"))) visited.add(d.optString("id"));
        String line = (byShip ? "乘星舰" : "肉身横渡") + " " + years + " 年，抵" + d.optString("name") + "（耗 " + need + " 灵石）";
        note(line);
        return line;
    }

    public boolean isXiu() { return spirit > 60 && karma < 60; }

    /** 私兵招募：每人 14 银，上限 60（原生版先给一个人数上限） */
    public String recruit(int n) {
        int can = Math.min(n, Math.max(0, 60 - men));
        int cost = can * 14;
        if (can <= 0) return "私兵到顶了。";
        if (silver < cost) return "银不够，还差 " + (cost - silver) + "。";
        silver -= cost; men += can;
        note("招了 " + can + " 名私兵，花 " + cost + " 银。");
        return "招到 " + can + " 人，花 " + cost + " 银（现 " + men + " 人）";
    }

    private int bagsWith(String prefix) {
        int n = 0;
        for (Map.Entry<String, Integer> e : bag.entrySet()) if (e.getKey().startsWith(prefix)) n += e.getValue();
        return n;
    }

    /** 确定性随机：同一个键永远同一个结果（存档可回放） */
    private double randDouble(String key) {
        long h = 2166136261L;
        for (int i = 0; i < key.length(); i++) { h ^= key.charAt(i); h *= 16777619L; }
        return new java.util.Random(h).nextDouble();
    }

    public String save() {
        try {
            JSONObject o = new JSONObject();
            o.put("px", px); o.put("py", py); o.put("clock", clock);
            o.put("stamina", stamina); o.put("hp", hp); o.put("silver", silver);
            o.put("karma", karma); o.put("men", men); o.put("place", place);
            o.put("stones", stones); o.put("realmLevel", realmLevel); o.put("ship", ship);
            o.put("layer", layer); o.put("rootId", rootId); o.put("tested", tested);
            o.put("practice", practiceProgress); o.put("pills", pills);
            o.put("weapon", weaponGrade); o.put("armor", armorGrade); o.put("talisman", talismanGrade);
            o.put("wounded", wounded); o.put("morale", morale); o.put("bias", bias);
            JSONObject b = new JSONObject(); for (Map.Entry<String, Integer> e : bag.entrySet()) b.put(e.getKey(), e.getValue());
            o.put("bag", b);
            JSONArray c = new JSONArray(); for (String s : cleared) c.put(s); o.put("cleared", c);
            JSONArray l = new JSONArray(); for (String s : log) l.put(s); o.put("log", l);
            return o.toString();
        } catch (Exception e) { return null; }
    }

    public void load(String raw) {
        if (raw == null || raw.isEmpty()) return;
        try {
            JSONObject o = new JSONObject(raw);
            px = o.optDouble("px", px); py = o.optDouble("py", py); clock = o.optDouble("clock", clock);
            stamina = o.optDouble("stamina", stamina); hp = o.optDouble("hp", hp);
            silver = o.optInt("silver", silver); karma = o.optInt("karma", karma); men = o.optInt("men", men);
            place = o.optString("place", place);
            stones = o.optInt("stones", stones); realmLevel = o.optInt("realmLevel", realmLevel); ship = o.optBoolean("ship", ship);
            layer = o.optInt("layer", layer); rootId = o.optString("rootId", rootId); tested = o.optBoolean("tested", tested);
            practiceProgress = o.optDouble("practice", practiceProgress); pills = o.optInt("pills", pills);
            weaponGrade = o.optString("weapon", weaponGrade); armorGrade = o.optString("armor", armorGrade);
            talismanGrade = o.optString("talisman", talismanGrade);
            wounded = o.optBoolean("wounded", wounded); morale = o.optInt("morale", morale); bias = o.optInt("bias", bias);
            JSONObject b = o.optJSONObject("bag");
            if (b != null) { bag.clear(); for (java.util.Iterator<String> it = b.keys(); it.hasNext(); ) { String k = it.next(); bag.put(k, b.optInt(k)); } }
            JSONArray c = o.optJSONArray("cleared");
            if (c != null) for (int i = 0; i < c.length(); i++) cleared.add(c.optString(i));
            JSONArray l = o.optJSONArray("log");
            if (l != null) { log.clear(); for (int i = 0; i < l.length(); i++) log.add(l.optString(i)); }
        } catch (Exception ignored) { }
    }
}
