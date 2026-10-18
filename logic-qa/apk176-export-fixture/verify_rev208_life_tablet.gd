extends SceneTree
## rev208 死亡后果（用户口径）：宗门修士死了宗门靠命牌立刻知道；
## 散修没人发现只能记失踪。确认死亡才进 region.deaths 与宗门文献，
## 人口账一律扣 1（确认死亡与失踪都算离开人口），存档往返保留口径。
var failures: Array[String]=[]
func _check(ok: bool,msg: String) -> void:
  if not ok:
    failures.append(msg)
    printerr("FAIL_REV208_LIFE_TABLET_"+msg)
func _initialize() -> void:
  call_deferred("_run")
func _run() -> void:
  # 不受前一个 QA 遗留存档影响：命牌测试必须从干净世界开始。
  DirAccess.remove_absolute("user://canglan_living_regions_rev207.json")
  DirAccess.remove_absolute("user://canglan_living_regions_rev207.json.tmp")
  var packed: GDScript=load("res://canglan_rev187/living_regions.gd") as GDScript
  if packed==null:
    printerr("FAIL_REV208_LIFE_TABLET_NO_SOURCE"); quit(2); return
  var model: RefCounted=packed.new()
  if not bool(model.call("initialize",20261017)):
    printerr("FAIL_INIT_"+String(model.get("_last_error"))); quit(2); return
  var sects: Dictionary=model.get("sects")
  var sect_id: String=String((sects.keys() as Array)[0])
  var pop0: int=int(model.call("stats")["population"])
  # 1) 宗门修士：无人目击，命牌照样确认死亡
  var a: Dictionary=model.call("record_named_cultivator_death","CL-XIUXIAN-002",true,false,"test_sword",sect_id,false)
  _check(bool(a.get("ok",false)),"sect_ok_"+str(a))
  _check(String(a.get("status",""))=="dead","sect_dead")
  _check(String(a.get("confirmed_by",""))=="life_tablet","sect_life_tablet_got_"+String(a.get("confirmed_by","")))
  var s1: Dictionary=model.call("stats")
  _check(int(s1["population"])==pop0-1,"sect_population_decrement")
  _check(int(s1["deaths"])==1,"sect_confirmed_deaths_1_got_"+str(s1["deaths"]))
  _check(int(s1["missing"])==0,"sect_no_missing")
  var obits: Dictionary=model.get("sect_obituaries")
  _check(obits.has(sect_id) and (obits[sect_id] as Array).size()==1,"sect_obituary_one")
  var row: Dictionary=(obits[sect_id] as Array)[0]
  _check(String(row.get("entity_id",""))=="CL-XIUXIAN-002","obit_entity")
  _check(String(row.get("confirmed_by",""))=="life_tablet","obit_confirmed_by")
  _check(bool((model.get("sects") as Dictionary)[sect_id].get("player_hostility",false)),"sect_grudge_on")
  _check(int(model.call("stats")["hostile_sects"])==1,"hostile_sects_1")
  # 2) 散修无人发现 -> 失踪，不进宗门文献
  var b: Dictionary=model.call("record_named_cultivator_death","CL-XIUXIAN-001",true,false,"test_sword","",false)
  _check(bool(b.get("ok",false)),"loner_ok_"+str(b))
  _check(String(b.get("status",""))=="missing","loner_missing")
  var s2: Dictionary=model.call("stats")
  _check(int(s2["population"])==pop0-2,"loner_population")
  _check(int(s2["deaths"])==1 and int(s2["missing"])==1,"loner_counters_"+str(s2))
  _check(int(s2["departed_total"])==2,"loner_departed_2")
  _check((model.get("sect_obituaries")[sect_id] as Array).size()==1,"loner_no_obituary")
  # 3) 散修被人看见 -> 目击确认
  var c: Dictionary=model.call("record_named_cultivator_death","CL-XIUXIAN-005",true,false,"test_sword","",true)
  _check(String(c.get("confirmed_by",""))=="witness","witness_kind")
  _check(int(model.call("stats")["deaths"])==2,"witness_deaths_2")
  # 4) 同一人重复写入不重复扣人口
  var d: Dictionary=model.call("record_named_cultivator_death","CL-XIUXIAN-002",true,false,"test_sword",sect_id,false)
  _check(bool(d.get("already_recorded",false)),"duplicate_idempotent")
  _check(int(model.call("stats")["population"])==pop0-3,"duplicate_no_double_debit")
  # 5) 人口守恒
  var s3: Dictionary=model.call("stats")
  _check(bool(s3["conserved"]),"conserved_"+str(s3))
  # 6) 存档往返保留命牌口径与宗门文献
  _check(bool(model.call("force_save")),"saved")
  var reload: RefCounted=packed.new()
  _check(bool(reload.call("initialize",20261017)),"reloaded_"+String(reload.get("_last_error")))
  var s4: Dictionary=reload.call("stats")
  _check(int(s4["deaths"])==2 and int(s4["missing"])==1 and int(s4["named_confirmed_deaths"])==2,"reload_counters_"+str(s4))
  var named: Dictionary=reload.get("named_deaths")
  _check(String(named["CL-XIUXIAN-001"].get("status",""))=="missing","reload_missing_kept")
  _check(String(named["CL-XIUXIAN-002"].get("confirmed_by",""))=="life_tablet","reload_life_tablet_kept")
  _check((reload.get("sect_obituaries")[sect_id] as Array).size()==1,"reload_obituary_kept")
  _check(bool((reload.get("sects") as Dictionary)[sect_id].get("player_hostility",false)),"reload_grudge_kept")
  if failures.is_empty():
    print("PASS_REV208_LIFE_TABLET_CONFIRMED_VS_MISSING_OBITUARY_IDEMPOTENT_ATOMIC_RELOAD")
    quit(0)
  else:
    quit(3)
