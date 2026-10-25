extends RefCounted
class_name XianfanEconomyAccounts

# Flow-based GDP for the ACTUALLY SIMULATED economy only, not GDP for every
# resident of the county. Trades, transfers, inheritances and wages for
# goods-producing workers are not new production a second time.
const SCHEMA := 1
const BASE_PRICES := {"粮":2,"木":3,"鱼":3,"药":5,"器":8}
const TARGETS := {"村":{"粮":120,"木":18,"鱼":8,"药":8,"器":5},
    "城":{"粮":300,"木":65,"鱼":15,"药":35,"器":30}}
const SECTORS := ["农林渔药","工坊制造","公共与生活服务"]
const MAX_DAYS := 90
const MAX_MONTHS := 36
const MAX_YEARS := 160
const MAX_AUDIT := 120

static func _period() -> Dictionary:
    var industries: Dictionary={}
    for sector in SECTORS:
        industries[sector]={"nominal":0,"real":0,"gross_real":0,"inputs_real":0,"jobs":0}
    return {"gdp_nominal":0,"gdp_real":0,"gross_real":0,"inputs_real":0,
        "trades":0,"trade_volume":0,"jobs":0,"industries":industries}

static func initialize(society: Dictionary, hour: int) -> bool:
    if society.has("economy_accounts"):
        return false
    var regions: Dictionary={}
    for zone in society.get("regions",{}):
        regions[str(zone)]={"total":_period(),"days":{},"months":{},"years":{},
            "latest_day":int(hour/24)+1}
    society["economy_accounts"]={
        "schema":SCHEMA,"started_at_hour":hour,
        "valuation":"固定基期物价按增加值测算；名义值按当时库存报价；仅覆盖规则真实结算的产出",
        "regions":regions,"audit":[]}
    return true

static func valid(society: Dictionary) -> bool:
    if not society.has("economy_accounts"): return true # earlier save migration
    var acc: Dictionary=society["economy_accounts"]
    if int(acc.get("schema",0))!=SCHEMA or not acc.has("regions"): return false
    for name in acc["regions"]:
        var region: Dictionary=acc["regions"][name]
        var total: Dictionary=region.get("total",{})
        if int(total.get("gross_real",-1))<0 or int(total.get("inputs_real",-1))<0: return false
        if int(total.get("gdp_real",-1))!=int(total.get("gross_real",0))-int(total.get("inputs_real",0)): return false
    return true

static func _quoted_price(society: Dictionary, region_name: String, good: String) -> int:
    var base:=int(BASE_PRICES.get(good,0))
    if base<=0: return 0
    var zone: Dictionary=society.get("regions",{}).get(region_name,{})
    var stock: Dictionary=zone.get("stock",{})
    var targets: Dictionary=TARGETS.get(region_name,{})
    var amount:=int(stock.get(good,0))
    var expected:=maxi(1,int(targets.get(good,10)))
    if amount<=expected/4: base+=3
    elif amount<=expected/2: base+=2
    elif amount>=expected*3: base-=2
    elif amount>=expected*2: base-=1
    return maxi(1,base)

static func price_snapshot(society: Dictionary, region_name: String) -> Dictionary:
    var prices: Dictionary={}
    for good in BASE_PRICES:
        prices[good]=_quoted_price(society,region_name,str(good))
    return prices

static func _add_metrics(bucket: Dictionary, sector: String, nominal: int, real_value: int,
        gross_real: int, inputs_real: int, is_work: bool) -> void:
    bucket["gdp_nominal"]=int(bucket["gdp_nominal"])+nominal
    bucket["gdp_real"]=int(bucket["gdp_real"])+real_value
    bucket["gross_real"]=int(bucket["gross_real"])+gross_real
    bucket["inputs_real"]=int(bucket["inputs_real"])+inputs_real
    if is_work: bucket["jobs"]=int(bucket["jobs"])+1
    var industries: Dictionary=bucket["industries"]
    var row: Dictionary=industries[sector]
    row["nominal"]=int(row["nominal"])+nominal
    row["real"]=int(row["real"])+real_value
    row["gross_real"]=int(row["gross_real"])+gross_real
    row["inputs_real"]=int(row["inputs_real"])+inputs_real
    if is_work: row["jobs"]=int(row["jobs"])+1

static func _add_trade(bucket: Dictionary, amount: int) -> void:
    bucket["trades"]=int(bucket["trades"])+1
    bucket["trade_volume"]=int(bucket["trade_volume"])+amount

static func _get_period(store: Dictionary, key: String) -> Dictionary:
    if not store.has(key): store[key]=_period()
    return store[key]

