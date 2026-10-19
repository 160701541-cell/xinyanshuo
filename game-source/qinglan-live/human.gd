extends RefCounted
# 人形与兽类：按 6cm 一格建模（28 格 ≈ 1.7m），再整体缩到世界尺度

var vb
const SKIN := Color(0.94, 0.80, 0.68)
const SKIN_D := Color(0.86, 0.71, 0.60)

func _limb(x: int, y: int, z: int, w: int, h: int, d: int, horiz: bool, c: Color) -> void:
	if horiz:
		vb.box(x, y, z, x + h, y + w, z + d, c)
	else:
		vb.box(x, y, z, x + w, y + h, z + d, c)

# 人形：robe 长袍色、hair 发色、hat 发饰、pose 姿势
func person(robe: Color, hair: Color, hat: String, pose: String) -> void:
	var under := robe.darkened(0.18)
	var trim := Color(0.86, 0.74, 0.42)
	# 腿（长袍下摆只到膝，小腿露出来）
	for sx in [-1, 1]:
		var x: int = 11 if sx < 0 else 16
		vb.box(x, 1, 11, x + 3, 10, 15, under)      # 小腿布裤
		vb.box(x, 0, 10, x + 3, 2, 16, Color(0.22, 0.18, 0.16))  # 鞋
	# 袍身：肩宽 10、腰收 8、下摆外扩到 14
	vb.box(10, 10, 10, 20, 14, 16, robe)             # 髋
	vb.box(10, 14, 10, 20, 20, 16, robe)             # 腰腹
	vb.box(9, 20, 9, 21, 26, 17, robe)               # 胸肩
	# 下摆（外扩、盖到膝上）
	vb.box(9, 8, 9, 21, 11, 17, robe.darkened(0.06))
	vb.box(8, 6, 8, 22, 9, 18, robe.darkened(0.12))
	# 腰带
	vb.box(10, 13, 9, 20, 14, 17, trim.darkened(0.12))
	# 衣领交叉
	vb.box(12, 22, 9, 18, 26, 10, robe.lightened(0.10))
	vb.box(14, 21, 9, 16, 25, 10, SKIN_D)
	# 手臂（袖子 + 手）
	var swing := 2 if pose == "walk" else 0
	vb.box(6, 17 + swing, 9, 9, 25, 15, robe)        # 左上臂
	vb.box(6, 13 + swing, 9, 9, 18 + swing, 15, robe.darkened(0.05))
	vb.box(6, 11 + swing, 10, 9, 14 + swing, 14, SKIN)  # 左手
	vb.box(21, 17 - swing, 9, 24, 25, 15, robe)
	vb.box(21, 13 - swing, 9, 24, 18 - swing, 15, robe.darkened(0.05))
	vb.box(21, 11 - swing, 10, 24, 14 - swing, 14, SKIN)
	if pose == "hoe":
		vb.box(4, 18, 9, 9, 26, 15, robe)
		vb.box(19, 18, 9, 24, 26, 15, robe)
		vb.box(7, 16, 9, 21, 19, 15, SKIN)            # 双手前伸
	# 脖子
	vb.box(13, 26, 12, 17, 28, 15, SKIN_D)
	# 头：下颌收窄
	vb.box(12, 28, 11, 18, 31, 17, SKIN)              # 下脸
	vb.box(11, 31, 10, 19, 36, 18, SKIN)              # 颅
	vb.box(11, 28, 10, 12, 31, 18, SKIN_D)            # 左耳
	vb.box(18, 28, 10, 19, 31, 18, SKIN_D)            # 右耳
	# 五官：眉、眼、鼻、嘴
	# 眉（细）
	vb.box(12, 34, 9, 14, 35, 10, Color(0.20, 0.15, 0.12))
	vb.box(16, 34, 9, 18, 35, 10, Color(0.20, 0.15, 0.12))
	# 眼：眼白 + 瞳
	vb.box(12, 32, 9, 14, 34, 10, Color(0.96, 0.95, 0.93))
	vb.box(16, 32, 9, 18, 34, 10, Color(0.96, 0.95, 0.93))
	vb.box(13, 32, 9, 14, 34, 10, Color(0.12, 0.10, 0.12))
	vb.box(16, 32, 9, 17, 34, 10, Color(0.12, 0.10, 0.12))
	vb.box(14, 29, 8, 16, 31, 10, SKIN_D)             # 鼻
	vb.box(13, 29, 9, 17, 30, 10, Color(0.52, 0.28, 0.26))  # 嘴
	# 头发
	vb.box(11, 34, 10, 19, 37, 19, hair)
	vb.box(11, 30, 17, 19, 37, 19, hair)              # 后发披到肩
	vb.box(11, 32, 10, 12, 36, 11, hair)
	vb.box(18, 32, 10, 19, 36, 11, hair)
	if hat == "bun":
		vb.box(13, 37, 13, 17, 39, 17, hair.darkened(0.08))
		vb.box(14, 39, 14, 16, 40, 16, trim)
	elif hat == "pin":
		vb.box(13, 37, 13, 17, 39, 17, hair.darkened(0.08))
		vb.box(10, 38, 14, 13, 39, 15, trim)
		vb.box(17, 38, 14, 20, 39, 15, trim)
	elif hat == "cloth":
		vb.box(11, 35, 9, 19, 37, 19, Color(0.50, 0.44, 0.34))
		vb.box(12, 36, 8, 18, 38, 10, Color(0.46, 0.40, 0.31))
	# 背面衣摆的褶皱
	for i in 3:
		vb.box(10 + i * 4, 6, 18, 11 + i * 4, 10, 19, robe.darkened(0.16))

