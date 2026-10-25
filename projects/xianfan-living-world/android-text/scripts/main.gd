extends Control

# Portrait-first reader, NPC dossier popups and separated dialogue history.
const BG := Color("#101d22")
const PAPER := Color("#f4eee2")
const FADED := Color("#b6c5c7")
const GOLD := Color("#dfbc80")
const PANEL := Color("#20343a")
const BTN := Color("#30494d")

var game := XianfanWorld.new()
var ai: XianfanAI
var view := "剧情"
var current_npc := "孙成明"
var scene_text: RichTextLabel
var title_label: Label
var hud: Label
var page_title: Label
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
    b.custom_minimum_size = Vector2(0, 49)
    b.add_theme_font_size_override("font_size", fs)
    b.add_theme_color_override("font_color", PAPER)
    b.add_theme_stylebox_override("normal", _box(BTN,Color("#446267")))
    b.add_theme_stylebox_override("hover", _box(Color("#415c61"), GOLD))
    b.add_theme_stylebox_override("pressed", _box(Color("#15292e"), GOLD))
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
    root.add_theme_constant_override("separation",8)
    margins.add_child(root)
    title_label=_label("仙 凡 · 苍 岚",29,GOLD)
    title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    root.add_child(title_label)
    hud=_label("",17,FADED)
    hud.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    root.add_child(hud)

    tab_buttons=HBoxContainer.new()
    tab_buttons.add_theme_constant_override("separation",4)
    root.add_child(tab_buttons)
    for name in ["剧情","对话","人物","反馈","设置"]:
        var tab_name := str(name)
        var b := _button(tab_name,func(): _change_tab(tab_name),17)
        b.size_flags_horizontal=SIZE_EXPAND_FILL
        b.custom_minimum_size=Vector2(0,54)
        tab_buttons.add_child(b)

    var reader := PanelContainer.new()
    reader.size_flags_vertical=SIZE_EXPAND_FILL
    reader.add_theme_stylebox_override("panel",_box(PANEL,Color("#4b6468")))
    root.add_child(reader)
    var inside := VBoxContainer.new()
    inside.add_theme_constant_override("separation",9)
    reader.add_child(inside)
    page_title=_label("眼前",20,GOLD)
    inside.add_child(page_title)
    scene_text=RichTextLabel.new()
    scene_text.bbcode_enabled=false
    scene_text.scroll_active=true
    scene_text.fit_content=false
    scene_text.scroll_following=false
    scene_text.size_flags_vertical=SIZE_EXPAND_FILL
    scene_text.add_theme_font_size_override("normal_font_size",23)
    scene_text.add_theme_color_override("default_color",PAPER)
    inside.add_child(scene_text)
    actor_buttons=VBoxContainer.new()
    actor_buttons.add_theme_constant_override("separation",6)
    inside.add_child(actor_buttons)

    notice=_label("",16,GOLD)
    root.add_child(notice)

    quick_buttons=HBoxContainer.new()
    quick_buttons.add_theme_constant_override("separation",7)
    root.add_child(quick_buttons)
    action_toggle=_button("展开参考行动  ▾",func(): _toggle_actions(),16)
    action_toggle.custom_minimum_size=Vector2(0,41)
    root.add_child(action_toggle)
    action_scroll=ScrollContainer.new()
    action_scroll.custom_minimum_size=Vector2(0,190)
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
    command.placeholder_text="直接写行动或对话，不限按钮"
    command.size_flags_horizontal=SIZE_EXPAND_FILL
    command.custom_minimum_size=Vector2(0,60)
    command.add_theme_font_size_override("font_size",20)
    command.add_theme_color_override("font_color",PAPER)
    command.add_theme_stylebox_override("normal",_box(PANEL,Color("#628084")))
    command.add_theme_stylebox_override("focus",_box(PANEL,GOLD))
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
    shade.color=Color(0.02,0.04,0.05,0.85)
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
    var box:=PanelContainer.new()
    box.add_theme_stylebox_override("panel",_box(PANEL,GOLD,15))
    popup_margin.add_child(box)
    var pop_column:=VBoxContainer.new()
    pop_column.add_theme_constant_override("separation",9)
    box.add_child(pop_column)
    modal_title=_label("人物",26,GOLD)
    pop_column.add_child(modal_title)
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
    for name in ["关闭","API","本机服务"]: setting_provider.add_item(name)
    for i in range(setting_provider.item_count):
        if setting_provider.get_item_text(i)==ai.provider: setting_provider.select(i)
    modal_form.add_child(setting_provider)
    setting_url=_input("请求地址（https://.../v1/chat/completions）",ai.endpoint,false)
    setting_model=_input("模型名（服务端实际提供的model）",ai.model,false)
    setting_key=_input("API密钥（只在本次运行内存中保存）","",true)
    for x in [setting_url,setting_model,setting_key]: modal_form.add_child(x)
    modal_actions.add_child(_button("保存本次配置",func(): _save_ai_settings()))

