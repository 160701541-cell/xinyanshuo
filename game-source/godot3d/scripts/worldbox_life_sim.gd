extends RefCounted
## CAC-LIFE-001: headless deterministic civilian economy and village development.
## This module models real state transitions; visuals/AI text never grant items.
const TICK_MINUTES := 60
const RESOURCE_KEYS := ["grain", "wood", "stone", "clay", "water", "food", "coin"]
var world_seed: int = 20261016
var hour: int = 6
var day: int = 1
var villages: Dictionary = {}
var citizens: Dictionary = {}
var event_log: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()

func start(seed: int = 20261016) -> void:
	world_seed = seed
	_rng.seed = seed
	hour = 6
	day = 1
	villages.clear()
	citizens.clear()
	event_log.clear()

func create_village(code: String, initial: Dictionary = {}) -> bool:
	if villages.has(code) or code.is_empty():
		return false
	var stock: Dictionary = {}
	for key in RESOURCE_KEYS:
		stock[key] = maxi(0, int(initial.get(key, 0)))
	villages[code] = {
		"id": code, "stock": stock, "homes": maxi(1,int(initial.get("homes", 2))),
		"fields": maxi(0,int(initial.get("fields",1))), "workshops": 0,
		"well": bool(initial.get("well",true)), "population": 0,
		"health": 100, "prosperity": 0, "construction": {},
		"history": []}
	return true

func add_citizen(code: String, village_id: String, profession: String,
		age: int = 27) -> bool:
	if citizens.has(code) or not villages.has(village_id) or code.is_empty():
		return false
	citizens[code] = {
		"id": code, "village_id":village_id,
		"profession":profession, "age":clampi(age,1,95),
		"energy":100, "hunger":0, "mood":60,
		"schedule":"idle", "private_stock":{"food":0,"coin":0}}
	villages[village_id]["population"] += 1
	return true

func _journal(village: String, action: String, amount: int, details: String) -> void:
	var item: Dictionary = {"day":day,"hour":hour,"village":village,
		"event":action,"amount":amount,"details":details}
	event_log.append(item)
	if event_log.size()>2048:
		event_log.pop_front()
	var history: Array = villages[village]["history"]
	history.append(item)
	if history.size()>128:
		history.pop_front()

func _add_stock(village_id: String, kind: String, delta: int) -> bool:
	if not villages.has(village_id):
		return false
	var stock: Dictionary = villages[village_id]["stock"]
	if not stock.has(kind) or int(stock[kind]) + delta < 0:
		return false
	stock[kind] = int(stock[kind]) + delta
	return true

func _spend(village_id: String, bill: Dictionary) -> bool:
	if not villages.has(village_id):
		return false
	var stock: Dictionary = villages[village_id]["stock"]
	for kind in bill:
		if not stock.has(kind) or int(bill[kind])<0 or int(stock[kind])<int(bill[kind]):
			return false
	for kind in bill:
		stock[kind] = int(stock[kind])-int(bill[kind])
	return true

# CAC-LIFE-002: finite real-world resource nodes and physical transport.
# Loading a fallen tree into a carrier's bag does NOT credit a village stock.
var natural_nodes: Dictionary = {}
var carried_by_actor: Dictionary = {}
var harvested_fields: Dictionary = {}

func register_natural_node(entity_code: String, village_id: String, kind: String,
		quantity: int) -> bool:
	if entity_code.is_empty() or natural_nodes.has(entity_code) or not villages.has(village_id):
		return false
	if kind not in ["tree","stone","clay"]:
		return false
	if quantity<=0 or quantity>1000:
		return false
	natural_nodes[entity_code]={"id":entity_code,"village":village_id,
		"kind":kind,"remaining":quantity,"depleted":false}
	return true

func gather_to_actor(actor_id: String, node_id: String) -> bool:
	if not citizens.has(actor_id) or not natural_nodes.has(node_id):
		return false
	if carried_by_actor.has(actor_id):
		return false
	var source: Dictionary = natural_nodes[node_id]
	var person: Dictionary = citizens[actor_id]
	if person["village_id"] != source["village"] or int(source["remaining"])<=0:
		return false
	if int(person["energy"])<10:
		return false
	var resource: String = {"tree":"wood","stone":"stone","clay":"clay"}[source["kind"]]
	var amount: int = mini(3,int(source["remaining"]))
	source["remaining"] = int(source["remaining"])-amount
	source["depleted"] = int(source["remaining"])==0
	carried_by_actor[actor_id]={"kind":resource,"amount":amount,"node":node_id}
	person["energy"] = maxi(0,int(person["energy"])-5)
	person["schedule"]="carrying_"+resource
	_journal(String(source["village"]),"harvest_from_world",amount,node_id)
	return true