static func _trim(store: Dictionary, max_periods: int) -> void:
    if store.size()<=max_periods: return
    var keys: Array=store.keys()
    keys.sort_custom(func(a,b): return int(a)<int(b))
    while keys.size()>max_periods:
        store.erase(keys.pop_front())

static func _period_keys(hour: int) -> Dictionary:
    var day:=int(hour/24)+1
    return {"day":str(day),"month":str(int((day-1)/30)+1),
        "year":str(int((day-1)/360)+1)}

static func _buckets(region: Dictionary, hour: int) -> Array[Dictionary]:
    var keys:=_period_keys(hour)
    var days: Dictionary=region["days"]
    var months: Dictionary=region["months"]
    var years: Dictionary=region["years"]
    var result: Array[Dictionary]=[region["total"],
        _get_period(days,str(keys["day"])),
        _get_period(months,str(keys["month"])),
        _get_period(years,str(keys["year"]))]
    _trim(days,MAX_DAYS)
    _trim(months,MAX_MONTHS)
    _trim(years,MAX_YEARS)
    region["latest_day"]=int(keys["day"])
    return result

static func _note(society: Dictionary, row: Dictionary) -> void:
    var accounts: Dictionary=society["economy_accounts"]
    var audit: Array=accounts["audit"]
    audit.append(row)
    if audit.size()>MAX_AUDIT: audit.pop_front()

# Nominal uses the same snapshot prices for outputs and intermediate goods.
# Fixed-price real VA remains additive across the production chain.
static func production(society: Dictionary, zone: String, hour: int, sector: String,
        outputs: Dictionary, inputs: Dictionary={}, service_output: int=0,
        quotes: Dictionary={}, source: String="") -> bool:
    if not SECTORS.has(sector) or not society.get("regions",{}).has(zone): return false
    if not society.has("economy_accounts"): initialize(society,hour)
    if not valid(society): return false
    if int(service_output)<0: return false
    var gross_real:=int(service_output)
    var intermediate_real:=0
    var nominal_gross:=int(service_output)
    var nominal_intermediate:=0
    var applied_quotes: Dictionary=quotes if not quotes.is_empty() else price_snapshot(society,zone)
    for good in outputs:
        if not BASE_PRICES.has(str(good)) or int(outputs[good])<0: return false
        gross_real+=int(BASE_PRICES[good])*int(outputs[good])
        nominal_gross+=int(applied_quotes.get(good,BASE_PRICES[good]))*int(outputs[good])
    for good in inputs:
        if not BASE_PRICES.has(str(good)) or int(inputs[good])<0: return false
        intermediate_real+=int(BASE_PRICES[good])*int(inputs[good])
        nominal_intermediate+=int(applied_quotes.get(good,BASE_PRICES[good]))*int(inputs[good])
    if gross_real<=0: return false
    var real_va:=gross_real-intermediate_real
    var nominal_va:=nominal_gross-nominal_intermediate
    var region: Dictionary=society["economy_accounts"]["regions"][zone]
    for bucket in _buckets(region,hour):
        _add_metrics(bucket,sector,nominal_va,real_va,gross_real,intermediate_real,true)
    _note(society,{"day":int(hour/24)+1,"hour":hour,"region":zone,"actor":source,
        "kind":"production","sector":sector,"real_value_added":real_va,
        "nominal_value_added":nominal_va,"outputs":outputs.duplicate(true),
        "intermediates":inputs.duplicate(true)})
    return true

# Transactions merely change owners; do NOT change GDP. They must have
# already passed the external inventory/currency settlement.
static func trade(society: Dictionary, zone: String, hour: int, money_paid: int,
        source: String="") -> bool:
    if money_paid<=0 or not society.get("regions",{}).has(zone): return false
    if not society.has("economy_accounts"): initialize(society,hour)
    if not valid(society): return false
    var region: Dictionary=society["economy_accounts"]["regions"][zone]
    for bucket in _buckets(region,hour): _add_trade(bucket,money_paid)
    _note(society,{"day":int(hour/24)+1,"region":zone,
        "kind":"trade","value":money_paid,"actor":source,
        "gdp_effect":0})
    return true

static func _int_comma(value: int) -> String:
    return str(value)