func _input(placeholder: String, value: String, hidden: bool) -> LineEdit:
    var e:=LineEdit.new()
    e.placeholder_text=placeholder
    e.text=value
    e.secret=hidden
    e.add_theme_font_size_override("font_size",17)
    e.custom_minimum_size=Vector2(0,54)
    return e

func _save_ai_settings() -> void:
    var p:=setting_provider.get_item_text(setting_provider.selected)
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
    action_toggle.text="收起参考行动  ▴" if drawer_open else "展开参考行动  ▾"

func _submit(text: String, typed: bool) -> void:
    var raw:=text.strip_edges()
    if raw.is_empty(): return
    if view=="对话" and typed:
        raw="跟"+current_npc+"说："+raw
    command.clear()
    command.release_focus()
    if typed and ai.configured():
        request_text=raw
        notice.text="AI正在理解你的行动；结果必须通过游戏规则才能生效。"
        ai.ask(raw,game.data)
        return
    var result:=game.act(raw)
    notice.text=("已记录到反馈页，可一键复制给开发者。" if result.begins_with("暂不支持") else "")
    if game.last_channel=="对话": view="对话"
    elif game.last_channel=="反馈": view="反馈"
    else: view="剧情"
    _refresh()

func _on_ai_completed(payload: Dictionary) -> void:
    if not payload.get("ok",false):
        var err:=str(payload.get("error","AI服务错误"))
        game.note_api_failure(request_text,err)
        notice.text=err+"  已记录，可到反馈页复制。"
        view="反馈"
        _refresh()
        return
    var kind:=str(payload.get("kind",""))
    if kind=="action":
        var c:=str(payload.get("command","")).strip_edges()
        if c.is_empty():
            game.note_api_failure(request_text,"AI未返回实际行动")
            notice.text="AI没有提供可结算的行动。"
            view="反馈"
        else:
            var outcome:=game.act(c)
            if outcome.begins_with("暂不支持"):
                notice.text="该行动尚未由世界引擎实现；已记录到反馈日志。"
                view="反馈"
            else:
                notice.text="AI已解析行动，由游戏规则完成结算。"
                view="剧情" if game.last_channel=="剧情" else game.last_channel
    elif kind=="dialogue":
        var person:=str(payload.get("npc",""))
        var reply:=str(payload.get("reply",""))
        var response:=game.record_ai_dialogue(person,request_text,reply)
        if game.last_channel=="对话": view="对话"
        else: game.note_api_failure(request_text,response)
        notice.text="AI角色对话已保存（不代表获得物品或修为）。"
    else:
        var info:=str(payload.get("message","描述不够明确"))
        game.note_api_failure(request_text,"尚未实现的行动："+info)
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
    hud.text="%s · %s\n精力 %d/100 · 铜钱 %d文 · %s" % [
        game.time_string(),str(game.data["place"]),int(game.data["stamina"]),
        int(game.data["money"]),str(game.data["realm"])]
    for button in tab_buttons.get_children():
        var tab: Button=button
        tab.add_theme_stylebox_override("normal",_box(Color("#425748") if tab.text==view else BTN,GOLD if tab.text==view else Color("#4c6569")))
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
                scene_text.text+="\n\n—— 刚才发生 ——\n"+game.last_result
            suggestions=game.actions_for_place().slice(0,3)
            _render_buttons(quick_buttons,suggestions)
            _render_buttons(action_list,game.actions_for_place())
        "对话":
            page_title.text="与人交谈 · "+current_npc
            scene_text.text=game.dialogue_recent()
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
            scene_text.text="当前："+ai.status()+"\n\n【API】支持兼容 chat/completions 的HTTPS服务。可自填服务地址、模型名和临时密钥。\n\n【本地模型】本版本没有随 APK 附带原生推理模块；本机服务仅用于连接其他运行在本手机127.0.0.1端口上的推理服务。\n\n【隐私】纯规则模式不联网。只有你主动开启AI并提交行动才发送现场上下文。\n\n【存档】原有存档不删除、不重开。灵根原始承诺仍保持锁定。"
    scene_text.call_deferred("scroll_to_line",0)
