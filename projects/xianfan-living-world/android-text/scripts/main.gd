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
var current_npc := "孙成明"
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

func _ready() -> void:
    ai = XianfanAI.new()
    add_child(ai)
    ai.completed.connect(_on_ai_completed)
    local_llm = load("res://scripts/local_llm.gd").new()
    add_child(local_llm)
    local_llm.status_changed.connect(_local_status)
    local_llm.answered.connect(_on_ai_completed)
    local_llm.streaming.connect(_on_local_stream)
    var choice := FileAccess.open("user://xianfan_local_choice.txt",FileAccess.READ)
    if choice!=null and choice.get_as_text()=="1": local_enabled=true
    var director_file:=FileAccess.open(DIRECTOR_PREF,FileAccess.READ)
    if director_file!=null:
        var saved: Variant=JSON.parse_string(director_file.get_as_text())
        if saved is Dictionary and str(saved.get("mode","")) in ["关闭","关键事件","每次行动"]:
            director_mode=str(saved["mode"])
    _build()
    _refresh()

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
    for name in ["剧情","对话","人物","反馈","设置"]:
        var tab_name := str(name)
        var b := _button(tab_name,func(): _change_tab(tab_name),17)
        b.size_flags_horizontal=SIZE_EXPAND_FILL
        b.custom_minimum_size=Vector2(0,54)
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

    reader_footer=_label("所见皆有因 · 行动可自由描述 · 建议指令并非限制",15,FADED)
    reader_footer.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    root.add_child(reader_footer)
    notice=_label("",16,GOLD)
    root.add_child(notice)
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
    settings_button=_button("配置 AI 服务（API / 本机服务）",func(): _open_ai_settings())
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
        "【地点】"+str(chosen["place"]),
        "【正在做】"+str(chosen["activity"]),
        "【情绪】"+str(chosen["mood"]),
        "【个人心愿】"+str(chosen.get("wish","尚未透露")),
        "【心愿行动进度】%d/100（不等于修为）" % int(chosen.get("goal_progress",0)),
        "【在场】"+("可以当面交流" if chosen["here"] else "不在身边，不能远程互动"),
        "【持有物品】"+items]
    if int(chosen["rapport"])>=0: details.append("【关系】亲近程度 %d/100" % int(chosen["rapport"]))
    if int(chosen["learning"])>=0: details.append("【学识】%d/100（不等于灵根或境界）" % int(chosen["learning"]))
    _open_modal("人物档案 · "+name,"\n\n".join(details))
    modal_actions.add_child(_button("与TA交谈",func():
        _close_modal()
        _change_tab("对话")
    ))
    if chosen["here"]:
        var address: String="妹妹" if name=="孙成明" else ("父亲" if name=="钱然泽" else "母亲")
        modal_actions.add_child(_button("询问吃饭了吗",func(): _npc_action("问"+address+"吃饭了吗")))
        modal_actions.add_child(_button("聊聊青云山门",func(): _npc_action("问"+address+"青云的事")))
        for item in game.data["items"].keys():
            if not str(item) in ["小河鱼","青菜","枯枝","车前草"]: continue
            if int(game.data["items"][item])<=0: continue
            var label := "赠送一份"+str(item)
            var cmd := "把"+str(item)+"给"+name
            modal_actions.add_child(_button(label,func(): _npc_action(cmd),17))

func _npc_action(text: String) -> void:
    _close_modal()
    _submit(text,false)

func _open_ai_settings() -> void:
    var expl:="AI 模式由你自行开启。API模式会把你输入的行动和少量游戏现场数据发送至你指定的服务商。\n\n本机服务模式仅连接已经在手机中运行的兼容服务，游戏安装包目前未自带模型权重或内置推理器。\n\n密钥不写入存档，也不加入反馈日志；关闭应用后需要重新填入。"
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
    setting_provider.item_selected.connect(func(_index: int): _sync_provider_fields())
    _sync_provider_fields()

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
        button.visible = (not is_local) if idx<2 else (is_local if idx<4 else true)
    if is_local:
        modal_info.text="在游戏中选择 1.7B / 4B / 8B / 14B 等本地模型，首次由手机自行下载GGUF，下载后缓存并离线生成。大型模型可能耗尽内存甚至被安卓终止。"
    else:
        modal_info.text="API模式通过你配置的服务联网。密钥仅本次运行内存保存；无需下载安装本地模型。"

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

