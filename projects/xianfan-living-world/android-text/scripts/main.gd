extends Control

# Portrait-first reader, NPC dossier popups and separated dialogue history.
# Native Godot interpretation of 《浮生簿·界面美化模块》: parchment-only
# content, single tinted heading stripe, ink text and chapter-dependent accents.
# No LaTeX/KaTeX; game mechanics and saved data remain unchanged.
const BG := Color("#FBF8F1")
const PAPER := Color("#3A362F")
const FADED := Color("#8A8074")
const GOLD := Color("#427C74")
const PANEL := Color("#FBF8F1")
const BTN := Color("#FBF8F1")
const DIVIDER := Color("#E6E0D4")
const JADE_BAND := Color("#D6DFD8")
const JADE_INK := Color("#152826")
const ROSE_BAND := Color("#EDD7D5")
const ROSE_INK := Color("#2B1317")
const ROSE_EDGE := Color("#B45464")

var game := XianfanWorld.new()
var ai: XianfanAI
var local_llm: Node
var local_enabled := false
var local_model_url: LineEdit
var local_model_selector: OptionButton
var local_model_hint: Label
var context_selector: OptionButton
var context_hint_label: Label
var local_model_fields: Array[Control]=[]
var remote_model_fields: Array[Control]=[]
var pending_model_path := ""
const DIRECTOR_PREF := "user://xianfan_ai_director.json"
var director_mode := "关键事件"
var director_selector: OptionButton
var last_director_clock := -99999
var last_director_place := ""
var latest_action := ""
var latest_outcome := ""
var view := "剧情"
var current_npc := ""
var map_selected := ""
var known_people_page := false
var letter_body_field: TextEdit
var last_roster_sector := ""
var last_roster_page := 0
var scene_text: RichTextLabel
var title_label: Label
var hud: Label
var page_title: Label
var paper_heading_strip: PanelContainer
var reader_card: PanelContainer
var stamina_bar: ProgressBar
var modal_card: PanelContainer
var modal_heading_strip: PanelContainer
var reader_footer: Label
var route_canvas: XianfanRouteCanvas
var cancel_ai_button: Button
var tab_buttons: HBoxContainer
var actor_buttons: VBoxContainer
var quick_buttons: HBoxContainer
var action_list: GridContainer
var action_scroll: ScrollContainer
var action_toggle: Button
var drawer_open := false
var command: LineEdit
var input_row: HBoxContainer
var feedback_copy: Button
var settings_button: Button
var notice: Label
var model_progress_bar: ProgressBar
var model_progress_label: Label
var resume_model_button: Button
var model_download_seen := false
var overlay: Control
var modal_title: Label
var modal_info: RichTextLabel
var modal_actions: VBoxContainer
var modal_form: VBoxContainer
var setting_provider: OptionButton
var setting_url: LineEdit
var setting_model: LineEdit
var setting_key: LineEdit
var request_text := ""
# A 5-second wall-time tick advances one game minute at 1x. Godot does not
# keep running in Android background; reopening performs bounded catch-up.
const WORLD_CLOCK_FILE := "user://xianfan_world_clock.json"
const MAX_OFFLINE_MINUTES := 43200  # 30 game days, bounded CPU and disk work.
var world_speed := 1
var clock_accumulator := 0.0
var clock_backgrounded := false
var world_clock_button: Button
var offline_progress_enabled := true
var _last_world_ui_hour := -1


func _ready() -> void:
    ai = XianfanAI.new()
    add_child(ai)
    ai.completed.connect(_on_ai_completed)
    local_llm = load("res://scripts/local_llm.gd").new()
    add_child(local_llm)
    local_llm.status_changed.connect(_local_status)
    local_llm.answered.connect(_on_ai_completed)
    local_llm.streaming.connect(_on_local_stream)
    local_llm.download_progress.connect(_on_model_download_progress)
    var choice := FileAccess.open("user://xianfan_local_choice.txt",FileAccess.READ)
    if choice!=null and choice.get_as_text()=="1": local_enabled=true
    var director_file:=FileAccess.open(DIRECTOR_PREF,FileAccess.READ)
    if director_file!=null:
        var saved: Variant=JSON.parse_string(director_file.get_as_text())
        if saved is Dictionary and str(saved.get("mode","")) in ["关闭","关键事件","每次行动"]:
            director_mode=str(saved["mode"])
    _build()
    _restore_world_clock()
    _refresh()
    if local_enabled:
        call_deferred("_restore_local_ai_on_startup")

func _save_world_clock() -> void:
    var f:=FileAccess.open(WORLD_CLOCK_FILE,FileAccess.WRITE)
    if f==null: return
    f.store_string(JSON.stringify({"wall_unix":Time.get_unix_time_from_system(),
        "speed":world_speed,"offline_enabled":offline_progress_enabled}))

func _restore_world_clock() -> void:
    if not FileAccess.file_exists(WORLD_CLOCK_FILE):
        _save_world_clock()
        return
    var f:=FileAccess.open(WORLD_CLOCK_FILE,FileAccess.READ)
    if f==null: return
    var p: Variant=JSON.parse_string(f.get_as_text())
    if not (p is Dictionary): return
    var clock: Dictionary=p
    var speed:=int(clock.get("speed",1))
    if speed in [0,1,5,20]: world_speed=speed
    offline_progress_enabled=bool(clock.get("offline_enabled",true))
    if offline_progress_enabled and world_speed>0:
        var elapsed:=maxf(0.0,Time.get_unix_time_from_system()-float(clock.get("wall_unix",Time.get_unix_time_from_system())))
        var game_mins:=mini(MAX_OFFLINE_MINUTES,int(elapsed*float(world_speed)/5.0))
        if game_mins>0:
            var remaining:=game_mins
            while remaining>0:
                var batch:=mini(720,remaining)
                game.passive_time(batch)
                remaining-=batch
            notice.text="离线补算了 %d 个游戏小时：NPC照常务工、吃饭和交易。超过上限的时间不会伪装成已演算。" % int(game_mins/60)
    _save_world_clock()

func _cycle_world_speed() -> void:
    var levels: Array=[0,1,5,20]
    var i:=levels.find(world_speed)
    world_speed=int(levels[(i+1)%levels.size()])
    clock_accumulator=0.0
    _save_world_clock()
    _refresh()

func _process(delta: float) -> void:
    if clock_backgrounded or world_speed==0: return
    # World time has its own real-time source; it never waits for actions.
    clock_accumulator+=clampf(delta,0.0,1.0)*float(world_speed)/5.0
    var mins:=mini(60,int(clock_accumulator))
    if mins<1: return
    clock_accumulator-=float(mins)
    game.passive_time(mins,false)
    if int(game._clock())%10==0:
        game.save()
        _save_world_clock()
    hud.text="%s · %s\n精力 %d/100 · 铜钱 %d文 · %s" % [
        game.time_string(),str(game.data["place"]),int(game.data["stamina"]),
        int(game.data["money"]),str(game.data["realm"])]
    var hour:=int(game._clock()/60)
    if view in ["世界","经济"] and hour!=_last_world_ui_hour:
        _last_world_ui_hour=hour
        _refresh()
    if int(game._clock())%60==0: _save_world_clock()

func _notification(what: int) -> void:
    if what==NOTIFICATION_APPLICATION_PAUSED:
        if local_llm!=null: local_llm.pause_download()
        clock_backgrounded=true
        if not game.data.is_empty():
            game.save()
            _save_world_clock()
    elif what==NOTIFICATION_APPLICATION_RESUMED:
        clock_backgrounded=false
        if not game.data.is_empty():
            _restore_world_clock()
            if is_inside_tree(): _refresh()
        if local_enabled and local_llm!=null:
            call_deferred("_resume_previous_model_download")

func _box(color: Color, border: Color = Color.TRANSPARENT, roundness: int = 12) -> StyleBoxFlat:
    var b := StyleBoxFlat.new()
    b.bg_color = color
    b.set_corner_radius_all(roundness)
    b.set_border_width_all(1 if border.a > 0.0 else 0)
    b.border_color = border
    b.content_margin_left = 14
    b.content_margin_right = 14
    b.content_margin_top = 12
    b.content_margin_bottom = 12
    return b

func _paper_palette(page: String) -> Dictionary:
    match page:
        "对话", "人物":
            return {"band":ROSE_BAND,"ink":ROSE_INK,"edge":ROSE_EDGE}
        "反馈":
            return {"band":Color("#EED6CE"),"ink":Color("#2D1310"),"edge":Color("#BC5044")}
        "设置":
            return {"band":Color("#D9DEDE"),"ink":Color("#162028"),"edge":Color("#517693")}
        _:
            return {"band":JADE_BAND,"ink":JADE_INK,"edge":GOLD}

