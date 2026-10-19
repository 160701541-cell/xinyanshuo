import json, random, statistics
random.seed(20261019)

GRADES = ["凡物","灵品","玄品","地品","天品","仙品","棱彩"]
N0 = [1,2,2,3,3,4,4]                  # 该阶基础词条数
BIAS_P = 0.055                        # 偏科概率（越阶高越常见一点，但总体少见）
GRADE_W = [0.52,0.24,0.12,0.065,0.032,0.015,0.008]   # 相对权重（归一到材料阶之后再用）

# 通用池：加基础属性
GENERIC = [
    ("攻击", 4, 9), ("防御", 3, 8), ("气血", 12, 30), ("灵力", 8, 22),
    ("身法", 2, 6), ("暴击", 1, 4), ("破甲", 2, 7),
]
# 属性池：元素加成（百分比），带一条附带的固定属性
ELEM = [
    ("木", "攻击"), ("火", "暴击"), ("土", "防御"), ("金", "破甲"), ("水", "灵力"), ("雷", "身法"),
]

def affix_mult(tier):        # tier 0..3
    return [1.00, 1.18, 1.40, 1.70][tier]

def roll_delta(m):
    """材料越好，越难再往上跳：0 阶材料爱出杂货，高阶材料才可能出精品"""
    base = [0.62,0.22,0.10,0.042,0.014,0.004]
    # 材料每高一阶，向上跳的权重整体乘 0.86，向下（0）补回来
    up = [w * (0.86 ** m) for w in base[1:]]
    w = [1.0 - sum(up)] + up
    return random.choices([0,1,2,3,4,5], w)[0]

def forge(mat_grade, craft_cap, tier):
    """mat_grade: 材料阶 0..6；craft_cap: 匠人可及的最高阶；tier: 0..3"""
    g = min(mat_grade + roll_delta(mat_grade), craft_cap)
    g = max(0, min(6, g))
    n0 = N0[g]
    p_bias = min(0.09, BIAS_P * (1.0 + 0.10 * g))
    bias = random.random() < p_bias
    n = 1 if bias else n0
    mult = affix_mult(tier) * (2.30 if bias else 1.0) * (1.0 + 0.12 * g)
    affixes = []
    for _ in range(n):
        if random.random() < 0.34:
            e, k = random.choice(ELEM)
            v = round(random.uniform(0.8, 2.2) * mult, 1)
            affixes.append({"kind":"elem","text":f"{k} +{v}%{e}之行" if False else f"{k}属性 +{v}%","v":v})
        else:
            k, lo, hi = random.choice(GENERIC)
            v = int(round(random.uniform(lo, hi) * mult))
            affixes.append({"kind":"gen","text":f"{k} +{v}","v":v})
    worth = (12.0 * (2.08 ** g)) * (1.0 if not bias else 1.75) * (1.0 + 0.06 * n)
    return {"grade":GRADES[g],"g":g,"tier":tier,"bias":bias,"n":n,"affixes":affixes,"worth":round(worth,1)}

def run(N=40000):
    rows=[]
    for m in range(7):
        cost = 10.0 * (2.02 ** m) + 6.0
        tot=0.0; gains=0; biases=0; upsig=0; dist={}
        for _ in range(N):
            tier = random.choices([0,1,2,3],[0.42,0.30,0.20,0.08])[0]
            it = forge(m, min(6, m+2), tier)
            tot += it["worth"]; gains += it["worth"] - cost
            biases += 1 if it["bias"] else 0
            upsig += 1 if it["g"] > m else 0
            dist[it["grade"]] = dist.get(it["grade"],0)+1
        rows.append({"mat":GRADES[m],"cost":round(cost,1),
                     "avg":round(tot/N,1),"roi":round((tot/N)/cost,2),
                     "bias_pct":round(100.0*biases/N,2),
                     "up_pct":round(100.0*upsig/N,2),
                     "dist":{k:round(100.0*v/N,2) for k,v in dist.items()}})
    return rows

if __name__ == "__main__":
    rows=run()
    json.dump(rows, open("forge_stats.json","w"), ensure_ascii=False, indent=1)
    for r in rows:
        print(f'{r["mat"]:>3} 成本{r["cost"]:>7} 期望{r["avg"]:>8} ROI {r["roi"]:>5}  越阶率 {r["up_pct"]:>5}%  偏科 {r["bias_pct"]:>5}%')
    # 三个偏科样例
    samples=[]
    want = [("gen",0), ("elem",3), ("gen",5)]
    for kind, m in want:
        for _ in range(20000):
            it = forge(m, 6, random.choice([0,1,2,3]))
            if it["bias"] and it["affixes"][0]["kind"] == kind:
                samples.append(it); break
    json.dump(samples, open("bias_samples.json","w"), ensure_ascii=False, indent=1)
    for s in samples:
        print("样例", s["grade"], "偏科", [(a["text"]) for a in s["affixes"]], "价值", s["worth"])