func _local_status(message: String) -> void:
    notice.text=message
    if message.contains("失败") or message.contains("无法运行") or message.contains("没有加载成功"):
        game.note_api_failure("内置GGUF模型 "+str(local_llm.get("active_name")),message)
    if view=="设置": _refresh()

func _enable_local_and_load(confirmed: bool=false) -> void:
    var target_path:=pending_model_path if confirmed else (local_model_url.text if local_model_url!=null else str(local_llm.get("model_source")))
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
    var p:=setting_provider.get_item_text(setting_provider.selected)
    if p=="内置模型":
        local_enabled=true
        ai.configure("关闭",ai.endpoint,ai.model,"")
        var f:=FileAccess.open("user://xianfan_local_choice.txt",FileAccess.WRITE)
        if f!=null: f.store_string("1")
        var result:=str(local_llm.choose_model(local_model_url.text))
        setting_key.clear()
        _close_modal()
        notice.text="已选择模型。请重新进入设置，点击‘下载/加载’，才会开始下载。"+result
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
        raw="跟"+current_npc+"说："+raw
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
        local_llm.talk(raw,npc_to_chat,game.data)
        return
    if not immediate and ai.configured():
        request_text=raw
        notice.text="正在通过你选定的API理解行动或人物对话。"
        if not ai.ask(raw,game.data,npc_to_chat):
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
        scene_text.text=game.dialogue_recent()+"\n\n—— 本地AI正在回复（未保存） ——\n"+contents
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
            scene_text.text=game.look()
            if not game.last_result.is_empty() and game.last_channel=="剧情":
                scene_text.text+="\n\n—— 已结算的行动 ——\n"+game.last_result
            var generated:=game.recent_story_ai(1)
            if not generated.is_empty():
                scene_text.text+="\n\n—— 本地AI叙事 · 不代替规则结算 ——\n"+generated
            var story_flags: Dictionary=game.data.get("story_flags",{})
            if not story_flags.is_empty():
                scene_text.text+="\n\n人生支线已开启 %d 条，可在人物档案查看各人的新打算。" % story_flags.size()
            suggestions=game.actions_for_place().slice(0,3)
            _render_buttons(quick_buttons,suggestions)
            _render_buttons(action_list,game.actions_for_place())
        "对话":
            page_title.text="与人交谈 · "+current_npc
            scene_text.text=game.dialogue_recent()
            if game.last_channel=="对话" and not game.last_result.is_empty() and not scene_text.text.contains(game.last_result):
                scene_text.text+="\n\n【刚才交谈】\n"+game.last_result
            actor_buttons.visible=true
            _wipe(actor_buttons)
            actor_buttons.add_child(_label("选择人物，点击查看状态或更换交谈对象：",16,FADED))
            for n in game.npcs_status():
                var who:=str(n["name"])
                actor_buttons.add_child(_button(who+" · "+str(n["activity"]),func(): _open_npc(who),16))
        "人物":
            page_title.text="人物与身家"
            var full:=game.status()
            scene_text.text=full.split("\n【背包】")[0]
            actor_buttons.visible=true
            _wipe(actor_buttons)
            actor_buttons.add_child(_label("人物档案 · 点击弹出详细属性和互动",18,GOLD))
            for n in game.npcs_status():
                var who:=str(n["name"])
                actor_buttons.add_child(_button(who+"  ·  "+str(n["relationship"])+"  ·  "+str(n["activity"]),func(): _open_npc(who),17))
        "反馈":
            page_title.text="可复制的功能缺口 / 错误日志"
            scene_text.text=game.feedback_report()
        "设置":
            page_title.text="引擎与 AI 模式"
            scene_text.text="AI剧情导演："+director_mode+"；本地模型使用共享推理实例，依人物记忆生成对话，重要行动触发规则约束的故事续写。\n\n当前："+(str(local_llm.status()) if local_enabled else ai.status())+"\n\n【游戏内模型库】支持0.6B、1.7B、4B、8B、14B Q4量化模型。点‘配置 AI 服务’ → ‘内置模型’ → 选择档位 → ‘下载/加载’。4B约2.50GB，8B约5.03GB，14B约9GB。大型模型需要大量RAM和储存空间，可能无法在普通手机上加载。\n\n【其他模型】也可填写合法HTTPS GGUF链接。下载失败请使用反馈页；实际推理速度取决于设备。\n\n【API】仍提供手动配置的OpenAI兼容API模式，密钥不随游戏提供。\n\n【存档】该预览版采用独立包名，不会覆盖已安装的主游戏；两者的存档互不通用。"
    scene_text.call_deferred("scroll_to_line",0)