func _progress_style(tint: Color) -> StyleBoxFlat:
    var b := StyleBoxFlat.new()
    b.bg_color = tint
    b.set_corner_radius_all(3)
    b.content_margin_top = 0
    b.content_margin_bottom = 0
    b.content_margin_left = 0
    b.content_margin_right = 0
    return b

func _label(value: String, font_size: int = 19, color: Color = PAPER) -> Label:
    var t := Label.new()
    t.text = value
    t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    t.add_theme_font_size_override("font_size", font_size)
    t.add_theme_color_override("font_color", color)
    return t

func _button(value: String, target: Callable, fs: int = 18) -> Button:
    var b := Button.new()
    b.text = value
    b.custom_minimum_size = Vector2(0, 45)
    b.add_theme_font_size_override("font_size", fs)
    b.add_theme_color_override("font_color", PAPER)
    b.add_theme_color_override("font_hover_color", JADE_INK)
    b.add_theme_color_override("font_pressed_color", JADE_INK)
    b.add_theme_color_override("font_focus_color", PAPER)
    b.add_theme_stylebox_override("normal", _box(BTN, DIVIDER, 7))
    b.add_theme_stylebox_override("hover", _box(JADE_BAND, GOLD, 7))
    b.add_theme_stylebox_override("pressed", _box(Color("#C7D8D0"), GOLD, 7))
    b.add_theme_stylebox_override("focus", _box(BTN, GOLD, 7))
    b.pressed.connect(target)
    return b

func _wipe(node: Node) -> void:
    for child in node.get_children():
        node.remove_child(child)
        child.queue_free()

func _build() -> void:
    var face := SystemFont.new()
    face.font_names=PackedStringArray(["Noto Sans CJK SC","Noto Sans SC","Droid Sans Fallback","sans-serif"])
    var visual := Theme.new()
    visual.default_font=face
    theme=visual
    var back := ColorRect.new()
    back.color=BG
    back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    back.mouse_filter=Control.MOUSE_FILTER_IGNORE
    add_child(back)
    var margins := MarginContainer.new()
    margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for direction in ["left","right","top","bottom"]:
        margins.add_theme_constant_override("margin_"+direction, 16 if direction in ["left","right"] else 10)
    add_child(margins)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation",7)
    margins.add_child(root)
    title_label=_label("仙 凡 · 苍 岚",30,JADE_INK)
    title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    root.add_child(title_label)
    hud=_label("",16,FADED)
    hud.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    root.add_child(hud)
    world_clock_button=_button("世界运行 1×",func(): _cycle_world_speed(),16)
    world_clock_button.custom_minimum_size=Vector2(0,31)
    root.add_child(world_clock_button)
    stamina_bar = ProgressBar.new()
    stamina_bar.show_percentage = false
    stamina_bar.min_value = 0
    stamina_bar.max_value = 100
    stamina_bar.custom_minimum_size = Vector2(0, 9)
    stamina_bar.add_theme_stylebox_override("background",_progress_style(DIVIDER))
    stamina_bar.add_theme_stylebox_override("fill",_progress_style(Color("#3F7C76")))
    root.add_child(stamina_bar)

    tab_buttons=HBoxContainer.new()
    tab_buttons.add_theme_constant_override("separation",4)
    root.add_child(tab_buttons)
    for name in ["剧情","对话","地图","人物","市集","更多"]:
        var tab_name := str(name)
        var b := _button(tab_name,func(): _change_tab(tab_name),17)
        b.size_flags_horizontal=SIZE_EXPAND_FILL
        b.custom_minimum_size=Vector2(0,44)
        tab_buttons.add_child(b)

    reader_card = PanelContainer.new()
    reader_card.size_flags_vertical=SIZE_EXPAND_FILL
    reader_card.add_theme_stylebox_override("panel",_box(PANEL,GOLD,8))
    root.add_child(reader_card)
    var inside := VBoxContainer.new()
    inside.add_theme_constant_override("separation",10)
    reader_card.add_child(inside)
    paper_heading_strip = PanelContainer.new()
    paper_heading_strip.add_theme_stylebox_override("panel",_box(JADE_BAND, Color.TRANSPARENT,4))
    inside.add_child(paper_heading_strip)
    page_title=_label("眼前",21,JADE_INK)
    paper_heading_strip.add_child(page_title)
    route_canvas=XianfanRouteCanvas.new()
    route_canvas.visible=false
    route_canvas.location_tapped.connect(_on_map_pin)
    inside.add_child(route_canvas)
    scene_text=RichTextLabel.new()
    scene_text.bbcode_enabled=false
    scene_text.scroll_active=true
    scene_text.fit_content=false
    scene_text.scroll_following=false
    scene_text.size_flags_vertical=SIZE_EXPAND_FILL
    scene_text.add_theme_font_size_override("normal_font_size",22)
    scene_text.add_theme_color_override("default_color",PAPER)
    scene_text.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)
    inside.add_child(scene_text)
    actor_buttons=VBoxContainer.new()
    actor_buttons.add_theme_constant_override("separation",6)
    inside.add_child(actor_buttons)

    reader_footer=_label("身在此处 · 看场景 → 选行动 → 世界结算；也可直接输入",14,FADED)
    reader_footer.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    root.add_child(reader_footer)
    notice=_label("",16,GOLD)
    root.add_child(notice)
    model_progress_label=_label("",15,GOLD)
    model_progress_label.visible=false
    root.add_child(model_progress_label)
    model_progress_bar=ProgressBar.new()
    model_progress_bar.min_value=0
    model_progress_bar.max_value=100
    model_progress_bar.value=0
    model_progress_bar.show_percentage=true
    model_progress_bar.custom_minimum_size=Vector2(0,15)
    model_progress_bar.visible=false
    root.add_child(model_progress_bar)
    resume_model_button=_button("继续/重试模型下载（保留已下载数据）",func(): _retry_model_download(),15)
    resume_model_button.visible=false
    root.add_child(resume_model_button)
    cancel_ai_button=_button("停止本轮 AI 生成",func(): _cancel_model_generation(),16)
    cancel_ai_button.visible=false
    root.add_child(cancel_ai_button)

    quick_buttons=HBoxContainer.new()
    quick_buttons.add_theme_constant_override("separation",7)
    root.add_child(quick_buttons)
    action_toggle=_button("本页可做 · 展开建议  ▾",func(): _toggle_actions(),16)
    action_toggle.custom_minimum_size=Vector2(0,41)
    root.add_child(action_toggle)
    action_scroll=ScrollContainer.new()
    action_scroll.custom_minimum_size=Vector2(0,175)
    action_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
    action_scroll.visible=false
    root.add_child(action_scroll)
    action_list=GridContainer.new()
    action_list.columns=2
    action_list.size_flags_horizontal=SIZE_EXPAND_FILL
    action_list.add_theme_constant_override("h_separation",7)
    action_list.add_theme_constant_override("v_separation",7)
    action_scroll.add_child(action_list)

    feedback_copy=_button("复制诊断与功能反馈日志",func(): _copy_feedback())
    root.add_child(feedback_copy)
    settings_button=_button("配置 AI 服务与本地模型",func(): _open_ai_settings())
    root.add_child(settings_button)

    input_row=HBoxContainer.new()
    input_row.add_theme_constant_override("separation",8)
    root.add_child(input_row)
    command=LineEdit.new()
    command.placeholder_text="写下想做的事，或对眼前的人说话……"
    command.size_flags_horizontal=SIZE_EXPAND_FILL
    command.custom_minimum_size=Vector2(0,60)
    command.add_theme_font_size_override("font_size",20)
    command.add_theme_color_override("font_color",PAPER)
    command.add_theme_stylebox_override("normal",_box(PANEL,Color("#B5AFA3"),6))
    command.add_theme_stylebox_override("focus",_box(Color("#FEFCF7"),GOLD,6))
    command.add_theme_color_override("caret_color",GOLD)
    command.add_theme_color_override("font_placeholder_color",FADED)
    command.text_submitted.connect(func(t: String): _submit(t,true))
    input_row.add_child(command)
    var send := _button("发送",func(): _submit(command.text,true),19)
    send.custom_minimum_size=Vector2(105,60)
    input_row.add_child(send)

    # Full-screen touch-modal (Godot Control, not an OS-specific Window).
    overlay=Control.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter=Control.MOUSE_FILTER_STOP
    overlay.visible=false
    add_child(overlay)
    var shade:=ColorRect.new()
    shade.color=Color(0.09,0.11,0.10,0.66)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter=Control.MOUSE_FILTER_STOP
    overlay.add_child(shade)
    var popup_margin:=MarginContainer.new()
    popup_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["left","right"]:
        popup_margin.add_theme_constant_override("margin_"+side,25)
    for side in ["top","bottom"]:
        popup_margin.add_theme_constant_override("margin_"+side,110)
    overlay.add_child(popup_margin)
    modal_card=PanelContainer.new()
    modal_card.add_theme_stylebox_override("panel",_box(PANEL,ROSE_EDGE,10))
    popup_margin.add_child(modal_card)
    var pop_column:=VBoxContainer.new()
    pop_column.add_theme_constant_override("separation",9)
    modal_card.add_child(pop_column)
    modal_heading_strip=PanelContainer.new()
    modal_heading_strip.add_theme_stylebox_override("panel",_box(ROSE_BAND,Color.TRANSPARENT,4))
    pop_column.add_child(modal_heading_strip)
    modal_title=_label("人物",25,ROSE_INK)
    modal_heading_strip.add_child(modal_title)
    modal_info=RichTextLabel.new()
    modal_info.bbcode_enabled=false
    modal_info.fit_content=false
    modal_info.size_flags_vertical=SIZE_EXPAND_FILL
    modal_info.add_theme_font_size_override("normal_font_size",21)
    modal_info.add_theme_color_override("default_color",PAPER)
    pop_column.add_child(modal_info)
    modal_form=VBoxContainer.new()
    pop_column.add_child(modal_form)
    modal_actions=VBoxContainer.new()
    modal_actions.add_theme_constant_override("separation",5)
    pop_column.add_child(modal_actions)
    pop_column.add_child(_button("关闭弹窗",func(): _close_modal(),19))

