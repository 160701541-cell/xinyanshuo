extends RefCounted
class_name XianfanConditionalStory
# Deterministic world observations; fact-bearing content is emitted ONLY when
# the named economic/ecological condition truly holds in an authoritative save.
const PATH := "res://data/conditional_story_v1.json"
var _templates: Array=[]

func _init() -> void:
    var input:=FileAccess.open(PATH,FileAccess.READ)
    if input==null: return
    var parsed: Variant=JSON.parse_string(input.get_as_text())
    if parsed is Dictionary and int(parsed.get("schema",0))==1:
        _templates=parsed.get("templates",[])

func template_count() -> int:
    return _templates.size()

func observe(world: Dictionary) -> Array[Dictionary]:
    var result: Array[Dictionary]=[]
    var society: Dictionary=world.get("society",{})
    var regions: Dictionary=society.get("regions",{})
    var day:=int(world.get("day",0))
    if day<=0 or regions.is_empty(): return result
    var flags: Dictionary=world.get("conditional_event_last_days",{})
    var cache: Array=world.get("verified_local_events",[])
    for row in _templates:
        if not (row is Dictionary): continue
        var definition: Dictionary=row
        var region_name:=str(definition.get("region",""))
        var id:=str(definition.get("id",""))
        if not regions.has(region_name) or id.is_empty(): continue
        if day-int(flags.get(id,-10000))<int(definition.get("cooldown_days",7)):
            continue
        var region: Dictionary=regions[region_name]
        var domain:=str(definition.get("source",""))
        var property:=str(definition.get("resource",""))
        var amount:=0
        if domain=="stock" or domain=="wild":
            var figures: Dictionary=region.get(domain,{})
            if not figures.has(property): continue
            amount=int(figures[property])
        elif domain=="treasury":
            amount=int(region.get("treasury",-1))
            if amount<0: continue
        else: continue
        var threshold:=int(definition.get("threshold",0))
        var op:=str(definition.get("operator",""))
        var matches:=(op=="lte" and amount<=threshold) or (op=="gte" and amount>=threshold)
        if not matches: continue
        var prose:=str(definition.get("description","")).replace("{value}",str(amount))
        prose=prose.replace("{threshold}",str(threshold))
        var entry: Dictionary={"id":"OBS-"+id+"-"+str(day),
            "type":"rule_observation","day":day,"region":region_name,
            "detail":prose,"value":amount,"threshold":threshold,
            "source_field":domain+"."+property,"confidence":"rule_confirmed"}
        flags[id]=day
        cache.append(entry)
        result.append(entry)
    # A bounded UI cache never substitutes for the append-only historical file.
    if cache.size()>256: cache=cache.slice(-256)
    world["conditional_event_last_days"]=flags
    world["verified_local_events"]=cache
    return result
