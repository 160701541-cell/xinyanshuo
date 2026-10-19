extends Node
# 通用截图入口：加载任意场景，稳定后截一张图退出
# 用法：godot --path /root/game res://rig/cap.tscn -- --scene=res://rig/compare.tscn --out=res://out/compare.png

func _ready() -> void:
	var path := Shot.arg_s("scene", "res://rig/compare.tscn")
	var out := Shot.arg_s("out", "res://out/cap.png")
	var scn: PackedScene = load(path)
	if scn == null:
		printerr("load failed: ", path)
		get_tree().quit(1)
		return
	add_child(scn.instantiate())
	await Shot.grab_quit(self, out)
