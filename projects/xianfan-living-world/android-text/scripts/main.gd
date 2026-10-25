extends Control

const INK := Color("#0d191d")
const PAPER := Color("#f2e7d6")
const MUTED := Color("#b6c6c2")
const GOLD := Color("#dfbb7e")
const PANEL := Color("#1c3338")
const BUTTON := Color("#29494c")

var game := XianfanWorld.new()
var story: RichTextLabel
var heading: Label
var status_line: Label
var actions: GridContainer
var command: LineEdit
var activity_title: Label
var tabs: HBoxContainer
var scroll: ScrollContainer
var current_tab := "游历"
var action_drawer: ScrollContainer
var action_toggle: Button
var drawer_open := false
var quick_row: HBoxContainer

func _ready() -> void:
    _build()
    refresh()

func _style(color: Color, border: Color = Color.TRANSPARENT, radius: int = 12) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = color
    s.set_corner_radius_all(radius)
    s.set_border_width_all(1 if border.a > 0.0 else 0)
    s.border_color = border
    s.content_margin_left = 15.0
    s.content_margin_right = 15.0
    s.content_margin_top = 12.0
    s.content_margin_bottom = 12.0
    return s

func _txt(value: String, px: int, color: Color = PAPER) -> Label:
    var label := Label.new()
    label.text = value
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", px)
    label.add_theme_color_override("font_color", color)
    return label

func _btn(value: String, cb: Callable, selected: bool = false) -> Button:
    var b := Button.new()
    b.text = value
    b.custom_minimum_size = Vector2(0, 62)
    b.add_theme_font_size_override("font_size", 21)
    b.add_theme_color_override("font_color", PAPER)
    b.add_theme_color_override("font_hover_color", PAPER)
    b.add_theme_stylebox_override("normal", _style(Color("#40544e") if selected else BUTTON, GOLD if selected else Color("#567174")))
    b.add_theme_stylebox_override("hover", _style(Color("#526b62"), GOLD))
    b.add_theme_stylebox_override("pressed", _style(Color("#1b2c30"), GOLD))
    b.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, GOLD))
    b.pressed.connect(cb)
    return b

func _build() -> void:
    # Use an Android-system font to avoid missing CJK glyphs on the default Godot font.
    var sysfont := SystemFont.new()
    sysfont.font_names = PackedStringArray(["Noto Sans CJK SC", "Noto Sans SC", "Droid Sans Fallback", "sans-serif"])
    var t := Theme.new()
    t.default_font = sysfont
    theme = t

    var background := ColorRect.new()
    background.color = INK
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_bottom", 12)
    add_child(margin)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 11)
    margin.add_child(root)

    var title_row := VBoxContainer.new()
    title_row.add_theme_constant_override("separation", 2)
    root.add_child(title_row)
    var title := _txt("仙 凡 · 苍 岚", 31, GOLD)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_row.add_child(title)
    var subtitle := _txt("第一世 · 红尘问仙", 16, MUTED)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_row.add_child(subtitle)

    var hud_box := PanelContainer.new()
    hud_box.add_theme_stylebox_override("panel", _style(PANEL, Color("#556c6a")))
    root.add_child(hud_box)
    var hud_lines := VBoxContainer.new()
    hud_box.add_child(hud_lines)
    heading = _txt("", 18, GOLD)
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hud_lines.add_child(heading)
    status_line = _txt("", 18, PAPER)
    status_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hud_lines.add_child(status_line)

    tabs = HBoxContainer.new()
    tabs.add_theme_constant_override("separation", 6)
    root.add_child(tabs)
    for tab in ["游历", "人物", "记事", "系统"]:
        var b := _btn(tab, func(): _switch(tab), tab == current_tab)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.custom_minimum_size = Vector2(0, 55)
        tabs.add_child(b)

    var story_panel := PanelContainer.new()
    story_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    story_panel.add_theme_stylebox_override("panel", _style(Color("#17292e"), Color("#426066")))
    root.add_child(story_panel)
    var inner := VBoxContainer.new()
    inner.add_theme_constant_override("separation", 9)
    story_panel.add_child(inner)
    activity_title = _txt("行走江湖", 21, GOLD)
    inner.add_child(activity_title)
    story = RichTextLabel.new()
    story.bbcode_enabled = false
    story.fit_content = false
    story.scroll_active = true
    story.scroll_following = false
    story.size_flags_vertical = Control.SIZE_EXPAND_FILL
    story.add_theme_font_size_override("normal_font_size", 23)
    story.add_theme_color_override("default_color", PAPER)
    inner.add_child(story)

    # The action menu folds away so most of the phone is a reading surface.
    quick_row = HBoxContainer.new()
    quick_row.add_theme_constant_override("separation", 7)
    root.add_child(quick_row)
    for quick in ["看看周围", "问妹妹在忙什么", "出门走走"]:
        var q := _btn(quick, func(): _execute("去林缘" if quick == "出门走走" else quick))
        q.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        q.custom_minimum_size = Vector2(0, 48)
        q.add_theme_font_size_override("font_size", 17)
        quick_row.add_child(q)

    action_toggle = _btn("参考操作 · 不限于这些  ▾", func(): _toggle_actions())
    action_toggle.custom_minimum_size = Vector2(0, 46)
    action_toggle.add_theme_font_size_override("font_size", 17)
    root.add_child(action_toggle)
    scroll = ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(0, 210)
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.visible = drawer_open
    root.add_child(scroll)
    actions = GridContainer.new()
    actions.columns = 2
    actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    actions.add_theme_constant_override("h_separation", 8)
    actions.add_theme_constant_override("v_separation", 8)
    scroll.add_child(actions)

    var input_row := HBoxContainer.new()
    input_row.add_theme_constant_override("separation", 8)
    root.add_child(input_row)
    command = LineEdit.new()
    command.placeholder_text = "自由描述行动：去林边拾柴、问妹妹在忙什么..."
    command.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    command.custom_minimum_size = Vector2(0, 62)
    command.add_theme_font_size_override("font_size", 19)
    command.add_theme_color_override("font_color", PAPER)
    command.add_theme_color_override("font_placeholder_color", MUTED)
    command.add_theme_stylebox_override("normal", _style(PANEL, Color("#547275")))
    command.add_theme_stylebox_override("focus", _style(PANEL, GOLD))
    command.text_submitted.connect(_execute)
    input_row.add_child(command)
    var go := _btn("执行", func(): _execute(command.text), true)
    go.custom_minimum_size = Vector2(110, 62)
    input_row.add_child(go)

