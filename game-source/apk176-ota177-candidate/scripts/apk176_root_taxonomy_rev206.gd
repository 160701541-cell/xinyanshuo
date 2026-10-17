extends RefCounted
## REV206: data-authoritative expandable xianxia spiritual-root taxonomy.
## "Mortal" is a cultivation stage, NOT an absence of spiritual aptitude.
## Player + ordinary named NPCs ALWAYS own a stable hidden spirit root.
## Only recruited/bonded laborers may lack a root. Roots grant affinity but
## NEVER grant learned spells, Qi, materials or cultivator status by themselves.
## Inspired by broad xianxia genre conventions, not a copy of one novel's IP.
const SCHEMA: int=206
const BASE: Array[String]=["金","木","水","火","土"]
const ELEMENTS: Dictionary={
  "金":{"color":"#e7d5a1","effect":"pierce","debuff":"破甲","terrain":"精炼金属/剑器共鸣","counter":"木","weak":"火","attack":"金刃斩/飞剑剑气"},
  "木":{"color":"#78d47e","effect":"entangle","debuff":"缠绕","terrain":"灵植催生/疗愈/木灵侦察","counter":"土","weak":"金","attack":"藤蔓束缚/青木愈"},
  "水":{"color":"#62baed","effect":"soak","debuff":"浸湿","terrain":"聚水/净化/水脉寻踪","counter":"火","weak":"土","attack":"水箭/水幕盾"},
  "火":{"color":"#ff733a","effect":"burn","debuff":"灼烧","terrain":"点燃/炼丹火候/驱寒","counter":"金","weak":"水","attack":"炎弹/火雨/焚焰"},
  "土":{"color":"#c99c61","effect":"slow","debuff":"迟缓","terrain":"固地/探矿/土盾","counter":"水","weak":"木","attack":"岩锥/地脉障"},
  "风":{"color":"#b6eddb","effect":"push","debuff":"击退","terrain":"御风/风向/追踪气味","counter":"雾","weak":"土","attack":"风刃/疾风步"},
  "雷":{"color":"#ae87ff","effect":"shock","debuff":"麻痹","terrain":"导电/破邪/引雷","counter":"水","weak":"土","attack":"雷击/雷链"},
  "冰":{"color":"#85e6ff","effect":"freeze","debuff":"寒冻","terrain":"凝冰/保鲜/延缓腐化","counter":"火","weak":"火","attack":"冰棱/霜域"},
  "光":{"color":"#fff2b6","effect":"purify","debuff":"致盲","terrain":"照明/破幻/光系净化","counter":"暗","weak":"暗","attack":"耀光/净光印"},
  "暗":{"color":"#805cbd","effect":"blind","debuff":"暗蚀","terrain":"遮蔽/隐匿/藏影","counter":"光","weak":"光","attack":"暗影缚/蚀影"},
  "毒":{"color":"#98c854","effect":"poison","debuff":"中毒","terrain":"辨药毒/炼毒/抗瘴","counter":"木","weak":"火","attack":"毒雾/蚀脉"},
  "血":{"color":"#d44a63","effect":"bleed","debuff":"流血","terrain":"血迹追踪/凝血","counter":"生","weak":"光","attack":"血刃/血影"},
  "魂":{"color":"#c7a7ff","effect":"soul","debuff":"神识动摇","terrain":"神识感应/招魂（需法门）","counter":"幻","weak":"雷","attack":"摄魂铃/神识刺"},
  "阴":{"color":"#8797bb","effect":"yin","debuff":"阴寒","terrain":"聚阴/夜行/镇魂","counter":"阳","weak":"阳","attack":"玄阴掌/寒魄气"},
  "阳":{"color":"#ffe0a2","effect":"yang","debuff":"阳灼","terrain":"驱邪/暖脉/日照汲灵","counter":"阴","weak":"阴","attack":"纯阳焰/阳元盾"},
  "星":{"color":"#b6cfff","effect":"star","debuff":"星印","terrain":"星象/夜行导航/星轨阵","counter":"幻","weak":"暗","attack":"星辉雨/陨星印"},
  "空":{"color":"#97b7e9","effect":"space","debuff":"空间错位","terrain":"储物/短距挪移（须境界与法门）","counter":"土","weak":"时","attack":"裂空刃/缩地"},
  "时":{"color":"#e4cba0","effect":"time","debuff":"时滞","terrain":"灵植时间感知（非免费加速）","counter":"空","weak":"因果","attack":"缓时域/时序印"},
  "幻":{"color":"#e49cd1","effect":"illusion","debuff":"迷幻","terrain":"幻景/伪装/反侦查","counter":"魂","weak":"光","attack":"迷魂阵/幻影步"},
  "音":{"color":"#f6accb","effect":"sonic","debuff":"震荡","terrain":"寻声/音律阵/兽群安抚","counter":"幻","weak":"金","attack":"音波斩/摄音"},
  "磁":{"color":"#6cc8d1","effect":"magnet","debuff":"吸附","terrain":"矿物感知/磁控金属（须法门）","counter":"金","weak":"土","attack":"磁极牵引"},
  "生":{"color":"#a2e39a","effect":"heal","debuff":"生机逆转","terrain":"愈合/催生/延续（耗真实资源）","counter":"死","weak":"死","attack":"生生印/复苏灵息"},
  "死":{"color":"#777f98","effect":"decay","debuff":"衰败","terrain":"腐朽探知/遗骸残念","counter":"生","weak":"生","attack":"死气侵蚀"},
  "梦":{"color":"#d7b9fd","effect":"dream","debuff":"困梦","terrain":"入梦/梦境探知（须同意或抵抗判定）","counter":"魂","weak":"光","attack":"浮梦障"},
  "重":{"color":"#8f918f","effect":"gravity","debuff":"压制","terrain":"沉降/稳身/重力阵","counter":"风","weak":"空","attack":"镇岳压"},
  "虚":{"color":"#b2a3c8","effect":"void","debuff":"虚化","terrain":"穿隙/隔绝神识（需高境界）","counter":"空","weak":"光","attack":"虚灭指"},
  "因果":{"color":"#e8b78f","effect":"karma","debuff":"业障","terrain":"追溯因果线索（受限）","counter":"幻","weak":"无","attack":"因果印"},
  "轮回":{"color":"#a9a8d8","effect":"cycle","debuff":"轮回印","terrain":"魂契记忆/生死轮转（非复活捷径）","counter":"魂","weak":"因果","attack":"六道轮印"},
  "造化":{"color":"#9dddc4","effect":"creation","debuff":"造化失衡","terrain":"材料性质演化（真实消耗材料）","counter":"死","weak":"虚","attack":"造化衍化"},
  "混沌":{"color":"#d3a6db","effect":"chaos","debuff":"灵息紊乱","terrain":"诸相容纳但消耗巨大","counter":"金","weak":"自身反噬","attack":"混沌气旋"},
  "鸿蒙":{"color":"#b39ce3","effect":"primordial","debuff":"鸿蒙失衡","terrain":"万灵同源（极稀有且有代价）","counter":"无","weak":"反噬","attack":"鸿蒙紫气"},
  "虚无":{"color":"#b1aabe","effect":"nihility","debuff":"灵力湮灭","terrain":"湮灭/隔绝（会毁真实资源）","counter":"造化","weak":"阳","attack":"归虚术"}
}
# Classification is separate from element: five-way mixed "伪灵根" still
# EXISTS. Mutation/rarity, aptitude, bloodline and constitution are different
# axes and must never replace the birth spirit root.
const MUTATIONS: Dictionary={
  "火风":["火","风"],"木雷":["木","雷"],"雷火":["雷","火"],
  "水冰":["水","冰"],"阴冰":["阴","冰"],"阴阳":["阴","阳"],
  "风雷":["风","雷"],"金磁":["金","磁"],"木毒":["木","毒"],
  "水魂":["水","魂"],"星空":["星","空"],"空时":["空","时"],
  "生死":["生","死"],"光暗":["光","暗"],
  "五行均衡":["金","木","水","火","土"],
  "混沌":["混沌"],"鸿蒙":["鸿蒙"],"虚无":["虚无"],
  "因果":["因果"],"轮回":["轮回"],"造化":["造化"]
}
const GRADES: Array[String]=[
  "残灵根","伪灵根","杂灵根","凡品","中品","上品",
  "地灵根","天灵根","极品天灵根","异灵根","圣灵根",
  "仙灵根","先天灵根","太初道根"]
