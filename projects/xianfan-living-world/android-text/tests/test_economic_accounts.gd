extends SceneTree

var failures: Array[String]=[]

func _initialize() -> void:
    call_deferred("_run")

func check(value: bool, reason: String) -> void:
    if not value:
        failures.append(reason)
        push_error("GDP ACCOUNT TEST FAILURE: "+reason)

func _run() -> void:
    var society: Dictionary=XianfanSocietySim.initial_state(0)
    check(society.has("economy_accounts"),"new game automatically initializes GDP ledger")
    check(XianfanEconomyAccounts.valid(society),"new economy ledger is internally consistent")
    var base: Dictionary=XianfanEconomyAccounts.BASE_PRICES.duplicate(true)
    var zone: String="村"
    var hour:=9
    var started:=XianfanEconomyAccounts.production(society,zone,hour,"农林渔药",
        {"木":2},{},0,base,"樵夫真实劳动")
    check(started,"basic forestry production may be recorded")
    var workshop:=XianfanEconomyAccounts.production(society,zone,hour,"工坊制造",
        {"器":1},{"木":2},0,base,"木匠真实加工")
    check(workshop,"crafting with consumed intermediate timber may be recorded")
    var public_service:=XianfanEconomyAccounts.production(society,zone,hour,"公共与生活服务",
        {},{},2,base,"实际巡逻")
    check(public_service,"paid non-market service at cost valuation")
    var totals: Dictionary=society["economy_accounts"]["regions"][zone]["total"]
    check(int(totals["gdp_real"])==10,"forestry6+workshop2+service2 = GDP10 without double-counting")
    check(int(totals["gdp_nominal"])==10,"nominal equals real under base prices")
    check(int(totals["gross_real"])==16,"gross forest6+craft8+service2 = 16")
    check(int(totals["inputs_real"])==6,"intermediate consumed wood=6 subtracted exactly once")
    check(int(totals["industries"]["工坊制造"]["real"])==2,
        "workshop value added is only 8 minus 6, not all 8")
    check(int(totals["industries"]["公共与生活服务"]["real"])==2,"service valuation at work cost")
    var before:=int(totals["gdp_real"])
    check(XianfanEconomyAccounts.trade(society,zone,hour,87,"商队交割"),"trace actual transaction")
    check(int(totals["gdp_real"])==before,"moving already produced goods has zero new GDP")
    check(int(totals["trade_volume"])==87 and int(totals["trades"])==1,
        "trade turnover counted separately without minting production")
    check(not XianfanEconomyAccounts.production(society,zone,hour,"工坊制造",
        {"器":-1},{},0,base,"无效生产"),"negative goods cannot be counted as output")
    check(not XianfanEconomyAccounts.production(society,zone,hour,"假产业",
        {"器":1},{},0,base,"无效部门"),"invalid production sectors rejected")
    check(int(totals["gdp_real"])==before,"rejected entries cannot change ledger")
    check(XianfanEconomyAccounts.valid(society),"ledger holds gross minus intermediate invariant")
    check(XianfanEconomyAccounts.production(society,zone,31*24+8,"农林渔药",
        {"粮":5},{},0,base,"新一月收成"),"next period has production")
    check(XianfanEconomyAccounts.production(society,zone,361*24+8,"农林渔药",
        {"粮":10},{},0,base,"第二年收成"),"new year has production")
    var led: Dictionary=society["economy_accounts"]["regions"][zone]
    check(led["years"].size()==2,"first and second years have separate ledgers")
    check(int(led["years"]["2"]["gdp_real"])==20,"second-year output is isolated")
    check(int(led["total"]["gdp_real"])==40,"period sums equal cumulative GDP")
    var displayed:=XianfanEconomyAccounts.report(society,zone)
    check(displayed.contains("GDP") and displayed.contains("增加值"),"dashboard names correct concept")
    check(displayed.contains("不能") or displayed.contains("不重复"),"GDP explanation prevents turnover mislabeling")
    check(displayed.contains("只统计") or displayed.contains("仅覆盖"),"dashboard honestly flags partial economy")
    var timeline:=XianfanEconomyAccounts.trend(society,zone,12)
    check(timeline.size()>=2,"monthly historical trend can be read from persistent ledger")

    var real: Dictionary=XianfanSocietySim.initial_state(0)
    XianfanSocietySim.advance_to(real,6*24*60)
    check(XianfanEconomyAccounts.valid(real),"full autonomous society continually validates GDP accounting")
    var econ: Dictionary=real["economy_accounts"]["regions"]["村"]["total"]
    check(int(econ["gdp_real"])>0,"daily real agricultural work generates GDP independently of player")
    var calculated:=0
    for industry in XianfanEconomyAccounts.SECTORS:
        calculated+=int(econ["industries"][industry]["real"])
    check(calculated==int(econ["gdp_real"]),"sum of three industries equals total real GDP")
    check(int(econ["trade_volume"])>0,"NPC food commerce is recorded separately")
    var played:=XianfanWorld.new()
    played.new_game()
    var original_soc: Dictionary=played.data["society"]
    var village_ledger: Dictionary=original_soc["economy_accounts"]["regions"]["村"]["total"]
    var starting_value:=int(village_ledger["gdp_real"])
    var initial_minutes:=int(played._clock())
    played.data["place"]="石桥村·街口"
    # Existing economic transactions: the player has two copper and a real fish.
    var price_report:=played.act("查看GDP")
    check(price_report.contains("经济统计"),"free action can query the economic report")
    var bought:=played.act("买粗粮")
    check(bought.contains("粗粮") or bought.contains("钱不够"),"buying grain follows money and inventory rules")
    check(int(village_ledger["gdp_real"])==starting_value,
        "retail sale does not count old stocks as new output")
    # Explicitly fund a real one-hour job from region reserves.
    played.data["stamina"]=100
    var worked:=played.act("做零工")
    check(worked.contains("两文"),"player can participate in GDP production as an ordinary worker")
    check(int(village_ledger["gdp_real"])>=starting_value+4,
        "two real grain units add four base-price copper of value")
    check(XianfanEconomyAccounts.valid(played.data["society"]),"player activity preserves GDP invariants")
    played.save()
    var resumed:=XianfanWorld.new()
    var reloaded: Dictionary=resumed.data["society"]["economy_accounts"]["regions"]["村"]["total"]
    check(int(reloaded["gdp_real"])==int(village_ledger["gdp_real"]),
        "economic accounts survive native save and app restart")
    var old_game:=XianfanSocietySim.initial_state(200*24*60)
    old_game.erase("economy_accounts")
    check(XianfanEconomyAccounts.initialize(old_game,200*24),
        "old society state receives new GDP accounting")
    check(int(old_game["economy_accounts"]["regions"]["村"]["total"]["gdp_real"])==0,
        "new GDP accounting does not invent unobserved output in old saves")
    var ui=load("res://main.tscn").instantiate()
    root.add_child(ui)
    ui._change_tab("经济")
    check(ui.page_title.text.contains("经济账本"),"Android screen contains real economy tab")
    check(ui.scene_text.text.contains("中间投入"),"economy page shows accounting breakdown")
    ui._change_tab("世界")
    check(ui.scene_text.text.contains("累计增加值"),"world tab displays economic summary")
    print("XIANFAN GDP ACCOUNT TESTS PASS" if failures.is_empty() else "XIANFAN GDP ACCOUNT TESTS FAILED")
    quit(0 if failures.is_empty() else 1)