func _close_modal() -> void:
    overlay.visible=false

func _open_modal(title: String, body: String) -> void:
    overlay.visible=true
    modal_title.text=title
    modal_info.text=body
    var person_popup := title.begins_with("人物")
    var band := ROSE_BAND if person_popup else JADE_BAND
    var ink := ROSE_INK if person_popup else JADE_INK
    var edge := ROSE_EDGE if person_popup else GOLD
    modal_card.add_theme_stylebox_override("panel",_box(PANEL,edge,10))
    modal_heading_strip.add_theme_stylebox_override("panel",_box(band,Color.TRANSPARENT,4))
    modal_title.add_theme_color_override("font_color",ink)
    _wipe(modal_actions)
    _wipe(modal_form)

func _show_page(name: String) -> void:
    _close_modal()
    _change_tab(name)

func _on_map_pin(place: String) -> void:
    if place==str(game.data["place"]):
        notice.text="你已经在这里。"
        return
    for road in XianfanTravelPost.available_routes(str(game.data["place"])):
        if str(road["to"])==place:
            _go_from_map(str(road["cmd"]),place)
            return
    notice.text="地点已标出，但当前没有可直接抵达的道路。请逐段前往，无法瞬间移动。"

func _show_map() -> void:
    # A route schematic of locations the rule engine can actually reach.
    # Do not pass an unimplemented waypoint to the time/position engine.
    var now:=str(game.data["place"])
    page_title.text="地图 · 已知道路"
    route_canvas.visible=true
    route_canvas.set_position_place(now)
    scene_text.text="● 当前所在：%s。点击地图地点或下方道路可尝试前往；远方无直达路不能瞬移。此图根据原仓库地点/道路数据绘制，是可操作路线示意。" % now
    actor_buttons.visible=true
    _wipe(actor_buttons)
    var routes: Array[Dictionary]=XianfanTravelPost.available_routes(now)
    actor_buttons.add_child(_label("可从此处直接前往",16,GOLD))
    if routes.is_empty():
        actor_buttons.add_child(_label("当前没有已核实的直达路线，可先打听路线或返回已知地点。",15,FADED))
    for route in routes:
        var dest:=str(route["to"])
        var cmd:=str(route["cmd"])
        actor_buttons.add_child(_button("%s · 约%d分钟" % [dest,int(route["minutes"])],
            func(): _go_from_map(cmd,dest),16))
    actor_buttons.add_child(_button("查看全部已知地点与往来路程",func(): _open_route_ledger(),16))

func _open_route_ledger() -> void:
    var lines: Array[String]=[]
    for place in XianfanTravelPost.PLACES:
        var entry: Dictionary=place
        var name:=str(entry["name"])
        var edges:=XianfanTravelPost.available_routes(name)
        var destinations: Array[String]=[]
        for road in edges: destinations.append("%s（%d分）" % [str(road["to"]),int(road["minutes"])])
        lines.append("%s → %s" % [name,"、".join(destinations) if not destinations.is_empty() else "尚无返程规则"])
    _open_modal("已知地点与道路", "\n\n".join(lines))

func _go_from_map(command_text: String, destination: String) -> void:
    var allowed:=false
    for road in XianfanTravelPost.available_routes(str(game.data["place"])):
        if str(road["cmd"])==command_text and str(road["to"])==destination: allowed=true
    if not allowed:
        notice.text="地图路线已变化，没有执行移动。"
        return
    _submit(command_text,false)
    if str(game.data["place"])==destination:
        _change_tab("地图")

func _do_market_action(command_text: String) -> void:
    var before:=str(game.data["place"])
    var outcome:=game.act(command_text)
    notice.text=outcome.substr(0,240)
    _change_tab("市集")
    if not outcome.begins_with("暂不支持") and before==str(game.data["place"]):
        # Marketplace is a persistent workspace; a purchase should not throw
        # the player back to a long story or global debug census page.
        scene_text.text=game.local_market_summary()+"\n\n【刚刚成交】\n"+outcome.substr(0,360)

func _open_contact_list() -> void:
    var contacts: Array[Dictionary]=game.known_contacts()
    var lines: Array[String]=["只列认识的人，不把县城全部居民当作你的熟人。远方交谈需要实际会面，或付费寄信。"]
    _open_modal("熟人通讯录", "\n".join(lines))
    if contacts.is_empty():
        modal_actions.add_child(_label("尚无熟人；与人实际相识后才会出现在这里。",15,FADED))
    for entry in contacts:
        var who:=str(entry["name"])
        var loc:=str(entry.get("place","未知"))
        modal_actions.add_child(_button("%s · %s · %s" % [who,loc,
            "就在眼前" if bool(entry["here"]) else "异地"],
            func(): _open_npc(who),16))

func _open_letter_writer(person: String) -> void:
    var quote: Dictionary=game.postage_quote(person)
    if not bool(quote.get("ok",false)):
        _open_modal("无法寄信",str(quote.get("reason","收信地址不明确")))
        return
    _open_modal("给%s写信"%person,
        "收信地：%s\n邮资：%d文｜预计%s送达\n%s\n\n只有点击『确认寄出』才会扣钱；对方不能立刻回答。" % [
            str(game.data["npc"][person].get("place","")),int(quote["fee"]),
            XianfanTravelPost.format_eta(int(quote["minutes"])),str(quote["route"])])
    letter_body_field=TextEdit.new()
    letter_body_field.custom_minimum_size=Vector2(0,125)
    letter_body_field.placeholder_text="写下你想告诉对方的事……（最多600字）"
    letter_body_field.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
    modal_form.add_child(letter_body_field)
    modal_actions.add_child(_button("确认寄出 · %d文" % int(quote["fee"]),func():
        var message_text:=letter_body_field.text
        var result: Dictionary=game.send_letter(person,message_text)
        if bool(result.get("ok",false)):
            _show_page("书信")
            notice.text=str(game.last_result)
        else:
            modal_info.text=str(result.get("error","寄信失败，未扣资"))
    ,17))

func _open_distant_roster() -> void:
    _open_society_roster()