const CONSTITUTIONS: Array[String]=[
  "凡体","剑骨","天生道体","先天剑胎","荒古圣体","混沌圣体",
  "玄阴体","纯阳体","寒髓体","雷灵体","龙血体","凤灵体",
  "九窍玲珑心","先天药体","不灭战体","五行道体",
  "无垢仙体","天煞孤星","噬灵体","灵眸","百脉通明",
  "轮回道体","重瞳","妖族血脉","古巫体"]
const ROOT_ACCESS_NORMAL: String="guaranteed"
const ROOT_ACCESS_BOUND_LABOR: String="may_lack"

func _stable_rng(seed: int,entity_id: String) -> RandomNumberGenerator:
  var n: int=seed & 0x7fffffff
  for j in range(entity_id.length()):
    n=(n*1664525+entity_id.unicode_at(j)+1013904223)&0x7fffffff
  var r:=RandomNumberGenerator.new()
  r.seed=n
  return r

func _all_elements() -> Array:
  return ELEMENTS.keys()

func generate(seed: int,entity_id: String,role: String="citizen") -> Dictionary:
  # Do NOT use the phrase "mortal" to decide talent: mortals can have roots.
  var labor: bool=role in ["bonded_labor","enslaved_labor","recruitable_servant"]
  var rng:=_stable_rng(seed,entity_id+"-XIANXIA-V206")
  if labor and rng.randf()<0.35:
    return {"schema":SCHEMA,"entity_id":entity_id,"has_root":false,
      "kind":"无灵根","roots":[],"root_weights":[0,0,0,0,0],
      "grade":"无","constitution":"凡体","detected":false,
      "origin":"bonded_labor_exception","talent_score":0}
  var root_count: int=1
  var q: float=rng.randf()
  if q>=0.10 and q<0.38:
    root_count=2
  elif q>=0.38 and q<0.72:
    root_count=3
  elif q>=0.72 and q<0.89:
    root_count=4
  elif q>=0.89:
    root_count=5
  var roots: Array=[]
  var pool: Array=BASE.duplicate()
  while roots.size()<root_count:
    var j: int=rng.randi_range(0,pool.size()-1)
    roots.append(pool[j])
    pool.remove_at(j)
  # Mutation is rarer than ordinary five-element mixed roots; a few
  # transcendent roots are vanishingly rare, NEVER default powers.
  var variant: String=""
  var rare: float=rng.randf()
  if rare<0.002:
    var mythic: Array=["混沌","鸿蒙","虚无","因果","轮回","造化"]
    variant=String(mythic[rng.randi_range(0,mythic.size()-1)])
  elif rare<0.065:
    var mutations: Array=MUTATIONS.keys().filter(func(k): return k not in [
      "混沌","鸿蒙","虚无","因果","轮回","造化"])
    variant=String(mutations[rng.randi_range(0,mutations.size()-1)])
  if variant!="":
    roots=MUTATIONS[variant].duplicate()
  var scores: Array=[]
  var highest: int=0
  for elem in BASE:
    var weight: int=rng.randi_range(4,28)
    if roots.has(elem):
      weight=rng.randi_range(50,99)
    scores.append(weight)
    highest=maxi(highest,weight)
  var grade: String="杂灵根" if roots.size()>=4 else (
    "地灵根" if roots.size()==1 else "凡品")
  if root_count==5 and rng.randf()<0.14:
    grade="伪灵根"
  if roots.size()==1 and rng.randf()<0.21:
    grade="天灵根"
  if rare<0.002:
    grade="先天灵根"
  elif variant!="":
    grade="异灵根"
  var body: String="凡体"
  if rng.randf()<0.035:
    body=CONSTITUTIONS[rng.randi_range(1,CONSTITUTIONS.size()-1)]
  var kind: String=variant+"灵根" if variant!="" else (
    String(roots[0])+"灵根" if roots.size()==1 else (
    "".join(roots)+"杂灵根"))
  return {"schema":SCHEMA,"entity_id":entity_id,"has_root":true,
    "kind":kind,"roots":roots,"root_weights":scores,"grade":grade,
    "constitution":body,"detected":false,"origin":"birth_stable",
    "talent_score":highest}

