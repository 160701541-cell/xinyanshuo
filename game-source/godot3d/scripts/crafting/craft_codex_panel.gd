extends Control
## Production-candidate in-game item graph viewer (Godot 4.4.1).
## READ ONLY. Never modifies inventories, WorldState.jobs, knowledge or saves.
signal closed
const Reader = preload("res://scripts/craft_catalog_reader.gd")
const INK := Color("#0e2020")
const PANEL := Color("#19302e")
const GOLD := Color("#d9c397")
const TEXT := Color("#eee8d7")
const DIM := Color("#a9b6ab")
const LINK := Color("#9ccec0")
const BLOCKED := Color("#ddad98")
const FILTERS := ["全部", "原料", "半成品", "成品与组件"]
var db = Reader.new()
var search_box: LineEdit
var filter_button: OptionButton
var inventory_list: VBoxContainer
var detail_rich: RichTextLabel
var summary_label: Label
var item_buttons: Dictionary = {}
var selected_item_id: String = ""
var acquired_research: Array[String] = []
var acquired_blueprints: Array[String] = []
var nearby_stations: Array[String] = []
var inventory_snapshot: Dictionary = {}
var source_path: String = Reader.CANONICAL_PATH
var source_error: String = ""

func _card_color(color: Color, radius: int = 10) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.border_width_left = 1
	box.border_width_right = 1
	box.border_width_top = 1
	box.border_width_bottom = 1
	box.border_color = GOLD.darkened(0.65)
	box.content_margin_left = 13.0
	box.content_margin_right = 13.0
	box.content_margin_top = 10.0
	box.content_margin_bottom = 10.0
	return box

func _ready() -> void:
	name = "CraftCodexPanel"
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_layout()
	reload_catalog(source_path)

func reload_catalog(path: String = Reader.CANONICAL_PATH) -> bool:
	source_path = path
	var ok: bool = db.load_catalog(path)
	source_error = db.error_code
	if not ok:
		selected_item_id = ""
		summary_label.text = "工艺目录尚未就绪 · " + source_error
		_clear_list()
		detail_rich.clear()
		detail_rich.append_text("资源校验失败。本模块只读；不会生成或扣除任何物资。")
		return false
	summary_label.text = "%d种物资 · %d条工艺 · %d项研究 · %d张图纸" % [
		db.items.size(), db.recipes.size(), db.research.size(), db.blueprints.size()]
	_refresh_items()
	if selected_item_id.is_empty() or not db.items.has(selected_item_id):
		select_item("clay_soil" if db.items.has("clay_soil") else String(db.items.keys()[0]))
	else:
		select_item(selected_item_id)
	return true

func set_world_view(research_ids: Array[String], blueprint_ids: Array[String],
		stations: Array[String], stock: Dictionary) -> void:
	# Caller passes a snapshot from CANONICAL WorldState; this module cannot grant it.
	acquired_research = research_ids.duplicate()
	acquired_blueprints = blueprint_ids.duplicate()
	nearby_stations = stations.duplicate()
	inventory_snapshot = stock.duplicate(true)
	if not selected_item_id.is_empty() and db.items.has(selected_item_id):
		select_item(selected_item_id)

func _heading(value: String, size: int, color: Color = TEXT) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	return node