func _open_society_roster(sector: String="",page: int=0) -> void:
    last_roster_sector=sector
    last_roster_page=page
    var roster: Dictionary=game.society_roster(sector,page)
    last_roster_page=int(roster["page"])
    var lines: Array[String]=[
        "这里的人物有永久身份编号，职业、阶层与组织互相独立。日常按天模拟，并非把几万人每帧交给8B计算。",
        "已登记：%d 人 · 第%d/%d页" % [
            int(roster["size"]),int(roster["page"])+1,int(roster["pages"])]
    ]
    var select:=OptionButton.new()
    select.custom_minimum_size=Vector2(0,52)
    select.add_theme_stylebox_override("normal",_box(PANEL,DIVIDER,5))
    select.add_theme_color_override("font_color",PAPER)
    select.add_item("全部行业")
    var selected:=0
    var idx:=1
    for group in game.society_sectors():
        select.add_item(group)
        if group==sector: selected=idx
        idx+=1
    select.select(selected)
    select.item_selected.connect(func(item: int):
        var chosen: String="" if item==0 else select.get_item_text(item)
        _open_society_roster(chosen,0)
    )
    _open_modal("百业人物名册", "\n\n".join(lines))
    modal_form.add_child(select)
    for entry in roster["entries"]:
        var npc: Dictionary=entry
        var who:=str(npc["name"])
        modal_actions.add_child(_button("%s · %s · %s%s" % [
            who,str(npc["job"]),str(npc["standing"]),
            "" if bool(npc["alive"]) else "（已故）"],
            func(): _open_npc(who),15))
    modal_actions.add_child(_button("上一页",func(): _open_society_roster(sector,last_roster_page-1),16))
    modal_actions.add_child(_button("下一页",func(): _open_society_roster(sector,last_roster_page+1),16))

func _open_economy_region(zone: String) -> void:
    var name: String="石桥村" if zone=="村" else "临安县城"
    var description:=game.economy_report(zone)
    var observations:=game.economy_trend(zone)
    var trend_text: Array[String]=[]
    for period in observations:
        trend_text.append("第%d个月：实际新增产值%d文；名义%d文；成交额%d文" % [
            int(period.get("month",0)),int(period.get("real",0)),
            int(period.get("nominal",0)),int(period.get("trade",0))])
    if not trend_text.is_empty():
        description+="\n\n【最近12个月的经济变化】\n"+"\n".join(trend_text)
    _open_modal("地区经济报表 · "+name,description)
    modal_actions.add_child(_button("切换到另一地区",func():
        _open_economy_region("城" if zone=="村" else "村")
    ,16))

func _open_npc(name: String) -> void:
    current_npc=name
    var chosen: Dictionary={}
    for n in game.npcs_status():
        if str(n["name"])==name: chosen=n
    if chosen.is_empty(): return
    var items:=str(chosen.get("items",{}))
    var details: Array[String]=[
        "【身份】%s · %d岁 · %s" % [name,int(chosen["age"]),str(chosen["relationship"])],
        "【编号】"+str(chosen["id"]),
        "【职业】"+str(chosen.get("job","家务")),
        "【行业】"+str(chosen.get("sector","家户")),
        "【社会身份】"+str(chosen.get("standing","平民")),
        "【所属组织】"+str(chosen.get("faction","无")),
        "【灵根】"+str(chosen.get("root","待鉴定"))+"（未鉴定不等于有资格修炼）",
        "【生存状态】"+("在世" if bool(chosen.get("alive",true)) else "已故 · 逝于第%d日" % int(chosen.get("death_day",0))),
        "【真实技能】"+str(chosen.get("skills",{})),
        "【师承】"+str(chosen.get("mentor","暂无")),
        "【学习进度】%d/24次实际工时" % int(chosen.get("training",0)),
        "【人生重要事件】%d条" % chosen.get("biography",[]).size(),
        "【个人钱财】%d文" % int(chosen.get("money",0)),
        "【同户关系】"+str(chosen.get("household","尚未登记")),
        "【身上口粮】%s份 · 【饥饿】%s" % [str(game.data.get("npc",{}).get(name,{}).get("rations","未登记")),str(chosen.get("hunger",0))],
        "【交往】"+str(chosen.get("social",{})),
        "【押送货物】"+str(chosen.get("cargo",{})),
        "【地点】"+str(chosen["place"]),
        "【正在做】"+str(chosen["activity"]),
        "【情绪】"+str(chosen["mood"]),
        "【个人心愿】"+str(chosen.get("wish","尚未透露")),
        "【心愿行动进度】%d/100（不等于修为）" % int(chosen.get("goal_progress",0)),
        "【在场】"+("可以当面交流" if chosen["here"] else "不在身边，不能远程互动"),
        "【持有物品】"+items]
    if int(chosen["rapport"])>=0: details.append("【关系】亲近程度 %d/100" % int(chosen["rapport"]))
    if int(chosen["learning"])>=0: details.append("【学识】%d/100（不等于灵根或境界）" % int(chosen["learning"]))
    var short_info: Array[String]=[
        "【身份】%s · %d岁 · %s" % [name,int(chosen["age"]),str(chosen.get("standing","平民"))],
        "【生活】%s · %s" % [str(chosen.get("job","居民")),str(chosen.get("activity","忙自己的事"))],
        "【现在】%s" % str(chosen["place"]),
        "【情绪】%s" % str(chosen.get("mood","平静")),
        "【个人愿望】%s" % str(chosen.get("wish","未透露")),
        "【联系】%s" % ("可以当面说话" if bool(chosen["here"]) else "相隔两地，不能当面交谈")]
    _open_modal("人物 · "+name,"\n\n".join(short_info))
    modal_actions.add_child(_button("展开完整人物档案",func():
        modal_info.text="\n\n".join(details)
    ,16))
    if bool(chosen.get("alive",true)) and bool(chosen.get("here",false)):
        modal_actions.add_child(_button("当面交谈",func():
            _close_modal()
            _change_tab("对话")
        ))
    elif bool(chosen.get("alive",true)):
        modal_actions.add_child(_label("此人现在不在你面前，不能当面交谈。",16,FADED))
        var is_known:=false
        for contact in game.known_contacts():
            if str(contact["name"])==name: is_known=true
        if is_known:
            modal_actions.add_child(_button("写信联系 · 查邮资",func(): _open_letter_writer(name),17))
        else:
            modal_actions.add_child(_label("尚不相识：可先前往其所在地认识他。",15,FADED))
    modal_actions.add_child(_button("查看长期记忆 · 生活习惯",func(): _open_npc_memory(name),16))
    if str(chosen.get("id","")).begins_with("CIV"):
        modal_actions.add_child(_button("返回百业人物名册",func(): _open_society_roster(last_roster_sector,last_roster_page),16))
    if chosen.get("biography",[]).size()>0:
        modal_actions.add_child(_button("查看真实人生履历",func():
            var lines: Array[String]=[]
            for event in chosen.get("biography",[]).slice(-12):
                lines.append("第%d日｜%s：%s" % [int(event.get("day",0)),
                    str(event.get("category","经历")),str(event.get("detail",""))])
            _open_modal("人物履历 · "+name,"\n\n".join(lines))
        ,16))
    if chosen["here"] and bool(chosen.get("alive",true)):
        var address: String="妹妹" if name=="孙成明" else ("父亲" if name=="钱然泽" else ("母亲" if name=="郑舟清" else name))
        modal_actions.add_child(_button("问问最近在忙什么",func(): _npc_action("问"+address+"最近忙什么")))
        modal_actions.add_child(_button("聊聊青云山门",func(): _npc_action("问"+address+"青云的事")))
        for item in game.data["items"].keys():
            if not str(item) in ["小河鱼","青菜","枯枝","车前草"]: continue
            if int(game.data["items"][item])<=0: continue
            var label := "赠送一份"+str(item)
            var cmd := "把"+str(item)+"给"+name
            modal_actions.add_child(_button(label,func(): _npc_action(cmd),17))

func _open_npc_memory(person: String) -> void:
    _open_modal("人物记忆 · "+person,game.memory_storage_info(person))
    modal_actions.add_child(_button("查看最近关键旧事",func():
        var memory: Dictionary=game.memory_digest(person)
        var pinned: Array=memory.get("important",[])
        var texts: Array[String]=[]
        for line in pinned.slice(-8):
            if not (line is Dictionary): continue
            texts.append("第%d日：%s\n%s" % [int(line.get("day",0)),str(line.get("player","")),str(line.get("reply",""))])
        modal_info.text="【原始记忆永久存于本机】\n\n"+("\n\n".join(texts) if not texts.is_empty() else "还没有被标记为重要的原始对话。")
    ))

func _npc_action(text: String) -> void:
    _close_modal()
    _submit(text,false)

