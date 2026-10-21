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
    /** 街上的人：位置每帧自己走，点一下能搭话 */
    public final List<JSONObject> npcs = new ArrayList<>();
    /** 碰撞用的矩形（院墙、主屋），普通人不能穿 */
    public final List<double[]> blocks = new ArrayList<>();
    public final List<double[]> roads = new ArrayList<>();
    public final Map<String, Integer> bag = new LinkedHashMap<>();
    /** 物品元数据（world.json 的 items）：id/name/value/weight/note */
    public final List<JSONObject> items = new ArrayList<>();
    public final List<String> log = new ArrayList<>();
    public final HashSet<String> cleared = new HashSet<>();

    public double px = 0, py = 0, tx = 0, ty = 0;
    public double stamina = 100, hp = 100, spirit = 90;
    public int coin = 1700, karma = 0, men = 0, stones = 0, realmLevel = 0, layer = 0, pills = 0;
    public String rootId = "none";
    public String weaponGrade = "mortal", armorGrade = "mortal", talismanGrade = "mortal";
    // 移速各来源（加成用乘区，全部可在「个人」页看到）
    public double bootsBonus = 0;      // 靴子
    public boolean wings = false;      // 风雷翅
    public boolean godspeed = false;   // 神行符
    public String vehicle = "";        // sword / boat
    public double martial = 0;         // 轻功身法
    public static final int BAG_SLOTS = 24;
    public boolean wounded = false, tested = false;
    public int morale = 70, bias = 0;
    public double lawSpace = 0, lawTime = 0;
    // 家业：住处等级 0 无 / 1 小屋 / 2 瓦房 / 3 宅院；宗门与王位
    public int homeLevel = 0, workDays = 0;
    // 建造：资源、建筑、科技、兵种
    public int resWood = 0, resStraw = 0, resStone = 0, resClay = 0, resIron = 0;
    public int huts = 0, techFarm = 0, techArms = 0, techFort = 0;
    public String sectName = null, throne = null;
    public int disciples = 0;
    public boolean ship = false;
    public final List<String> visited = new ArrayList<>();
    public double clock = 7 * 60; // 第 0 天 07:00
    public String place = "东市";
    public String targetName = "";
    public boolean moving = false;
    public long seed = 20261022L;
    public String locked = null, lockedName = null;
    public boolean flying = false, horse = false, justArrived = false;
    private double approachTimer = 0;
    private final Map<String, double[]> npcTarget = new LinkedHashMap<>();
    /** 街上的人的位置（不用 JSONObject.put，省得每帧都在 try/catch 里） */
    public final Map<String, double[]> npcPos = new LinkedHashMap<>();
    public final Map<String, double[]> npcHome = new LinkedHashMap<>();

    public Sim(JSONObject world) {
        this.world = world;
        JSONArray p = world.optJSONArray("places");
        if (p != null) for (int i = 0; i < p.length(); i++) places.add(p.optJSONObject(i));
        JSONArray s = world.optJSONArray("structures");
        if (s != null) for (int i = 0; i < s.length(); i++) structures.add(s.optJSONObject(i));
        JSONArray d = world.optJSONArray("dens");
        if (d != null) for (int i = 0; i < d.length(); i++) dens.add(d.optJSONObject(i));
        JSONArray np = world.optJSONArray("npcs");
        if (np != null) for (int i = 0; i < np.length(); i++) {
            JSONObject o = np.optJSONObject(i);
            npcs.add(o);
            String id = o.optString("id");
            npcPos.put(id, new double[]{o.optDouble("x"), o.optDouble("y")});
            npcHome.put(id, new double[]{o.optDouble("x"), o.optDouble("y")});
        }
        JSONArray it = world.optJSONArray("items");
        if (it != null) for (int i = 0; i < it.length(); i++) items.add(it.optJSONObject(i));
        JSONArray bl = world.optJSONArray("blocks");
        if (bl != null) for (int i = 0; i < bl.length(); i++) {
            JSONObject b = bl.optJSONObject(i);
            blocks.add(new double[]{b.optDouble("x"), b.optDouble("y"), b.optDouble("w"), b.optDouble("h")});
        }
        JSONArray rd = world.optJSONArray("roads");
        if (rd != null) for (int i = 0; i < rd.length(); i++) {
            JSONArray line = rd.optJSONArray(i);
            if (line == null) continue;
            for (int j = 0; j + 1 < line.length(); j++) {
                JSONArray a = line.optJSONArray(j), b2 = line.optJSONArray(j + 1);
                if (a == null || b2 == null) continue;
                roads.add(new double[]{a.optDouble(0), a.optDouble(1), b2.optDouble(0), b2.optDouble(1)});
            }
        }
        JSONArray l = world.optJSONArray("landmarks");
        if (l != null) for (int i = 0; i < l.length(); i++) landmarks.add(l.optJSONObject(i));
        visited.add("xuanhuang");
        rootId = Roots.roll(randDouble("root:" + seed));
        practiceProgress = 0;
        addItem("grain|mortal", 3);
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

    /** 每帧推进：移动 + 体力 + 世界时钟 + 街上的人 + 锁定的目标 */
    public void tick(double dtReal) {
        double dt = Math.min(0.1, Math.max(0, dtReal));
        tickNpcs(dt);
        if (locked != null) approachTimer += dt;

        if (moving) {
            double dx = tx - px, dy = ty - py;
            double dist = Math.hypot(dx, dy);
            double speed = WALK * speedMul(px, py) * (stamina > 20 ? 1 : 0.6) * (flying ? 2.4 : 1);
            double step = speed * dt;
            if (dist <= step) {
                px = tx; py = ty; moving = false; justArrived = true;
                note("到了" + targetName + "。");
                targetName = "";
            } else {
                double nx = px + dx / dist * step, ny = py + dy / dist * step;
                if (!flying && blocked(nx, ny)) {
                    // 贴着墙滑动：先试单轴，再退回去
                    if (!blocked(nx, py)) { py = py; px = nx; }
                    else if (!blocked(px, ny)) { py = ny; }
                    else { moving = false; note("前面是墙，走不过去。"); }
                } else {
                    px = nx; py = ny;
                }
                stamina = Math.max(0, stamina - step * (flying ? 0.02 : 0.09));
                if (flying) spirit = Math.max(0, spirit - step * 0.02);
            }
        } else {
            stamina = Math.min(100, stamina + dt * 0.5);
            if (flying) spirit = Math.min(100, spirit + dt * 0.4);
        }

        // 锁定的人会跑：每半秒按他当前的位置重新规划一次，追不上就报跟丢
        if (locked != null) {
            JSONObject npc = npcById(locked);
            if (npc == null) { locked = null; lockedName = null; moving = false; }
            else {
                double d = Math.hypot(npcX(locked) - px, npcY(locked) - py);
                if (d <= 7) {
                    note("追上了" + npc.optString("name") + "。");
                    String name = npc.optString("name");
                    locked = null; lockedName = null; moving = false;
                    lastTalk = "你追上" + name + "，他停了脚："+ talkLine(name, npc.optString("job")) + "\n（可以点「搭话」继续）";
                } else if (d > 600) {
                    note("跟丢了" + npc.optString("name") + "。");
                    locked = null; lockedName = null; moving = false;
                } else if (approachTimer >= 0.5) {
                    approachTimer = 0;
                    goTo(npcX(locked), npcY(locked), npc.optString("name"));
                }
            }
        }
        clock += dt * TIME_SCALE;
    }

    public String lastTalk = "";

    private String talkLine(String name, String job) {
        return "“在下" + name + "，" + (job == null || job.isEmpty() ? "混口饭吃" : "做" + job + "营生") + "。听说城里最近不太平。”";
    }

    /** 街上的人自己走：在住处周围 80 米内晃，慢得像闲逛 */
    private void tickNpcs(double dt) {
        for (JSONObject n : npcs) {
            String id = n.optString("id");
            double[] pos = npcPos.get(id);
            double[] home = npcHome.get(id);
            if (pos == null || home == null) continue;
            double[] t = npcTarget.get(id);
            if (t == null || Math.hypot(t[0] - pos[0], t[1] - pos[1]) < 3) {
                double r = randDouble("wander:" + id + ":" + (int) (clock / 60));
                double ang = r * Math.PI * 2;
                double rad = 25 + randDouble("r:" + id + ":" + (int) (clock / 60)) * 55;
                t = new double[]{home[0] + Math.cos(ang) * rad, home[1] + Math.sin(ang) * rad};
                npcTarget.put(id, t);
            }
            double dx = t[0] - pos[0], dy = t[1] - pos[1], d = Math.hypot(dx, dy);
            double step = 1.05 * dt;
            if (d > 0.01) {
                pos[0] += dx / d * Math.min(step, d);
                pos[1] += dy / d * Math.min(step, d);
            }
        }
    }

    public double npcX(String id) { double[] p = npcPos.get(id); return p == null ? 0 : p[0]; }
    public double npcY(String id) { double[] p = npcPos.get(id); return p == null ? 0 : p[1]; }

    public JSONObject npcById(String id) {
        for (JSONObject n : npcs) if (n.optString("id").equals(id)) return n;
        return null;
    }

    public JSONObject npcNear(double x, double y, double radius) {
        JSONObject best = null; double bd = radius;
        for (JSONObject n : npcs) {
            double[] p = npcPos.get(n.optString("id"));
            if (p == null) continue;
            double d = Math.hypot(p[0] - x, p[1] - y);
            if (d < bd) { bd = d; best = n; }
        }
        return best;
    }

    /** 锁定一个人：之后每半秒按他的新位置重算路线，追到 7 米内自动搭话 */
    public String lockNpc(JSONObject n) {
        locked = n.optString("id"); lockedName = n.optString("name");
        approachTimer = 1;
        goTo(npcX(locked), npcY(locked), lockedName);
        note("跟上" + lockedName + "。");
        return "跟着" + lockedName + "走，他停下你就追上了。";
    }

    public void unlock() { locked = null; lockedName = null; }

    /** 这里能不能站人：院墙与主屋挡住，飞行时无视 */
    public boolean blocked(double x, double y) {
        for (double[] r : blocks) {
            if (x > r[0] && x < r[0] + r[2] && y > r[1] && y < r[1] + r[3]) return true;
        }
        return false;
    }

    /** 官道 1.6 倍（其余在 speed() 里按乘区算） */
    public boolean onRoad(double x, double y) {
        for (double[] r : roads) if (distToSeg(x, y, r[0], r[1], r[2], r[3]) < 14) return true;
        return false;
    }

    public double speedMul(double x, double y) {
        return speed(x, y) / WALK;
    }

    /** 完整移速：基础 × 境界 × 靴子 × 翅 × 符 × 坐骑 × 载具 × 轻功 × 官道 × 负重 */
    public double speed(double x, double y) {
        double mul = 1.0;
        mul *= 1 + realmLevel * 0.05;
        mul *= 1 + bootsBonus;
        if (wings) mul *= 1.9;
        if (godspeed) mul *= 1.25;
        if (horse) mul *= 1.4;
        if ("sword".equals(vehicle)) mul *= 2.4;
        else if ("boat".equals(vehicle)) mul *= 2.0;
        mul *= 1 + martial;
        if (onRoad(x, y)) mul *= 1.6;
        int over = Math.max(0, bagSlots() - bagCap());
        if (over > 0) mul *= 1.0 / (1 + 0.2 * over);
        return WALK * mul;
    }

    /** 速度逐项，给「个人」页列出来 */
    public String speedText(double x, double y) {
        StringBuilder b = new StringBuilder();
        b.append(String.format("%.2f 米/秒\n", speed(x, y)));
        b.append("境界 ×").append(String.format("%.2f", 1 + realmLevel * 0.05)).append("\n");
        if (bootsBonus > 0) b.append("靴子 ×").append(String.format("%.2f", 1 + bootsBonus)).append("\n");
        if (wings) b.append("风雷翅 ×1.90\n");
        if (godspeed) b.append("神行符 ×1.25\n");
        if (horse) b.append("坐骑 ×1.40\n");
        if ("sword".equals(vehicle)) b.append("御飞剑 ×2.40\n");
        else if ("boat".equals(vehicle)) b.append("飞舟 ×2.00\n");
        if (martial > 0) b.append("轻功 ×").append(String.format("%.2f", 1 + martial)).append("\n");
        if (onRoad(x, y)) b.append("官道 ×1.60\n");
        b.append("负重 ").append(bagSlots()).append("/").append(bagCap()).append(" 格");
        int over = Math.max(0, bagSlots() - bagCap());
        if (over > 0) b.append("（超 ").append(over).append(" 格，×").append(String.format("%.2f", 1.0 / (1 + 0.2 * over))).append("）");
        return b.toString();
    }

    public int bagSlots() { return bagCount(); }

    public int bagCap() { return BAG_SLOTS; }

    /** 一键整理：按 id 合并，件数多的排前面 */
    public String tidyBag() {
        java.util.Map<String, Integer> merged = new LinkedHashMap<>();
        for (Map.Entry<String, Integer> e : bag.entrySet()) {
            String id = iconId(e.getKey());
            merged.merge(id, e.getValue(), Integer::sum);
        }
        java.util.List<Map.Entry<String, Integer>> list = new ArrayList<>(merged.entrySet());
        list.sort((a, b) -> b.getValue() - a.getValue());
        bag.clear();
        for (Map.Entry<String, Integer> e : list) bag.put(e.getKey(), e.getValue());
        return "整理完毕，共 " + bagCount() + " 件。";
    }

    private static double distToSeg(double px, double py, double x1, double y1, double x2, double y2) {
        double dx = x2 - x1, dy = y2 - y1;
        double l2 = dx * dx + dy * dy;
        double t = l2 == 0 ? 0 : ((px - x1) * dx + (py - y1) * dy) / l2;
        t = Math.max(0, Math.min(1, t));
        return Math.hypot(px - (x1 + t * dx), py - (y1 + t * dy));
    }

    /** 御剑：修士且灵力够；城主（御城军）也能在城内飞 */
    public String toggleFlight() {
        if (flying) { flying = false; vehicle = ""; note("落地。"); return "已落地，普通人绕墙走。"; }
        if (realmLevel < 2) return "御剑要筑基以上。";
        if (spirit < 12) return "灵力不足，先吐纳。";
        flying = true; vehicle = "sword"; note("御剑起飞。");
        return "御剑而行：掠过屋脊，不再被院墙挡。";
    }

    public String buyHorse() {
        if (horse) return "已经有一匹了。";
        if (coin < 3000) return "买马要 " + coinText(3000) + "。";
        coin -= 3000; horse = true;
        note("买了一匹脚力。");
        return "有马了，官道上更快。";
    }

    public String talk() {
        JSONObject n = npcNear(px, py, 12);
        if (n == null) return "附近没有人。点点头，也就过去了。";
        lastTalk = n.optString("name") + "（" + n.optString("job") + "）：" + talkLine(n.optString("name"), n.optString("job"));
        return lastTalk;
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
        // 尸体就是材料：按物种给皮/骨/肉，带品阶
        String[] mats = {"skin", "bone", "meat", "bone", "skin", "meat"};
        for (int i = 0; i < pieces; i++) {
            String m = mats[r.nextInt(mats.length)];
            String g = Grades.roll(r.nextDouble());
            bag.merge(m + "|" + g, 1, Integer::sum);
        }
        StringBuilder sb = new StringBuilder();
        if (r.nextDouble() < (new double[]{0.30, 0.58, 0.82, 0.96})[Math.min(3, realm)]) {
            String g = Grades.roll(0.35 + r.nextDouble() * 0.55);   // 妖丹出货品阶偏高
            bag.merge("core|" + g, 1, Integer::sum);
            sb.append("妖丹·").append(Grades.name(g)).append(" ");
        }
        if (r.nextDouble() < (new double[]{0.08, 0.16, 0.26, 0.34})[Math.min(3, realm)]) {
            bag.merge("pill|low", 1, Integer::sum); sb.append("精血×1 ");
        }
        if (realm >= 2 && r.nextDouble() < 0.22) { bag.merge("pill|low", 1, Integer::sum); sb.append("妖卵×1 "); }
        if (realm >= 2 && r.nextDouble() < 0.10) { bag.merge("meat|low", 1, Integer::sum); sb.append("幼崽×1 "); }
        int worth = pieces * 8 + (bagsWith("妖丹") > 0 ? 120 : 0);
        coin += worth;
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

    /** 时空法则：正常要化神，空/时灵根的元婴可提前 */
    public boolean isGeniusRoot() { return "kong".equals(rootId) || "shi".equals(rootId); }

    public String lawGateText() {
        int gate = isGeniusRoot() ? 4 : 5;
        if (realmLevel < gate) return "时空法则要" + Power.REALM_NAMES[gate] + "才摸得到" + (isGeniusRoot() ? "（你是时空天赋，可提前）" : "") + "，你如今" + realmName();
        return "";
    }

    public String comprehend(String law, int hours) {
        String gate = lawGateText();
        if (!gate.isEmpty()) return gate;
        double speed = (realmLevel - 4 + 1) * 0.0005 * (isGeniusRoot() ? 1.6 : 1);
        double gain = hours * speed;
        if ("space".equals(law)) {
            if (lawSpace >= 10) return "空间法则已圆满。";
            lawSpace = Math.min(10, lawSpace + gain);
            note("参悟空间法则 " + String.format("%.2f", lawSpace) + "/10");
            return "空间法则 " + String.format("%.2f", lawSpace) + "/10";
        }
        if (lawTime >= 10) return "时间法则已圆满。";
        lawTime = Math.min(10, lawTime + gain);
        note("参悟时间法则 " + String.format("%.2f", lawTime) + "/10");
        return "时间法则 " + String.format("%.2f", lawTime) + "/10";
    }

    /** 虫洞阵法：空间六重 + 时间三重 + 十万下品灵石 */
    public String wormholeState() {
        if (lawSpace < 6) return "空间法则 " + String.format("%.1f", lawSpace) + "/6";
        if (lawTime < 3) return "时间法则 " + String.format("%.1f", lawTime) + "/3";
        if (stones < 100000) return "阵法待开：需十万下品灵石";
        return "虫洞阵法可激发（稳定）";
    }

    /** 星域横渡：银河到仙女座那种距离，只有化神以上谈得上 */
    public String voidGateText() {
        if (realmLevel >= 5) return "化神：肉身可渡虚空，但一趟就是几十年上千年";
        return "不过是" + realmName() + "。跨星域是银河到仙女座的距离，凡人连这颗星都走不完";
    }

    /** 凡人一辈子能走多远：每天 30 公里、六十年，约 65 万公里 */
    public String mortalRangeText() {
        double km = 30 * 365 * 60;
        double circle = 4375233;
        return String.format("凡人脚程：一生约 %.0f 万年? %.0f 公里，绕玄黄星 %.2f 圈——走不完，更出不了星域", km / 10000, km, km / circle);
    }

    /** 星舰：化神押船才有意义，凡人上船等于送死 */
    public String buildShip() {
        if (realmLevel < 5) return "星舰没有化神押船，开进虚空就是一口活棺材。";
        if (ship) return "已有一艘星舰。";
        ship = true;
        note("星舰「玄黄一号」下水，由化神押船。");
        return "星舰下水。";
    }

    /** 距离单位光年；十万下品灵石起步，越远越贵，耗时以百年计 */
    public String travelDomain(int idx) {
        JSONArray ds = world.optJSONArray("domains");
        if (ds == null || idx < 0 || idx >= ds.length()) return "没有这一域。";
        JSONObject d = ds.optJSONObject(idx);
        if (d.optBoolean("home")) return "你已经在本域。";
        if (realmLevel < 5) return voidGateText();
        double ly = d.optDouble("ly", d.optDouble("distWkm") / 9.46e8);
        boolean hole = lawSpace >= 6 && lawTime >= 3;
        int need = hole ? 100000 : 100000 + (int) Math.round(ly / 40);
        if (stones < need) return "下品灵石不够：需 " + need + " 块，你有 " + stones + " 块。";
        stones -= need;
        double years = hole ? Math.max(0.05, ly / 480000.0) : Math.max(20, ly / 1200.0);
        clock += (long) (years * 360.0 * 1440);
        if (!visited.contains(d.optString("id"))) visited.add(d.optString("id"));
        String line = (hole ? "走虫洞 " : "横渡 ") + String.format("%s", years < 1 ? String.format("%.2f", years) : String.valueOf((int) years)) + " 年，抵" + d.optString("name") + "（耗 " + need + " 下品灵石，" + (int) ly + " 光年）";
        note(line);
        return line;
    }

    /* ── 家业 ─────────────────────────────────────── */

    public String stayInn(int days) {
        int cost = 20 * days;
        if (coin < cost) return "住店要 " + coinText(cost) + "，你只有 " + coinText(coin) + "。";
        coin -= cost;
        hp = Math.min(100, hp + 45 * days);
        stamina = Math.min(100, stamina + 60 * days);
        clock += days * 480 * 60L / 60L;
        return "住店 " + days + " 天，付 " + coinText(cost) + "，气力回来一些。";
    }

    public String restDay(int days) {
        double bonus = homeLevel > 0 ? 1.5 : 1.0;
        stamina = Math.min(100, stamina + 45 * days * bonus);
        hp = Math.min(100, hp + 20 * days * bonus);
        clock += days * 720 * 60L;
        return "歇了 " + days + " 天，体力 " + String.format("%.0f", stamina) + (homeLevel > 0 ? "（自家歇得快）" : "（睡街边，恢复慢）");
    }

    public String buyHome(String kind) {
        int price = "yard".equals(kind) ? 150000 : "house".equals(kind) ? 40000 : 12000;
        if (homeLevel > 0) return "你已经有宅子了。";
        if (coin < price) return "要 " + coinText(price) + "，你只有 " + coinText(coin) + "。";
        coin -= price;
        homeLevel = "yard".equals(kind) ? 3 : "house".equals(kind) ? 2 : 1;
        note("置下宅子，住得起 " + recruitCap() + " 个人");
        return "置下宅子，能养 " + recruitCap() + " 人。";
    }

    public int recruitCap() { return homeLevel == 0 ? 2 : homeLevel == 1 ? 6 : homeLevel == 2 ? 14 : 30; }

    public String workDay(String job) {
        int pay, need;
        if ("clerk".equals(job)) { pay = 9; need = 6; }
        else if ("guard".equals(job)) { pay = 14; need = 14; }
        else if ("herb".equals(job)) { pay = 11; need = 22; }
        else { pay = 6; need = 18; }
        if (stamina < need) return "体力不够，先歇着。";
        stamina -= need; coin += pay; workDays++;
        clock += 8 * 60 * 60L;
        return "做了一天活，得 " + coinText(pay) + "（累计 " + workDays + " 天）。";
    }

    public String hire(int n) {
        if (men + n > recruitCap()) return "住处只养得起 " + recruitCap() + " 人，先置宅。";
        int cost = n * 1000;
        if (coin < cost) return "招 " + n + " 人要 " + coinText(cost) + "。";
        coin -= cost; men += n;
        note("招了 " + n + " 名护院");
        return "招了 " + n + " 人，现共 " + men + " 人。";
    }

    public String foundSect(String name) {
        if (sectName != null) return "你已经有一处山门。";
        if (realmLevel < 2) return "筑基以上才配开山立派。";
        if (coin < 60000) return "开山要 " + coinText(60000) + "。";
        if (stones < 50) return "要 50 块下品灵石布护山大阵。";
        coin -= 60000; stones -= 50; sectName = name;
        note("开辟山门，立「" + name + "」");
        return "「" + name + "」立起来了。";
    }

    public String takeDisciple(int n) {
        if (sectName == null) return "还没有山门。";
        int cost = n * 1200;
        if (coin < cost) return "收徒要置办行头，每人 " + coinText(1200) + "。";
        coin -= cost; disciples += n;
        return "收 " + n + " 名弟子，门下共 " + disciples + " 人。";
    }

    public String takeThrone(String title) {
        if (throne != null) return "你已经是" + throne + "了。";
        if (realmLevel < 3) return "金丹以上才镇得住一方。";
        if (men < 60) return "至少 60 兵。";
        if (coin < 300000) return "要 " + coinText(300000) + "。";
        coin -= 300000; throne = title;
        note("于临安县衙称「" + title + "」");
        return "你称「" + title + "」，自立一方。";
    }

    public String chopWood() {
        if (stamina < 8) return "体力不够，先歇。";
        stamina -= 8; resWood += 3; addItem("wood", 2); clock += 90 * 60L;
        return "砍了一趟，木头 " + resWood + "。";
    }

    public String cutStraw() {
        if (stamina < 5) return "体力不够，先歇。";
        stamina -= 5; resStraw += 5; if (stamina < 30) addItem("herb", 1); clock += 45 * 60L;
        return "割了一趟草，稻草 " + resStraw + "。";
    }

    public String helpElder() {
        stamina = Math.min(100, stamina + 60);
        hp = Math.min(100, hp + 30);
        resStraw += 8; clock += 360 * 60L;
        return "帮村长干了一天，管饭管住，捎回 8 捆稻草（没工钱）。";
    }

    public String buildHut() {
        if (resWood < 10 || resStraw < 50) return "还缺：木头 " + Math.max(0, 10 - resWood) + "、稻草 " + Math.max(0, 50 - resStraw);
        resWood -= 10; resStraw -= 50; huts++;
        clock += 360 * 60L;
        note("盖起第一间茅屋");
        return "茅屋盖好了，共 " + huts + " 间。";
    }

    public String researchArms() {
        int cost = 3500 * (techArms + 1);
        int iron = 10 * (techArms + 1);
        if (techArms >= 5) return "军械已到顶。";
        if (coin < cost) return "要 " + coinText(cost) + "。";
        if (resIron < iron) return "要 " + iron + " 生铁。";
        coin -= cost; resIron -= iron; techArms++;
        return "军械提升到 " + techArms + " 级。";
    }

    public String trainSpear() {
        if (techArms < 1) return "需要军械 1 级。";
        if (coin < 400) return "要 " + coinText(400) + "。";
        if (resWood < 4) return "要 4 根木头。";
        coin -= 400; resWood -= 4; men++;
        return "练出一名长枪兵，现共 " + men + " 人。";
    }

    public String buildText() {
        return "木头 " + resWood + " · 稻草 " + resStraw + " · 石 " + resStone + " · 土 " + resClay + " · 铁 " + resIron
            + "\n茅屋 " + huts + " 间 · 军械 " + techArms + " 级\n\n"
            + "茅屋 = 10 木 + 50 草\n长枪兵 = " + coinText(400) + " + 4 木（需军械 1）";
    }

    public String lifeText() {
        StringBuilder b = new StringBuilder();
        b.append("住处　").append(homeLevel == 0 ? "无（睡客栈或街边）" : homeLevel == 1 ? "一间小屋" : homeLevel == 2 ? "一所瓦房" : "一座宅院").append("\n");
        b.append("能养　").append(recruitCap()).append(" 人 · 现有 ").append(men).append(" 人\n");
        b.append("银钱　").append(coinText(coin)).append(" · 下品灵石 ").append(stones).append("\n");
        b.append("打工　").append(workDays).append(" 天\n");
        b.append("山门　").append(sectName == null ? "无" : sectName + "（弟子 " + disciples + "）").append("\n");
        b.append("名分　").append(throne == null ? "布衣" : throne).append("\n\n");
        b.append("打工 6–14 文/日 · 住店 20 文/日 · 置宅 12,000 文起 · 招人 1,000 文/人 · 立宗 60,000 文 + 50 灵石 · 称王 300,000 文 + 60 兵");
        return b.toString();
    }

    /** 钱的显示：文 / 两银 / 两金 / 灵石，不堆一串零 */
    public static String coinText(int wen) {
        long n = Math.max(0, wen);
        if (n >= 1000000L) return (n / 1000000L) + " 下品灵石";
        long jin = n / 10000L, yin = (n % 10000L) / 100L, rest = n % 100L;
        StringBuilder b = new StringBuilder();
        if (jin > 0) b.append(jin).append(" 两金");
        if (yin > 0) b.append(b.length() > 0 ? " " : "").append(yin).append(" 两银");
        if (rest > 0 || b.length() == 0) b.append(b.length() > 0 ? " " : "").append(rest).append(" 文");
        return b.toString();
    }

    public void addItem(String id, int n) {
        if (bagCount() + n > bagCap()) return;   // 一件一格，满了装不下
        bag.merge(id, n, Integer::sum);
    }

    public JSONObject itemById(String id) {
        for (JSONObject o : items) if (id.equals(o.optString("id"))) return o;
        return null;
    }

    public int bagCount() { int n = 0; for (int v : bag.values()) n += v; return n; }

    public long bagWorth() {
        long v = 0;
        for (Map.Entry<String, Integer> e : bag.entrySet()) {
            JSONObject o = itemById(iconId(e.getKey()));
            if (o != null) v += (long) o.optInt("value") * e.getValue();
        }
        return v;
    }

    public double bagWeight() {
        double w = 0;
        for (Map.Entry<String, Integer> e : bag.entrySet()) {
            JSONObject o = itemById(iconId(e.getKey()));
            if (o != null) w += o.optDouble("weight", 0) * e.getValue();
        }
        return w;
    }

    /** 行囊一行：[图标 id, 显示名, 件数, 原键（含品阶）] */
    public java.util.List<String[]> bagRows() {
        java.util.List<String[]> rows = new java.util.ArrayList<>();
        for (Map.Entry<String, Integer> e : bag.entrySet()) {
            String key = e.getKey();
            int bar = key.indexOf('|');
            String id = iconId(key);
            String grade = bar < 0 ? "" : key.substring(bar + 1);
            JSONObject meta = itemById(id);
            String name = meta != null ? meta.optString("name") : key;
            if (!grade.isEmpty()) name += "·" + Grades.name(grade);
            rows.add(new String[]{id, name, String.valueOf(e.getValue()), key});
        }
        return rows;
    }

    private String iconId(String key) {
        int bar = key.indexOf('|');
        return bar < 0 ? key : key.substring(0, bar);
    }

    /** 分档显示（支持 long：行囊估价会超过 int） */
    public static String coinText(long v) { return coinText((int) Math.min(Integer.MAX_VALUE, Math.max(Integer.MIN_VALUE, v))); }

    public String buyBoots() {
        if (bootsBonus > 0) return "已经有靴子了。";
        if (coin < 600) return "靴子要 600 文。";
        coin -= 600; bootsBonus = 0.1; return "买了一双快靴（+10%）。";
    }

    public String buyGodspeedTalisman() {
        if (godspeed) return "神行符还在生效。";
        if (coin < 120) return "神行符要 120 文。";
        coin -= 120; godspeed = true; return "贴了一张神行符（×1.25）。";
    }

    public String learnQinggong() {
        if (martial > 0) return "轻功已经会了。";
        if (coin < 3000) return "学轻功要 3000 文束脩。";
        coin -= 3000; martial = 0.2; return "跟武师学了轻功（+20%）。";
    }

    /** 从行囊里把兵器/甲/符换上身，品阶决定加成 */
    public String equip(String key) {
        int bar = key.indexOf('|');
        String id = bar < 0 ? key : key.substring(0, bar);
        String grade = bar < 0 ? "mortal" : key.substring(bar + 1);
        if ("blade".equals(id)) { weaponGrade = grade; return "换上兵器：" + Grades.name(grade); }
        if ("armor".equals(id)) { armorGrade = grade; return "换上甲：" + Grades.name(grade); }
        if ("talisman".equals(id)) { talismanGrade = grade; return "换上符：" + Grades.name(grade); }
        return "这件不能装备。";
    }

    /** 个人状态：一行一项，给「个人」页用 */
    public String profileText() {
        StringBuilder b = new StringBuilder();
        b.append("心魇说 · ").append(realmLevel > 0 ? "修士" : "凡人").append("\n")
         .append("境界　").append(realmName()).append(layer > 0 ? "·炼气" + layer + "层" : "").append("\n")
         .append("灵根　").append(tested ? Roots.name(rootId) : "未测").append("\n")
         .append("气血　").append(String.format("%.0f/100", hp)).append("　体力 ").append(String.format("%.0f/100", stamina)).append("\n")
         .append("战力　").append(power()).append("\n")
         .append("业力　").append(karma).append("\n")
         .append("住处　").append(homeLevel > 0 ? "自有宅院（" + homeLevel + " 间）" : "客店 / 借住").append("\n")
         .append("身份　").append(sectName == null || sectName.isEmpty() ? "白身" : sectName).append("\n")
         .append("私兵　").append(men).append(" 人　马 ").append(horse ? "有" : "无").append("\n")
         .append("钱　　文 ").append(coin).append("　灵石 ").append(stones).append("\n")
         .append("行囊　").append(bagCount()).append("/").append(bagCap()).append(" 格 · 值 ").append(coinText(bagWorth())).append("\n")
         .append("移速　").append(speedText(px, py));
        return b.toString();
    }

    public String gearText() {
        return "兵器　" + Grades.name(weaponGrade) + "（×" + Grades.mult(weaponGrade) + "）\n"
             + "甲　　" + Grades.name(armorGrade) + "（×" + Grades.mult(armorGrade) + "）\n"
             + "符　　" + Grades.name(talismanGrade) + "（×" + Grades.mult(talismanGrade) + "）\n\n"
             + powerBreakdown();
    }

    public boolean isXiu() { return spirit > 60 && karma < 60; }

    /** 私兵招募：每人 14 银，上限 60（原生版先给一个人数上限） */
    public String recruit(int n) {
        int can = Math.min(n, Math.max(0, 60 - men));
        int cost = can * 300;
        if (can <= 0) return "私兵到顶了。";
        if (coin < cost) return "钱不够，还差 " + coinText(cost - coin) + "。";
        coin -= cost; men += can;
        note("招了 " + can + " 名私兵，花 " + coinText(cost) + "。");
        return "招到 " + can + " 人，花 " + coinText(cost) + "（现 " + men + " 人）";
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
            o.put("stamina", stamina); o.put("hp", hp); o.put("coin", coin);
            o.put("karma", karma); o.put("men", men); o.put("place", place);
            o.put("stones", stones); o.put("realmLevel", realmLevel); o.put("ship", ship);
            o.put("layer", layer); o.put("rootId", rootId); o.put("tested", tested);
            o.put("lawSpace", lawSpace); o.put("lawTime", lawTime);
            o.put("homeLevel", homeLevel); o.put("workDays", workDays);
            o.put("resWood", resWood); o.put("resStraw", resStraw); o.put("resStone", resStone);
            o.put("resClay", resClay); o.put("resIron", resIron); o.put("huts", huts);
            StringBuilder bg = new StringBuilder();
            for (Map.Entry<String, Integer> e : bag.entrySet()) bg.append(e.getKey()).append(':').append(e.getValue()).append(';');
            o.put("bag", bg.toString());
            o.put("techArms", techArms); o.put("techFarm", techFarm); o.put("techFort", techFort); o.put("sectName", sectName);
            o.put("disciples", disciples); o.put("throne", throne);
            o.put("practice", practiceProgress); o.put("pills", pills);
            o.put("boots", bootsBonus); o.put("wings", wings); o.put("godspeed", godspeed); o.put("vehicle", vehicle); o.put("martial", martial);
            o.put("weapon", weaponGrade); o.put("armor", armorGrade); o.put("talisman", talismanGrade);
            o.put("wounded", wounded); o.put("morale", morale); o.put("bias", bias);
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
            coin = o.optInt("coin", coin); karma = o.optInt("karma", karma); men = o.optInt("men", men);
            place = o.optString("place", place);
            stones = o.optInt("stones", stones); realmLevel = o.optInt("realmLevel", realmLevel); ship = o.optBoolean("ship", ship);
            layer = o.optInt("layer", layer); rootId = o.optString("rootId", rootId); tested = o.optBoolean("tested", tested);
            lawSpace = o.optDouble("lawSpace", lawSpace); lawTime = o.optDouble("lawTime", lawTime);
            homeLevel = o.optInt("homeLevel", homeLevel); workDays = o.optInt("workDays", workDays);
            resWood = o.optInt("resWood", resWood); resStraw = o.optInt("resStraw", resStraw);
            resStone = o.optInt("resStone", resStone); resClay = o.optInt("resClay", resClay);
            resIron = o.optInt("resIron", resIron); huts = o.optInt("huts", huts);
            techArms = o.optInt("techArms", techArms);
            bag.clear();
            String rawBag = o.optString("bag", "");
            if (rawBag.startsWith("{")) {
                // 旧存档把行囊存成 JSON 对象，迁到 id|品阶 记账
                try {
                    JSONObject old = new JSONObject(rawBag);
                    for (java.util.Iterator<String> it = old.keys(); it.hasNext(); ) {
                        String k = it.next();
                        String id = k.contains("妖丹") ? "core" : k.contains("精血") ? "pill"
                            : k.contains("皮") ? "skin" : k.contains("骨") ? "bone"
                            : k.contains("肉") ? "meat" : k.contains("干粮") ? "grain" : "grain";
                        bag.merge(id, old.optInt(k, 1), Integer::sum);
                    }
                } catch (Exception ignored) { }
            } else {
                for (String kv : rawBag.split(";")) {
                    if (kv.isEmpty()) continue;
                    int c = kv.lastIndexOf(':');
                    if (c <= 0) continue;
                    try { bag.merge(kv.substring(0, c), Integer.parseInt(kv.substring(c + 1)), Integer::sum); }
                    catch (NumberFormatException ignored) { }
                }
            } techFarm = o.optInt("techFarm", techFarm);
            techFort = o.optInt("techFort", techFort);
            sectName = o.has("sectName") ? o.optString("sectName", null) : sectName;
            disciples = o.optInt("disciples", disciples);
            throne = o.has("throne") ? o.optString("throne", null) : throne;
            practiceProgress = o.optDouble("practice", practiceProgress); pills = o.optInt("pills", pills);
            bootsBonus = o.optDouble("boots", bootsBonus); wings = o.optBoolean("wings", wings);
            godspeed = o.optBoolean("godspeed", godspeed); vehicle = o.optString("vehicle", vehicle);
            martial = o.optDouble("martial", martial);
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