static func report(society: Dictionary, zone: String) -> String:
    if not society.has("economy_accounts"): return "当前存档尚未启用新增产值统计。"
    if not valid(society): return "经济统计账本校验失败；不会显示伪造数据。"
    if not society["economy_accounts"]["regions"].has(zone): return "未知经济区域："+zone
    var region: Dictionary=society["economy_accounts"]["regions"][zone]
    var now_hour:=int(society.get("last_hour",0))
    var keys:=_period_keys(now_hour)
    var month: Dictionary=region["months"].get(str(keys["month"]),_period())
    var year: Dictionary=region["years"].get(str(keys["year"]),_period())
    var day: Dictionary=region["days"].get(str(keys["day"]),_period())
    var total: Dictionary=region["total"]
    var stock: Dictionary=society["regions"][zone]["stock"]
    var cash:=int(society["regions"][zone]["treasury"])
    var population:=int(society["regions"][zone].get("population_aggregate",0))
    var money_sum:=cash
    for actor in society.get("agents",{}).values():
        if ("村" if str(actor.get("origin",""))=="石桥村" else "城")==zone:
            money_sum+=int(actor.get("coins",0))
    for actor in society.get("civic_agents",{}).values():
        var area:=str(actor.get("region",actor.get("origin","")))
        if area==zone or (zone=="村" and area.contains("石桥村")) or (zone=="城" and area.contains("临安县")):
            money_sum+=int(actor.get("coins",0))
    var lines: Array[String]=[
        "【%s · 已模拟经济统计样本】" % ("石桥村" if zone=="村" else "临安县城（非全县）"),
        "统计自游戏第%d日启用；只统计可追溯的规则产出，不回填过去。" %
            (int(int(society["economy_accounts"]["started_at_hour"])/24)+1),
        "【本日新增价值】实际产值%d文（固定基期），名义%d文" % [
            int(day["gdp_real"]),int(day["gdp_nominal"])],
        "【本月累计】实际产值%d文，名义产值%d文；成交额%d文（不计入GDP）" % [
            int(month["gdp_real"]),int(month["gdp_nominal"]),int(month["trade_volume"])],
        "【本年累计】实际产值%d文，名义产值%d文；成交额%d文" % [
            int(year["gdp_real"]),int(year["gdp_nominal"]),int(year["trade_volume"])],
        "【启用后累计增加值】实际%d文，名义%d文" % [
            int(total["gdp_real"]),int(total["gdp_nominal"])],
        "【增加值计算】实际毛产出%d文－中间投入%d文＝%d文" % [
            int(year["gross_real"]),int(year["inputs_real"]),int(year["gdp_real"])],
        "【分产业年度实际增加值】"]
    for industry in SECTORS:
        var bucket: Dictionary=year["industries"][industry]
        lines.append("%s：%d文，已结算工作%d次" % [
            industry,int(bucket["real"]),int(bucket["jobs"])])
    lines.append("【存量不等于GDP】区域财政余额%d文；具名NPC与区域库现金合计%d文（非全县社会财富）" % [cash,money_sum])
    lines.append("【现货库存】粮%d 木%d 鱼%d 药%d 器%d；库存的总价不可直接算年度GDP。" % [
        int(stock.get("粮",0)),int(stock.get("木",0)),int(stock.get("鱼",0)),
        int(stock.get("药",0)),int(stock.get("器",0))])
    lines.append("【登记背景人口】约%d人，但居民全行业产出尚未全面建模；不计算误导性县域人均GDP。" % population)
    if int(year["gdp_real"])>0:
        lines.append("【样本经济价格比】当年名义/实际 ×100＝%.1f（仅模拟产出结构，不代表全县CPI）。" % (
            float(year["gdp_nominal"])*100.0/float(year["gdp_real"])))
    lines.append("【统计边界】当前仅有石桥村与临安县城两个样本经济区；县域其他乡镇、村落、村际物流及行业尚未建账，故绝对禁止将县城样本GDP作为临安县全县GDP，或据此断言村县经济规模相当。")
    lines.append("【口径警告】本表是已模拟活动的部分增加值。职业工资、救济、二手转卖、商队交割不重复计入生产；年份按360个游戏日。")
    return "\n".join(lines)

static func trend(society: Dictionary, zone: String, last_months: int=12) -> Array[Dictionary]:
    if not valid(society) or not society.has("economy_accounts"): return []
    var ledger: Dictionary=society["economy_accounts"]["regions"].get(zone,{})
    var history: Dictionary=ledger.get("months",{})
    var months: Array=history.keys()
    months.sort_custom(func(a,b):return int(a)<int(b))
    var result: Array[Dictionary]=[]
    for month_key in months.slice(-clampi(last_months,1,36)):
        var p: Dictionary=history[month_key]
        result.append({"month":int(month_key),"real":int(p["gdp_real"]),
            "nominal":int(p["gdp_nominal"]),"trade":int(p["trade_volume"])})
    return result