func _open_ai_settings() -> void:
    var expl:="AI模式可选：内置模型通过安卓原生推理库离线运行。GGUF权重需要单独下载，下载百分比、速度和缓存状态会显示在页面上；网络中断可按HTTP Range从已保存文件继续。\n\n本机服务模式则连接你已经启动的兼容服务；API模式才向你指定的服务商发送内容。密钥不写进人物存档。"
    _open_modal("AI 设置",expl)
    setting_provider=OptionButton.new()
    setting_provider.add_theme_color_override("font_color",PAPER)
    setting_provider.add_theme_color_override("font_hover_color",PAPER)
    setting_provider.add_theme_stylebox_override("normal",_box(PANEL,DIVIDER,6))
    for name in ["关闭","API","本机服务","内置模型"]: setting_provider.add_item(name)
    for i in range(setting_provider.item_count):
        if setting_provider.get_item_text(i)==("内置模型" if local_enabled else ai.provider): setting_provider.select(i)
    modal_form.add_child(setting_provider)
    setting_url=_entry_field("请求地址（https://.../v1/chat/completions）",ai.endpoint,false)
    setting_model=_entry_field("模型名（服务端实际提供的model）",ai.model,false)
    setting_key=_entry_field("API密钥（只在本次运行内存中保存）","",true)
    remote_model_fields.clear()
    local_model_fields.clear()
    for control in [setting_url,setting_model,setting_key]:
        modal_form.add_child(control)
        remote_model_fields.append(control)
    local_model_selector=OptionButton.new()
    local_model_selector.add_theme_color_override("font_color",PAPER)
    local_model_selector.add_theme_stylebox_override("normal",_box(PANEL,DIVIDER,6))
    for item in XianfanLocalLLM.MODELS:
        var model_item: Dictionary=item
        local_model_selector.add_item("%s · %.2f GB" % [str(model_item["title"]),float(model_item["size_gb"])])
    var current_index:=XianfanLocalLLM.preset_index(str(local_llm.get("model_source")))
    local_model_selector.select(current_index if current_index>=0 else 2)
    local_model_selector.custom_minimum_size=Vector2(0,54)
    local_model_selector.item_selected.connect(_choose_local_preset)
    modal_form.add_child(local_model_selector)
    local_model_fields.append(local_model_selector)
    local_model_hint=_label(XianfanLocalLLM.model_hint(current_index if current_index>=0 else 2),15,FADED)
    modal_form.add_child(local_model_hint)
    local_model_fields.append(local_model_hint)
    local_model_url=_entry_field("GGUF地址；可改成自定义HTTPS下载源",str(local_llm.get("model_source")),false)
    modal_form.add_child(local_model_url)
    local_model_fields.append(local_model_url)
    var mirror_switch:=_button("官方站连不上？改用第三方镜像（点按切换）",
        func(): _switch_model_mirror(),15)
    modal_form.add_child(mirror_switch)
    local_model_fields.append(mirror_switch)
    var ctx_title:=_label("模型上下文（长期经历在磁盘中，较大窗口增加RAM占用）",15,FADED)
    modal_form.add_child(ctx_title)
    local_model_fields.append(ctx_title)
    context_selector=OptionButton.new()
    context_selector.add_theme_stylebox_override("normal",_box(PANEL,DIVIDER,6))
    context_selector.add_theme_color_override("font_color",PAPER)
    var index:=0
    for tokens in XianfanLocalLLM.CONTEXT_CHOICES:
        context_selector.add_item("%d tokens"%int(tokens))
        if int(tokens)==int(local_llm.get("context_tokens")): context_selector.select(index)
        index+=1
    context_selector.custom_minimum_size=Vector2(0,50)
    context_selector.item_selected.connect(func(i: int):
        context_hint_label.text=XianfanLocalLLM.context_hint(int(XianfanLocalLLM.CONTEXT_CHOICES[i]),str(local_llm.get("active_name")))
    )
    modal_form.add_child(context_selector)
    local_model_fields.append(context_selector)
    context_hint_label=_label(XianfanLocalLLM.context_hint(int(local_llm.get("context_tokens")),str(local_llm.get("active_name"))),15,FADED)
    modal_form.add_child(context_hint_label)
    local_model_fields.append(context_hint_label)
    local_model_fields.append(_label("剧情演化强度（会增加本地模型生成次数，8B较慢）",15,FADED))
    modal_form.add_child(local_model_fields.back())
    director_selector=OptionButton.new()
    for mode in ["关闭","关键事件","每次行动"]:
        director_selector.add_item(mode)
    for i in range(director_selector.item_count):
        if director_selector.get_item_text(i)==director_mode: director_selector.select(i)
    director_selector.custom_minimum_size=Vector2(0,52)
    director_selector.add_theme_color_override("font_color",PAPER)
    director_selector.add_theme_stylebox_override("normal",_box(PANEL,DIVIDER,6))
    local_model_fields.append(director_selector)
    modal_form.add_child(director_selector)
    modal_actions.add_child(_button("DeepSeek API 示例",func(): _preset_api("https://api.deepseek.com/chat/completions","deepseek-flash")))
    modal_actions.add_child(_button("OpenAI API 示例",func(): _preset_api("https://api.openai.com/v1/chat/completions","gpt-5-mini")))
    modal_actions.add_child(_button("下载/加载选中的本地模型",func(): _enable_local_and_load()))
    modal_actions.add_child(_button("卸载已运行的模型（切换时使用）",func(): _unload_active_model(),16))
    modal_actions.add_child(_button("保存设置（不自动下载）",func(): _save_ai_settings()))
    modal_actions.add_child(_button("查看当前上下文占用",func(): _inspect_context_usage(),15))
    setting_provider.item_selected.connect(func(_index: int): _sync_provider_fields())
    _sync_provider_fields()

func _switch_model_mirror() -> void:
    if local_model_url==null: return
    var current:=local_model_url.text.strip_edges()
    if current.begins_with("https://hf-mirror.com/"):
        local_model_url.text=current.replace("https://hf-mirror.com/","https://huggingface.co/")
        notice.text="已切回Hugging Face官方站。"
        return
    var resolved:=XianfanResumableModelDownload.source_url(current)
    if resolved.is_empty() or not resolved.begins_with("https://huggingface.co/"):
        notice.text="仅支持为Hugging Face模型切换镜像；自定义地址请手动编辑。"
        return
    local_model_url.text=resolved.replace("https://huggingface.co/","https://hf-mirror.com/")
    notice.text="已选第三方HF-Mirror。下载前仍会校验官方8B/14B模型SHA256；该镜像不是Hugging Face官方站。"

func _choose_local_preset(index: int) -> void:
    var info:=XianfanLocalLLM.preset(index)
    if info.is_empty(): return
    local_model_url.text=str(info["path"])
    local_model_hint.text=XianfanLocalLLM.model_hint(index)

func _sync_provider_fields() -> void:
    var is_local:=setting_provider.get_item_text(setting_provider.selected)=="内置模型"
    for control in local_model_fields: control.visible=is_local
    for control in remote_model_fields: control.visible=not is_local
    var actions:=modal_actions.get_children()
    for idx in range(actions.size()):
        var button: Control=actions[idx]
        # Two API preset actions, two local model actions, one save button.
        button.visible = (not is_local) if idx<2 else (is_local if idx in [2,3,5] else true)
    if is_local:
        modal_info.text="在游戏中选择 1.7B / 4B / 8B / 14B 等本地模型，首次由手机自行下载GGUF，下载后缓存并离线生成。大型模型可能耗尽内存甚至被安卓终止。"
    else:
        modal_info.text="API模式通过你配置的服务联网。密钥仅本次运行内存保存；无需下载安装本地模型。"

func _save_context_setting() -> String:
    if context_selector==null: return ""
    var n:=int(XianfanLocalLLM.CONTEXT_CHOICES[context_selector.selected])
    return str(local_llm.choose_context(n))

func _inspect_context_usage() -> void:
    var info: String=await local_llm.context_usage()
    notice.text=info
    if overlay.visible and modal_title.text=="AI 设置": modal_info.text=info

func _save_director_mode() -> void:
    if director_selector==null: return
    director_mode=director_selector.get_item_text(director_selector.selected)
    var f:=FileAccess.open(DIRECTOR_PREF,FileAccess.WRITE)
    if f!=null: f.store_string(JSON.stringify({"mode":director_mode}))