func chicken() -> void:
	var body := Color(0.92, 0.88, 0.78)
	vb.box(0, 3, 0, 5, 7, 4, body)                    # 身
	vb.box(0, 4, -1, 5, 6, 1, body.lightened(0.06))   # 胸
	vb.box(4, 6, 1, 7, 9, 3, body)                    # 脖
	vb.box(5, 8, 1, 8, 11, 4, body)                   # 头
	vb.box(8, 9, 2, 9, 10, 3, Color(0.92, 0.72, 0.24)) # 喙
	vb.box(6, 11, 2, 8, 12, 3, Color(0.82, 0.26, 0.22)) # 冠
	vb.box(5, 11, 3, 7, 12, 4, Color(0.82, 0.26, 0.22))
	vb.box(0, 4, 4, 3, 7, 5, body.darkened(0.10))      # 尾
	vb.box(0, 5, 5, 2, 8, 6, body.darkened(0.16))
	for sx in [1, 4]:
		vb.box(sx, 0, 1, sx + 1, 3, 2, Color(0.90, 0.68, 0.22))  # 腿
		vb.box(sx - 1, 0, 0, sx + 2, 1, 3, Color(0.90, 0.68, 0.22)) # 爪

func wolf() -> void:
	var fur := Color(0.42, 0.40, 0.38)
	var fur_d := Color(0.30, 0.29, 0.28)
	vb.box(0, 3, 0, 14, 8, 5, fur)                    # 身
	vb.box(0, 4, 1, 14, 9, 4, fur.lightened(0.06))
	vb.box(13, 5, 1, 18, 10, 5, fur)                  # 头
	vb.box(17, 6, 2, 20, 8, 4, fur_d)                 # 吻
	vb.box(14, 9, 1, 15, 12, 3, fur)                  # 耳
	vb.box(16, 9, 2, 17, 12, 4, fur)
	vb.box(11, 8, 1, 14, 9, 5, fur_d)                 # 颈鬃
	vb.box(0, 5, 1, 6, 9, 2, fur)                     # 尾根
	vb.box(-3, 6, 1, 0, 9, 3, fur_d)
	for i in 4:
		var x: int = 1 + i * 3
		vb.box(x, 0, 0, x + 2, 4, 2, fur_d)
		vb.box(x, 0, 0, x + 2, 1, 4, fur_d)
		vb.box(x, 0, 3, x + 2, 4, 5, fur_d)
	vb.box(18, 7, 3, 19, 8, 4, Color(0.92, 0.86, 0.60))  # 眼

# 灵植：藤（不可移动、长刺、花苞发光）
func vine(glow: Color) -> void:
	vb.box(6, 0, 6, 9, 3, 9, Color(0.30, 0.22, 0.14))   # 根
	for i in 10:
		var y := 3 + i * 3
		var x := 7 + int(round(sin(float(i) * 0.9) * 3.0))
		vb.box(x, y, 7, x + 2, y + 3, 9, Color(0.26, 0.40, 0.20))
		if i % 2 == 0:
			vb.box(x - 3, y + 1, 7, x, y + 2, 8, Color(0.30, 0.46, 0.22))  # 叶
			vb.box(x + 2, y + 2, 8, x + 5, y + 3, 9, Color(0.30, 0.46, 0.22))
		if i % 3 == 0:
			vb.box(x + 1, y + 1, 6, x + 2, y + 2, 7, Color(0.16, 0.14, 0.12))  # 刺
	vb.box_e(8, 33, 7, 11, 36, 10, glow)                 # 花苞

func tree_spirit() -> void:
	var bark := Color(0.36, 0.28, 0.20)
	vb.box(6, 0, 6, 12, 16, 12, bark)                    # 主干
	vb.box(5, 16, 5, 13, 30, 13, bark.darkened(0.06))
	vb.box(2, 22, 7, 6, 25, 10, bark)                    # 臂枝
	vb.box(12, 24, 7, 16, 27, 10, bark)
	vb.box(6, 26, 2, 9, 28, 6, bark)
	vb.box(6, 12, 3, 12, 14, 6, bark)                    # 根须
	vb.box(6, 10, 12, 12, 12, 15, bark)
	vb.box(7, 18, 4, 11, 21, 5, Color(0.10, 0.09, 0.08)) # 眼窝
	vb.box(8, 19, 4, 9, 21, 5, Color(0.86, 0.72, 0.30))
	vb.box(10, 19, 4, 11, 21, 5, Color(0.86, 0.72, 0.30))
	vb.box(8, 16, 4, 11, 17, 5, Color(0.14, 0.12, 0.10)) # 嘴
	vb.box(4, 28, 3, 8, 32, 8, Color(0.24, 0.38, 0.20))  # 冠叶
	vb.box(10, 29, 3, 15, 33, 8, Color(0.24, 0.38, 0.20))