func migrate_existing(seed: int,entity_id: String,kind: String,
    weights: Array,role: String="citizen") -> Dictionary:
  # Preserve the old revealed elemental root and OLD cultivation progress;
  # only override a legacy 'no root' for guaranteed-root actors.
  var generated: Dictionary=generate(seed,entity_id,role)
  if kind=="":
    return generated
  if kind=="无灵根":
    if role in ["bonded_labor","enslaved_labor","recruitable_servant"]:
      generated["has_root"]=false
      generated["kind"]="无灵根"
      generated["roots"]=[]
      generated["origin"]="retained_labor_exception"
      return generated
    generated["origin"]="migrated_legacy_no_root"
    return generated
  generated["kind"]=kind
  var selected: Array=[]
  if kind.ends_with("灵根") and kind.length()>2:
    var prefix: String=kind.trim_suffix("灵根")
    if ELEMENTS.has(prefix):
      selected=[prefix]
    elif MUTATIONS.has(prefix):
      selected=(MUTATIONS[prefix] as Array).duplicate()
  if selected.is_empty():
    for elem in BASE:
      if kind.contains(elem):
        selected.append(elem)
  if not selected.is_empty():
    generated["roots"]=selected
  if weights.size()==5:
    generated["root_weights"]=weights.duplicate(true)
  generated["origin"]="preserved_rev201_root"
  generated["has_root"]=true
  return generated

