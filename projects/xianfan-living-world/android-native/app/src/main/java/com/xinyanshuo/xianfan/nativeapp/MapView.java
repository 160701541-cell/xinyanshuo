package com.xinyanshuo.xianfan.nativeapp;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.RectF;
import android.view.GestureDetector;
import android.view.MotionEvent;
import android.view.ScaleGestureDetector;
import android.view.View;

import org.json.JSONObject;

import java.io.InputStream;

/** 原生 Canvas 地图：一张烘焙好的 PNG，加相机、手势与标记。 */
public final class MapView extends View {
    public interface OnPick { void pick(float wx, float wy); }

    private Bitmap map;
    private final Sim sim;
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Matrix m = new Matrix();
    private final RectF dst = new RectF();
    private float cx = 0, cy = 0;         // 相机中心（米）
    private float scale = 1.0f;           // 1 = 整城
    private float pxPerM = 1;             // 图像像素/米
    private float vw = 1, vh = 1;
    private OnPick onPick;
    private final GestureDetector gestures;
    private final ScaleGestureDetector scaler;
    private float downX, downY;
    private boolean dragged;

    public MapView(Context ctx, Sim sim) {
        super(ctx);
        this.sim = sim;
        try (InputStream in = ctx.getAssets().open("map.png")) { map = BitmapFactory.decodeStream(in); }
        catch (Exception e) { map = null; }
        double extent = sim.world.optDouble("extent", 840);
        if (map != null) pxPerM = (float) (map.getWidth() / (extent * 2));
        gestures = new GestureDetector(ctx, new GestureDetector.SimpleOnGestureListener() {
            @Override public boolean onDown(MotionEvent e) { downX = e.getX(); downY = e.getY(); dragged = false; return true; }
            @Override public boolean onScroll(MotionEvent e1, MotionEvent e2, float dx, float dy) {
                if (Math.abs(e2.getX() - downX) + Math.abs(e2.getY() - downY) > 18) dragged = true;
                cx += dx / (pxPerM * scale);
                cy += dy / (pxPerM * scale);
                clampCam(); invalidate(); return true;
            }
            @Override public boolean onSingleTapUp(MotionEvent e) {
                if (dragged) return false;
                if (onPick != null) onPick.pick(screenToWorldX(e.getX()), screenToWorldY(e.getY()));
                return true;
            }
            @Override public boolean onDoubleTap(MotionEvent e) {
                float wx = screenToWorldX(e.getX()), wy = screenToWorldY(e.getY());
                zoomAt(wx, wy, 2.0f); return true;
            }
        });
        scaler = new ScaleGestureDetector(ctx, new ScaleGestureDetector.SimpleOnScaleGestureListener() {
            @Override public boolean onScale(ScaleGestureDetector d) {
                float wx = screenToWorldX(d.getFocusX()), wy = screenToWorldY(d.getFocusY());
                zoomAt(wx, wy, d.getScaleFactor()); return true;
            }
        });
    }

    public void setOnPick(OnPick p) { onPick = p; }
    public float zoom() { return scale; }

    private void zoomAt(float wx, float wy, float f) {
        float before = scale;
        scale = Math.max(0.85f, Math.min(9f, scale * f));
        // 以手指位置为锚：缩放后该世界点仍在屏幕同一处
        cx = wx + (cx - wx) * (before / scale);
        cy = wy + (cy - wy) * (before / scale);
        clampCam(); invalidate();
    }

    private void clampCam() {
        float halfW = vw / (pxPerM * scale) / 2f, halfH = vh / (pxPerM * scale) / 2f;
        float lim = 1500;
        cx = Math.max(-lim + halfW, Math.min(lim - halfW, cx));
        cy = Math.max(-lim + halfH, Math.min(lim - halfH, cy));
    }

    public float screenToWorldX(float sx) { return cx + (sx - vw / 2f) / (pxPerM * scale); }
    public float screenToWorldY(float sy) { return cy + (sy - vh / 2f) / (pxPerM * scale); }
    private float worldToScreenX(float wx) { return (wx - cx) * pxPerM * scale + vw / 2f; }
    private float worldToScreenY(float wy) { return (wy - cy) * pxPerM * scale + vh / 2f; }

    public void centerOn(double x, double y) { cx = (float) x; cy = (float) y; clampCam(); invalidate(); }

