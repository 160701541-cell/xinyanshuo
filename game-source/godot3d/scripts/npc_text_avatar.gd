extends Node3D
## CAC-TEXT-001: text-only NPC marker in a genuine 3D scene.
## Label3D + Area3D collision; world coordinates, actor data, no fake 2D game.
signal selected(actor_id: String)
const COLORS := [
	Color("#86b6a7"), Color("#d7bd85"), Color("#9cb1d0"),
	Color("#d5a79a"), Color("#b6c29f")]
var actor_id: String = ""
var display_name: String = ""
var occupation: String = ""
var caption: Label3D
var descriptor: Label3D
var selection_area: Area3D
var is_selected: bool = false

func configure(id: String, person_name: String, job: String, tone: int) -> void:
	actor_id = id
	display_name = person_name
	occupation = job
	name = "TextOnly_NPC_3D"
	caption = Label3D.new()
	caption.name = "ProfessionIn3D"
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	caption.no_depth_test = false
	caption.font_size = 56
	caption.pixel_size = 0.006
	caption.outline_size = 7
	caption.modulate = COLORS[posmod(tone,COLORS.size())]
	caption.text = job
	caption.position = Vector3(0,2.32,0)
	add_child(caption)
	descriptor = Label3D.new()
	descriptor.name = "UniqueNameAndIdentity3D"
	descriptor.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	descriptor.font_size = 36
	descriptor.pixel_size = 0.005
	descriptor.outline_size = 6
	descriptor.modulate = Color("#e9e4d8")
	descriptor.text = person_name + " · " + id.right(4)
	descriptor.position = Vector3(0,1.92,0)
	add_child(descriptor)
	selection_area = Area3D.new()
	selection_area.name = "InteractionArea3D"
	selection_area.collision_layer = 8
	selection_area.collision_mask = 0
	selection_area.set_meta("entity_id",id)
	add_child(selection_area)
	var target := CollisionShape3D.new()
	target.name = "TextSelectionVolume"
	var volume := BoxShape3D.new()
	volume.size = Vector3(1.60,2.90,0.95)
	target.shape = volume
	target.position = Vector3(0,1.45,0)
	selection_area.add_child(target)
	selection_area.input_ray_pickable = true
	selection_area.input_event.connect(_on_interaction)

func _on_interaction(_camera: Node, event: InputEvent,
		_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected.emit(actor_id)
	elif event is InputEventScreenTouch and event.pressed:
		selected.emit(actor_id)

func set_status(task: String, hunger: int, energy: int) -> void:
	if descriptor==null:
		return
	var task_name: String = String({
		"work":"劳作","carrying_grain":"背粮","carrying_wood":"背木",
		"carrying_stone":"搬石","waiting_for_harvest":"待收获",
		"rest":"休息","sleep":"睡觉","delivered":"已交货",
		"eat":"进食","craft":"制作","cook":"做饭"}.get(task,task))
	descriptor.text = display_name+" · "+String(task_name)
	caption.text = occupation+"  饱食"+str(100-clampi(hunger,0,100))+"%"

func mark_selected(value: bool) -> void:
	is_selected = value
	if caption!=null:
		caption.modulate = Color("#fff1b9") if value else COLORS[posmod(int(actor_id.hash()),COLORS.size())]