func resource_remaining(kind: String) -> int:
	var sum: int = 0
	for entry in natural_nodes.values():
		if entry["kind"]==kind:
			sum+=int(entry["remaining"])
	return sum

func deliver_carried(actor_id: String) -> bool:
	if not citizens.has(actor_id) or not carried_by_actor.has(actor_id):
		return false
	var load: Dictionary = carried_by_actor[actor_id]
	var village: String = String(citizens[actor_id]["village_id"])
	if not _add_stock(village,String(load["kind"]),int(load["amount"])):
		return false
	carried_by_actor.erase(actor_id)
	citizens[actor_id]["schedule"]="delivered"
	_journal(village,"delivered_"+String(load["kind"]),int(load["amount"]),actor_id)
	return true

func register_field(field_code: String, village_id: String) -> bool:
	if field_code.is_empty() or harvested_fields.has(field_code) or not villages.has(village_id):
		return false
	harvested_fields[field_code]={"ready":true,"next_day":day,
		"village":village_id}
	return true

func gather_field_to_actor(actor_id: String, field_code: String) -> bool:
	if not citizens.has(actor_id) or not harvested_fields.has(field_code):
		return false
	if carried_by_actor.has(actor_id):
		return false
	var plot: Dictionary = harvested_fields[field_code]
	var village: String = String(citizens[actor_id]["village_id"])
	if String(plot.get("village",""))!=village or not bool(plot["ready"]) or day<int(plot["next_day"]):
		return false
	var grain: int = 5
	plot["ready"]=false
	plot["next_day"]=day+1
	carried_by_actor[actor_id]={"kind":"grain","amount":grain,"node":field_code}
	citizens[actor_id]["schedule"]="carrying_grain"
	_journal(village,"field_harvest_carried",grain,field_code)
	return true

func harvest_field(village_id: String, field_code: String, actor_id: String) -> bool:
	if not villages.has(village_id) or not citizens.has(actor_id):
		return false
	if citizens[actor_id]["village_id"]!=village_id:
		return false
	if int(villages[village_id]["fields"])<=0:
		return false
	if not harvested_fields.has(field_code):
		harvested_fields[field_code]={"ready":true,"next_day":1}
	var plot: Dictionary = harvested_fields[field_code]
	if not bool(plot["ready"]) or day<int(plot["next_day"]):
		return false
	# The player must fetch field yield; this cannot be spammed every frame.
	var grain: int = 5
	if not _add_stock(village_id,"grain",grain):
		return false
	plot["ready"]=false
	plot["next_day"]=day+1
	_journal(village_id,"harvest_grain",grain,field_code)
	return true

func prepare_meal(village_id: String, actor_id: String) -> bool:
	if not citizens.has(actor_id) or citizens[actor_id]["village_id"]!=village_id:
		return false
	if not _spend(village_id,{"grain":2,"water":1}):
		return false
	_add_stock(village_id,"food",3)
	_journal(village_id,"cooked_food",3,actor_id)
	return true

func feed_citizen(actor_id: String) -> bool:
	if not citizens.has(actor_id):
		return false
	var person: Dictionary = citizens[actor_id]
	var village: String = String(person["village_id"])
	if not _spend(village,{"food":1}):
		return false
	person["hunger"]=maxi(0,int(person["hunger"])-45)
	person["energy"]=mini(100,int(person["energy"])+4)
	_journal(village,"citizen_fed",1,actor_id)
	return true

func _citizen_work(person: Dictionary) -> void:
	var town: String = person["village_id"]
	if int(person["energy"])<24 or int(person["hunger"])>70:
		person["schedule"]="rest"
		person["energy"]=mini(100,int(person["energy"])+8)
		return
	var job: String = person["profession"]
	var action: String = ""
	var amount: int = 0
	if job == "farmer" and int(villages[town]["fields"])>0:
		if not harvested_fields.is_empty():
			person["schedule"]="waiting_for_harvest"
			return
		amount = 2+_rng.randi_range(0,2)
		action="grain"
	elif job in ["woodcutter","quarryman"]:
		# Only physical gather_to_actor -> deliver_carried may mint these resources
		# when authored finite world nodes exist. Never fabricate timber in time tick.
		if not natural_nodes.is_empty():
			person["schedule"]="looking_for_worksite"
			return
		amount = 2+_rng.randi_range(0,1) if job=="woodcutter" else 1+_rng.randi_range(0,1)
		action="wood" if job=="woodcutter" else "stone"
	elif job == "potter":
		if _spend(town,{"clay":2,"wood":1}):
			_add_stock(town,"coin",3)
			_journal(town,"fired_pottery",1,person["id"])
			person["schedule"]="craft"
			person["energy"]=maxi(0,int(person["energy"])-8)
		return
	elif job == "cook":
		if _spend(town,{"grain":2,"water":1}):
			_add_stock(town,"food",3)
			_journal(town,"cooked_food",3,person["id"])
			person["schedule"]="cook"
			person["energy"]=maxi(0,int(person["energy"])-8)
		return
	if not action.is_empty():
		_add_stock(town,action,amount)
		_journal(town,"gather_"+action,amount,person["id"])
		person["energy"]=maxi(0,int(person["energy"])-6)
		person["schedule"]="work"
	else:
		person["schedule"]="idle"

