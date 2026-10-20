#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""自我迭代优化协议 v1.0 —— 轮次台账校验器。

用法:
    python3 tools/self_iteration/check_round.py tools/self_iteration/rounds/round-1.json

作用: 把 docs/SELF_ITERATION_OPTIMIZATION_PROTOCOL_V1.md 第 2 节的门槛表变成机器判定。
- 指标在门槛内 -> PASS; 在阈值外 -> FAIL; 键缺失/值为 null -> BLOCKED(不许猜)
- 严禁把 aesthetic 填成 PASS(第 5 节禁令), 填了直接判违规并 exit 2
- exit 0 仅当所有适用指标 PASS 且无违规

无第三方依赖, 纯标准库。
"""
import json
import sys

# 指标 -> (比较方式, 阈值, 人类可读门槛)
THRESHOLDS = {
    "delta_L":            ("min", 25.0,  "主体/背景明度差 ΔL* >= 25"),
    "accent_area_pct":    ("range", (3.0, 8.0), "点缀色面积占比 3%-8%"),
    "delta_E00":          ("max", 6.0,   "主色漂移 ΔE00 <= 6"),
    "outline_px":         ("range", (1.5, 2.5), "屏幕空间描边宽度 1.5-2.5 px"),
    "parts_readable":     ("min", 5,     "四视图可辨部件数 >= 5"),
    "neck_gap_px":        ("max", 0,     "颈/关节穿帮空隙 = 0 px"),
}
# 依赖当轮预算, 不在本表内硬判, 只要求存在并回显
BUDGET_KEYS = ("triangles", "head_torso_leg_ratio", "frame_ms_p95")

REQUIRED_TOP = ("round", "date", "target", "branch", "commit", "changes",
                "renders", "metrics", "verdict", "attribution", "lessons", "next")

VIOLATIONS = []


def gate(key, value):
    if value is None:
        return "BLOCKED", "未测出/未提供 —— 不许填估计值, 须补测或标 BLOCKED 原因"
    spec = THRESHOLDS.get(key)
    if not spec:
        return "N/A", "非门槛指标(回显)"
    mode, thr, human = spec
    try:
        v = float(value)
    except (TypeError, ValueError):
        return "BLOCKED", "非数值: %r" % (value,)
    if mode == "min" and v < thr:
        return "FAIL", human
    if mode == "max" and v > thr:
        return "FAIL", human
    if mode == "range" and not (thr[0] <= v <= thr[1]):
        return "FAIL", human
    return "PASS", human


def main(path):
    with open(path, encoding="utf-8") as f:
        rec = json.load(f)

    missing = [k for k in REQUIRED_TOP if k not in rec]
    if missing:
        VIOLATIONS.append("台账缺字段: %s (协议第 3 节字段固定)" % ", ".join(missing))

    # R3: 没有渲染图 -> R4/R5 非法
    renders = rec.get("renders") or []
    if len(renders) < 4:
        VIOLATIONS.append("四视图不足: 只有 %d 张, R3 要求 >=4 (正/侧/背/三视角)" % len(renders))

    verdict = rec.get("verdict") or {}
    if str(verdict.get("aesthetic", "")).upper() == "PASS":
        VIOLATIONS.append("违规自批审美: aesthetic=PASS 只能由用户/人工判定 (协议第 5 节)")

    changes = rec.get("changes") or []
    if len(changes) > 1:
        VIOLATIONS.append("违反 R7 最小改动: 本轮声明改了 %d 个变量族群, 必须只改一个" % len(changes))

    print("=" * 62)
    print("轮次 %s | %s | %s" % (rec.get("round"), rec.get("date"), rec.get("target")))
    print("分支 %s | 提交 %s" % (rec.get("branch"), str(rec.get("commit"))[:12]))
    print("-" * 62)
    print("%-20s %-12s %-10s %s" % ("指标", "实测", "判定", "门槛"))
    metrics = rec.get("metrics") or {}
    if not metrics:
        VIOLATIONS.append("metrics 为空 —— R4 未执行")
    worst = "PASS"
    for key in list(THRESHOLDS) + [k for k in BUDGET_KEYS if k in metrics]:
        v = metrics.get(key)
        state, human = gate(key, v)
        if state == "FAIL":
            worst = "FAIL"
        elif state == "BLOCKED" and worst == "PASS":
            worst = "BLOCKED"
        print("%-20s %-12s %-10s %s" % (key, "-" if v is None else v, state, human))
    skipped = [k for k in THRESHOLDS if k not in metrics]
    if skipped:
        print("-" * 62)
        print("未提供的门槛指标: %s" % ", ".join(skipped))
    print("-" * 62)
    print("技术判定: %s | 审美判定: %s (人工)" % (worst, verdict.get("aesthetic", "PENDING")))
    print("归因: %s" % rec.get("attribution", "(空)"))
    print("教训: %s" % rec.get("lessons", "(空)"))
    print("下一轮唯一变量: %s" % rec.get("next", "(空)"))
    print("=" * 62)

    if VIOLATIONS:
        print("\n违规 %d 项:" % len(VIOLATIONS))
        for v in VIOLATIONS:
            print("  - %s" % v)
        return 2
    if worst != "PASS":
        return 1
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(64)
    sys.exit(main(sys.argv[1]))
