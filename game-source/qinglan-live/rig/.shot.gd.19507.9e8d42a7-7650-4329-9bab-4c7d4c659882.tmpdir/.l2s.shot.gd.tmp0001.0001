extends Node
# 通用截图：等若干帧让画面稳定，再抓视口存 PNG
# 用法（已注册 autoload "Shot"）：await Shot.grab(self, "res://out/x.png")
# 命令行可传 --out=<path> 覆盖默认输出路径

func arg_s(key: String, def: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="):
			return a.substr(key.length() + 3)
	return def

func settle(n := 3) -> void:
	for i in n:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw

func grab(node: Node, path: String, warm := 3) -> void:
	await settle(warm)
	var img: Image = node.get_viewport().get_texture().get_image()
	img.save_png(path)
	print("SHOT ", path, " ", img.get_width(), "x", img.get_height())

# 截图并退出（用于一次性场景）
func grab_quit(node: Node, path: String, warm := 3) -> void:
	await grab(node, path, warm)
	get_tree().quit()
