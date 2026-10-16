extends RefCounted
## CAC-NPC-AI-001: local Qwen ONLY proposes one constrained intention.
## Immutable WorldBox economy is the authority. No LLM can spawn money,
## build a finished house, change professions, read other citizens' secrets,
## command arbitrary GDScript or bypass physical transport.
const TOWN := "CL-HX-VILLAGE-0001"
const ACTIONS := ["eat","rest","inspect_stock","inspect_site","keep_working"]
var outcomes: Array[Dictionary] = []
var last_applied_hour: Dictionary = {}

func parse_intent(reply: String) -> String:
	# Native llama.cpp emits free text; this is NOT executable JSON/code.
	# Require an exact first line so hidden/verbose instructions fail closed.
	if reply.length()>512:
		return ""
	var first: String = reply.strip_edges().get_slice("\n",0).strip_edges()
	if not first.begins_with("ACTION="):
		return ""
	var action: String = first.substr(7).strip_edges()
	if action not in ACTIONS:
		return ""
	return action

func apply_intent(entity_id: String, intent: String, sim: RefCounted,
		actor: Node3D, construction: Node3D, now_hour: int) -> bool:
	if intent not in ACTIONS or sim==null or actor==null or not is_instance_valid(actor):
		return false
	if String(actor.get_meta("entity_id",""))!=entity_id:
		return false
	var citizens: Dictionary = sim.get("citizens")
	if not citizens.has(entity_id):
		return false
	var profile: Dictionary = citizens[entity_id]
	if String(profile.get("village_id",""))!=TOWN:
		return false
	# Prevent model-text prompt floods from taking over simulation.
	if int(last_applied_hour.get(entity_id,-100))>=now_hour-1:
		return false
	var busy: bool = bool(actor.get("_externally_assigned_job"))
	var accepted: bool = false
	match intent:
		"eat":
			if int(profile.get("hunger",0))>=35:
				accepted = bool(sim.call("feed_citizen",entity_id))
				if accepted:
					profile["schedule"]="ai_eat"
		"rest":
			if not busy and int(profile.get("energy",100))<=70:
				profile["energy"]=mini(100,int(profile["energy"])+6)
				profile["schedule"]="ai_rest"
				accepted=true
		"inspect_stock":
			if not busy and int(profile.get("energy",0))>=25:
				actor.call("assign_work_destination",Vector3(2.0,0.4,40.0))
				profile["schedule"]="ai_inspect_stock_en_route"
				accepted=true
		"inspect_site":
			if not busy and construction!=null:
				var project: String = String(construction.get("current_project"))
				var sites: Dictionary = construction.get("construction_sites")
				if not project.is_empty() and sites.has(project):
					actor.call("assign_work_destination",sites[project]["position"])
					profile["schedule"]="ai_inspect_site_en_route"
					accepted=true
		"keep_working":
			# Existing NPC work scheduler remains authoritative; no extra rewards.
			if int(profile.get("energy",0))>=20:
				accepted=true
	if not accepted:
		return false
	last_applied_hour[entity_id]=now_hour
	if intent!="eat":
		sim.call("_journal",TOWN,"local_ai_intent",1,entity_id+":"+intent)
	outcomes.append({"id":entity_id,"action":intent,"hour":now_hour,
		"physical_world_authoritative":true})
	if outcomes.size()>32:
		outcomes.pop_front()
	return true

func snapshot() -> Dictionary:
	return {"schema":1,"accepted_intents":outcomes.duplicate(true),
		"last_applied_hour":last_applied_hour.duplicate(true),
		"source":"REAL_OFFLINE_QWEN_IF_LOADED_OTHERWISE_WORLD_SIM_NO_FAKE_AI"}