func _build_layout() -> void:
	var overlay := ColorRect.new()
	overlay.name = "DarkOverlay"
	overlay.color = Color(0.025, 0.052, 0.05, 0.97)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var margins := MarginContainer.new()
	margins.name = "ContentMargins"
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margins.add_theme_constant_override("margin_left", 34)
	margins.add_theme_constant_override("margin_right", 34)
	margins.add_theme_constant_override("margin_top", 26)
	margins.add_theme_constant_override("margin_bottom", 26)
	add_child(margins)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 18)
	margins.add_child(outer)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 20)
	outer.add_child(top)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(_heading("苍岚 · 万物工艺谱", 30, GOLD))
	titles.add_child(_heading("原材料 → 加工 → 图纸 → 建造   ·   只读技术预览", 15, DIM))
	top.add_child(titles)
	var close_button := Button.new()
	close_button.name = "CloseCraftCodex"
	close_button.text = "返回游戏  ×"
	close_button.custom_minimum_size = Vector2(145, 60)
	close_button.add_theme_stylebox_override("normal", _card_color(PANEL))
	close_button.add_theme_font_size_override("font_size", 18)
	close_button.pressed.connect(func(): closed.emit())
	top.add_child(close_button)
	summary_label = _heading("", 15, DIM)
	summary_label.name = "CatalogSummary"
	outer.add_child(summary_label)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 22)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(split)
	var left := PanelContainer.new()
	left.name = "ItemsListCard"
	left.custom_minimum_size.x = 330
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 0.8
	left.add_theme_stylebox_override("panel", _card_color(PANEL))
	split.add_child(left)
	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 12)
	left.add_child(left_col)
	left_col.add_child(_heading("物资索引", 21, GOLD))
	search_box = LineEdit.new()
	search_box.name = "MaterialSearch"
	search_box.placeholder_text = "搜索名称或材料编号"
	search_box.custom_minimum_size.y = 50
	search_box.text_changed.connect(func(_value): _refresh_items())
	left_col.add_child(search_box)
	filter_button = OptionButton.new()
	filter_button.name = "MaterialStageFilter"
	filter_button.custom_minimum_size.y = 49
	for label in FILTERS:
		filter_button.add_item(label)
	filter_button.item_selected.connect(func(_index): _refresh_items())
	left_col.add_child(filter_button)
	var left_scroll := ScrollContainer.new()
	left_scroll.name = "MaterialsScroll"
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_col.add_child(left_scroll)
	inventory_list = VBoxContainer.new()
	inventory_list.name = "MaterialRows"
	inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_list.add_theme_constant_override("separation", 5)
	left_scroll.add_child(inventory_list)
	var right := PanelContainer.new()
	right.name = "RecipeDetailsCard"
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.5
	right.add_theme_stylebox_override("panel", _card_color(PANEL))
	split.add_child(right)
	var right_col := VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 8)
	right.add_child(right_col)
	right_col.add_child(_heading("材料档案 / 工艺关系", 21, GOLD))
	detail_rich = RichTextLabel.new()
	detail_rich.name = "SelectedItemDetails"
	detail_rich.bbcode_enabled = true
	detail_rich.fit_content = false
	detail_rich.scroll_active = true
	detail_rich.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_rich.add_theme_font_size_override("normal_font_size", 18)
	detail_rich.add_theme_color_override("default_color", TEXT)
	right_col.add_child(detail_rich)
	var footer := _heading("研究 ≠ 免费领材料    ·    图纸 ≠ 已建成实体    ·    真正生产由 WorldState 结算", 15, DIM)
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(footer)

func _clear_list() -> void:
	item_buttons.clear()
	for child in inventory_list.get_children():
		inventory_list.remove_child(child)
		child.queue_free()

func _filter_match(item: Dictionary) -> bool:
	var selected := filter_button.selected
	var stage := String(item.get("stage", ""))
	if selected == 1:
		return stage == "raw"
	if selected == 2:
		return stage in ["intermediate", "byproduct"]
	if selected == 3:
		return stage in ["product", "construction"]
	return true