func _detect_npc_speech(line: String) -> String:
    var spoken:=line.begins_with("问") or line.begins_with("跟") or line.begins_with("和") or line.begins_with("对") or line.begins_with("与")
    spoken = spoken or line.contains("聊天") or line.contains("说话")
    if not spoken: return ""
    if line.contains("孙成明") or line.contains("妹妹") or line.contains("成明"): return "孙成明"
    if line.contains("钱然泽") or line.contains("父亲") or line.contains("爹"): return "钱然泽"
    if line.contains("郑舟清") or line.contains("母亲") or line.contains("娘"): return "郑舟清"
    for npc in game.npcs_status():
        var person_name:=str(npc["name"])
        if line.contains(person_name): return person_name
    return ""

func _narration_needed(before_clock: int, before_place: String, outcome: String, speech: bool=false) -> bool:
    if not local_enabled or director_mode=="关闭" or not bool(local_llm.get("model_ready")):
        return false
    if outcome.begins_with("暂不支持") or outcome.is_empty(): return false
    if game.last_channel=="反馈": return false
    var elapsed:=game._clock()-before_clock
    if elapsed<=0 and before_place==str(game.data["place"]): return false
    if director_mode=="每次行动": return true
    # Spend expensive 8B inference only when an event actually matters.
    if before_place!=str(game.data["place"]): return true
    if elapsed>=60: return true
    if speech and game.data.get("dialogue_log",[]).size()%3==0: return true
    return game._clock()-last_director_clock >= 80

func _request_story(player_action: String, outcome: String, before_clock: int, before_place: String, speech: bool=false) -> void:
    if not _narration_needed(before_clock,before_place,outcome,speech): return
    if bool(local_llm.get("busy")): return
    last_director_clock=game._clock()
    last_director_place=str(game.data["place"])
    latest_action=player_action
    latest_outcome=outcome
    notice.text="本地AI正在根据真实行动推演剧情与人物伏笔；规则存档不会交给模型直接修改。"
    local_llm.tell_story(player_action,outcome,game.story_context(),game._clock())

func _unload_active_model() -> void:
    notice.text=str(local_llm.unload_model())
    if local_model_hint!=null:
        local_model_hint.text=str(local_llm.status())

func _preset_api(url: String, model_id: String) -> void:
    setting_provider.select(1)
    setting_url.text=url
    setting_model.text=model_id
    _sync_provider_fields()
    notice.text="已填写示例服务地址与模型名。仍需你自己的有效 API Key；此按钮没有实际调用接口。"

func _entry_field(placeholder: String, value: String, hidden: bool) -> LineEdit:
    var e:=LineEdit.new()
    e.placeholder_text=placeholder
    e.text=value
    e.secret=hidden
    e.add_theme_font_size_override("font_size",17)
    e.add_theme_color_override("font_color",PAPER)
    e.add_theme_color_override("font_placeholder_color",FADED)
    e.add_theme_stylebox_override("normal",_box(PANEL,DIVIDER,6))
    e.add_theme_stylebox_override("focus",_box(Color("#FEFCF7"),GOLD,6))
    e.custom_minimum_size=Vector2(0,54)
    return e

# Restore the last explicitly selected model without downloading anything at boot.
# Pending partial downloads are not resumed silently on a cold start: a network
# transfer must remain a clear user action; an existing verified cache can load.
func _restore_local_ai_on_startup() -> void:
    if not local_enabled or local_llm==null: return
    if bool(local_llm.get("model_ready")) or bool(local_llm.get("loading")): return
    var source:=str(local_llm.get("model_source"))
    var cached_path:=source
    if not source.begins_with("user://"):
        var downloader: XianfanResumableModelDownload=local_llm.get("download_manager")
        cached_path=downloader.final_path(source)
    if FileAccess.file_exists(cached_path):
        notice.text="检测到上次使用的本地模型，正在自动加载（不会联网重新下载）。"
        local_llm.load_model()
    else:
        notice.text="已恢复本地AI选项；模型文件尚未就绪，请在设置中确认下载或继续断点。"

func _resume_previous_model_download() -> void:
    if not local_enabled or local_llm==null: return
    # Android can resume before the download coroutine has processed the
    # previous socket-close. Give it a bounded chance to save its .part state.
    for attempt in range(6):
        if not bool(local_llm.get("loading")): break
        await get_tree().create_timer(0.35).timeout
    if not bool(local_llm.get("loading")):
        local_llm.resume_pending()
    _refresh_download_widgets()

func _retry_model_download() -> void:
    if bool(local_llm.get("loading")):
        notice.text="下载任务仍在进行，网络异常时会自动重试。"
        return
    local_llm.load_model()
    _refresh_download_widgets()

func _on_model_download_progress(info: Dictionary) -> void:
    model_download_seen=true
    _refresh_download_widgets()
    var total:=int(info.get("total",-1))
    var downloaded:=int(info.get("bytes",0))
    var speed:=float(info.get("speed_bps",0.0))
    var progress_percent:=100.0*float(downloaded)/float(total) if total>0 else 0.0
    model_progress_bar.value=clampf(progress_percent,0.0,100.0)
    model_progress_bar.show_percentage=total>0
    var size_text: String=("%.2f GB" % (float(total)/1000000000.0)) if total>0 else "总大小待服务器确认"
    var phase:=str(info.get("phase","下载中"))
    model_progress_label.text="%s · %s · %.2f GB / %s · %.2f MB/s · 第%d次连接" % [
        str(local_llm.get("active_name")),phase,float(downloaded)/1000000000.0,
        size_text,speed/1000000.0,int(info.get("attempt",0))]
    var error_text:=str(info.get("error",""))
    if not error_text.is_empty() and error_text!="paused":
        model_progress_label.text+="\n网络诊断："+error_text

func _refresh_download_widgets() -> void:
    if model_progress_label==null: return
    var worker: Node=local_llm.get("download_manager")
    var pending:=false
    if worker!=null and local_enabled:
        pending=worker.is_pending(str(local_llm.get("model_source")))
    var downloading:=bool(local_llm.get("loading")) and not bool(local_llm.get("loading_weights"))
    # Completed downloads do not occupy story space forever.
    model_progress_label.visible=(downloading or pending) and view=="设置"
    model_progress_bar.visible=(downloading or pending) and view=="设置"
    resume_model_button.visible=pending and not bool(local_llm.get("loading"))

func _local_status(message: String) -> void:
    notice.text=message
    if ["失败","无法","已停止","错误","校验","异常","不完整","损坏","中断","HTTP","网络诊断"].any(
        func(marker: String): return message.contains(marker)):
        game.note_api_failure("本机GGUF "+str(local_llm.get("active_name")),message)
    if view=="设置": _refresh()
    _refresh_download_widgets()

func _enable_local_and_load(confirmed: bool=false) -> void:
    var target_path:=pending_model_path if confirmed else (local_model_url.text if local_model_url!=null else str(local_llm.get("model_source")))
    if not confirmed:
        var ctx_status:=_save_context_setting()
        if ctx_status.contains("请先卸载"):
            notice.text=ctx_status
            return
    var tier:=XianfanLocalLLM.preset_index(target_path)
    if tier>=3 and not confirmed:
        pending_model_path=target_path
        _open_modal("确认下载大型模型",XianfanLocalLLM.model_hint(tier)+"\n\n这是大文件下载和高内存操作。耗电、发热、性能下降、系统杀进程均有可能。请确认设备存储和RAM足够，再自行选择是否继续。")
        modal_actions.add_child(_button("我了解风险 · 确认下载",func(): _enable_local_and_load(true)))
        return
    _close_modal()
    var status_result: String=str(local_llm.choose_model(target_path))
    if not status_result.begins_with("已选择"):
        notice.text=status_result
        return
    local_enabled=true
    ai.configure("关闭",ai.endpoint,ai.model,"")
    var f:=FileAccess.open("user://xianfan_local_choice.txt",FileAccess.WRITE)
    if f!=null: f.store_string("1")
    notice.text=status_result
    local_llm.load_model()
    _refresh()

func _save_ai_settings() -> void:
    _save_director_mode()
    var ctx_response:=_save_context_setting()
    var p:=setting_provider.get_item_text(setting_provider.selected)
    if p=="内置模型":
        local_enabled=true
        ai.configure("关闭",ai.endpoint,ai.model,"")
        var f:=FileAccess.open("user://xianfan_local_choice.txt",FileAccess.WRITE)
        if f!=null: f.store_string("1")
        var result:=str(local_llm.choose_model(local_model_url.text))
        setting_key.clear()
        _close_modal()
        notice.text="已保存配置。"+ctx_response+"；"+result+"；点击下载/加载才会开始下载。"
        _refresh()
        return
    local_enabled=false
    var choice_file:=FileAccess.open("user://xianfan_local_choice.txt",FileAccess.WRITE)
    if choice_file!=null: choice_file.store_string("0")
    var response:=ai.configure(p,setting_url.text,setting_model.text,setting_key.text)
    setting_key.clear()
    notice.text=response
    _close_modal()
    _refresh()

