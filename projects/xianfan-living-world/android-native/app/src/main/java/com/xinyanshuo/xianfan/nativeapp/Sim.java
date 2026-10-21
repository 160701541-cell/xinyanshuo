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
    public int silver = 170, karma = 0, men = 0;
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
        bag.put("干粮", 3);
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
            bag.put(m, bag.getOrDefault(m, 0) + 1);
        }
        StringBuilder sb = new StringBuilder();
        if (r.nextDouble() < (new double[]{0.30, 0.58, 0.82, 0.96})[Math.min(3, realm)]) {
            bag.put("妖丹", bag.getOrDefault("妖丹", 0) + 1); sb.append("妖丹×1 ");
        }
        if (r.nextDouble() < (new double[]{0.08, 0.16, 0.26, 0.34})[Math.min(3, realm)]) {
            bag.put("精血", bag.getOrDefault("精血", 0) + 1); sb.append("精血×1 ");
        }
        if (realm >= 2 && r.nextDouble() < 0.22) { bag.put("妖卵", bag.getOrDefault("妖卵", 0) + 1); sb.append("妖卵×1 "); }
        if (realm >= 2 && r.nextDouble() < 0.10) { bag.put("幼崽", bag.getOrDefault("幼崽", 0) + 1); sb.append("幼崽×1 "); }
        int worth = pieces * 8 + (bag.getOrDefault("妖丹", 0) > 0 ? 120 : 0);
        silver += worth / 3;
        karma += 1;
        String line = "讨平" + den.optString("name") + "：" + pieces + " 件材料 " + sb + "折银 " + (worth / 3);
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

    public String save() {
        try {
            JSONObject o = new JSONObject();
            o.put("px", px); o.put("py", py); o.put("clock", clock);
            o.put("stamina", stamina); o.put("hp", hp); o.put("silver", silver);
            o.put("karma", karma); o.put("men", men); o.put("place", place);
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
            JSONObject b = o.optJSONObject("bag");
            if (b != null) { bag.clear(); for (java.util.Iterator<String> it = b.keys(); it.hasNext(); ) { String k = it.next(); bag.put(k, b.optInt(k)); } }
            JSONArray c = o.optJSONArray("cleared");
            if (c != null) for (int i = 0; i < c.length(); i++) cleared.add(c.optString(i));
            JSONArray l = o.optJSONArray("log");
            if (l != null) { log.clear(); for (int i = 0; i < l.length(); i++) log.add(l.optString(i)); }
        } catch (Exception ignored) { }
    }
}
