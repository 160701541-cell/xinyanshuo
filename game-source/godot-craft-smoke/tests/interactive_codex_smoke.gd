extends SceneTree
## Render-independent UI event smoke: real Godot 4.4.1 parser and Control tree.
const CodexUI = preload("res://scripts/craft_codex_panel.gd")
func _initialize() -> void:
	call_deferred("_run_actual_ui")

func _run_actual_ui() -> void:
	var ui: Control = CodexUI.new()
	ui.source_path = "res://data/material_graph.v1.json"
	root.add_child(ui)
	var snap: Dictionary = ui.get_snapshot()
	if snap.get("item_count") != 24 or snap.get("recipe_count") != 14:
		_die(ui, "UI_ITEM_OR_RECIPE_COUNT")
		return
	if snap.get("selected") != "clay_soil" or not snap.get("read_only", false):
		_die(ui, "UI_READ_ONLY_OR_DEFAULT_SELECTION")
		return
	if ui.mouse_filter != Control.MOUSE_FILTER_STOP:
		_die(ui, "UI_TOUCH_INPUT_NOT_BLOCKED")
		return
	if ui.item_buttons.size() != 24:
		_die(ui, "UI_LIST_NOT_FULLY_RENDERED")
		return
	ui.search_box.text = "青瓦"
	ui._refresh_items()
	if ui.item_buttons.size() != 2 or not ui.item_buttons.has("qing_roof_tile") or not ui.item_buttons.has("roof_module"):
		_die(ui, "UI_SEARCH_INCORRECT")
		return
	ui.search_box.text = ""
	ui.filter_button.select(1)
	ui._refresh_items()
	if ui.item_buttons.size() != 7:
		_die(ui, "UI_RAW_FILTER_INCORRECT")
		return
	ui.filter_button.select(0)
	ui._refresh_items()
	ui.select_item("qing_roof_tile")
	if ui.selected_item_id != "qing_roof_tile":
		_die(ui, "UI_ITEM_NAVIGATION_INCORRECT")
		return
	var text_value: String = ui.detail_rich.get_parsed_text()
	if not text_value.contains("烧青瓦") or not text_value.contains("条件不足"):
		_die(ui, "UI_LOCKED_RECIPE_NOT_EXPLAINED")
		return
	var snapshot_before: Dictionary = ui.get_snapshot()
	var actual_research: Array[String] = ["ceramics_1"]
	var actual_blueprints: Array[String] = ["bp_kiln_arch"]
	var actual_stations: Array[String] = ["kiln"]
	ui.set_world_view(actual_research, actual_blueprints, actual_stations,
		{"tile_blank":1,"firewood":1})
	var unlocked_text: String = ui.detail_rich.get_parsed_text()
	if not unlocked_text.contains("可申请工单"):
		_die(ui, "UI_UNLOCKED_RECIPE_NOT_IN_VIEW")
		return
	if ui.get_snapshot()["item_count"] != snapshot_before["item_count"]:
		_die(ui, "UI_MUTATED_STATIC_ITEMS")
		return
	var closed_flag := [false]
	ui.closed.connect(func(): closed_flag[0] = true)
	ui.get_node("ContentMargins").get_child(0).get_child(0).get_child(1).emit_signal("pressed")
	if not closed_flag[0]:
		_die(ui, "UI_CLOSE_ACTION")
		return
	print("PASS_GODOT_4_4_1_INTERACTIVE_CRAFT_CODEX_READ_ONLY")
	print("USER_RESEARCH_STOCK_UNCHANGED_AND_GAME_RELEASE_UNVERIFIED")
	ui.queue_free()
	quit(0)

func _die(ui: Control, reason: String) -> void:
	push_error("CODEX_UI_FAIL: " + reason)
	ui.queue_free()
	quit(4)