func _copy_feedback() -> void:
    DisplayServer.clipboard_set(game.feedback_report())
    notice.text="反馈内容已复制。可以粘贴到 ChatGPT，让我按错误日志修复。"

func _change_tab(name: String) -> void:
    view=name
    _refresh()

func _toggle_actions() -> void:
    drawer_open=not drawer_open
    action_scroll.visible=drawer_open and view=="剧情"
    action_toggle.text="收起建议  ▴" if drawer_open else "本页可做 · 展开建议  ▾"

func _submit(text: String, typed: bool) -> void:
    var raw:=text.strip_edges()
    if raw.is_empty(): return
    var npc_to_chat := current_npc if view=="对话" and typed else _detect_npc_speech(raw)
    if view=="对话" and typed:
        if current_npc.is_empty() or not game.at_same_place(current_npc):
            notice.text="没有可当面交谈的人。先在『人物』页选择眼前的人；远方熟人请写信。"
            return
        raw="跟"+current_npc+"说："+raw
    if not npc_to_chat.is_empty() and not game.at_same_place(npc_to_chat):
        notice.text="%s此刻不在此地。不会调用AI假装当面对话；可在人物档案中寄信。" % npc_to_chat
        return
    command.clear()
    command.release_focus()
    # Fast-path exact game actions and buttons; reserve heavy 8B inference for
    # natural language and narrative generation, not known button commands.
    var immediate:=not typed and npc_to_chat.is_empty()
    if typed and npc_to_chat.is_empty() and game.actions_for_place().has(raw):
        immediate=true
    if not immediate and local_enabled and bool(local_llm.get("model_ready")):
        request_text=raw
        if bool(local_llm.get("busy")):
            notice.text="本地AI仍在生成上一轮内容。请等它完成再继续，避免丢失对话。"
            return
        notice.text=("本机 "+str(local_llm.get("active_name"))+" 正在与"+npc_to_chat+"交谈……") if not npc_to_chat.is_empty() else "本地AI正在理解行动……"
        local_llm.talk(raw,npc_to_chat,game.ai_context(npc_to_chat,raw))
        return
    if not immediate and ai.configured():
        request_text=raw
        notice.text="正在通过你选定的API理解行动或人物对话。"
        if not ai.ask(raw,game.ai_context(npc_to_chat,raw),npc_to_chat):
            notice.text="API当前不可用，请查看配置或切换离线规则模式。"
        return
    # No-model fallback must remain playable and clearly identify its source.
    var before_clock:=game._clock()
    var before_place:=str(game.data["place"])
    var result:=game.act(raw)
    notice.text=("当前未加载本地模型：规则回复；打开设置下载安装GGUF后即可AI对话。" if local_enabled else "")
    if result.begins_with("暂不支持"): notice.text="未支持的行动已记录，可去反馈页复制。"
    if game.last_channel=="对话": view="对话"
    elif game.last_channel=="反馈": view="反馈"
    else: view="剧情"
    _refresh()
    _request_story(raw,result,before_clock,before_place,false)

func _cancel_model_generation() -> void:
    if bool(local_llm.get("busy")):
        local_llm.cancel_generation()
        notice.text="正在中止本轮AI生成，已经确认的世界状态不会回滚。"

func _on_local_stream(kind: String, contents: String) -> void:
    # Player sees the answer as it arrives rather than waiting for an 8B batch.
    cancel_ai_button.visible=true
    if kind=="dialogue" and view=="对话":
        scene_text.text=game.dialogue_with(current_npc,12)+"\n\n—— 本机AI正在回复（未保存） ——\n"+contents
        scene_text.call_deferred("scroll_to_line",9999)
    elif kind=="story":
        notice.text="本地AI正在推演下一段剧情（%d字）；结算仍以游戏规则为准。" % contents.length()
    else:
        notice.text="本地AI正在解析自由行动（%d字）……" % contents.length()

func _on_ai_completed(payload: Dictionary) -> void:
    cancel_ai_button.visible=false
    var kind:=str(payload.get("kind",""))
    if kind=="story":
        if not bool(payload.get("ok",false)):
            var why:=str(payload.get("error","AI叙事暂不可用"))
            game.note_api_failure("AI剧情导演",why)
            notice.text=why+"；原有世界事件与存档不受影响。"
            _refresh()
            return
        var accepted: Dictionary=game.record_ai_story(str(payload.get("scene","")),
            str(payload.get("beat_id","none")),int(payload.get("expected_clock",-1)),
            str(payload.get("origin","local-gguf")))
        if accepted.get("ok",false):
            notice.text="剧情演化已保存。"+("新人生支线已开启。" if not str(accepted.get("approved_beat","")).is_empty() else "世界数值未被旁白改动。")
        else:
            game.note_api_failure("AI剧情导演",str(accepted.get("error","规则校验未通过")))
            notice.text="本轮叙事未通过规则验证，已记录反馈。"
        _refresh()
        return
    if not bool(payload.get("ok",false)):
        var err:=str(payload.get("error","AI服务错误"))
        if bool(local_llm.get("generation_cancelled")):
            notice.text="已取消AI生成，世界存档未变更。"
            _refresh()
            return
        game.note_api_failure(request_text,err)
        notice.text=err+"；反馈页可复制错误。"
        view="反馈"
        _refresh()
        return
    if kind=="action":
        var c:=str(payload.get("command","")).strip_edges()
        if c.is_empty():
            game.note_api_failure(request_text,"AI未返回实际行动")
            notice.text="AI没有提供可结算的行动。"
            view="反馈"
        else:
            var before_clock:=game._clock()
            var before_place:=str(game.data["place"])
            var outcome:=game.act(c)
            if game.last_channel=="反馈" or outcome.begins_with("暂不支持"):
                notice.text="该行动尚未由世界引擎实现，已记录到反馈。"
                view="反馈"
            else:
                notice.text="本地AI已理解行动，世界规则完成结算。"
                view="剧情" if game.last_channel=="剧情" else game.last_channel
                _refresh()
                _request_story(request_text,outcome,before_clock,before_place)
                return
    elif kind=="dialogue":
        var person:=str(payload.get("npc",""))
        var reply:=str(payload.get("reply",""))
        var source:=str(payload.get("engine","api"))
        var history: Array=game.data.get("dialogue_log",[])
        var repeated:=false
        for i in range(history.size()-1,-1,-1):
            var old: Dictionary=history[i]
            if str(old.get("speaker",""))==person:
                repeated=str(old.get("reply","")).strip_edges()==reply.strip_edges() and str(old.get("player","")).strip_edges()!=request_text.strip_edges()
                break
        if repeated:
            game.note_api_failure(request_text,"NPC对不同问题重复上一条回复，没有写入存档。")
            notice.text="NPC重复了上一轮回复，已记录反馈。"
            view="反馈"
            _refresh()
            return
        var before_clock:=game._clock()
        var before_place:=str(game.data["place"])
        var response:=game.record_ai_dialogue(person,request_text,reply,source)
        if response==reply.strip_edges() and game.last_channel=="对话":
            current_npc=person
            view="对话"
            notice.text=("本机 "+str(local_llm.get("active_name"))+" · 已更新此人物的长期记忆" if source=="local-gguf" else "API已回复 · 已写入人物记忆")
            _refresh()
            _request_story(request_text,response,before_clock,before_place,true)
            return
        game.note_api_failure(request_text,response)
        view="反馈"
        notice.text=response
    else:
        var info:=str(payload.get("message","描述不够明确"))
        game.note_api_failure(request_text,"无法执行："+info)
        notice.text="未擅自执行："+info
        view="反馈"
    _refresh()

func _render_buttons(node: Node, labels: Array[String], enabled: bool = true) -> void:
    _wipe(node)
    if not enabled: return
    for action in labels:
        var item:=str(action)
        var b:=_button(item,func(): _submit(item,false),16)
        b.size_flags_horizontal=SIZE_EXPAND_FILL
        node.add_child(b)