func _eat(person: Dictionary) -> void:
	var town: String = person["village_id"]
	if _spend(town,{"food":1}):
		person["hunger"]=maxi(0,int(person["hunger"])-45)
		person["mood"]=mini(100,int(person["mood"])+2)
		person["schedule"]="eat"
	else:
		person["hunger"]=mini(100,int(person["hunger"])+10)
		person["mood"]=maxi(0,int(person["mood"])-3)
		_journal(town,"food_shortage",1,person["id"])

func request_construction(village_id: String, kind: String) -> bool:
	var bill: Dictionary = {}
	match kind:
		"home": bill={"wood":12,"stone":6}
		"field": bill={"wood":2,"water":4}
		"workshop": bill={"wood":18,"stone":8,"clay":6}
		_: return false
	if not _spend(village_id,bill):
		return false
	var village: Dictionary = villages[village_id]
	village["construction"][kind] = int(village["construction"].get(kind,0))+1
	_journal(village_id,"construction_started",1,kind)
	return true

func _complete_building(village_id: String, kind: String) -> void:
	var town: Dictionary = villages[village_id]
	match kind:
		"home": town["homes"] += 1
		"field": town["fields"] += 1
		"workshop": town["workshops"] += 1
	_journal(village_id,"construction_completed",1,kind)

func _refresh_field_growth() -> void:
	for plot in harvested_fields.values():
		if day>=int(plot["next_day"]):
			plot["ready"]=true

func tick() -> void:
	hour += 1
	if hour>=24:
		hour=0
		day+=1
	_refresh_field_growth()
	for citizen_id in citizens.keys():
		var person: Dictionary = citizens[citizen_id]
		person["hunger"]=mini(100,int(person["hunger"])+4)
		if hour>=7 and hour<=18:
			_citizen_work(person)
		else:
			person["energy"]=mini(100,int(person["energy"])+12)
			person["schedule"]="sleep"
		if hour in [7,12,19]:
			_eat(person)
	for village_id in villages.keys():
		var village: Dictionary = villages[village_id]
		var construction: Dictionary = village["construction"]
		for kind in construction.keys():
			if int(construction[kind])>0:
				construction[kind]-=1
				_complete_building(village_id,kind)
		var avg_hunger: int = 0
		for person in citizens.values():
			if person["village_id"]==village_id:
				avg_hunger+=int(person["hunger"])
		avg_hunger=avg_hunger/maxi(1,int(village["population"]))
		var capacity: int = int(village["homes"])*4
		village["prosperity"]=clampi(30 + int(village["fields"])*3
			+int(village["workshops"])*5+mini(20,int(village["stock"]["coin"])/5)
			-maxi(0,int(village["population"])-capacity)*10-avg_hunger/2,0,100)
		village["health"]=clampi(int(village["health"])
			+ (1 if avg_hunger<30 else -1),0,100)

func snapshot() -> Dictionary:
	return {"schema":1,"seed":world_seed,"day":day,"hour":hour,
		"villages":villages.duplicate(true),"citizens":citizens.duplicate(true),
		"natural_nodes":natural_nodes.duplicate(true),
		"loads":carried_by_actor.duplicate(true),
		"plots":harvested_fields.duplicate(true),
		"last_events":event_log.slice(maxi(0,event_log.size()-32))}

func get_world_summary() -> Dictionary:
	var total_people: int = citizens.size()
	var average_prosperity: int = 0
	for town in villages.values():
		average_prosperity += int(town["prosperity"])
	return {"day":day,"hour":hour,"villages":villages.size(),
		"population":total_people,
		"average_prosperity":average_prosperity/maxi(1,villages.size()),
		"events":event_log.size()}