func _refresh_items() -> void:
	_clear_list()
	var needle := search_box.text.strip_edges().to_lower()
	var keys: Array = db.items.keys()
	keys.sort()
	for key in keys:
		var item: Dictionary = db.items[key]
		if not _filter_match(item):
			continue
		if not needle.is_empty() and needle not in String(key).to_lower() and needle not in String(item.get("name", "")).to_lower():
			continue
		var btn := Button.new()
		btn.name = "Item_" + String(key)
		btn.text = "%s  ·  %s" % [String(item.get("name", key)), String(key)]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size.y = 53
		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_color_override("font_color", TEXT)
		btn.add_theme_stylebox_override("normal", _card_color(INK))
		btn.add_theme_stylebox_override("hover", _card_color(INK.lightened(0.11)))
		btn.pressed.connect(select_item.bind(String(key)))
		inventory_list.add_child(btn)
		item_buttons[key] = btn
	if item_buttons.is_empty():
		inventory_list.add_child(_heading("没有找到符合条件的物资", 16, DIM))

func _material_name(item_id: String) -> String:
	return String(db.items[item_id].get("name", item_id)) if db.items.has(item_id) else item_id

func _format_items(entries: Dictionary) -> String:
	var result: Array[String] = []
	var keys: Array = entries.keys()
	keys.sort()
	for key in keys:
		result.append("%s ×%d" % [_material_name(String(key)), int(entries[key])])
	return "、".join(result)

func select_item(item_id: String) -> void:
	if not db.items.has(item_id):
		return
	selected_item_id = item_id
	for key in item_buttons:
		(item_buttons[key] as Button).modulate = GOLD if String(key) == item_id else Color.WHITE
	var item: Dictionary = db.items[item_id]
	var label: String = String(item.get("name", item_id))
	var lines: Array[String] = []
	lines.append("[color=#d9c397][font_size=28]%s[/font_size][/color]" % label)
	lines.append("[color=#a9b6ab]编号：%s  |  类型：%s  |  单位质量：%d g[/color]" %
		[item_id, String(item.get("stage","?")), int(item.get("mass_g",0))])
	lines.append("\n[color=#9ccec0]来源 / 采集[/color]\n" + String(item.get("origin", "?")))
	var makers: Array[String] = db.producers_of(item_id)
	lines.append("\n[color=#d9c397][font_size=20]生产它的工序（%d）[/font_size][/color]" % makers.size())
	if makers.is_empty():
		lines.append("自然资源：需要前往真实生态地点取得，并遵守产权和采集条件。")
	for rid in makers:
		var r: Dictionary = db.recipes[rid]
		var verdict: Dictionary = db.inspect_recipe(rid, acquired_research,
			acquired_blueprints, nearby_stations, inventory_snapshot)
		var state := "[color=#9ccec0]可申请工单[/color]" if verdict.get("ok", false) else "[color=#ddad98]条件不足 · 尚不能生产[/color]"
		lines.append("\n[b]%s[/b]  %s" % [String(r["name"]), state])
		lines.append("投料：%s" % _format_items(r["inputs"]))
		lines.append("产出：%s" % _format_items(r["outputs"]))
		lines.append("设备：%s  ·  工时：%d分钟  ·  损耗：%dg" %
			[String(r["station"]), int(r["work_minutes"]), int(r["loss_g"])])
		if not verdict.get("ok", false):
			lines.append("[color=#ddad98]尚缺：%s[/color]" % "、".join(verdict["missing"]))
	var uses: Array[String] = db.consumers_of(item_id)
	lines.append("\n[color=#d9c397][font_size=20]可参与的后续制作（%d）[/font_size][/color]" % uses.size())
	if uses.is_empty():
		lines.append("目前没有更多下游工序。")
	for rid in uses:
		var r: Dictionary = db.recipes[rid]
		lines.append("• %s → %s" % [String(r["name"]), _format_items(r["outputs"])])
	lines.append("\n[color=#a9b6ab]此界面只展示配方与前置条件。不生成物品，不修改世界，不会因打开面板获得研究或图纸。[/color]")
	detail_rich.clear()
	detail_rich.append_text("\n".join(lines))

func get_snapshot() -> Dictionary:
	return {"selected":selected_item_id,"item_count":db.items.size(),
		"recipe_count":db.recipes.size(),"search":search_box.text,
		"filtered_count":item_buttons.size(),"source_error":source_error,
		"read_only":true}