func _refresh() -> void:
    cancel_ai_button.visible=bool(local_llm.get("busy"))
    world_clock_button.text="世界时间："+("暂停" if world_speed==0 else ("%d×" % world_speed))+" · 点按调速"
    stamina_bar.value=clampf(float(game.data.get("stamina",0)),0.0,100.0)
    hud.text="%s · %s\n精力 %d/100 · 铜钱 %d文 · %s" % [
        game.time_string(),str(game.data["place"]),int(game.data["stamina"]),
        int(game.data["money"]),str(game.data["realm"])]
    var palette := _paper_palette(view)
    reader_card.add_theme_stylebox_override("panel",_box(PANEL,palette["edge"],8))
    paper_heading_strip.add_theme_stylebox_override("panel",_box(palette["band"],Color.TRANSPARENT,4))
    page_title.add_theme_color_override("font_color",palette["ink"])
    for button in tab_buttons.get_children():
        var tab: Button=button
        var selected := tab.text==view
        var band: Color = _paper_palette(tab.text)["band"]
        var edge: Color = _paper_palette(tab.text)["edge"]
        tab.add_theme_stylebox_override("normal",_box(band if selected else PANEL,edge if selected else DIVIDER,5))
        tab.add_theme_color_override("font_color",PAPER)
        tab.add_theme_color_override("font_hover_color",PAPER)
    var suggestions: Array[String]=[]
    route_canvas.visible=view=="地图"
    actor_buttons.visible=false
    feedback_copy.visible=view=="反馈"
    settings_button.visible=view=="设置"
    input_row.visible=view in ["剧情","对话"]
    quick_buttons.visible=view=="剧情"
    action_toggle.visible=view=="剧情"
    action_scroll.visible=view=="剧情" and drawer_open
    match view:
        "剧情":
            page_title.text="眼前 · "+str(game.data["place"])
            # The story screen shows what happens here, not a world census.
            scene_text.text=game.look()
            # MUD-style contextual scene: visible local presence, not a global roster.
            var present_count:=game.nearby_people(999).size()
            scene_text.text+="\n\n〔眼前〕%d位人物在此 · 点击【对话】选择交谈对象" % present_count
            if not game.last_result.is_empty() and game.last_channel=="剧情":
                scene_text.text+="\n\n【刚刚发生】\n"+game.last_result.substr(0,700)
            var generated:=game.recent_story_ai(1)
            if not generated.is_empty():
                scene_text.text+="\n\n【人生故事】\n"+generated.substr(0,700)
            suggestions=game.actions_for_place().slice(0,3)
            _render_buttons(quick_buttons,suggestions)
            _render_buttons(action_list,game.actions_for_place())
        "对话":
            var selected_here:=not current_npc.is_empty() and game.at_same_place(current_npc)
            if not selected_here: current_npc=""
            page_title.text="对话 · "+(current_npc if selected_here else "选择眼前的人")
            scene_text.text=game.dialogue_with(current_npc,12) if selected_here else "你现在在%s。\n\n请选择下方真正处于同一地点的人物。\n\n远处的人不能隔空聊天，熟人可通过书信联系。" % str(game.data["place"])
            actor_buttons.visible=true
            _wipe(actor_buttons)
            var nearby:=game.nearby_people(7)
            actor_buttons.add_child(_label("眼前 · %d人" % game.nearby_people(999).size(),17,GOLD))
            for person in nearby:
                var who:=str(person["name"])
                actor_buttons.add_child(_button("%s · %s" % [who,str(person["activity"])],
                    func(): _open_npc(who),16))
            if nearby.is_empty():
                actor_buttons.add_child(_label("此地暂时没有其他可交谈的人。",16,FADED))
            actor_buttons.add_child(_button("联系远方熟人 → 书信",func(): _show_page("书信"),16))
        "地图":
            _show_map()
        "人物":
            page_title.text="人物 · 眼前与熟人"
            scene_text.text="你在%s。\n\n眼前的人可以互动；其他地方的人可在熟人通讯录中查找，不能隔空交谈。" % str(game.data["place"])
            actor_buttons.visible=true
            _wipe(actor_buttons)
            actor_buttons.add_child(_label("眼前 · %d人" % game.nearby_people(999).size(),17,GOLD))
            for person in game.nearby_people(6):
                var who:=str(person["name"])
                actor_buttons.add_child(_button("%s · %s · %s" % [who,str(person.get("job","居民")),
                    str(person.get("activity",""))],func(): _open_npc(who),16))
            actor_buttons.add_child(_button("认识的人 · 查看 / 写信",func(): _open_contact_list(),17))
            actor_buttons.add_child(_button("寻找其他地区居民 · 按行业筛选",func(): _open_distant_roster(),16))
        "市集":
            page_title.text="市集 · 真实买卖"
            scene_text.text=game.local_market_summary()
            actor_buttons.visible=true
            _wipe(actor_buttons)
            if str(game.data["place"]) in ["石桥村·街口","临安县城·东市"]:
                actor_buttons.add_child(_button("买一份粗粮",func(): _do_market_action("买粗粮"),17))
                actor_buttons.add_child(_button("卖一条小河鱼",func(): _do_market_action("卖鱼"),17))
                actor_buttons.add_child(_button("找一小时零工",func(): _do_market_action("做零工"),17))
            else:
                actor_buttons.add_child(_button("打开地图，前往真正的集市",func(): _show_page("地图"),17))
        "书信":
            page_title.text="书信 · 邮资与送达"
            scene_text.text=game.letters_report()
            actor_buttons.visible=true
            _wipe(actor_buttons)
            actor_buttons.add_child(_button("选择熟人写信",func(): _open_contact_list(),17))
            actor_buttons.add_child(_label("信件走真实时间。收到信不代表对方一定回信。",15,FADED))
        "世界":
            page_title.text="世界 · 自主运行"
            var s: Dictionary=game.data.get("society",{})
            var region: String="村" if str(game.data["place"]).begins_with("石桥村") else "城"
            var roster: Dictionary=game.society_roster()
            scene_text.text="【当前区域】%s\n【具名社会居民】%d人\n【自主演算】%d小时\n【货物交易】%d次\n\n世界按真实时间推进；其他居民不必等待你的行动。" % [
                str(game.data["place"]),int(roster.get("size",0)),
                int(s.get("total_steps",0)),int(s.get("total_trades",0))]
            var region_accounts: Dictionary=s.get("economy_accounts",{}).get("regions",{}).get(region,{})
            var region_totals: Dictionary=region_accounts.get("total",{})
            scene_text.text+="\n【累计增加值（GDP）】%d文（固定基期，非交易额）" % int(region_totals.get("gdp_real",0))
            actor_buttons.visible=true
            _wipe(actor_buttons)
            actor_buttons.add_child(_button("查看本地区社会经济详情",func(): _open_economy_region(region),16))
            actor_buttons.add_child(_button("浏览行业与社会身份（按页）",func(): _open_society_roster(),16))
        "经济":
            page_title.text="经济账本 · GDP / 财政 / 物价"
            var current_zone: String="村" if str(game.data["place"]).begins_with("石桥村") else "城"
            scene_text.text=game.economy_report(current_zone)
            actor_buttons.visible=true
            _wipe(actor_buttons)
            actor_buttons.add_child(_button("石桥村经济报表",func(): _open_economy_region("村"),17))
            actor_buttons.add_child(_button("临安县城经济报表",func(): _open_economy_region("城"),17))
        "更多":
            page_title.text="更多 · 功能导航"
            scene_text.text="主界面只保留经常使用的页面。以下资料和工具按需打开，不再挤在游历剧情中。"
            actor_buttons.visible=true
            _wipe(actor_buttons)
            for name in ["书信","世界","经济","设置","反馈"]:
                var target_page:=str(name)
                actor_buttons.add_child(_button("打开 · "+target_page,func(): _show_page(target_page),17))
        "反馈":
            page_title.text="诊断 · 错误与功能建议"
            scene_text.text=game.feedback_report()
        "设置":
            page_title.text="设置 · AI模型与世界参数"
            scene_text.text="模型："+str(local_llm.status() if local_enabled else ai.status())+"\n\n已下载的模型不会因为切换页面而删除。首次下载和断点续传请点击下方『配置AI服务』，本页可查看进度。"
    if view in ["剧情","对话"]:
        # Only auto-follow the two chronological reading surfaces.
        # Updating RichTextLabel invalidates line layout until next frame;
        # deferred scrolling runs after the text has been rebuilt.
        scene_text.scroll_following=true
        scene_text.call_deferred("scroll_to_line",999999)
    else:
        scene_text.scroll_following=false
        scene_text.call_deferred("scroll_to_line",0)
    _refresh_download_widgets()