func _toggle_actions() -> void:
    drawer_open = not drawer_open
    scroll.visible = drawer_open
    action_toggle.text = "收起参考操作  ▴" if drawer_open else "参考操作 · 不限于这些  ▾"

func _switch(tab: String) -> void:
    current_tab = tab
    refresh()

func _execute(raw: String) -> void:
    if raw.strip_edges().is_empty(): return
    game.act(raw.strip_edges())
    command.clear()
    command.release_focus()
    current_tab = "游历"
    refresh()

func _set_actions(list: Array[String]) -> void:
    for child in actions.get_children():
        actions.remove_child(child)
        child.queue_free()
    for label in list:
        var b := _btn(label, func(): _execute(label))
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        actions.add_child(b)
    scroll.scroll_vertical = 0

func refresh() -> void:
    heading.text = game.time_string() + "   ·   " + game.data["weather"]
    status_line.text = "%s  |  %s  |  精力 %d  |  铜钱 %d" % [game.data["place"], game.data["realm"], int(game.data["stamina"]), int(game.data["money"])]
    # On narrower phones the long HUD needs two lines, not a clipped single line.
    status_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    match current_tab:
        "游历":
            activity_title.text = "近事 · " + game.data["place"]
            story.text = game.scene_overview()
            _set_actions(game.actions_for_place())
        "人物":
            activity_title.text = "人物 · 身家 · 行囊"
            story.text = game.status()
            _set_actions(["查看四周", "跟妹妹说话", "查看修炼结论"])
        "记事":
            activity_title.text = "第一世 · 事件日记（完整保留）"
            story.text = "\n\n".join(game.journal)
            _set_actions(["查看四周", "自动完成今日安排"])
        "系统":
            activity_title.text = "存档与玩法说明"
            story.text = "《仙凡·苍岚》安卓独立文字游戏 1.1\n\n无需网络、账号或API。游戏使用Godot原生界面，每次有效行动自动保存，损坏时尝试备份恢复。\n\n自由输入采用本地意图识别，不是联网AI。可选‘自动完成今日安排’批量结算生活行动；连续修炼在功法真伪与原始灵根未验证时不会伪造突破。\n\n主线锚点：" + game.data["source_event"] + "。安卓游戏的新增经历仅存手机本地，不会自动同步GitHub。\n\n本机存档：user://xianfan_first_life.json\n\n可用按钮打开全部操作；不支持的命令不扣时间与物品。"
            _set_actions(["查看四周", "查看修炼结论"])
    story.call_deferred("scroll_to_line", 0)
    for b in tabs.get_children():
        b.add_theme_stylebox_override("normal", _style(Color("#40544e") if b.text == current_tab else BUTTON, GOLD if b.text == current_tab else Color("#567174")))