package com.xinyanshuo.xianfan.nativeapp;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.View;
import android.view.WindowInsets;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.InputStream;
import java.util.Map;

/** 原生壳：一个 Canvas 地图 + 原生 HUD + 原生按钮，没有 WebView。 */
public final class MainActivity extends Activity {
    private Sim sim;
    private MapView mapView;
    private TextView hud, hint;
    private final Handler ui = new Handler(Looper.getMainLooper());
    private long lastTick;
    private SharedPreferences prefs;

    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);
        prefs = getSharedPreferences("xianfan-native", MODE_PRIVATE);
        JSONObject world;
        try (InputStream in = getAssets().open("world.json")) {
            byte[] buf = new byte[in.available()];
            //noinspection ResultOfMethodCallIgnored
            in.read(buf);
            world = new JSONObject(new String(buf, "UTF-8"));
        } catch (Exception e) { throw new IllegalStateException("缺少 world.json", e); }
        sim = new Sim(world);
        sim.load(prefs.getString("save", ""));

        FrameLayout root = new FrameLayout(this);
        mapView = new MapView(this, sim);
        root.addView(mapView, new FrameLayout.LayoutParams(-1, -1));

        hud = new TextView(this);
        hud.setTextColor(Color.rgb(36, 30, 22));
        hud.setTextSize(13);
        hud.setPadding(28, 26, 28, 22);
        GradientDrawable bg = new GradientDrawable();
        bg.setColor(Color.argb(232, 250, 246, 236));
        bg.setCornerRadius(26);
        hud.setBackground(bg);
        FrameLayout.LayoutParams hlp = new FrameLayout.LayoutParams(-2, -2, Gravity.TOP | Gravity.START);
        hlp.setMargins(24, 40, 24, 0);
        root.addView(hud, hlp);

        hint = new TextView(this);
        hint.setTextColor(Color.argb(235, 250, 246, 236));
        hint.setTextSize(12);
        hint.setText("拖动看地图 · 双指缩放 · 点建筑或红点");
        hint.setPadding(24, 12, 24, 12);
        GradientDrawable hbg = new GradientDrawable();
        hbg.setColor(Color.argb(120, 20, 32, 24));
        hbg.setCornerRadius(30);
        hint.setBackground(hbg);
        FrameLayout.LayoutParams tlp = new FrameLayout.LayoutParams(-2, -2, Gravity.TOP | Gravity.CENTER_HORIZONTAL);
        tlp.setMargins(0, 40, 0, 0);
        root.addView(hint, tlp);

        LinearLayout bar = new LinearLayout(this);
        bar.setOrientation(LinearLayout.HORIZONTAL);
        bar.setPadding(12, 10, 12, 10);
        GradientDrawable bbg = new GradientDrawable();
        bbg.setColor(Color.argb(240, 244, 240, 230));
        bbg.setCornerRadius(28);
        bar.setBackground(bbg);
        String[][] tabs = {{"人物", "people"}, {"修行", "cult"}, {"妖兽", "wild"}, {"行囊", "bag"}, {"纪事", "log"}, {"星域", "star"}};
        for (String[] t : tabs) {
            Button bt = new Button(this);
            bt.setText(t[0]);
            bt.setTextSize(13);
            bt.setAllCaps(false);
            bt.setMinHeight(0);
            bt.setMinimumHeight(0);
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, 132, 1f);
            lp.setMargins(4, 0, 4, 0);
            bt.setLayoutParams(lp);
            bt.setOnClickListener(v -> open(t[1]));
            bar.addView(bt);
        }
        FrameLayout.LayoutParams blp = new FrameLayout.LayoutParams(-1, -2, Gravity.BOTTOM);
        blp.setMargins(20, 0, 20, 40);
        root.addView(bar, blp);

        mapView.setOnPick(this::onPick);
        setContentView(root);
        if (android.os.Build.VERSION.SDK_INT >= 35) {
            root.setOnApplyWindowInsetsListener((v, insets) -> {
                android.graphics.Insets i = insets.getInsets(WindowInsets.Type.systemBars());
                v.setPadding(i.left, i.top, i.right, i.bottom);
                return insets;
            });
            root.requestApplyInsets();
        }
        updateHud();
        ui.post(tick);
    }

    private final Runnable tick = new Runnable() {
        @Override public void run() {
            long now = System.currentTimeMillis();
            double dt = lastTick == 0 ? 0.016 : Math.min(0.1, (now - lastTick) / 1000.0);
            lastTick = now;
            sim.tick(dt);
            mapView.invalidate();
            if (++frames % 6 == 0) updateHud();
            ui.postDelayed(this, 16);
        }
    };
    private int frames;

    private void updateHud() {
        hud.setText(String.format("%s · %s\n银 %d · 灵石 %d · 私兵 %d · 体力 %.0f\n%s",
            sim.timeText(), sim.realmName(), sim.silver, sim.stones, sim.men, sim.stamina,
            sim.moving ? "前往：" + sim.targetName : "在" + nearestName()));
    }

    private String nearestName() {
        JSONObject s = sim.structureAt(sim.px, sim.py, 60);
        return s != null ? s.optString("name") : "城中";
    }

    private void onPick(float wx, float wy) {
        JSONObject den = sim.denAt(wx, wy, Math.max(45, 90 / mapView.zoom()));
        if (den != null) { denDialog(den); return; }
        JSONObject s = sim.structureAt(wx, wy, Math.max(40, 60 / mapView.zoom()));
        if (s != null) { placeDialog(s); return; }
        sim.goTo(wx, wy, "那儿");
        mapView.centerOn(sim.px, sim.py);
        toast("走过去");
    }

    private void placeDialog(JSONObject s) {
        new AlertDialog.Builder(this)
            .setTitle(s.optString("name"))
            .setMessage("类型：" + s.optString("kind") + "\n" + s.optString("note"))
            .setPositiveButton("前往门口", (d, w) -> { sim.goTo(s.optDouble("x"), s.optDouble("y") + 22, s.optString("name")); })
            .setNegativeButton("取消", null).show();
    }

    private void denDialog(JSONObject den) {
        boolean done = sim.cleared.contains(den.optString("id"));
        String info = String.format("%s · %s（妖%d）\n%d 只 · %.1f 米 · 气血 %d · 伤害 %d\n绝招 %s",
            den.optString("name"), den.optString("beast"), den.optInt("realm") + 1,
            den.optInt("count"), den.optDouble("meters"), den.optInt("hp"), den.optInt("dmg"), den.optString("move"));
        new AlertDialog.Builder(this)
            .setTitle(done ? "已讨平" : "妖兽巢穴")
            .setMessage(info)
            .setPositiveButton(done ? "知道了" : "带人去打", (d, w) -> {
                if (done) return;
                String r = sim.hunt(den);
                toast(r);
                updateHud();
                mapView.invalidate();
            })
            .setNegativeButton("先过去", (d, w) -> sim.goTo(den.optDouble("x"), den.optDouble("y") + 40, den.optString("name")))
            .show();
    }

    private void open(String what) {
        StringBuilder sb = new StringBuilder();
        if ("people".equals(what)) {
            sb.append("心魇说 · ").append(sim.realmLevel > 0 ? "修士" : "平民").append("\n")
              .append("境界 ").append(sim.realmName()).append(sim.layer > 0 ? "·" + sim.layer + "层" : "").append("\n")
              .append("灵根 ").append(sim.tested ? Roots.name(sim.rootId) : "未测").append("\n")
              .append("气血 ").append(String.format("%.0f", sim.hp)).append(" · 体力 ").append(String.format("%.0f", sim.stamina))
              .append(" · 业力 ").append(sim.karma).append("\n")
              .append("战力 ").append(sim.power()).append("\n\n").append(sim.powerBreakdown())
              .append("\n\n").append(sim.mortalRangeText());
        } else if ("cult".equals(what)) {
            sb.append("境界 ").append(sim.realmName()).append(sim.layer > 0 ? "·炼气" + sim.layer + "层" : "").append("\n")
              .append("修为 ").append(String.format("%.0f", sim.practiceProgress)).append("\n")
              .append("灵根 ").append(sim.tested ? Roots.name(sim.rootId) : "未测").append("\n")
              .append("战力 ").append(sim.power()).append("\n\n").append(sim.powerBreakdown())
              .append("\n\n").append(sim.mortalRangeText());
            new AlertDialog.Builder(this).setTitle("修行").setMessage(sb.toString())
                .setPositiveButton("测灵根", (x, w) -> { toast(sim.detectRoot()); updateHud(); })
                .setNeutralButton("吐纳 4 时辰", (x, w) -> { toast(sim.practice(4)); updateHud(); })
                .setNegativeButton("关闭", null).show();
            return;
        } else if ("wild".equals(what)) {
            for (JSONObject d : sim.dens) {
                sb.append(sim.cleared.contains(d.optString("id")) ? "✔ " : "· ")
                  .append(d.optString("name")).append("　").append(d.optString("beast"))
                  .append("（妖").append(d.optInt("realm") + 1).append("）×").append(d.optInt("count")).append("\n");
            }
        } else if ("bag".equals(what)) {
            for (Map.Entry<String, Integer> e : sim.bag.entrySet()) sb.append(e.getKey()).append(" ×").append(e.getValue()).append("\n");
        } else if ("log".equals(what)) {
            int from = Math.max(0, sim.log.size() - 18);
            for (int i = sim.log.size() - 1; i >= from; i--) sb.append(sim.log.get(i)).append("\n");
        } else if ("star".equals(what)) {
            JSONArray ds = sim.world.optJSONArray("domains");
            sb.append(sim.voidGateText()).append("\n\n");
            sb.append("行星：").append(sim.world.optJSONObject("planet").optString("name"))
              .append("，半径 ").append(sim.world.optJSONObject("planet").optInt("radiusKm")).append(" 公里\n\n");
            if (ds != null) for (int i = 0; i < ds.length(); i++) {
                JSONObject d = ds.optJSONObject(i);
                sb.append(d.optBoolean("home") ? "◎ " : "　").append(d.optString("name"));
                if (!d.optBoolean("home")) {
                    int need = (int) Math.max(20, Math.round(d.optDouble("distWkm") / 4e7));
                    sb.append("　").append(String.format("%.1f", d.optDouble("distWkm") / 10000.0)).append(" 万公里")
                      .append("　约 ").append(need).append(" 灵石");
                }
                sb.append("\n");
            }
            AlertDialog dlg = new AlertDialog.Builder(this).setTitle("星域与虚空").setMessage(sb.toString())
                .setPositiveButton("造星舰", (x, w) -> { toast(sim.buildShip()); updateHud(); })
                .setNeutralButton("看太虚", (x, w) -> { toast(sim.travelDomain(1)); updateHud(); })
                .setNegativeButton("关闭", null).create();
            dlg.show(); return;
        } else {
            sb.append("私兵 ").append(sim.men).append(" 人（上限 60）\n每人 14 银，月饷 2.2 银。\n");
            AlertDialog d = new AlertDialog.Builder(this).setTitle("招募").setMessage(sb.toString())
                .setPositiveButton("招 5 人", (x, w) -> { toast(sim.recruit(5)); updateHud(); }).setNegativeButton("关闭", null).create();
            d.show(); return;
        }
        new AlertDialog.Builder(this).setTitle(what.equals("people") ? "人物" : what.equals("wild") ? "妖兽巢穴" : what.equals("bag") ? "行囊" : "纪事")
            .setMessage(sb.length() == 0 ? "（空）" : sb.toString()).setPositiveButton("关闭", null).show();
    }

    private void toast(String s) { Toast.makeText(this, s, Toast.LENGTH_SHORT).show(); }

    @Override protected void onPause() {
        super.onPause();
        String raw = sim.save();
        if (raw != null) prefs.edit().putString("save", raw).apply();
    }
}