func has_root(profile: Dictionary) -> bool:
  return bool(profile.get("has_root",false)) and (
    not (profile.get("roots",[]) as Array).is_empty())

func signature(profile: Dictionary) -> Dictionary:
  var roots: Array=profile.get("roots",[])
  if roots.is_empty():
    return {"color":"#aab0b3","attack":"none","effect":"none",
      "debuff":"none","terrain":"普通体力劳动","status_time":0.0}
  var primary: String=String(roots[0])
  var e: Dictionary=ELEMENTS.get(primary,ELEMENTS["金"])
  return {"color":e["color"],"attack":e["attack"],
    "effect":e["effect"],"debuff":e["debuff"],
    "terrain":e["terrain"],"status_time":3.0,
    "secondary":roots.slice(1),"primary":primary,
    "grade":String(profile.get("grade","凡品"))}

func describe(profile: Dictionary) -> String:
  if not has_root(profile):
    return "无灵根｜凡人体力/职业劳动可成长"
  var roots: Array=profile.get("roots",[])
  var effect: Dictionary=signature(profile)
  return "%s · %s · %s｜主属性%s：%s，命中附带%s；天赋体质%s" % [
    String(profile.get("kind","")),String(profile.get("grade","凡品")),
    "/".join(roots),String(effect.get("primary","")),
    String(effect.get("terrain","")),String(effect.get("debuff","")),
    String(profile.get("constitution","凡体"))]

func interaction(attacker: Dictionary,defender: Dictionary) -> Dictionary:
  # This matrix is always deterministic and side-effect free. Actual skills
  # must pay real mana, check range/LOS/defence before using this multiplier.
  var atk: String=String(signature(attacker).get("primary",""))
  var def: String=String(signature(defender).get("primary",""))
  var a: Dictionary=ELEMENTS.get(atk,{})
  var b: Dictionary=ELEMENTS.get(def,{})
  var modifier: float=1.0
  if String(a.get("counter",""))==def:
    modifier=1.20
  elif String(a.get("weak",""))==def or String(b.get("counter",""))==atk:
    modifier=0.80
  return {"multiplier":modifier,"attacker":atk,"defender":def,
    "status":String(a.get("debuff","none"))}