    @Override protected void onSizeChanged(int w, int h, int ow, int oh) {
        super.onSizeChanged(w, h, ow, oh); vw = w; vh = h;
        if (scale < 1.2f) scale = Math.max(w, h) / (float) (1680 * pxPerM) * 1.15f;
        clampCam();
    }

    @Override protected void onDraw(Canvas c) {
        c.drawColor(Color.rgb(20, 30, 22));
        if (map != null) {
            m.reset();
            m.postScale(scale, scale);
            m.postTranslate(vw / 2f - cx * pxPerM * scale, vh / 2f - cy * pxPerM * scale);
            c.drawBitmap(map, m, paint);
        }
        // 巢穴
        for (JSONObject d : sim.dens) {
            float x = worldToScreenX((float) d.optDouble("x")), y = worldToScreenY((float) d.optDouble("y"));
            if (x < -40 || y < -40 || x > vw + 40 || y > vh + 40) continue;
            boolean done = sim.cleared.contains(d.optString("id"));
            paint.setColor(done ? Color.rgb(120, 120, 110) : Color.rgb(176, 46, 34));
            c.drawCircle(x, y, 7 + d.optInt("realm") * 2, paint);
            paint.setColor(Color.WHITE);
            c.drawCircle(x, y, 2.5f, paint);
            if (scale > 2.2f) {
                paint.setColor(Color.rgb(60, 30, 20)); paint.setTextSize(26);
                c.drawText(d.optString("name"), x + 12, y + 9, paint);
            }
        }
        // 街上的人：小点 + 锁定光圈
        for (JSONObject n : sim.npcs) {
            float x = worldToScreenX((float) sim.npcX(n.optString("id"))), y = worldToScreenY((float) sim.npcY(n.optString("id")));
            if (x < -20 || y < -20 || x > vw + 20 || y > vh + 20) continue;
            boolean lock = sim.locked != null && sim.locked.equals(n.optString("id"));
            paint.setColor(lock ? Color.rgb(210, 160, 60) : Color.rgb(58, 46, 34));
            c.drawCircle(x, y - 6, 4.2f, paint);
            paint.setColor(lock ? Color.rgb(240, 200, 110) : Color.rgb(96, 78, 56));
            c.drawRect(x - 3, y - 3, x + 3, y + 5, paint);
            if (lock) {
                paint.setStyle(Paint.Style.STROKE); paint.setStrokeWidth(2.5f);
                paint.setColor(Color.argb(200, 240, 200, 110));
                c.drawCircle(x, y - 1, 22, paint);
                paint.setStyle(Paint.Style.FILL);
            }
            if (scale > 2.4f) {
                paint.setTextSize(22); paint.setColor(Color.rgb(44, 34, 22));
                c.drawText(n.optString("name"), x + 8, y - 10, paint);
            }
        }
        // 建筑：地图上已经画出来了，这里只在放大时标名字
        for (JSONObject s : sim.structures) {
            float x = worldToScreenX((float) s.optDouble("x")), y = worldToScreenY((float) s.optDouble("y"));
            if (x < -60 || y < -60 || x > vw + 60 || y > vh + 60) continue;
            if (scale > 3.4f) {
                paint.setTextSize(24); paint.setColor(Color.rgb(38, 30, 20));
                c.drawText(s.optString("name"), x + 30, y - 26, paint);
            }
        }
        // 玩家
        float px = worldToScreenX((float) sim.px), py = worldToScreenY((float) sim.py);
        paint.setColor(Color.rgb(36, 74, 168));
        c.drawCircle(px, py - 14, 9, paint);
        c.drawRect(px - 5, py - 6, px + 5, py + 10, paint);
        paint.setColor(Color.rgb(246, 232, 196));
        c.drawCircle(px, py - 16, 4, paint);
        if (sim.moving) {
            float tx = worldToScreenX((float) sim.tx), ty = worldToScreenY((float) sim.ty);
            paint.setColor(Color.argb(150, 40, 60, 120));
            paint.setStrokeWidth(3);
            c.drawLine(px, py, tx, ty, paint);
        }
    }

    @Override public boolean onTouchEvent(MotionEvent e) {
        scaler.onTouchEvent(e);
        gestures.onTouchEvent(e);
        return true;
    }
}
