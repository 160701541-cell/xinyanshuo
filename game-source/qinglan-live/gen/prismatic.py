"""棱彩规则引擎：世界上恒有 10 件棱彩物品，同时最多 9 人被持有，最弱持有者会被淘汰。
另含棱彩人物的保命曲线与气运下限。所有判定都走真实随机。
"""
import random, json
random.seed(99)

SLOTS = 10
MAX_HELD = 9
REALMS = ["炼气","筑基","金丹","元婴","化神","炼虚","合体","大乘","渡劫"]
# 境界越高，保命越弱（元婴之前几乎不死）
PROTECT = [0.995,0.99,0.98,0.97,0.70,0.45,0.25,0.10,0.03]
PRISM_LUCK_FLOOR = 72      # 棱彩人物气运下限（0-100）
PRISM_LUCK_MEAN = 84

class Item:
    def __init__(self, i):
        self.id = i; self.holder = None; self.history = []; self.dormant_years = 0

class Person:
    _n = 0
    def __init__(self, prismatic=False, realm=4, power=None, luck=None):
        Person._n += 1
        self.id = Person._n; self.prismatic = prismatic
        self.realm = realm
        self.power = power if power is not None else random.gauss(50, 15)
        self.luck = luck if luck is not None else (random.gauss(PRISM_LUCK_MEAN, 6) if prismatic else random.gauss(45, 15))
        self.luck = max(PRISM_LUCK_FLOOR, self.luck) if prismatic else max(0, min(100, self.luck))
        self.alive = True; self.items = []

world = {"items": [Item(i) for i in range(SLOTS)], "people": [], "year": 0,
         "evictions": 0, "unheld_max": 0, "held_log": []}

def held_count():
    return sum(1 for it in world["items"] if it.holder and it.holder.alive)

def spawn(n=1, prismatic_p=0.0001):
    for _ in range(n):
        pr = random.random() < prismatic_p
        realm = random.randint(4, 8) if pr else random.randint(0, 7)
        world["people"].append(Person(prismatic=pr, realm=realm))

def try_claim(p):
    """尝试拿一件无主棱彩；若已 9 人持有，则最弱持有者被淘汰"""
    free = [it for it in world["items"] if it.holder is None]
    if not free:
        return None
    it = random.choice(free)
    holders = [q for q in world["people"] if q.alive and q.items]
    if len(holders) >= MAX_HELD:
        weakest = min(holders, key=lambda q: q.power)
        lost = weakest.items.pop()
        lost.holder = None
        world["evictions"] += 1
        weakest.power *= 0.72          # 被夺者元气大伤
    it.holder = p; p.items.append(it)
    it.history.append((world["year"], p.id))
    return it

def step(years=1):
    for _ in range(years):
        world["year"] += 1
        spawn(random.choices([0,1,2,3],[0.35,0.4,0.2,0.05])[0])
        # 每个活人可能有欲求：气运越高越容易"撞上"棱彩
        for p in list(world["people"]):
            if not p.alive or p.items: continue
            chance = 0.0008 * (1 + p.luck / 40.0) * (1.6 if p.prismatic else 1.0)
            if random.random() < chance:
                try_claim(p)
        # 死亡判定：棱彩保命强，凡人易死
        for p in list(world["people"]):
            if not p.alive: continue
            age_risk = 0.0009
            if p.prismatic:
                prot = PROTECT[p.realm] if p.realm < len(PROTECT) else 0.02
                risk = age_risk * (1 - prot) * 0.25
            else:
                risk = age_risk * (1 + 0.25 * p.realm)
            if random.random() < risk:
                p.alive = False
                for it in p.items:
                    it.holder = None
                p.items = []
        held = held_count()
        world["held_log"].append(held)
        if held > world["unheld_max"]:
            world["unheld_max"] = held

if __name__ == "__main__":
    spawn(4000)
    step(600)
    held = [h for h in world["held_log"] if h > 0]
    print("模拟 600 年")
    print("棱彩物品总数:", SLOTS, " 同时被持有最大值:", world["unheld_max"], "(上限 9)")
    print("历史上至少被拿过的件数:", sum(1 for it in world["items"] if it.history))
    print("易主次数合计:", sum(len(it.history) for it in world["items"]))
    print("淘汰（最弱被顶掉）次数:", world["evictions"])
    pr = [p for p in world["people"] if p.prismatic]
    alive_pr = [p for p in pr if p.alive]
    print(f"棱彩人物 {len(pr)} 人，存活 {len(alive_pr)}，平均境界 {sum(p.realm for p in alive_pr)/max(1,len(alive_pr)):.2f}")
    other = [p for p in world["people"] if not p.prismatic]
    print(f"普通人物 {len(other)} 人，存活 {sum(1 for p in other if p.alive)}")
    # 保命曲线
    json.dump({"protect": PROTECT, "held_max": world["unheld_max"], "evictions": world["evictions"]},
              open("prismatic_stats.json","w"), ensure_ascii=False, indent=1)
